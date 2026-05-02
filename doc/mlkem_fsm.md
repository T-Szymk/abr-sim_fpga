# ML-KEM FSM annotations

This document maps the `[seq]` markers emitted by `abr_wrap` (via the
`rtl/abr_seq_decode.sv` hook) to the FIPS 203 algorithm pseudocode in
[`doc/nist.fips.203.pdf`](nist.fips.203.pdf). Each FSM marker corresponds to a
single microcode address in the sequencer ROM (`adams-bridge/src/abr_top/rtl/abr_seq.sv`).

`abr_seq_decode.sv` prints lines of the form

```
#<cyc> [seq]  <addr>: <NAME>            (named state)
#<cyc> [seq]  <addr>: <BASE> +<offs>    (range state, offs = addr − BASE)
```

The decoder covers four top-level ML-KEM flows:

- `MLKEM_KG_*` — internal key generation (Algorithm 16 → K-PKE.KeyGen Alg 13).
- `MLKEM_ENCAPS_*` — internal encapsulation (Algorithm 17 → K-PKE.Encrypt Alg 14).
- `MLKEM_DECAPS_*` + `MLKEM_ENCAPS_*` + `MLKEM_DECAPS_CHK` — internal
  decapsulation (Algorithm 18). The decaps flow first does a K-PKE.Decrypt
  (Alg 15), then re-runs the K-PKE.Encrypt path (Alg 14, via the same
  `MLKEM_ENCAPS_S` ROM block) for the FO-transform integrity check, then
  produces the implicit-rejection branch in `MLKEM_DECAPS_CHK`.
- `MLKEM_KG_E` / `MLKEM_ENCAPS_E` / `MLKEM_DECAPS_E` — terminal NOPs.

Throughout this document `k = 4`, `η_1 = η_2 = 2`, `d_u = 11`, `d_v = 5`
(ML-KEM-1024 parameters). The ROM has one microinstruction slot per logical
fan-out in those vectors, which is why most FSM ranges have 4 sub-rows.

Opcode notation: `*MASKED*` opcodes do share-domain compute with fresh NTT
randomness (under `MLDSA_MASKING`); the unmasked variants are used for
public-only computations (KeyGen, the public matrix `Â`).

## ML-KEM.KeyGen_internal — FIPS 203 §6.1, Algorithm 16

```text
Input: d, z ∈ B^32

1: (ek_PKE, dk_PKE) ← K-PKE.KeyGen(d)
2: ek ← ek_PKE
3: dk ← (dk_PKE ‖ ek ‖ H(ek) ‖ z)
4: return (ek, dk)
```

K-PKE.KeyGen (Algorithm 13) does the cryptographic work:

```text
Input: d ∈ B^32

 1: (ρ, σ) ← G(d ‖ k)                       ▷ G = SHA3-512
 3: for i ∈ [0..k):                         ▷ k = 4 for ML-KEM-1024
 4:   for j ∈ [0..k):
 5:     Â[i, j] ← SampleNTT(ρ ‖ j ‖ i)
 8: for i ∈ [0..k): s[i] ← SamplePolyCBD_η1(PRF_η1(σ, N)); N ← N+1
12: for i ∈ [0..k): e[i] ← SamplePolyCBD_η1(PRF_η1(σ, N)); N ← N+1
16: ŝ ← NTT(s)
17: ê ← NTT(e)
18: t̂ ← Â ∘ ŝ + ê
19: ek_PKE ← ByteEncode_12(t̂) ‖ ρ
20: dk_PKE ← ByteEncode_12(ŝ)
21: return (ek_PKE, dk_PKE)
```

ROM range: `MLKEM_KG_S` … `MLKEM_KG_S+42`, then `MLKEM_KG_E`.

