#!/bin/bash
#   ML-KEM keygen trace acquisition: random d/z each iteration.

if [ "$#" -ne 4 ]; then
    echo "Usage: gen-kem-kg <maxcyc> <readvcd.prm> <id> <n>"
    exit
fi

maxcyc="$1"
vcdprm="$(cat $2)"

#   make abr_wrap readvcd
for x in `seq $4`; do
    tmpdir="_tr_kem-kg-$3-$x"
    echo "=== $tmpdir ==="
    mkdir -p $tmpdir
    cd $tmpdir
    echo "tmpdir=${tmpdir}" | tee param.txt
    echo "maxcyc=${maxcyc}" | tee -a param.txt
    echo "vcdprm=${vcdprm}" | tee -a param.txt
    echo "op=mlkem-keygen"  | tee -a param.txt
    echo "fixed=none"       | tee -a param.txt
    dd if=/dev/urandom of=ent_in.dat bs=1 count=64 2>/dev/null
    randd=`cat /dev/urandom | tr -dc '0-9A-F' | head -c 64`
    randz=`cat /dev/urandom | tr -dc '0-9A-F' | head -c 64`
    echo "randd=${randd}"   | tee -a param.txt
    echo "randz=${randz}"   | tee -a param.txt
    python3 ../flow/mlkem-gen.py keygen $randd $randz 00
    mkfifo trace.vcd
    ../readvcd trace.vcd $vcdprm > trace.log &
    ../abr_wrap -t $maxcyc -vcd trace.vcd mlkem-keygen | tee run.log
    gzip *.log
    cd ..
done

#   time ./flow/gen-kem-kg.sh 20000 flow/readvcd.prm a 1000
