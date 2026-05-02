#   abr-sim

2025-05-27  Markku-Juhani O. Saarinen

Pre-silicon trace generator for the
[Adam's Bridge](https://github.com/chipsalliance/adams-bridge)
PQC hardware accelerator from Caliptra / Chips Alliance. It runs the Adam's
Bridge `abr_top` RTL under Verilator and generates toggle traces for FIPS 204
ML-DSA-87 and FIPS 203 ML-KEM-1024 operations.

Dilithium is another name for
[FIPS 204 ML-DSA](https://doi.org/10.6028/NIST.FIPS.204)
(The Module-Lattice-Based Digital Signature Standard). Kyber is another name
for [FIPS 203 ML-KEM](https://doi.org/10.6028/NIST.FIPS.203)
(The Module-Lattice-Based Key-Encapsulation Mechanism Standard).

What's here:
```
abr-sim
├── Makefile      # Main makefile
├── adams-bridge  # Submodule: Adam's Bridge RTL repo (v2.0.3)
├── doc           # misc documentation; hardwear.io presentation
├── flow          # Python and shell scripts
├── plot          # Gnuplot scripts for TVLA traces
├── rtl           # Hook for printing "line number" of execution
├── src           # Verilator C and python
└── README.md     # this file
```

### Building

As a prerequisite, you will need standard C toolchains and
[verilator](https://github.com/verilator/verilator)
(Tested using the dev version 5.037.)

The python3 parts use pycryptodome; you may have to install it
(`pip3 install pycryptodome`).

Fetch the repo. Note that the `adams-bridge` submodule directory needs to point
to a correct release, currently v2.0.3:
```
$ git clone --recurse-submodules https://github.com/ml-dsa/abr-sim.git
...
Submodule path 'adams-bridge': checked out 'b77e3d8...'
```

You're ready to build the main binaries, `readvcd` and `abr_wrap`, using the
Makefile. `abr_wrap` is the current v2 executable; old v1 notes and examples may
refer to `mldsa_wrap`, but the generic v2 driver is named `abr_wrap` because it
drives both ML-DSA and ML-KEM. Verilator build can take a few minutes.
```
$ make
gcc -O2 -Wall -Wextra -o readvcd src/readvcd.c
mkdir -p _build
(..)
g++  abr_wrap.o verilated.o verilated_vcd_c.o verilated_threads.o Vabr_wrap__ALL.a    -pthread -lpthread -latomic   -o Vabr_wrap
rm Vabr_wrap__ALL.verilator_deplist.tmp
make[1]: Leaving directory '<repo>/_build'
cp -p _build/Vabr_wrap abr_wrap
```

##  abr_wrap

The executable `abr_wrap` provides full RTL simulation of Adam's Bridge,
together with a wrapper that allows one to load/store files from command line.
```
$ ./abr_wrap
USAGE: abr_wrap [options] [operation]

Operation is one of:
    mldsa-keygen, mldsa-sign, mldsa-verify, mldsa-kgsign
    mldsa-sign-extmu, mldsa-sign-stream
    mlkem-keygen, mlkem-encaps, mlkem-decaps, mlkem-kgdecaps
    keygen, sign, verify, kgsign are aliases for the mldsa-* operations

Options (with default values):
    -t      <n>     timeout in cycles (none)
    -vcd    <fn>    vcd output file (trace.vcd)
    -pk     <fn>    public/verification key (pk_in.dat, pk_out.dat)
    -sk     <fn>    private/signing key (sk_in.dat, sk_out.dat)
    -sig    <fn>    signature (sig_in.dat, sig_out.dat)
    -hash   <fn>    message hash (hash_in.dat)
    -seed   <fn>    key generation seed (seed_in.dat)
    -rnd    <fn>    signing rnd input (rnd_in.dat)
    -ent    <fn>    signing sca entropy input (ent_in.dat)
    -vfy    <fn>    verify result output block (none)
    -d      <fn>    ML-KEM seed d (seed_d_in.dat)
    -z      <fn>    ML-KEM seed z (seed_z_in.dat)
    -msg    <fn>    ML-KEM message/randomness (msg_in.dat)
    -ek     <fn>    ML-KEM encapsulation key (ek_in.dat, ek_out.dat)
    -dk     <fn>    ML-KEM decapsulation key (dk_in.dat, dk_out.dat)
    -ct     <fn>    ML-KEM ciphertext (ct_in.dat, ct_out.dat)
    -ss     <fn>    ML-KEM shared secret output (ss_out.dat)
```

#### Example: abr_wrap

For example, we may start the keygen + signing operation without any
parameters (in this case, the code will assume that the keygen seed is zero, and the message hash being signed is also zero:
```
./abr_wrap mldsa-kgsign
[INIT]  1
[STAT]  4   fsm= 1  status= 1 <READY>
[XFER]  14  fsm= 2
[INFO]  name + ver: 00000000000000000000000000000000
[INIT]  kgsign
seed_in.dat: No such file or directory
hash_in.dat: No such file or directory
rnd_in.dat: No such file or directory
ent_in.dat: No such file or directory
[XFER]  34  fsm= 402
[XFER]  68  fsm= 403
[XFER]  86  fsm= 404
[XFER]  120 fsm= 405
[KGSG]  121 start
#     122 [prim]    2: MLDSA_KG_S +  0
#     122 [sec ]    0: MLDSA_RESET +  0
[STAT]  124 fsm= 406    status= 0
#     135 [prim]    3: MLDSA_KG_S +  1
#     167 [prim]    4: MLDSA_KG_S +  2
...
#  124152 [prim]  207: MLDSA_SIGN_E +  0
#  124153 [prim]    0: MLDSA_RESET +  0
#  124153 [sec ]    0: MLDSA_RESET +  0
[STAT]  124156  fsm= 406    status= 3 <READY> <VALID>
[KGSG]  124157  done
[XFER]  127629  fsm= 407
[SAVE]  sig_out.dat (wrote 4627 bytes)
[EXIT]  127630
```
As can be seen, there are default filenames for most inputs and outputs,
but they can also be specified from the command line. The wrapper
implements a finite state machine that transfers ("XFER") data in/out
from files to the RTL model.
Our modified RTL has a "hook" to display the finite state machine state
(e.g. `MLDSA_SIGN_E`). After 127,630 cycles (in this case, three signing "rounds") the model finished creating the signature, and the C wrapper wrote the resulting signature into the file `sig_out.dat`.

##  mldsa-gen.py

The Python program `flow/mldsa-gen.py` uses a full FIPS 204 ML-DSA implementation (in `flow/fips204.py`) to generate test cases and verify the correctness of the operation of the model. The code requires hash functions from cryptodome; `pip3 install cryptodome`.

The command line arguments are:
```
python3 flow/mldsa-gen.py <message> <xi> <rho'>
```
All parameters are optional:

*   `<message>`: Message to be signed (hashed with SHA512 even though
    "PURE" ML-DSA is being used, as per CNSA 2.0 practices). This is
    written out into 64-byte `hash_in.dat`.
*   `<xi>`: This is the 32-byte key seed for ML-DSA keypair generation
    ( Algorithm 6: ML-DSA.KeyGen_internal() in FIPS 204. ), specified in HEX.
*   `<rho'>`: If present, this 64-byte hex value sets the secret key (s1,s2)
    seed "rho prime" directly, overriding seed expansion on line 1 of
    ML-DSA.KeyGen_internal(). This allows fix-random TVLA testing.

The Python program will create the following files, which can be
directly used as inputs for `abr_wrap`:

*   `hash_in.dat`: 64-byte message hash to be signed.
*   `pk_in.dat`: 2592-byte ML-DSA-87 public (verification) key.
*   `sk_in.dat`: 4896-byte ML-DSA-87 secret (signing) key.
*   `rnd_in.dat`: 32-byte rnd input parameter for ML-DSA-87 signing.
    It can be all zeros, signifying deterministic signing.

Additionally, the program creates 4627-byte "expected" signature `sig_in.dat`,
which is not read by `abr_wrap`, but can be used to compare to `sig_out.dat`
created by the RTL model. They should match exactly if the DUT is operating
correctly.

#### Example: mldsa-gen.py

```
$ python3 flow/mldsa-gen.py 3
# msg: 33
# kg_seed: 0000000000000000000000000000000000000000000000000000000000000000
# kappa 0
# verify True
$ ls *.dat
hash_in.dat  pk_in.dat  rnd_in.dat  seed_in.dat  sig_in.dat  sk_in.dat
```
Here the message `3` was chosen so that signature is found on the first
iteartion (counter `kappa 0`).

Given that all default filenames are used, we may generate a VCD trace
`trace.vcd` with these inputs:
```
./abr_wrap -vcd trace.vcd mldsa-sign
[INIT]  1
[STAT]  4   fsm= 1  status= 1 <READY>
[XFER]  14  fsm= 2
[INFO]  name + ver: 00000000000000000000000000000000
[INIT]  sign
[LOAD]  hash_in.dat (read 64 bytes)
[LOAD]  sk_in.dat (read 4896 bytes)
[LOAD]  rnd_in.dat (read 32 bytes)
...
[STAT]  2556    fsm= 206    status= 0
```
There is an additional input, `ent_in.dat` which can provide randomizing
entropy for the LFSR masking random number generators; we will ignore
it in this example.

We see that the actual operation starts after data transfers at cycle 2556 and finishes cycle 39192; requiring 36636 cycles in this case (transfer cycles are not counted).
```
#   39190 [sec ]    0: MLDSA_RESET +  0
[STAT]  39192   fsm= 206    status= 3 <READY> <VALID>
[SIGN]  39193   done
[XFER]  42665   fsm= 207
[SAVE]  sig_out.dat (wrote 4627 bytes)
[EXIT]  42666
```
We observe that the signature written out by the model matches the
one created by the Python implementation:
```
$ cmp sig_out.dat sig_in.dat
```

Also a 24 GB (!!) tracefile is generated:
```
$ ls -l trace.vcd
-rw-rw-r-- 1 mjos mjos 25759748411 May 27 19:09 trace.vcd
```

##  ML-KEM trace acquisition

The Python program `flow/mlkem-gen.py` uses the FIPS 203 ML-KEM implementation
in `flow/fips203.py` to generate ML-KEM-1024 test vectors for Adam's Bridge.

```
$ python3 flow/mlkem-gen.py --help
USAGE: mlkem-gen.py [operation] [d-hex] [z-hex] [m-hex]

operation: keygen, encaps, decaps, kgdecaps, all
defaults: operation=all, d=0, z=0, m=0
```

The generator writes the default files consumed by `abr_wrap`:

- `seed_d_in.dat`: 32-byte ML-KEM seed `d`.
- `seed_z_in.dat`: 32-byte ML-KEM seed `z`.
- `msg_in.dat`: 32-byte encapsulation randomness/message `m`.
- `ek_in.dat`: ML-KEM-1024 encapsulation key.
- `dk_in.dat`: ML-KEM-1024 decapsulation key.
- `ct_in.dat`: ML-KEM-1024 ciphertext.
- `ss_in.dat`: expected 32-byte shared secret for comparison.

#### Example: one ML-KEM keygen trace

```
$ python3 flow/mlkem-gen.py keygen 01 02 00
$ ./abr_wrap -t 20000 -vcd trace.vcd mlkem-keygen
$ cmp ek_out.dat ek_in.dat
$ cmp dk_out.dat dk_in.dat
```

Keygen reads `seed_d_in.dat`, `seed_z_in.dat`, and optional `ent_in.dat`, then
writes `ek_out.dat` and `dk_out.dat`.

#### Example: one ML-KEM encapsulation trace

```
$ python3 flow/mlkem-gen.py encaps 01 02 03
$ ./abr_wrap -t 30000 -vcd trace.vcd mlkem-encaps
$ cmp ct_out.dat ct_in.dat
$ cmp ss_out.dat ss_in.dat
```

Encapsulation reads `ek_in.dat`, `msg_in.dat`, and optional `ent_in.dat`, then
writes `ct_out.dat` and `ss_out.dat`.

#### Example: one ML-KEM decapsulation trace

```
$ python3 flow/mlkem-gen.py decaps 01 02 03
$ ./abr_wrap -t 30000 -vcd trace.vcd mlkem-decaps
$ cmp ss_out.dat ss_in.dat
```

Decapsulation reads `dk_in.dat`, `ct_in.dat`, and optional `ent_in.dat`, then
writes `ss_out.dat`.

#### Example: ML-KEM FIFO trace scripts

For large trace sets, do not write VCD files to disk. The ML-KEM scripts use a
FIFO between `abr_wrap` and `readvcd`, just like the ML-DSA scripts:

```
$ ./flow/gen-kem-kg.sh 20000 flow/readvcd-full.prm kemkg-a 1000
$ ./flow/gen-kem-enc-fix.sh 30000 flow/readvcd-full.prm kemenc-fix-a 1000
$ ./flow/gen-kem-enc-rnd.sh 30000 flow/readvcd-full.prm kemenc-rnd-a 1000
$ ./flow/gen-kem-dec-fix.sh 30000 flow/readvcd-full.prm kemdec-fix-a 1000
$ ./flow/gen-kem-dec-rnd.sh 30000 flow/readvcd-full.prm kemdec-rnd-a 1000
```

The fixed/random split is:

- `gen-kem-kg.sh`: keygen, random `d` and `z`.
- `gen-kem-enc-fix.sh`: encapsulation with fixed `m`, random keypair.
- `gen-kem-enc-rnd.sh`: encapsulation with random `d`, `z`, and `m`.
- `gen-kem-dec-fix.sh`: decapsulation with fixed decapsulation key, random ciphertext.
- `gen-kem-dec-rnd.sh`: decapsulation with random `d`, `z`, and `m`.

Pass any hierarchy-focused preset as the second argument to localize leakage:

```
$ ./flow/gen-kem-enc-rnd.sh 30000 flow/readvcd-ntt.prm kemenc-ntt 1000
$ ./flow/gen-kem-dec-rnd.sh 30000 flow/readvcd-sha3.prm kemdec-sha3 1000
$ ./flow/gen-kem-dec-rnd.sh 30000 flow/readvcd-mlkem-codec.prm kemdec-codec 1000
```

##  readvcd

**readvcd** is a C program that parses an ASCII VCD stream and counts signal
toggles per DUT cycle. The timebase is a cycle counter inside the RTL hook; for
the v2 Adam's Bridge wrapper the canonical substring is `dec.cyc`.

```
$ ./readvcd
Usage: readvcd <file.vcd> <time signal> [threshold] [report cycles]
       readvcd <file.vcd> <time signal> [threshold] [-i glob]... [-e glob]... [report cycles]
```

The first two arguments are the VCD file and a substring used to find the cycle
counter signal. The optional threshold suppresses small per-cycle toggle counts
from the normal `[togd]` output. Additional numeric arguments request verbose
`[sigd]` signal reports for specific cycles.

`readvcd` can also restrict toggle counting to selected VCD hierarchy paths:

- `-i <glob>` / `--include <glob>`: include signals whose full hierarchy matches
  the glob.
- `-e <glob>` / `--exclude <glob>`: exclude matching signals.
- If no include is given, all signals are counted as before.
- Excludes win over includes.
- The cycle counter is still tracked even when it is outside the selected
  hierarchy; filters only decide which identifiers contribute to `[togd]`.

The flow keeps hierarchy presets as `.prm` files because the trace scripts pass
their contents directly to `readvcd`.

| File | Counted hierarchy |
| --- | --- |
| `flow/readvcd.prm` | Full-core default (`dec.cyc 1`) |
| `flow/readvcd-full.prm` | Full-core baseline, explicit alias |
| `flow/readvcd-control.prm` | `abr_ctrl_inst` and `abr_reg_inst` |
| `flow/readvcd-sampler.prm` | `sampler_top_inst`, including SHA3 |
| `flow/readvcd-sha3.prm` | `sampler_top_inst.sha3_inst` |
| `flow/readvcd-keccak.prm` | `sampler_top_inst.sha3_inst.u_keccak` |
| `flow/readvcd-ntt.prm` | generated `ntt_gen*.ntt_top_inst` instances |
| `flow/readvcd-mldsa-aux.prm` | ML-DSA encode/decode/check auxiliary blocks |
| `flow/readvcd-mlkem-codec.prm` | ML-KEM compress/decompress blocks |
| `flow/readvcd-memory.prm` | wrapper memory/export signals |

#### Example: full-core VCD conversion

```
$ ./readvcd trace.vcd dec.cyc 1 | tee toggle-full.txt
[info] toggle threshold: 1
trace.vcd preamble: 70121 lines, 57126 signames, 30013 ids, max var 3188, tot 416100 bits.
[info] selected hierarchy: 416100 / 416100 bits counted
[info] timing signal: TOP.abr_wrap.top0.abr_ctrl_inst.abr_seq_inst.dec.cyc[25:0]
#      84 [togd]  1
#      85 [togd]  158
...
```

Each `# c [togd] n` line means that `n` selected signal bits toggled during DUT
cycle interval `c`.

#### Example: focused NTT count from an existing VCD

```
$ ./readvcd trace.vcd dec.cyc 1 -i '*top0.ntt_gen*.ntt_top_inst*' \
    | tee toggle-ntt.txt
[info] selected hierarchy: 283117 / 416100 bits counted includes: *top0.ntt_gen*.ntt_top_inst*
```

This is useful after a TVLA spike in a full-core trace: rerun `readvcd` on the
same VCD with NTT, sampler, SHA3/Keccak, control, memory, or codec filters and
compare which focused trace still carries the spike.

#### Example: exclude SHA3 from the sampler region

```
$ ./readvcd trace.vcd dec.cyc 1 \
    -i '*top0.sampler_top_inst*' \
    -e '*top0.sampler_top_inst.sha3_inst*' \
    | tee toggle-sampler-no-sha3.txt
```

#### Example: use a preset with FIFO acquisition

The shell trace scripts take `<readvcd.prm>` as their second argument, so the
same fixed/random acquisition can be repeated with different hierarchy presets.
Internally, the scripts run `readvcd` in a `set -f` subshell so glob patterns
from the preset file are passed literally instead of being expanded against
files in the trace directory.

```
$ ./flow/gen-kem-kg.sh 20000 flow/readvcd-full.prm kg-full 100
$ ./flow/gen-kem-kg.sh 20000 flow/readvcd-ntt.prm kg-ntt 100
$ ./flow/gen-kem-kg.sh 20000 flow/readvcd-sha3.prm kg-sha3 100
```

For ML-DSA signing, use the same pattern:

```
$ ./flow/gen-fix.sh 50000 flow/readvcd-full.prm sign-full 1000
$ ./flow/gen-fix.sh 50000 flow/readvcd-ntt.prm sign-ntt 1000
$ ./flow/gen-fix.sh 50000 flow/readvcd-keccak.prm sign-keccak 1000
```

#### Example: omit threshold when using filters

The threshold defaults to `1`, so these two forms are equivalent:

```
$ ./readvcd trace.vcd dec.cyc 1 -i '*top0.ntt_gen*.ntt_top_inst*'
$ ./readvcd trace.vcd dec.cyc -i '*top0.ntt_gen*.ntt_top_inst*'
```

Negative numeric thresholds still parse as thresholds:

```
$ ./readvcd trace.vcd dec.cyc -1 -i '*top0.ntt_gen*.ntt_top_inst*'
```


##  Further processing

The rough scripts in flow directory
(`gen-fix.sh`, `gen-kgr.sh`, `gen-rnd.sh`, `gen-sum.sh`) can be used
to set up parallel trace acquisition in a Linux system, and collecting
of the data in appropriate forum.

The toggle files can be further processed into TVLA data with
`flow/tvla.py`. An example of output of a total of 11,042 fixed+random
signing traces can be found in `plot/tvla11k.txt`. You can display the
results with `grep '# f:' plot/tvla11k.txt | less`. A line of tvla script output can be interpreted as follows:
```
 2557   77.4110 # f:( 5519,    220.0,     0.00) r:( 5523,    217.8,     2.11) [t]
   ^       ^           ^         ^         ^         ^        ^         ^
   |       |           |         |         |         |        |         |
 cycle   t-value     fix.n     fix.avg  fix.std   rand.n   rand.avg  rand.std
```
In this case, the t-value is large (77.4) as the fixed traces have zero standard deviation at that early time point (cycle 2557), while the random traces have variation. They are hence easily distinguishable.

The `plot` directory contains a script `plot.sh` that was used to create
the trace and tvla plots in the presentation.
