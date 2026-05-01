# Adams Bridge v2.0.3 Trace Generator Plan

This document tracks the migration of `abr-sim` from the current Adams Bridge
`v1.0.1` / `1cad033` integration to Adams Bridge `v2.0.3`, including ML-KEM
trace acquisition.

## Progress Tracking

Update this file as work lands. Use the status tags below at the start of each
stage heading:

- `[TODO]` not started
- `[WIP]` actively being implemented
- `[BLOCKED]` blocked by an explicit issue
- `[DONE]` implemented and checked

For each completed stage, add a short note with:

- commit or branch name, if applicable
- commands used for validation
- known limitations or follow-up work

Do not mark a stage `[DONE]` only because it compiles. Mark it done when the
stage-specific validation described below has passed.

## Stage 1: `[WIP]` Target And Baseline

Sync `adams-bridge` to upstream `v2.0.3`.

Keep the current `v1.0.1` flow runnable until the new `abr_top` path passes
ML-DSA regression. This gives a known-good reference for trace shape, generated
files, and TVLA tooling.

Validation:

- Current `mldsa_wrap sign` flow still runs before migration work starts.
- `adams-bridge` checkout is pinned to `v2.0.3`.

Progress:

- `adams-bridge` is checked out at `v2.0.3`
  (`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`).
- The old `mldsa_wrap` runtime checkpoint was not rerun before moving the
  submodule, so this remains `[WIP]` rather than `[DONE]`.

## Stage 2: `[DONE]` Sequence Decode Hook

Rewrite the trace decode hook before wrapper bring-up.

Tasks:

- Replace `rtl/mldsa_seq_prim.sv.patch` and `rtl/mldsa_seq_sec.sv.patch` with
  one `rtl/abr_seq.sv.patch`.
- Generate patched `rtl/abr_seq.sv` from
  `adams-bridge/src/abr_top/rtl/abr_seq.sv`.
- Rewrite `rtl/mldsa_seq_decode.sv` as `rtl/abr_seq_decode.sv`.
- Decode one unified `[seq]` channel instead of `[prim]` / `[sec]`.
- Cover both `MLDSA_*` and `MLKEM_*` symbols from `abr_ctrl_pkg`.
- Update trace params from `dec_prim.cyc` to `dec.cyc`.

Validation:

- Verilator sees the patched `abr_seq.sv`.
- A short ML-DSA run emits meaningful `[seq]` decode markers.

Progress:

- Added `rtl/abr_seq.sv.patch`.
- Added `rtl/abr_seq_decode.sv`.
- Updated `flow/readvcd.prm` from `dec_prim.cyc` to `dec.cyc`.
- `make lint-abr` confirms Verilator sees the patched sequencer.
- Runtime validation passed with short ML-DSA and ML-KEM runs. The decoder emits
  unified `[seq]` markers, including `MLDSA_KG_S`, `MLKEM_KG_S`,
  `MLKEM_ENCAPS_S`, `MLKEM_DECAPS_S`, and `MLKEM_DECAPS_CHK`.

## Stage 3: `[DONE]` ABR Wrapper Boundary

Replace the ML-DSA-only wrapper with `abr_wrap.sv`.

Tasks:

- Instantiate `abr_top`.
- Instantiate `abr_mem_top`.
- Keep `CALIPTRA` disabled initially.
- Explicitly set `AHB_ADDR_WIDTH=32`.
- Leave optional SCA trigger ports for a later enhancement.

Validation:

- Wrapper elaborates against `v2.0.3` RTL.
- Reset/status reads work through AHB.

Progress:

- Added `rtl/abr_wrap.sv`.
- `make lint-abr` elaborates the wrapper against `v2.0.3`.
- Reset/status/name reads work through the C++ driver for both ML-DSA and
  ML-KEM register apertures.

## Stage 4: `[DONE]` Verilator File List

Base `flow/xabr_wrap.vf` on upstream `src/abr_top/config/abr_top.vf`.

Tasks:

- Include new v2 RTL blocks: `abr_top`, `abr_sampler_top`, `cbd_sampler`,
  `barrett_reduction`, `compress`, `decompress`, updated NTT files.
- Handle `${ADAMSBRIDGE_ROOT}` directly in the Makefile or materialize relative
  paths once.
- Do not use symlink indirection; upstream regenerates `.vf` files.

Validation:

- Verilator can parse the full file list for the wrapper.

Progress:

- Makefile now generates `_build/xabr_wrap.vf` from upstream
  `adams-bridge/src/abr_top/config/abr_top.vf`.
- `${ADAMSBRIDGE_ROOT}` is materialized as the local absolute submodule path.
- The generated list swaps in patched `rtl/abr_seq.sv` and appends
  `rtl/abr_seq_decode.sv` plus `rtl/abr_wrap.sv`.
- Validation command: `make lint-abr`.

## Stage 5: `[DONE]` Generic C++ Driver

Refactor `src/mldsa_wrap.cpp` into an ABR driver.

Tasks:

- Audit all address widths for `AHB_ADDR_WIDTH=32`.
- Preserve existing AHB data-lane logic.
- Preserve existing VCD windowing: off during bulk `[XFER]`, on during
  cryptographic operation windows.
- Poll `READY`, `VALID`, and `ERROR`.
- Split ML-DSA and ML-KEM register maps/sizes into descriptors.

Validation:

- Driver can read ABR name/version/status registers.
- Timeout and error reporting are clear enough for batch trace scripts.

Progress:

- Replaced the mechanical copy with a descriptor-driven `src/abr_wrap.cpp`.
- The driver supports the ML-DSA and ML-KEM register maps, 32-bit AHB addresses,
  common input/output transfers, and VCD windowing around only the cryptographic
  operation.
