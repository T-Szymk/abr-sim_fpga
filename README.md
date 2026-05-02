#   abr-sim

2025-05-27  Markku-Juhani O. Saarinen

Pre-silicon trace generator for the
[Adam's Bridge](https://github.com/chipsalliance/adams-bridge)
PQC (Dilithium) hardware accelerator from Caliptra 2.0 / Chips Alliance.
Generates "toggle traces" (and logic signal dumps) for the
~40000-cycle ML-DSA-87 signing operation in under 1 minute.

Dilithium is another name for
[FIPS 204 ML-DSA](https://doi.org/10.6028/NIST.FIPS.204)
(The Module-Lattice-Based Digital Signature Standard.)

What's here:
```
abr-sim
├── Makefile      # Main makefile
├── adams-bridge  # Submodule: Adam's Bridge RTL repo (v1.0.1)
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

Fetch the repo. Note that the `adams-bridge' submodule directory needs to point
to a correct release, currently v1.0.1 (May 16, 2025):
```
$ git clone --recurse-submodules https://github.com/ml-dsa/abr-sim.git
...
Submodule path 'adams-bridge': checked out '1cad0334eebf66173f80500f4fc0b628f7cf3335'
```

You're ready to build the main binaries, `readvcd` and `mldsa_wrap` using
the Makefile. Verilator build will take a minute or two.
```
$ make
gcc -O2 -Wall -Wextra -o readvcd src/readvcd.c
mkdir -p _build
(..)
g++  mldsa_wrap.o verilated.o verilated_vcd_c.o verilated_threads.o Vmldsa_wrap__ALL.a    -pthread -lpthread -latomic   -o Vmldsa_wrap
rm Vmldsa_wrap__ALL.verilator_deplist.tmp
make[1]: Leaving directory '/home/mjos/src/abr-sim/_build'
cp -p _build/Vmldsa_wrap mldsa_wrap
```

##  mldsa_wrap

The executable `mldsa_wrap` provides full RTL simulation of Adam's Bridge,
together with a wrapper that allows one to load/store files from command line.
```
$ ./mldsa_wrap
USAGE: mldsa_wrap [options] [operation]

Operation is one of: keygen, sign, verify, kgsign

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
```

#### Example: mldsa_wrap

For example, we may start the keygen + signing operation without any
parameters (in this case, the code will assume that the keygen seed is zero, and the message hash being signed is also zero:
```
./mldsa_wrap kgsign
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
directly used as inputs for `mldsa_wrap`:

*   `hash_in.dat`: 64-byte message hash to be signed.
*   `pk_in.dat`: 2592-byte ML-DSA-87 public (verification) key.
*   `sk_in.dat`: 4896-byte ML-DSA-87 secret (signing) key.
*   `rnd_in.dat`: 32-byte rnd input parameter for ML-DSA-87 signing.
    It can be all zeros, signifying deterministic signing.

Additionally, the program creates 4627-byte "expected" signature `sig_in.dat`,
which is not read by `mldsa_wrap`, but can be used to compare to `sig_out.dat`
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
./mldsa_wrap -vcd trace.vcd sign
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
$ PYTHON=/home/mjos/mf3/bin/python3 ./flow/gen-kem-kg.sh 20000 flow/readvcd-full.prm kg-full 100
$ PYTHON=/home/mjos/mf3/bin/python3 ./flow/gen-kem-kg.sh 20000 flow/readvcd-ntt.prm kg-ntt 100
$ PYTHON=/home/mjos/mf3/bin/python3 ./flow/gen-kem-kg.sh 20000 flow/readvcd-sha3.prm kg-sha3 100
```

For ML-DSA signing, use the same pattern:

```
$ PYTHON=/home/mjos/mf3/bin/python3 ./flow/gen-fix.sh 50000 flow/readvcd-full.prm sign-full 1000
$ PYTHON=/home/mjos/mf3/bin/python3 ./flow/gen-fix.sh 50000 flow/readvcd-ntt.prm sign-ntt 1000
$ PYTHON=/home/mjos/mf3/bin/python3 ./flow/gen-fix.sh 50000 flow/readvcd-keccak.prm sign-keccak 1000
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
