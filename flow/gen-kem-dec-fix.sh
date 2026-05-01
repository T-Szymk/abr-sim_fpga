#!/bin/bash
#   ML-KEM decaps trace acquisition: fixed leg.
#   Fixed dk (fixed d/z); ciphertext varies because m varies in encaps.
set -euo pipefail

hexrand() {
    od -An -N"$1" -tx1 /dev/urandom | tr -d ' \n' | tr 'a-f' 'A-F'
}

if [ "$#" -ne 4 ]; then
    echo "Usage: gen-kem-dec-fix <maxcyc> <readvcd.prm> <id> <n>"
    exit
fi

maxcyc="$1"
vcdprm="$(cat $2)"
PYTHON="${PYTHON:-python3}"

#   make abr_wrap readvcd
for x in `seq $4`; do
    tmpdir="_tr_kem-dec-fix-$3-$x"
    echo "=== $tmpdir ==="
    mkdir -p $tmpdir
    cd $tmpdir
    echo "tmpdir=${tmpdir}" | tee param.txt
    echo "maxcyc=${maxcyc}" | tee -a param.txt
    echo "vcdprm=${vcdprm}" | tee -a param.txt
    echo "op=mlkem-decaps"  | tee -a param.txt
    echo "fixed=dk"         | tee -a param.txt
    dd if=/dev/urandom of=ent_in.dat bs=1 count=64 2>/dev/null
    fixd=00
    fixz=00
    randm="$(hexrand 32)"
    echo "fixd=${fixd}"     | tee -a param.txt
    echo "fixz=${fixz}"     | tee -a param.txt
    echo "randm=${randm}"   | tee -a param.txt
    $PYTHON ../flow/mlkem-gen.py decaps $fixd $fixz $randm
    mkfifo trace.vcd
    ../readvcd trace.vcd $vcdprm > trace.log &
    ../abr_wrap -t $maxcyc -vcd trace.vcd mlkem-decaps | tee run.log
    gzip *.log
    cd ..
done

#   time ./flow/gen-kem-dec-fix.sh 30000 flow/readvcd.prm a 1000