| FSM marker (offset) | Opcode | FIPS 203 ref | Note |
|---|---|---|---|
| `MLKEM_KG_S +0` | `LD_SHAKE256` (entropy) | (preamble) | load 64 B masking entropy |
| `MLKEM_KG_S +1` | `SHAKE256` → LFSR seed | (preamble) | seed LFSR from entropy |
| `MLKEM_KG_S +2` | `LFSR` | (preamble) | initialize randomness pipe |
| `MLKEM_KG_S +3` | `SHA512(seed_d ‖ 0x04, 33)` → (ρ, σ) | Alg 13 line 1 (`G(d ‖ k)`) | the trailing `0x04` is `IntegerToBytes(k=4, 1)`; ML-KEM uses SHA3-512 = `G` |
| `MLKEM_KG_S +4..+7` | `CBD(σ, N)` × 4 → s[0..3] | Alg 13 lines 8–11 (`s ← SamplePolyCBD_η1(PRF_η1(σ, N))`) | k=4 polys |
| `MLKEM_KG_S +8..+11` | `CBD(σ, N)` × 4 → e[0..3] | Alg 13 lines 12–15 | continues N counter |
| `MLKEM_KG_S +12..+15` | `MLKEM_NTT(s[0..3])` | Alg 13 line 16 (`ŝ ← NTT(s)`) | unmasked |
| `MLKEM_KG_S +16..+19` | `MLKEM_NTT(e[0..3])` | Alg 13 line 17 (`ê ← NTT(e)`) | unmasked |
| `MLKEM_KG_S +20..+23` | `MLKEM_REJS_PWM`, `REJS_PWMA` × 4 | Alg 13 lines 5+18 fused | sample row 0 of Â on the fly (`SampleNTT(ρ ‖ j ‖ i)`, Algorithm 7) and accumulate `Σ_j Â[0,j] ∘ ŝ[j]` into AS0 |
| `MLKEM_KG_S +24` | `MLKEM_PWA(AS0 + e[0])` → t[0] | Alg 13 line 18 (`+ ê`) | row 0 of t̂ |
| `MLKEM_KG_S +25..+29` | row 1 (REJS_PWM/A ×4, PWA) | Alg 13 lines 5+18 | t[1] |
| `MLKEM_KG_S +30..+34` | row 2 | Alg 13 lines 5+18 | t[2] |
| `MLKEM_KG_S +35..+39` | row 3 | Alg 13 lines 5+18 | t[3] |
| `MLKEM_KG_S +40` | `COMPRESS(t[0..3])` → EK_MEM | Alg 13 line 19 (`ek_PKE ← ByteEncode_12(t̂) ‖ ρ`) | imm `0x0403` selects ByteEncode_12 mode; ρ is appended by hardware bookkeeping |
| `MLKEM_KG_S +41` | `COMPRESS(s[0..3])` → DK_MEM | Alg 13 line 20 (`dk_PKE ← ByteEncode_12(ŝ)`) | same opcode, different source |
| `MLKEM_KG_S +42` | `SHA256(ek)` → tr | Alg 16 line 3 (`H(ek)` via SHA3-256) | tr is the public-key hash component of `dk` |
| `MLKEM_KG_E` | `NOP` | Alg 16 line 4 (return) | engine raises `MLKEM_STATUS.VALID`; wrapper concatenates `dk_PKE ‖ ek ‖ tr ‖ z` to form final dk |

Notes:

- **`SampleNTT` is fused with the multiply**: there is no explicit
  `MLKEM_REJ_NTTPOLY` opcode for `Â`. The `MLKEM_REJS_PWM`/`REJS_PWMA`
  opcode samples a row of `Â` directly into the NTT-domain pointwise
  multiplier (Algorithm 7: SampleNTT, the FIPS 203 generalization of
  RejNTTPoly), accumulating into `AS0`. The `imm` field carries the
  matrix row/column index (high byte = row, low byte = column).
- **`G` and `H`**: FIPS 203 specifies G = SHA3-512 and H = SHA3-256. The
  hardware uses `ABR_UOP_SHA512` for G (line 1) and `ABR_UOP_SHA256` for H
  (line 42); both are implemented as Keccak modes.
- **`z` is not touched in keygen**: `z` (the implicit-rejection seed) is
  loaded into the engine via the `MLKEM_SEED_Z` register and copied
  verbatim into `dk` by the wrapper. It only enters the FSM at decapsulation
  time (`MLKEM_DECAPS_CHK +0`).

## ML-KEM.Encaps_internal — FIPS 203 §6.2, Algorithm 17

```text
Input: ek, m ∈ B^32

1: (K, r) ← G(m ‖ H(ek))                     ▷ G = SHA3-512
2: c ← K-PKE.Encrypt(ek, m, r)
3: return (K, c)
```

K-PKE.Encrypt (Algorithm 14) does the cryptographic work:

