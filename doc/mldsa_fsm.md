# ML-DSA FSM annotations

This document maps the `[seq]` markers emitted by `abr_wrap` (via the
`rtl/abr_seq_decode.sv` hook) to the FIPS 204 algorithm pseudocode in
[`doc/nist.fips.204.pdf`](nist.fips.204.pdf). Each FSM marker corresponds to a
single microcode address in the sequencer ROM (`adams-bridge/src/abr_top/rtl/abr_seq.sv`).

`abr_seq_decode.sv` prints lines of the form

```
#<cyc> [seq]  <addr>: <NAME>            (named state)
#<cyc> [seq]  <addr>: <BASE> +<offs>    (range state, offs = addr − BASE)
```

The decoder covers three top-level ML-DSA flows: `MLDSA_KG_*` (Algorithm 6),
`MLDSA_SIGN_*` (Algorithm 7), `MLDSA_VERIFY_*` (Algorithm 8). Mode-specific
prologues for `mldsa-sign-extmu`, `mldsa-sign-stream`, and `mldsa-kgsign`
share the same ROM and just enter through different `*_CHECK_MODE` /
`*_JUMP_*` states.

Throughout this document `k = 8`, `ℓ = 7` (ML-DSA-87 parameters). The ROM has
one microinstruction slot per logical fan-out in those vectors, which is why
many FSM ranges have 7 or 8 sub-rows.

Opcode notation: `*MASKED*` opcodes do share-domain compute with fresh NTT
randomness (under `MLDSA_MASKING`); the unmasked variants are used for
public-only computations.


## ML-DSA.KeyGen_internal — FIPS 204 §6.1, Algorithm 6

```text
Input: ξ ∈ B^32

 1: (ρ, ρ′, K) ∈ B^32 × B^64 × B^32 ← H(ξ ‖ IntegerToBytes(k,1) ‖ IntegerToBytes(ℓ,1), 128)
 3: Â ← ExpandA(ρ)                         ▷ matrix in NTT domain
 4: (s1, s2) ← ExpandS(ρ′)
 5: t ← NTT⁻¹(Â ∘ NTT(s1)) + s2            ▷ public value
 6: (t1, t0) ← Power2Round(t)
 8: pk ← pkEncode(ρ, t1)
 9: tr ← H(pk, 64)
10: sk ← skEncode(ρ, K, tr, s1, s2, t0)
11: return (pk, sk)
```

ROM range: `MLDSA_KG_S` … `MLDSA_KG_S+100`, then `MLDSA_KG_JUMP_SIGN`,
`MLDSA_KG_E`. The `JUMP_SIGN` slot is the splice point for `mldsa-kgsign`; it
re-enters the signing flow without re-decoding the secret key.

