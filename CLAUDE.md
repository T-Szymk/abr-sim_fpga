# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project purpose

Pre-silicon trace generator for the [Adam's Bridge](https://github.com/chipsalliance/adams-bridge) PQC (FIPS 204 ML-DSA / Dilithium) hardware accelerator. It runs a full Verilator RTL simulation of an ML-DSA-87 sign/keygen/verify operation (~40k cycles) and emits VCD toggle traces suitable for TVLA-style side-channel leakage analysis.

## In-progress migration: read `v2-plan.md` first

The repo is currently on `adams-bridge` v1.0.1 (commit `1cad033`, May 2025). A staged migration to v2.0.3 — which adds ML-KEM, renames `mldsa_top`→`abr_top`, collapses the split `mldsa_seq_prim`/`mldsa_seq_sec` sequencers into a single `abr_seq`, and exposes a `MASKING_EN` parameter — is tracked in `v2-plan.md`.

`v2-plan.md` is the source of truth for what changes, in what order, and what's already landed. Before making structural changes (touching `rtl/mldsa_wrap.sv`, the patches under `rtl/*.sv.patch`, `flow/xabr_wrap.vf`, or the AHB register map in `src/mldsa_wrap.cpp`), check the plan to see which stage covers the work and update the stage's status tag (`[TODO]` / `[WIP]` / `[BLOCKED]` / `[DONE]`) when it lands. Do not mark a stage `[DONE]` solely because it compiles — only when its stage-specific validation has passed.

## Prerequisites

- Verilator >= 5.037 (development version; older versions may not work)
- Standard C/C++ toolchain (`gcc`, `g++`)
- Python 3 with `pycryptodome` (`pip3 install pycryptodome`) — used by `flow/fips204.py` and `flow/mldsa-gen.py`
- The `adams-bridge` git submodule must be checked out at the pinned release (currently v1.0.1, commit `1cad0334`). After fresh clone: `git submodule update --init --recursive`.

## Build

```
make            # builds both readvcd and mldsa_wrap (Verilator step takes a minute or two)
make clean      # also removes *.vcd, *.dat, _build/, _tr*/, plot/ artifacts
```

The Makefile build does two non-obvious things:

1. **Patches upstream RTL.** `rtl/mldsa_seq_prim.sv` and `rtl/mldsa_seq_sec.sv` are *generated* by copying the corresponding files from `adams-bridge/src/mldsa_top/rtl/` and applying `rtl/*.sv.patch`. The patches insert hooks that `$display` the current FSM state each cycle (producing the `[prim]` / `[sec ]` lines in run output). If you bump the `adams-bridge` submodule, the patches will likely need to be regenerated.
2. **Verilator file list lives in `flow/xabr_wrap.vf`.** This is the `-f` argument to Verilator and lists every `+incdir` and every `.sv` source. Adding new RTL means editing this file. The local files at the bottom (`rtl/mldsa_seq_*.sv`, `rtl/mldsa_wrap.sv`) wrap and instrument the upstream design.

## End-to-end trace flow

The pipeline has four stages, each producing inputs for the next:

1. **`flow/mldsa-gen.py <message> <xi> <rho'>`** — pure-Python ML-DSA reference (in `flow/fips204.py`) generates test vectors and writes `hash_in.dat`, `seed_in.dat`, `pk_in.dat`, `sk_in.dat`, `rnd_in.dat`, plus an "expected" `sig_in.dat` for cross-check. All args optional.
2. **`./mldsa_wrap [options] {keygen|sign|verify|kgsign}`** — Verilated RTL sim with a C++ AHB-driving testbench (`src/mldsa_wrap.cpp`). Reads the `*_in.dat` files via the AHB register map (constants near the top of `mldsa_wrap.cpp`, mirrors `adams-bridge/.../mldsa_reg.sv`), runs the operation, writes `sig_out.dat` (or `pk_out.dat`/`sk_out.dat`), and dumps a VCD trace (default `trace.vcd`). After signing, a successful run satisfies `cmp sig_out.dat sig_in.dat`.
3. **`./readvcd <trace.vcd> <time-signal> [threshold] [report-cycles]`** — single-pass C VCD parser. The `<time-signal>` is matched as a substring against signal names; the canonical choice is `dec_prim.cyc` (the cycle counter inserted by the FSM-decode hook in `rtl/mldsa_seq_decode.sv`). Output is one `# <cycle> [togd] <count>` line per cycle.
4. **`flow/tvla.py`** — Welch t-test over toggle counts from many fixed/random runs, using the streaming `fdist` accumulator (no full data array kept in memory).

VCD traces are huge (~25 GB for one signing op). The `flow/gen-*.sh` scripts avoid writing them to disk by piping through a named pipe:

```
mkfifo trace.vcd
./readvcd trace.vcd "$vcdprm" > trace.log &
./mldsa_wrap -t $maxcyc -vcd trace.vcd sign | tee run.log
```

`gen-fix.sh` / `gen-rnd.sh` / `gen-kgr.sh` each spawn `n` runs into `_tr_<kind>-<id>-<x>/` subdirs (gitignored); `gen-sum.sh` then concatenates `*.log.gz` from each into a single sorted `.dat`. `flow/tvla.py` consumes those.

The `plot/` directory has a `plot.sh` that turns a tvla output (e.g. `tvla11k.txt`) into the trace/avg/std/tvla gnuplot figures used in `doc/20250530-hardwear-abr.pdf`.

## Default file conventions

`mldsa_wrap` uses fixed default filenames so the scripts can chain without flags: `pk_in.dat`/`pk_out.dat`, `sk_in.dat`/`sk_out.dat`, `sig_in.dat`/`sig_out.dat`, `hash_in.dat`, `seed_in.dat`, `rnd_in.dat`, `ent_in.dat`. Override with `-pk`, `-sk`, `-sig`, `-hash`, `-seed`, `-rnd`, `-ent`, `-vcd`, `-vfy`. `-t <n>` sets a cycle timeout.