```text
Input: ek_PKE, m, r ∈ B^32

 1: N ← 0
 2: t̂ ← ByteDecode_12(ek_PKE[0:384k])
 3: ρ ← ek_PKE[384k:384k+32]
 4: for i ∈ [0..k):                          ▷ k = 4 for ML-KEM-1024
 5:   for j ∈ [0..k):
 6:     Â[i, j] ← SampleNTT(ρ ‖ j ‖ i)
 9: for i ∈ [0..k): y[i] ← SamplePolyCBD_η1(PRF_η1(r, N)); N ← N+1
13: for i ∈ [0..k): e_1[i] ← SamplePolyCBD_η2(PRF_η2(r, N)); N ← N+1
17: e_2 ← SamplePolyCBD_η2(PRF_η2(r, N))
18: ŷ ← NTT(y)
19: u ← NTT⁻¹(Â^T ∘ ŷ) + e_1
20: μ ← Decompress_1(ByteDecode_1(m))
21: v ← NTT⁻¹(t̂^T ∘ ŷ) + e_2 + μ
22: c_1 ← ByteEncode_d_u(Compress_d_u(u))
23: c_2 ← ByteEncode_d_v(Compress_d_v(v))
24: return c ← (c_1 ‖ c_2)
```

ROM range: `MLKEM_ENCAPS_S` … `MLKEM_ENCAPS_S+54`, an implicit-NOP slot at
`MLKEM_ENCAPS_S+55`, then `MLKEM_ENCAPS_E` (= `MLKEM_ENCAPS_S+56`). Real
`[seq]` traces will include a `MLKEM_ENCAPS_S +55` line because
`abr_seq_decode.sv` falls into the range-decode for that address.

| FSM marker (offset) | Opcode | FIPS 203 ref | Note |
|---|---|---|---|
| `MLKEM_ENCAPS_S +0..+2` | `LD_SHAKE256`, `SHAKE256`, `LFSR` | (preamble) | masking entropy + LFSR seed |
| `MLKEM_ENCAPS_S +3` | `DECOMPRESS(EK_MEM)` → t[0..3] | Alg 14 line 2 (`t̂ ← ByteDecode_12(ek)`) | imm `0x0403` selects ByteDecode_12 mode; ρ stays in the EK byte stream |
| `MLKEM_ENCAPS_S +4` | `COMPRESS(t)` → EK_MEM (re-pack) | (book-keeping) | repacks t̂ into the canonical wire format used by the SHA pipe; not a FIPS-mandated step |
| `MLKEM_ENCAPS_S +5` | `SHA256(ek)` → tr | Alg 17 line 1 partial (`H(ek)`) | tr will be hashed with m to form (K, r) |
| `MLKEM_ENCAPS_S +6` | `LD_SHA512(msg)` | Alg 17 line 1 (start of G) | absorb m |
| `MLKEM_ENCAPS_S +7` | `SHA512(tr, 32)` → (K, r) | Alg 17 line 1 (`G(m ‖ H(ek))`) | one SHA3-512 absorb covers both halves; output split into K (32 B) and r (32 B) |
| `MLKEM_ENCAPS_S +8..+11` | `CBD(r, N)` × 4 → y[0..3] | Alg 14 lines 9–12 (`y[i] ← SamplePolyCBD_η1`) | uses η_1 (which equals η_2 = 2 for ML-KEM-1024) |
| `MLKEM_ENCAPS_S +12..+15` | `CBD(r, N)` × 4 → e_1[0..3] | Alg 14 lines 13–15 (`e_1[i] ← SamplePolyCBD_η2`) | |
| `MLKEM_ENCAPS_S +16` | `CBD(r, N)` → e_2 | Alg 14 line 17 (`e_2 ← SamplePolyCBD_η2`) | scalar poly |
| `MLKEM_ENCAPS_S +17..+20` | `MLKEM_NTT(y[0..3])` | Alg 14 line 18 (`ŷ ← NTT(y)`) | masked-NTT input — y is per-encapsulation randomness |
| `MLKEM_ENCAPS_S +21..+24` | `MLKEM_MASKED_REJS_PWM/A` × 4 | Alg 14 line 19 partial (`Â^T ∘ ŷ` for row 0) | masked SampleNTT + masked PWM; `imm` low nibble selects row of Â^T |
| `MLKEM_ENCAPS_S +25` | `MLKEM_MASKED_INTT(AY0)` → AY | Alg 14 line 19 (`NTT⁻¹(...)`) | row 0 of u (pre-error) |
| `MLKEM_ENCAPS_S +26` | `MLKEM_PWA(AY + e_1[0])` → u[0] | Alg 14 line 19 (`+ e_1`) | row 0 of u |
| `MLKEM_ENCAPS_S +27..+32` | row 1 (REJS_MASKED_PWM/A ×4, MASKED_INTT, PWA) | Alg 14 line 19 | u[1] |
| `MLKEM_ENCAPS_S +33..+38` | row 2 | Alg 14 line 19 | u[2] |
| `MLKEM_ENCAPS_S +39..+44` | row 3 | Alg 14 line 19 | u[3] |
| `MLKEM_ENCAPS_S +45..+48` | `MLKEM_MASKED_PWM/A(t̂[0..3] ∘ ŷ[0..3])` → TY | Alg 14 line 21 partial (`t̂^T ∘ ŷ`) | accumulates into TY_MASKED |
| `MLKEM_ENCAPS_S +49` | `MLKEM_MASKED_INTT(TY)` → V | Alg 14 line 21 (`NTT⁻¹`) | partial v before error/μ addition |
| `MLKEM_ENCAPS_S +50` | `DECOMPRESS(MSG_MEM)` → MU | Alg 14 line 20 (`μ ← Decompress_1(ByteDecode_1(m))`) | imm `0x0100` selects 1-bit decompress |
| `MLKEM_ENCAPS_S +51` | `MLKEM_PWA(MU + e_2)` → e_2 | Alg 14 line 21 partial (`e_2 + μ`) | rewrites e_2 in place |
| `MLKEM_ENCAPS_S +52` | `MLKEM_PWA(V + e_2)` → V | Alg 14 line 21 (`+ (e_2 + μ)`) | finalize v |
| `MLKEM_ENCAPS_S +53` | `COMPRESS(u)` → C1_MEM | Alg 14 line 22 (`c_1 ← ByteEncode_d_u(Compress_d_u(u))`) | imm `0x0422` carries (k=4, d_u=11) |
| `MLKEM_ENCAPS_S +54` | `COMPRESS(v)` → C2_MEM | Alg 14 line 23 (`c_2 ← ByteEncode_d_v(Compress_d_v(v))`) | imm `0x0121` carries (k=1, d_v=5) |
| `MLKEM_ENCAPS_E` | `NOP` | Alg 14 line 24 / Alg 17 line 3 (return) | engine raises `MLKEM_STATUS.VALID`; wrapper reads (ct, K) |