| FSM marker (offset) | Opcode | FIPS 204 Alg 6 | Note |
|---|---|---|---|
| `MLDSA_KG_S +0` | `LD_SHAKE256` (entropy) | (preamble) | load 64 B masking entropy |
| `MLDSA_KG_S +1` | `SHAKE256` → LFSR seed | (preamble) | seed the on-chip LFSR |
| `MLDSA_KG_S +2` | `LFSR` | (preamble) | initialize randomness pipe |
| `MLDSA_KG_S +3` | `SHAKE256(ξ‖k‖ℓ, 128)` → (ρ, ρ′, K) | line 1 | seed expansion: `MLDSA_DEST_K_RHO_REG_ID` writes ρ ← bits[255:0], ρ′ ← bits[767:256], K ← bits[1023:768] of the SHAKE squeeze (`abr_ctrl.sv:1345-1349`) |
| `MLDSA_KG_S +4 … +10` | `REJB` × 7 → s1[0..6] | line 4 (`ExpandS(ρ′)`, RejBoundedPoly per coordinate) | uses Algorithm 31 RejBoundedPoly; ℓ=7 polys |
| `MLDSA_KG_S +11 … +18` | `REJB` × 8 → s2[0..7] | line 4 (continued) | k=8 polys |
| `MLDSA_KG_S +19 … +25` | `NTT(s1[0..6])` (unmasked) | line 5 (`NTT(s1)`) | secret in clear here — see notes |
| `MLDSA_KG_S +26 … +32` | `REJS_PWM`, `REJS_PWMA` × 7 | lines 3+5 fused | sample row 0 of Â on the fly (`ExpandA(ρ)`, RejNTTPoly, Algorithm 30) and accumulate `Σ_j Â[0,j] ∘ NTT(s1)[j]` into `AS0` |
| `MLDSA_KG_S +33` | `INTT(AS0)` | line 5 (`NTT⁻¹(...)`) | back to time domain |
| `MLDSA_KG_S +34` | `PWA(AS0_INTT + s2[0])` → t[0] | line 5 (`+ s2`) | row 0 of `t` |
| `MLDSA_KG_S +35 … +43` | row 1 of t (REJS_PWM/A ×7, INTT, PWA) | lines 3+5 | repeat for `t[1]` |
| `MLDSA_KG_S +44 … +52` | row 2 of t | lines 3+5 | `t[2]` |
| `MLDSA_KG_S +53 … +61` | row 3 of t | lines 3+5 | `t[3]` |
| `MLDSA_KG_S +62 … +70` | row 4 of t | lines 3+5 | `t[4]` |
| `MLDSA_KG_S +71 … +79` | row 5 of t | lines 3+5 | `t[5]` |
| `MLDSA_KG_S +80 … +88` | row 6 of t | lines 3+5 | `t[6]` |
| `MLDSA_KG_S +89 … +97` | row 7 of t | lines 3+5 | `t[7]` |
| `MLDSA_KG_S +98` | `PWR2RND(t[0])` → SK_T0 | line 6 (`Power2Round`) | engine streams t[0..7] sequentially through Power2Round; only one ROM slot because `aux` block consumes the whole vector |
| `MLDSA_KG_S +99` | `SHAKE256(pk, 64)` → tr | line 9 | tr is computed from the encoded pk, which the wrapper has already streamed into the PK register |
| `MLDSA_KG_S +100` | `SKENCODE` | line 10 (`skEncode`) | packs (ρ, K, tr, s1, s2, t0) into the AHB-readable `sk` mailbox |
| `MLDSA_KG_JUMP_SIGN` | `NOP` | (control) | branch target for `mldsa-kgsign` (KeyGen + immediate Sign in one engine cycle) |
| `MLDSA_KG_E` | `NOP` | line 11 (return) | engine raises `MLDSA_STATUS.READY` |

Notes:

- **Public-vs-secret split**: keygen runs entirely with unmasked NTT/PWM
  opcodes. The threat model assumes keygen happens once in a trusted context,
  so the secrets `s1`, `s2`, `t0` are computed in the clear and are then
  stored unmasked in SRAM for later signing.
- **`ExpandA` is fused with the multiply**: there is no explicit `ABR_UOP_NTT`
  for matrix `Â`. The `REJS_PWM`/`REJS_PWMA` opcode samples a row of `Â`
  directly into the NTT-domain pointwise multiplier (Algorithm 30:
  RejNTTPoly), accumulating into `AS0`. The `imm` field carries the matrix
  row/column index.
- **`Power2Round` is implicit in line 6**: the auxiliary block consumes the
  whole `t` vector and writes both `t1` (into the PK mailbox) and `t0`
  (into the SK mailbox) in one ROM slot.

## ML-DSA.Sign_internal — FIPS 204 §6.2, Algorithm 7

```text
Input: sk, M′, rnd ∈ B^32

 1: (ρ, K, tr, s1, s2, t0) ← skDecode(sk)
 2: ŝ1 ← NTT(s1)
 3: ŝ2 ← NTT(s2)
 4: t̂0 ← NTT(t0)
 5: Â ← ExpandA(ρ)                          ▷ stored in NTT representation
 6: μ ← H(BytesToBits(tr) ‖ M′, 64)
 7: ρ″ ← H(K ‖ rnd ‖ μ, 64)
 8: κ ← 0
 9: (z, h) ← ⊥
10: while (z, h) = ⊥ do                     ▷ rejection sampling loop
11:   y ∈ R_q^ℓ ← ExpandMask(ρ″, κ)
12:   w ← NTT⁻¹(Â ∘ NTT(y))                 ▷ signer's commitment
13:   w1 ← HighBits(w)
15:   c̃ ← H(μ ‖ w1Encode(w1), λ/4)          ▷ commitment hash
16:   c ∈ R_q ← SampleInBall(c̃)              ▷ verifier's challenge
17:   ĉ ← NTT(c)
18:   ⟨⟨cs1⟩⟩ ← NTT⁻¹(ĉ ∘ ŝ1)
19:   ⟨⟨cs2⟩⟩ ← NTT⁻¹(ĉ ∘ ŝ2)
20:   z ← y + ⟨⟨cs1⟩⟩                        ▷ signer's response
21:   r0 ← LowBits(w − ⟨⟨cs2⟩⟩)
23:   if ‖z‖∞ ≥ γ1−β or ‖r0‖∞ ≥ γ2−β then (z, h) ← ⊥
24:   else
25:     ⟨⟨ct0⟩⟩ ← NTT⁻¹(ĉ ∘ t̂0)
26:     h ← MakeHint(−⟨⟨ct0⟩⟩, w − ⟨⟨cs2⟩⟩ + ⟨⟨ct0⟩⟩)
28:     if ‖⟨⟨ct0⟩⟩‖∞ ≥ γ2 or |h|>ω then (z, h) ← ⊥
31:   κ ← κ + ℓ
33: σ ← sigEncode(c̃, z mod^± q, h)
34: return σ
```