- ML-KEM status completes with `VALID` rather than `READY`; the driver treats
  either `READY` or `VALID` as a terminal wait condition and still prints
  `ERROR` when present.
- Validation commands: `make abr_wrap`, short bounded `mldsa-keygen`, and full
  ML-KEM keygen/encaps/decaps runs.

## Stage 6: `[TODO]` ML-DSA Regression Checkpoint

Restore existing ML-DSA operations first:

- `keygen`
- `sign`
- `verify`
- `kgsign`

This is the hard checkpoint. Do not start ML-KEM RTL acquisition until current
ML-DSA signing trace acquisition works on `abr_top`.

Validation:

- Existing ML-DSA vector generation still works.
- `sign` produces a valid signature.
- `verify` accepts that signature.
- VCD/toggle trace generation still works with the new `[seq]` decode channel.

## Stage 7: `[BLOCKED]` MASKING_EN Build Matrix

Add a build switch for masked and unmasked DUTs.

Tasks:

- Default to `MASKING=1`.
- Support `make MASKING=0`.
- Pass the value as a parameter override to `abr_top`.

Validation:

- Both masked and unmasked builds compile.
- A small ML-DSA trace comparison shows strong leakage on the unmasked build,
  confirming the TVLA pipeline is still sensitive.

Blocker:

- The `v2.0.3` `abr_top` module does not expose `MASKING_EN` or `SRAM_LATENCY`
  parameters. Masking is encoded in sequencer opcodes and internal control, so
  this needs an explicit RTL-level hook or patch rather than a simple top-level
  parameter override.

## Stage 8: `[DONE]` ML-KEM Vector Generator

Use a small self-contained generator for ML-KEM-1024 vectors.

Current files:

- `flow/fips203.py`: local FIPS 203 implementation
- `flow/mlkem-gen.py`: raw `.dat` generator

Expected generated files:

- `seed_d_in.dat` - 32 bytes
- `seed_z_in.dat` - 32 bytes
- `msg_in.dat` - 32 bytes
- `ek_in.dat` - 1568 bytes
- `dk_in.dat` - 3168 bytes
- `ct_in.dat` - 1568 bytes
- `ss_in.dat` - 32 bytes

Use the mamba Python environment unless system Python has `Crypto.Hash`.

Validation:

- Generator passes internal `keygen -> encaps -> decaps` self-check.
- Generated file sizes match the list above.

Progress:

- Added `flow/mlkem-gen.py`.
- Adjusted `flow/fips203.py` so it can be imported without the optional
  upstream `test_mlkem.py` harness.
- Validation command:
  `/home/mjos/mf3/bin/mamba run python3 flow/mlkem-gen.py all 01 02 03`.

## Stage 9: `[WIP]` ML-KEM Acquisition

Add wrapper operations:

- `kem-keygen`
- `kem-encaps`
- `kem-decaps`
- `kem-kgdecaps`

Use the `v2.0.3` ML-KEM register map:

- `MLKEM_CTRL = 0x9010`
- `MLKEM_STATUS = 0x9014`
- `MLKEM_SEED_D = 0x9018`
- `MLKEM_SEED_Z = 0x9038`
- `MLKEM_SHARED_KEY = 0x9058`
- `MLKEM_MSG = 0x9080`
- `MLKEM_DECAPS_KEY = 0xa000`
- `MLKEM_ENCAPS_KEY = 0xb000`
- `MLKEM_CIPHERTEXT = 0xb800`

Also verify the shared `ABR_ENTROPY` block at `0x18` is correctly used for
ML-KEM masking entropy.

Validation:

- `mlkem-keygen` output matches `mlkem-gen.py`.
- `mlkem-encaps` output shared key and ciphertext match `mlkem-gen.py`.
- `mlkem-decaps` output shared key matches `mlkem-gen.py`.

Progress:

- Implemented `mlkem-keygen`, `mlkem-encaps`, `mlkem-decaps`, and
  `mlkem-kgdecaps` in `src/abr_wrap.cpp`.
- Validated keygen with `/tmp/seed_d_in.dat` and `/tmp/seed_z_in.dat`; DUT
  `dk` and `ek` matched `flow/mlkem-gen.py`.
- Validated encaps with generated `ek` and `msg`; DUT `ct` and `ss` matched.
- Validated decaps with generated `dk` and `ct`; DUT `ss` matched.
- `mlkem-kgdecaps` is implemented but not yet separately checked, so this stage
  remains `[WIP]`.

## Stage 10: `[TODO]` ML-KEM Trace Scripts

Mirror the current ML-DSA trace scripts for ML-KEM.

Initial scripts should cover:

- fixed/random encaps traces
- decapsulation traces
- optional keygen traces
- parameter logs compatible with current TVLA scripts

Validation:

- Batch scripts collect traces through FIFO VCD parsing.
- Logs are compressed and named consistently with existing ML-DSA flows.

## Stage 11: `[TODO]` Trace Resolution Enhancements

Keep basic acquisition independent from selective hierarchy filtering.

After acquisition works, add optional hierarchy-focused configs for:

- NTT/PWM
- CBD sampler
- compression/decompression
- SHA3
- memory/control

Validation:

- Full-core toggle traces still work.
- Optional focused configs produce shorter, interpretable traces.

## Stage 12: `[TODO]` New ML-DSA Modes

Add non-P0 `v2.0.3` ML-DSA flows:

- external-mu
- stream-message mode
- context handling, if needed

Stream-message mode deserves separate traces because chunk timing changes the
acquisition shape.

Validation:

- External-mu mode passes known-answer or self-generated vectors.
- Stream-message mode handles partial final chunks and exposes useful timing in
  the trace logs.
