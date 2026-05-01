#!/bin/bash
set -euo pipefail

hexrand() {
    od -An -N"$1" -tx1 /dev/urandom | tr -d ' \n' | tr 'a-f' 'A-F'
}

if [ "$#" -ne 4 ]; then
    echo "Usage: gen-rnd <maxcyc> <readvcd.prm> <id> <n>"
    exit
fi

maxcyc="$1"
vcdprm="$(cat $2)"
PYTHON="${PYTHON:-python3}"

#   make abr_wrap readvcd
for x in `seq $4`; do
    tmpdir="_tr_rnd-$3-$x"
    echo "=== $tmpdir ==="
    mkdir -p $tmpdir
    cd $tmpdir
    echo "tmpdir=${tmpdir}" | tee param.txt
    echo "maxcyc=${maxcyc}" | tee -a param.txt
    echo "vcdprm=${vcdprm}" | tee -a param.txt
    dd if=/dev/urandom of=ent_in.dat bs=1 count=64 2>/dev/null
    randxi="$(hexrand 32)"
    echo "randxi=${randxi}" | tee -a param.txt
    $PYTHON ../flow/mldsa-gen.py $tmpdir $randxi
    mkfifo trace.vcd
    ../readvcd trace.vcd $vcdprm > trace.log &
    ../abr_wrap -t $maxcyc -vcd trace.vcd mldsa-sign | tee run.log
    gzip *.log
    cd ..
done