ROM range: `MLDSA_SIGN_S` … `MLDSA_SIGN_E`. The rejection-sampling loop
(Alg 7 lines 10–32) is mapped onto a **single linear pass** of the ROM
(`MAKE_Y_S` → `MAKE_W_S` → `MAKE_W` → `MAKE_C` → `VALID_S` → `CHL_E`); on a
rejection the engine restarts at `MLDSA_SIGN_LFSR_S` to re-seed the LFSR for
the next κ value. `[seq]` markers therefore repeat across iterations.

| FSM marker (offset) | Opcode | FIPS 204 Alg 7 | Note |
|---|---|---|---|
| `MLDSA_SIGN_S +0 … +2` | `LD_SHAKE256`, `SHAKE256`, `LFSR` | (preamble) | masking entropy + LFSR seed |
| `MLDSA_SIGN_CHECK_MODE` | `NOP` | (control) | branch point — `mldsa-sign-extmu` skips H_MU; `mldsa-sign-stream` enters the byte-streaming sub-FSM here |
| `MLDSA_SIGN_H_MU +0..+1` | `LD_SHAKE256(tr)` then `SHAKE256(M′, 66)` → μ | line 6 (`μ ← H(tr ‖ M′, 64)`) | engine prepends the standard `0x00 ‖ ctx_size` framing inside `abr_ctrl.sv` for pure-mode signing |
| `MLDSA_SIGN_H_RHO_P +0..+2` | `LD_SHAKE256(K)`, `LD_SHAKE256(rnd)`, `SHAKE256(μ, 64)` → ρ″ | line 7 (`ρ″ ← H(K ‖ rnd ‖ μ, 64)`) | the deterministic variant fixes `rnd = 0^32` at the wrapper level |
| `MLDSA_SIGN_INIT_S +0` | `SKDECODE` | line 1 (`skDecode(sk)`) | unpacks `(ρ, K, tr, s1, s2, t0)` into private SRAM |
| `MLDSA_SIGN_INIT_S +1..+8` | `NTT(t0[0..7])` | line 4 (`t̂0 ← NTT(t0)`) | unmasked because ABR stores/uses `t0` unmasked; FIPS 204 treats `t0` as a private-key component (Alg 6 lines 6, 10), so this is a leakage surface, not a public computation |
| `MLDSA_SIGN_INIT_S +9..+15` | `NTT(s1[0..6])` | line 2 (`ŝ1 ← NTT(s1)`) | unmasked — see masking note below |
| `MLDSA_SIGN_INIT_S +16..+23` | `NTT(s2[0..7])` | line 3 (`ŝ2 ← NTT(s2)`) | unmasked |
| `MLDSA_SIGN_LFSR_S +0..+2` | `LD_SHAKE256`, `SHAKE256`, `LFSR` | (rejection-loop preamble) | re-seed LFSR per κ; on a `(z,h)=⊥` rejection the engine jumps back here |
| `MLDSA_SIGN_MAKE_Y_S +0..+6` | `EXP_MASK(ρ″, κ, j)` × 7 → y[0..6] | line 11 (`ExpandMask(ρ″, κ)`) | Algorithm 34 |
| `MLDSA_SIGN_MAKE_Y_S +7..+13` | `NTT(y[0..6])` | line 12 (`NTT(y)`) | masked-NTT input — fresh per κ |
| `MLDSA_SIGN_MAKE_W_S +0..+6` | `REJS_MASKED_PWM/PWMA` × 7 | line 12 (`Â ∘ NTT(y)`) for w[0] | row 0 of Â sampled on the fly + masked PWM accumulate into AY0 |
| `MLDSA_SIGN_MAKE_W_S +7` | `MASKED_INTT(AY0)` → w[0] | line 12 (`NTT⁻¹(...)`) | row 0 of `w` (`HighBits` is implicit in subsequent `w1Encode` consumption) |
| `MLDSA_SIGN_MAKE_W_S +8..+15` | row 1: REJS_MASKED_PWM/A ×7, MASKED_INTT | line 12 | w[1] |
| `MLDSA_SIGN_MAKE_W_S +16..+23` | row 2 | line 12 | w[2] |
| `MLDSA_SIGN_MAKE_W_S +24..+31` | row 3 | line 12 | w[3] |
| `MLDSA_SIGN_MAKE_W_S +32..+39` | row 4 | line 12 | w[4] |
| `MLDSA_SIGN_MAKE_W_S +40..+47` | row 5 | line 12 | w[5] |
| `MLDSA_SIGN_MAKE_W_S +48..+55` | row 6 | line 12 | w[6] |
| `MLDSA_SIGN_MAKE_W_S +56..+63` | row 7 | line 12 | w[7] (k=8) |
| `MLDSA_SIGN_MAKE_W_S +64` | (implicit NOP) | (control) | `MLDSA_SIGN_MAKE_W = MLDSA_SIGN_MAKE_W_S + 65`, so address 220 falls into the `MAKE_W_S` range-decode and prints as `MLDSA_SIGN_MAKE_W_S +64` |
| `MLDSA_SIGN_MAKE_W` | (boundary marker) | (control) | tag separating `w` computation from challenge hash |
| `MLDSA_SIGN_MAKE_C +0` | `RUN_SHAKE256` → c̃ | line 15 (`c̃ ← H(μ ‖ w1Encode(w1), λ/4)`) | hash absorbs μ then streams `w1Encode(w[i])` for i=0..7 |
| `MLDSA_SIGN_MAKE_C +1` | `SIB(c̃, 64)` → c | line 16 (`c ← SampleInBall(c̃)`) | Algorithm 29 |
| `MLDSA_SIGN_VALID_S +0` | `NTT(c)` → ĉ | line 17 (`ĉ ← NTT(c)`) | unmasked — c is public |
| `MLDSA_SIGN_VALID_S +1` | `MASKED_PWM(ĉ ∘ s1[0])` → CS_NTT | line 18 (term i=0) | reads `s1[0]` unmasked from SRAM, splits to shares inside PWM |
| `MLDSA_SIGN_VALID_S +2` | `MASKED_INTT(CS_NTT)` → cs1[0] | line 18 | |
| `MLDSA_SIGN_VALID_S +3` | `PWA(y[0] + cs1[0])` → z[0] | line 20 (term i=0) | unmasked PWA — z is the public response |
| `MLDSA_SIGN_VALID_S +4` | `NORMCHK(z[0], γ1−β)` | line 23 (`‖z‖∞ ≥ γ1−β`) | per-row early reject |
| `MLDSA_SIGN_VALID_S +5` | `SIGENCODE(z[0])` | line 33 partial (`sigEncode`) | encodes z[0] in place into SIG mailbox |
| `MLDSA_SIGN_VALID_S +6..+10` | row 1 of (s1, z) | lines 18, 20, 23, 33 | repeat for i=1 |
| `MLDSA_SIGN_VALID_S +11..+15` | row 2 | lines 18, 20, 23, 33 | i=2 |
| `MLDSA_SIGN_VALID_S +16..+20` | row 3 | lines 18, 20, 23, 33 | i=3 |
| `MLDSA_SIGN_VALID_S +21..+25` | row 4 | lines 18, 20, 23, 33 | i=4 |
| `MLDSA_SIGN_VALID_S +26..+30` | row 5 | lines 18, 20, 23, 33 | i=5 |
| `MLDSA_SIGN_VALID_S +31..+35` | row 6 | lines 18, 20, 23, 33 | i=6 |
| `MLDSA_SIGN_VALID_S +36..+37` | `MASKED_PWM(ĉ ∘ t0[0])`, `MASKED_INTT` → ct0[0] | line 25 (term i=0) | `⟨⟨ct0⟩⟩` |
| `MLDSA_SIGN_VALID_S +38..+39` | row 1 of ct0 | line 25 | ct0[1] |
| `MLDSA_SIGN_VALID_S +40..+51` | rows 2..7 of ct0 | line 25 | ct0[2..7] |
| `MLDSA_SIGN_VALID_S +52..+53` | `MASKED_PWM(ĉ ∘ s2[0])`, `MASKED_INTT` → cs2[0] | line 19 (term i=0) | `⟨⟨cs2⟩⟩` |
| `MLDSA_SIGN_VALID_S +54` | `PWS(cs2[0] − w0[0])` → r0 | line 21 (`LowBits(w − ⟨⟨cs2⟩⟩)`, the LowBits is implicit in the previous `w` representation) | |
| `MLDSA_SIGN_VALID_S +55` | `NORMCHK(r0, γ2−β)` | line 23 (`‖r0‖∞ ≥ γ2−β`) | |
| `MLDSA_SIGN_VALID_S +56` | `NORMCHK(ct0[0], γ2)` | line 28 (`‖⟨⟨ct0⟩⟩‖∞ ≥ γ2`) | second validity check |
| `MLDSA_SIGN_VALID_S +57` | `PWA(r0 + ct0[0])` → hint_r[0] | line 26 prep (one operand of MakeHint) | r0 + ct0 = w − cs2 + ct0; the engine's MakeHint takes (-ct0, this) |
| `MLDSA_SIGN_VALID_S +58..+63` | row 1 of (s2, r0, ct0, hint_r) | lines 19, 21, 23, 26, 28 | i=1 |
| `MLDSA_SIGN_VALID_S +64..+69` | row 2 | i=2 | |
| `MLDSA_SIGN_VALID_S +70..+75` | row 3 | i=3 | |
| `MLDSA_SIGN_VALID_S +76..+81` | row 4 | i=4 | |
| `MLDSA_SIGN_VALID_S +82..+87` | row 5 | i=5 | |
| `MLDSA_SIGN_VALID_S +88..+93` | row 6 | i=6 | |
| `MLDSA_SIGN_VALID_S +94..+99` | row 7 | i=7 | |
| `MLDSA_SIGN_VALID_S +100` | `MAKEHINT(hint_r[0..7], -ct0[0..7])` → h | line 26 (`MakeHint`) | also enforces `|h| ≤ ω` constraint of line 28; on overflow the engine signals `(z,h)=⊥` and the FSM resumes at `MLDSA_SIGN_LFSR_S` |
| `MLDSA_SIGN_CHL_E` | `NOP` | (control) | end of one rejection iteration; on success the FSM falls through to `MLDSA_SIGN_E`; on rejection it loops to `MLDSA_SIGN_LFSR_S` |
| `MLDSA_SIGN_E` | `NOP` | line 34 (return) | `STATUS.VALID` is raised — wrapper reads encoded σ |