Notes:

- **Re-encrypt path**: this same `MLKEM_ENCAPS_S` ROM block is re-entered
  during decapsulation as a "re-encryption" check (the FO transform).
  See the Decaps section below.
- **Masked `Â^T ∘ ŷ` in encaps**: the encaps `Â^T ∘ ŷ` step uses
  `MLKEM_MASKED_REJS_PWM/A` even though both operands are public. This is
  consistent across the family — the masked opcode is selected uniformly
  whenever `ŷ` is involved, because in decaps the same instruction sequence
  is reused with `m'` (recovered plaintext) and you cannot afford to leak
  the recovered plaintext.

## ML-KEM.Decaps_internal — FIPS 203 §6.3, Algorithm 18

```text
Input: dk, c

1: dk_PKE ← dk[0:384k]
2: ek_PKE ← dk[384k:768k+32]
3: h ← dk[768k+32:768k+64]
4: z ← dk[768k+64:768k+96]
5: m′ ← K-PKE.Decrypt(dk_PKE, c)
6: (K′, r′) ← G(m′ ‖ h)
7: K̄ ← J(z ‖ c, 32)                          ▷ J = SHAKE256 with 32-byte output
8: c′ ← K-PKE.Encrypt(ek_PKE, m′, r′)
9: if c ≠ c′ then K′ ← K̄                    ▷ implicit rejection
12: return K′
```

K-PKE.Decrypt (Algorithm 15):

```text
Input: dk_PKE, c

1: c_1 ← c[0:32 d_u k]
2: c_2 ← c[32 d_u k : 32 (d_u k + d_v)]
3: u′ ← Decompress_d_u(ByteDecode_d_u(c_1))
4: v′ ← Decompress_d_v(ByteDecode_d_v(c_2))
5: ŝ ← ByteDecode_12(dk_PKE)
6: w ← v′ − NTT⁻¹(ŝ^T ∘ NTT(u′))
7: m ← ByteEncode_1(Compress_1(w))
8: return m
```

ROM ranges (in execution order):

1. `MLKEM_DECAPS_S` … `MLKEM_DECAPS_S+17` — K-PKE.Decrypt of c → m'
2. `MLKEM_ENCAPS_S` … `MLKEM_ENCAPS_S+54` (+ implicit NOP at +55) — re-Encrypt m' to c'
3. `MLKEM_ENCAPS_E` (NOP boundary)
4. `MLKEM_DECAPS_CHK` … `MLKEM_DECAPS_CHK+1` — implicit-rejection branch
5. `MLKEM_DECAPS_E` (NOP terminal)

