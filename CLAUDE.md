# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project purpose

Pre-silicon trace generator for the [Adam's Bridge](https://github.com/chipsalliance/adams-bridge) PQC hardware accelerator (FIPS 204 ML-DSA / Dilithium and FIPS 203 ML-KEM / Kyber). It runs a full Verilator RTL simulation of an ML-DSA-87 or ML-KEM-1024 operation and emits VCD toggle traces suitable for TVLA-style side-channel leakage analysis.

## In-progress migration: read `v2-plan.md` first

The repo is on `adams-bridge` v2.0.3 (commit `b77e3d8`). The v2 migration introduced `abr_top` (replacing `mldsa_top`), collapsed the split `mldsa_seq_prim`/`mldsa_seq_sec` sequencers into a single `abr_seq`, added ML-KEM, and added new ML-DSA modes (external-µ, stream-msg). Most stages have landed; `v2-plan.md` is the source of truth for what's `[DONE]` vs `[WIP]` / `[BLOCKED]` / `[TODO]`.

Open items at the time of this writing: Stage 7 (`MASKING_EN`) is `[BLOCKED]` upstream. Stage 11 (hierarchy-focused readvcd configs) is `[DONE]`.

Before making structural changes (touching `rtl/abr_wrap.sv`, `rtl/abr_seq.sv.patch`, `rtl/abr_seq_decode.sv`, `flow/xabr_wrap.vf` generation in the Makefile, or the AHB register map in `src/abr_wrap.cpp`), check the plan to see which stage covers the work and update the stage's status tag when it lands. Do not mark a stage `[DONE]` solely because it compiles — only when its stage-specific validation has passed.

## Prerequisites

- Verilator >= 5.037 (development version; older versions may not work)
- Standard C/C++ toolchain (`gcc`, `g++`)
- Python 3 with `pycryptodome` (provides `Crypto.Hash`) — used by `flow/fips204.py`, `flow/fips203.py`, `flow/mldsa-gen.py`, `flow/mlkem-gen.py`. The system `python3` typically lacks this; bash trace scripts honor `PYTHON=...` (e.g. `PYTHON=/home/mjos/mf3/bin/python3`).
- The `adams-bridge` git submodule must be checked out at the pinned release (currently v2.0.3, commit `b77e3d8`). After fresh clone: `git submodule update --init --recursive`.

## Build

```
make            # builds both readvcd and abr_wrap (Verilator step takes a minute or two)
make abr_wrap   # just the wrapped DUT binary
make lint-abr   # Verilator lint-only check
make clean      # also removes *.vcd, *.dat, _build/, _tr*/, plot/ artifacts
```

The Makefile build does three non-obvious things:

1. **Patches upstream RTL.** `rtl/abr_seq.sv` is *generated* by copying `adams-bridge/src/abr_top/rtl/abr_seq.sv` and applying `rtl/abr_seq.sv.patch`. The patch inserts a hook that `$display`s the current FSM state each cycle, decoded via `rtl/abr_seq_decode.sv` (covers both `MLDSA_*` and `MLKEM_*` symbols). The decoded output appears as `[seq]` lines in run output. If you bump the `adams-bridge` submodule, the patch will likely need to be regenerated.
2. **Verilator file list is generated** at `_build/xabr_wrap.vf` from upstream `adams-bridge/src/abr_top/config/abr_top.vf`. The Makefile materializes `${ADAMSBRIDGE_ROOT}` to the local submodule path, swaps in the patched `rtl/abr_seq.sv`, and appends `rtl/abr_seq_decode.sv` and `rtl/abr_wrap.sv`. Adding new local RTL means editing the Makefile's append step.
3. **Local wrapper.** `rtl/abr_wrap.sv` instantiates `abr_top` + `abr_mem_top` with `AHB_ADDR_WIDTH=32` and CALIPTRA disabled. This is the top-level module that `abr_wrap` (the C++ binary) drives.

## End-to-end trace flow

The pipeline has four stages, each producing inputs for the next:

1. **Vector generators.**
   - `flow/mldsa-gen.py <message> <xi> <rho'>` — pure-Python ML-DSA reference (`flow/fips204.py`) generates test vectors and writes `hash_in.dat`, `seed_in.dat`, `pk_in.dat`, `sk_in.dat`, `rnd_in.dat`, `mu_in.dat` (for external-µ), plus an "expected" `sig_in.dat` for cross-check. All args optional.
   - `flow/mlkem-gen.py {all|keygen|encaps|decaps} <d> <z> <m>` — pure-Python ML-KEM reference (`flow/fips203.py`) writes `seed_d_in.dat`, `seed_z_in.dat`, `msg_in.dat`, `ek_in.dat`, `dk_in.dat`, `ct_in.dat`, `ss_in.dat`.
2. **`./abr_wrap [options] <operation>`** — Verilated RTL sim with a descriptor-driven C++ AHB testbench (`src/abr_wrap.cpp`). Reads the `*_in.dat` files via the AHB register map (constants near the top of `abr_wrap.cpp`, mirrors `adams-bridge/src/abr_top/rtl/abr_reg.rdl`), runs the operation, writes the corresponding `*_out.dat`, and dumps a VCD trace (none by default). Operations:
   - ML-DSA: `mldsa-keygen`, `mldsa-sign`, `mldsa-verify`, `mldsa-kgsign`, `mldsa-sign-extmu` (caller-supplied µ), `mldsa-sign-stream` (variable-length byte stream via `MSG_STROBE`). The bare names `keygen` / `sign` / `verify` / `kgsign` are aliases for the `mldsa-*` versions.
   - ML-KEM: `mlkem-keygen`, `mlkem-encaps`, `mlkem-decaps`, `mlkem-kgdecaps`.
   After signing, a successful run satisfies `cmp sig_out.dat sig_in.dat`. Engine-specific status error masks live in the `Operation` table (`STATUS_MLDSA_ERROR=0x8`, `STATUS_MLKEM_ERROR=0x4`).
3. **`./readvcd <trace.vcd> <time-signal> [threshold] [filters/report-cycles]`** — single-pass C VCD parser. The `<time-signal>` is matched as a substring against signal names; the canonical choice (set in `flow/readvcd.prm`) is `dec.cyc` (the cycle counter inserted by `rtl/abr_seq_decode.sv`). Output is one `# <cycle> [togd] <count>` line per cycle. Optional hierarchy filters `-i <glob>` / `-e <glob>` restrict which VCD signals contribute to the toggle count; the timing signal is still used even if it is outside the selected hierarchy.
4. **`flow/tvla.py`** — Welch t-test over toggle counts from many fixed/random runs, using the streaming `fdist` accumulator (no full data array kept in memory).

VCD traces are huge (~25 GB for one signing op). The `flow/gen-*.sh` scripts avoid writing them to disk by piping through a named pipe:

```
mkfifo trace.vcd
( set -f; ./readvcd trace.vcd $vcdprm > trace.log ) &
./abr_wrap -t $maxcyc -vcd trace.vcd mldsa-sign | tee run.log
```

Trace scripts:

- ML-DSA: `gen-fix.sh` (fixed key, random rnd), `gen-rnd.sh` (fully random sign), `gen-kgr.sh` (keygen+sign combo).
- ML-KEM: `gen-kem-enc-fix.sh`, `gen-kem-enc-rnd.sh`, `gen-kem-dec-fix.sh`, `gen-kem-dec-rnd.sh`, `gen-kem-kg.sh`.

Each script spawns `n` runs into `_tr_<kind>-<id>-<x>/` subdirs (gitignored); `gen-sum.sh` then concatenates `*.log.gz` from each into a single sorted `.dat`. `flow/tvla.py` consumes those.

Hierarchy-focused `readvcd` presets can be passed anywhere a script asks for `<readvcd.prm>`:

- `flow/readvcd.prm` or `flow/readvcd-full.prm`: full-core baseline.
- `flow/readvcd-control.prm`: ABR control/register block.
- `flow/readvcd-sampler.prm`: sampler top, including SHA3.
- `flow/readvcd-sha3.prm`: SHA3 below sampler.
- `flow/readvcd-keccak.prm`: Keccak round/storage below SHA3.
- `flow/readvcd-ntt.prm`: generated NTT instances.
- `flow/readvcd-mldsa-aux.prm`: ML-DSA auxiliary encode/decode/check blocks.
- `flow/readvcd-mlkem-codec.prm`: ML-KEM compress/decompress blocks.
- `flow/readvcd-memory.prm`: wrapper memory/export signals.

The `plot/` directory has a `plot.sh` that turns a tvla output (e.g. `tvla11k.txt`) into the trace/avg/std/tvla gnuplot figures used in `doc/20250530-hardwear-abr.pdf`.

## Default file conventions

`abr_wrap` uses fixed default filenames so scripts can chain without flags. Override any of them with the matching flag.

ML-DSA: `pk_in.dat`/`pk_out.dat` (`-pk`), `sk_in.dat`/`sk_out.dat` (`-sk`), `sig_in.dat`/`sig_out.dat` (`-sig`), `hash_in.dat` (`-hash`), `seed_in.dat` (`-seed`), `rnd_in.dat` (`-rnd`), `mu_in.dat` (`-mu`, external-µ), `strm_in.dat` (`-strm`, stream-msg variable-length payload), `-vfy` (verify result block, default off).

ML-KEM: `seed_d_in.dat` (`-d`), `seed_z_in.dat` (`-z`), `msg_in.dat` (`-msg`), `ek_in.dat`/`ek_out.dat` (`-ek`), `dk_in.dat`/`dk_out.dat` (`-dk`), `ct_in.dat`/`ct_out.dat` (`-ct`), `ss_out.dat` (`-ss`).

Shared: `ent_in.dat` (`-ent`, optional masking entropy at `ABR_ENTROPY=0x18`), VCD output via `-vcd <fn>` (off by default), cycle timeout via `-t <n>`.