Notes:

- **Masking model**: the `*MASKED*` opcodes split inputs into two shares
  inside the NTT/PWM unit using `ntt_rand_bits` from the LFSR. Stored
  values like `s1`, `s2`, `t0` are read from SRAM unmasked; the masking
  starts on the bus → PWM input boundary. See the discussion in the
  v2-plan and CLAUDE.md root cause sections.
- **`HighBits` / `LowBits` are implicit**: `w` is decomposed by the
  representation used in subsequent operations. The hardware does not have
  separate `ABR_UOP_HIGHBITS` / `ABR_UOP_LOWBITS` opcodes; the decomposition
  is folded into the `w1Encode` consumption (line 14 of Alg 7) and the `PWS`
  step that produces `r0`.
- **Rejection loop**: a `[seq]` log of a real signing run shows
  `MLDSA_SIGN_LFSR_S` → `MAKE_Y_S` → `MAKE_W_S` → `MAKE_C` → `VALID_S` →
  `CHL_E` repeating until acceptance. The number of iterations is
  data-dependent (geometric distribution; ~3 expected iterations for ML-DSA-87).
- **`mldsa-sign-extmu` / `mldsa-sign-stream`**: in external-µ mode the
  engine skips the `MLDSA_SIGN_H_MU` block and reads µ from `MLDSA_EXTERNAL_MU`
  directly. In stream-msg mode the wrapper streams bytes via `MLDSA_MSG_STROBE`
  and the engine prefixes `0x00 ‖ ctx_size ‖ ctx` internally. Both modes
  re-enter at `MLDSA_SIGN_CHECK_MODE`.