The compare `c ≠ c′` (line 9) is performed in hardware between stages 3 and
4. The FSM tracks a `decaps_valid` register that is *set at decapsulation
command dispatch* (`set_decaps_valid = 1` at `abr_ctrl.sv:1633` for
`MLKEM_DECAPS` and `:1639` for `MLKEM_KEYGEN_DEC`) and is *cleared* if the
COMPRESS comparison fails during the recomputed-ciphertext writeback
(`clear_decaps_valid` at `abr_ctrl.sv:1520-1521`, which gates on
`compress_compare_failed_i` during the `MLKEM_COMPRESS` aux op). So the
register is "assumed valid, cleared on mismatch."

`K′` is the `(K, r) ← G(m′ ‖ H(ek))` output written to `shared_key` at
`MLKEM_ENCAPS_S+7` (`abr_ctrl.sv:1364`, unconditional). The implicit-reject
value `K̄ = J(z‖c)` is always computed in `MLKEM_DECAPS_CHK +0..+1`, but
its write to `shared_key` (`abr_ctrl.sv:1367-1370`, in the
`MLKEM_DEST_K_REG_ID` arm) is gated by `~decaps_valid & mlkem_decaps_process`
— so on a successful decap `K′` survives, and on a failure it is
overwritten by `K̄`. The wrapper just reads the already-selected value
from `MLKEM_SHARED_KEY`.

| FSM marker (offset) | Opcode | FIPS 203 ref | Note |
|---|---|---|---|
| `MLKEM_DECAPS_S +0..+2` | `LD_SHAKE256`, `SHAKE256`, `LFSR` | (preamble) | masking entropy + LFSR seed |
| `MLKEM_DECAPS_S +3` | `SHA256(ek_PKE)` → tr | Alg 18 line 6 partial (`H(ek)` for `G(m′ ‖ h)`) | `h` is recomputed here rather than read from dk; identical value |
| `MLKEM_DECAPS_S +4` | `DECOMPRESS(DK_MEM)` → s[0..3] | Alg 15 line 5 (`ŝ ← ByteDecode_12(dk_PKE)`) | imm `0x0403` selects ByteDecode_12 mode |
| `MLKEM_DECAPS_S +5` | `DECOMPRESS(C1_MEM)` → u[0..3] | Alg 15 line 3 (`u′ ← Decompress_d_u(ByteDecode_d_u(c_1))`) | imm `0x0402` selects (k=4, d_u=11) |
| `MLKEM_DECAPS_S +6` | `DECOMPRESS(C2_MEM)` → v | Alg 15 line 4 (`v′ ← Decompress_d_v(ByteDecode_d_v(c_2))`) | imm `0x0101` selects (k=1, d_v=5) |
| `MLKEM_DECAPS_S +7..+10` | `MLKEM_NTT(u[0..3])` | Alg 15 line 6 partial (`NTT(u′)`) | masked input domain |
| `MLKEM_DECAPS_S +11..+14` | `MLKEM_MASKED_PWM/A(s[0..3] ∘ NTT(u)[0..3])` → SU | Alg 15 line 6 partial (`ŝ^T ∘ NTT(u′)`) | reads s unmasked from SRAM, splits to shares inside PWM |
| `MLKEM_DECAPS_S +15` | `MLKEM_MASKED_INTT(SU_MASKED)` → SU | Alg 15 line 6 (`NTT⁻¹`) | |
| `MLKEM_DECAPS_S +16` | `MLKEM_PWS(SU − V)` → V | Alg 15 line 6 (`v′ − ...`) | sign convention: hardware computes `SU − V`, then negates by interpretation in the next op |
| `MLKEM_DECAPS_S +17` | `COMPRESS(V)` → MSG_MEM | Alg 15 line 7 (`m ← ByteEncode_1(Compress_1(w))`) | imm `0x0100` = 1-bit compress; result is `m'` |
| `MLKEM_ENCAPS_S +0..+54` | (re-enters encaps ROM) | Alg 18 line 8 (`c′ ← K-PKE.Encrypt(ek_PKE, m′, r′)`) | every step from the encaps section above runs with input `m'` (in MSG_MEM, just written by `DECAPS_S+17`) — note that `MLKEM_ENCAPS_S+5` re-hashes `ek` and `MLKEM_ENCAPS_S+7` produces `(K′, r′)` from `G(m′ ‖ tr)`. The COMPRESS at +53/+54 writes back to C1_MEM/C2_MEM and asserts `compress_compare_failed` if the recomputed bytes differ from the stored ciphertext. |
| `MLKEM_ENCAPS_E` | `NOP` | (control) | re-encrypt finished |
| `MLKEM_DECAPS_CHK +0` | `LD_SHAKE256(seed_z, 32)` | Alg 18 line 7 (start of `J(z ‖ c, 32)`) | absorb z into J |
| `MLKEM_DECAPS_CHK +1` | `SHAKE256(ciphertext, CT_NUM_BYTES)` → K | Alg 18 line 7 (`K̄ ← J(z ‖ c, 32)`) | output is written to `MLKEM_DEST_K_REG_ID`; the conditional write at `abr_ctrl.sv:1367-1370` lets `K̄` overwrite the earlier `K′` only when `~decaps_valid & mlkem_decaps_process` (i.e., the COMPRESS compare cleared `decaps_valid` during re-encrypt) |
| `MLKEM_DECAPS_E` | `NOP` | Alg 18 line 12 (return) | engine raises `MLKEM_STATUS.VALID`; wrapper reads `MLKEM_SHARED_KEY`, which holds either `K′` (success) or `K̄` (implicit reject) |

