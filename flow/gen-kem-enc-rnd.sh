#!/bin/bash
#   ML-KEM encaps trace acquisition: random leg.
#   Random d/z (random ek) and random m each iteration.
set -euo pipefail

hexrand() {
    od -An -N"$1" -tx1 /dev/urandom | tr -d ' \n' | tr 'a-f' 'A-F'
}

if [ "$#" -ne 4 ]; then
    echo "Usage: gen-kem-enc-rnd <maxcyc> <readvcd.prm> <id> <n>"
    exit
fi

maxcyc="$1"
vcdprm="$(cat $2)"
PYTHON="${PYTHON:-python3}"

#   make abr_wrap readvcd
for x in `seq $4`; do
    tmpdir="_tr_kem-enc-rnd-$3-$x"
    echo "=== $tmpdir ==="
    mkdir -p $tmpdir
    cd $tmpdir
    echo "tmpdir=${tmpdir}" | tee param.txt
    echo "maxcyc=${maxcyc}" | tee -a param.txt
    echo "vcdprm=${vcdprm}" | tee -a param.txt
    echo "op=mlkem-encaps"  | tee -a param.txt
    echo "fixed=none"       | tee -a param.txt
    dd if=/dev/urandom of=ent_in.dat bs=1 count=64 2>/dev/null
    randd="$(hexrand 32)"
    randz="$(hexrand 32)"
    randm="$(hexrand 32)"
    echo "randd=${randd}"   | tee -a param.txt
    echo "randz=${randz}"   | tee -a param.txt
    echo "randm=${randm}"   | tee -a param.txt
    $PYTHON ../flow/mlkem-gen.py encaps $randd $randz $randm
    mkfifo trace.vcd
    ( set -f; ../readvcd trace.vcd $vcdprm > trace.log ) &
    ../abr_wrap -t $maxcyc -vcd trace.vcd mlkem-encaps | tee run.log
    gzip *.log
    cd ..
done

#   time ./flow/gen-kem-enc-rnd.sh 30000 flow/readvcd.prm a 1000