## ML-DSA.Verify_internal — FIPS 204 §6.3, Algorithm 8

```text
Input: pk, M′, σ

 1: (ρ, t1) ← pkDecode(pk)
 2: (c̃, z, h) ← sigDecode(σ)
 3: if h = ⊥ then return false
 5: Â ← ExpandA(ρ)
 6: tr ← H(pk, 64)
 7: μ ← H(BytesToBits(tr) ‖ M′, 64)
 8: c ∈ R_q ← SampleInBall(c̃)
 9: w′_Approx ← NTT⁻¹(Â ∘ NTT(z) − NTT(c) ∘ NTT(t1·2^d))
10: w′_1 ← UseHint(h, w′_Approx)
12: c̃′ ← H(μ ‖ w1Encode(w′_1), λ/4)
13: return ‖z‖∞ < γ1−β  ∧  c̃ = c̃′
```

ROM range: `MLDSA_VERIFY_S` … `MLDSA_VERIFY_E`.

| FSM marker (offset) | Opcode | FIPS 204 Alg 8 | Note |
|---|---|---|---|
| `MLDSA_VERIFY_S +0` | `PKDECODE` → t1 | line 1 (`pkDecode(pk)`) | also stores `t0 ← t1·2^d` representation in SRAM |
| `MLDSA_VERIFY_S +1` | `SIGDEC_Z` → z[0..6] | line 2 partial (`sigDecode(σ)` → z) | extracts only z here; c̃ stays in the SIG_C register; h is decoded later in `VERIFY_RES` |
| `MLDSA_VERIFY_S +2..+8` | `NORMCHK(z[0..6], γ1−β)` × 7 | line 13 first conjunct (`‖z‖∞ < γ1−β`) | early reject — short-circuits without computing `c̃′` if z is out of range |
| `MLDSA_VERIFY_H_TR` | `SHAKE256(pk, 64)` → tr | line 6 (`tr ← H(pk, 64)`) | |
| `MLDSA_VERIFY_CHECK_MODE` | `NOP` | (control) | branch for verify variants |
| `MLDSA_VERIFY_H_MU +0..+1` | `LD_SHAKE256(tr)`, `SHAKE256(M′, 66)` → μ | line 7 (`μ ← H(tr ‖ M′, 64)`) | same framing as signing |
| `MLDSA_VERIFY_MAKE_C` | `SIB(c̃, 64)` → c | line 8 (`c ← SampleInBall(c̃)`) | reads c̃ from SIG_C |
| `MLDSA_VERIFY_NTT_C` | `NTT(c)` → ĉ | line 9 partial (`NTT(c)`) | |
| `MLDSA_VERIFY_NTT_T1 +0..+7` | `NTT(t[0..7])` → t̂ | line 9 partial (`NTT(t1·2^d)`) | the `·2^d` scaling was applied during PKDECODE |
| `MLDSA_VERIFY_NTT_Z +0..+6` | `NTT(z[0..6])` → ẑ | line 9 partial (`NTT(z)`) | ℓ=7 |
| `MLDSA_VERIFY_EXP_A +0..+6` | `REJS_PWM`, `REJS_PWMA` × 7 | line 9 partial (`Â ∘ NTT(z)` for row 0) | `ExpandA` row 0 fused with PWM accumulate into AZ0 |
| `MLDSA_VERIFY_EXP_A +7` | `PWM(ĉ ∘ t̂[0])` → CT | line 9 partial (`NTT(c) ∘ NTT(t1·2^d)` for row 0) | unmasked — verify uses no secrets |
| `MLDSA_VERIFY_EXP_A +8` | `PWS(CT, AZ0)` → AZ0 | line 9 partial (subtract) | `Â ∘ ẑ − ĉ ∘ t̂` for row 0 |
| `MLDSA_VERIFY_EXP_A +9` | `INTT(AZ0)` → w[0] | line 9 partial (`NTT⁻¹`) | row 0 of w′_Approx |
| `MLDSA_VERIFY_EXP_A +10..+19` | row 1 (REJS_PWM/A ×7, PWM, PWS, INTT) | line 9 | w[1] |
| `MLDSA_VERIFY_EXP_A +20..+29` | row 2 | line 9 | w[2] |
| `MLDSA_VERIFY_EXP_A +30..+39` | row 3 | line 9 | w[3] |
| `MLDSA_VERIFY_EXP_A +40..+49` | row 4 | line 9 | w[4] |
| `MLDSA_VERIFY_EXP_A +50..+59` | row 5 | line 9 | w[5] |
| `MLDSA_VERIFY_EXP_A +60..+69` | row 6 | line 9 | w[6] |
| `MLDSA_VERIFY_EXP_A +70..+79` | row 7 | line 9 | w[7] |
| `MLDSA_VERIFY_RES +0` | `SIGDEC_H` → h[0..k−1] | line 2 partial (`sigDecode(σ)` → h) | hint bits; the byte-encoded h was already validated at SIGDECODE time, so the `if h=⊥` of line 3 is the early-reject path of the engine |
| `MLDSA_VERIFY_RES +1` | `LD_SHAKE256(μ)` | line 12 (start) | begin computing c̃′ |
| `MLDSA_VERIFY_RES +2` | `USEHINT(w[0..7], h[0..7])` → w′_1 streamed | line 10 (`UseHint`) | aux block consumes whole w/h vectors; output is streamed via w1Encode into the SHAKE256 absorb path |
| `MLDSA_VERIFY_RES +3` | `RUN_SHAKE256` → c̃′ | line 12 (`c̃′ ← H(μ ‖ w1Encode(w′_1), λ/4)`) | the recomputed 64-byte c̃′ is written to the `MLDSA_VERIFY_RES` register block |
| `MLDSA_VERIFY_E` | `NOP` | line 13 (return) | engine raises `MLDSA_STATUS.VALID` (operation-complete only — there is no in-hardware Boolean for the c̃ = c̃′ check). The wrapper compares the 64-byte `MLDSA_VERIFY_RES` against the first 64 bytes of σ (`src/abr_wrap.cpp:735`) and prints `Signature verify OK` / `BAD` |