Notes:

- **`ek_PKE` is reconstructed from `dk` inside the FSM**: there is no opcode
  for "extract ek_PKE bytes". The encaps re-entry at `MLKEM_ENCAPS_S+3`
  reads from `EK_MEM`, which the wrapper has already loaded. For the
  combined `mlkem-kgdecaps` operation the wrapper assembles ek in EK_MEM
  before invoking the FSM.
- **Constant-time implicit-reject**: J(z‖c) is *always* computed
  (`MLKEM_DECAPS_CHK +0..+1`), regardless of whether c = c'. The selection
  between `K′` and `K̄` is the conditional write of `K̄` over `K′` inside
  the `MLKEM_DEST_K_REG_ID` write arm (gated by `~decaps_valid &
  mlkem_decaps_process`); both branches execute the same FSM path, so the
  trace shape is identical for valid and invalid ciphertexts. The wrapper
  observes only the post-selection `MLKEM_SHARED_KEY` value.
- **`mlkem-kgdecaps`**: the `MLKEM_ENCAPS_S+5`'s `SHA256(ek)` is reused as
  the `H(ek)` for the `G(m′‖H(ek))` of `(K′, r′)`. In the combined
  `mlkem-kgdecaps` flow that the wrapper exposes, `ek` is materialized from
  `(d, z)` first (full keygen path), then decapsulation proceeds. The
  `dk` readback in the combined flow is documented as zero in `v2-plan.md`
  Stage 9 — only `ss` is contractual.

## Reading a real `[seq]` log

A real ML-KEM keygen run (`flow/mlkem-gen.py all 01 02 03` vectors)
produces a `[seq]` stream that begins around cycle 85 in the run we used
to verify these docs (the absolute cycle varies — `abr_wrap` does an
AHB-setup window before entering the FSM). Treat the addresses and names
as the stable part — not the cycles.

```
#       3 [seq]      0: ABR_RESET
#      85 [seq]    443: MLKEM_KG_S
...
#    6735 [seq]    486: MLKEM_KG_E
```

For encapsulation the implicit-NOP slot at `MLKEM_ENCAPS_S +55` is observable
in the trace because the decoder falls through to the range-decode branch:

```
#    9389 [seq]    559: MLKEM_ENCAPS_S + 54
#    9459 [seq]    560: MLKEM_ENCAPS_S + 55
#    9460 [seq]    561: MLKEM_ENCAPS_E
```

Decapsulation re-enters the encaps ROM in the middle of its FSM walk, so a
real trace traverses the ROM in this order:

```
487: MLKEM_DECAPS_S
...
504: MLKEM_DECAPS_S + 17
505: MLKEM_ENCAPS_S
...
561: MLKEM_ENCAPS_E
562: MLKEM_DECAPS_CHK
563: MLKEM_DECAPS_CHK +  1
564: MLKEM_DECAPS_E
```

An out-of-spec ciphertext does *not* short the trace — the implicit-reject
path runs identically; the difference is whether the conditional `K̄`-over-`K′`
write at `abr_ctrl.sv:1367-1370` fires.