Notes:

- **Validity check ordering**: line 13 checks both `‖z‖∞ < γ1−β` *and*
  `c̃ = c̃′`. The engine performs the norm check *first* (`MLDSA_VERIFY_S+2..8`)
  to short-circuit the expensive `Â ∘ ẑ` computation when z is obviously
  malformed.
- **`UseHint` is fused with `w1Encode`**: there is no separate `w′_1`
  materialization in SRAM. The aux block reads `w` and `h`, applies UseHint
  per coefficient, and emits `w1Encode(w′_1)` directly into the SHAKE256
  absorb pipe.

## Reading a real `[seq]` log

A real ML-DSA signing run (deterministic `mldsa-gen.py 3` vectors) produces
a `[seq]` stream that looks like the excerpt below. Cycle counts are from
one verified run; the absolute values vary because each `abr_wrap` invocation
starts with an AHB setup window before the engine enters the FSM. Treat
the addresses and names as the stable part — not the cycles.

```
#       3 [seq]      0: ABR_RESET
#    2550 [seq]    106: MLDSA_SIGN_S
#    2563 [seq]    107: MLDSA_SIGN_S +  1
#    2595 [seq]    108: MLDSA_SIGN_S +  2
#    2598 [seq]    109: MLDSA_SIGN_CHECK_MODE
...
#   40302 [seq]    220: MLDSA_SIGN_MAKE_W_S + 64
#   40315 [seq]    221: MLDSA_SIGN_MAKE_W
#   40833 [seq]    222: MLDSA_SIGN_MAKE_C
#   40871 [seq]    223: MLDSA_SIGN_MAKE_C +  1
#   41036 [seq]    224: MLDSA_SIGN_VALID_S
...
#   65182 [seq]    324: MLDSA_SIGN_VALID_S +100
#   65717 [seq]    325: MLDSA_SIGN_CHL_E
#   65718 [seq]    326: MLDSA_SIGN_E
```

Note the implicit NOP at `MLDSA_SIGN_MAKE_W_S +64`: the explicit ROM lines
fill `+0..+63` (8 rows × 8 micro-ops), and `MLDSA_SIGN_MAKE_W` sits at
`MAKE_W_S+65`, so address 220 falls into the range-decode and prints as
`MLDSA_SIGN_MAKE_W_S +64`.

The cycle-delta between successive markers gives a quick latency profile
per microcode step. A rejection loop iteration shows up as a jump back to
`MLDSA_SIGN_LFSR_S` (139) followed by a fresh `MLDSA_SIGN_MAKE_Y_S`
sequence.
