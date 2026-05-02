#!/usr/bin/env python3
#   mlkem-gen.py
#   2026-05-01  ML-KEM test vector generator for ABR trace acquisition.

import sys

from fips203 import ML_KEM


def hextolen(s, l=32):
    if len(s) < 2 * l:
        s = '0' * (2 * l - len(s)) + s
    return bytes.fromhex(s[-2 * l:])


def write_fn(fn, data):
    with open(fn, "wb") as f:
        f.write(data)


def usage():
    print(
        "USAGE: mlkem-gen.py [operation] [d-hex] [z-hex] [m-hex]\n\n"
        "operation: keygen, encaps, decaps, kgdecaps, all\n"
        "defaults: operation=all, d=0, z=0, m=0\n"
        "writes: seed_d_in.dat, seed_z_in.dat, msg_in.dat,\n"
        "        ek_in.dat, dk_in.dat, ct_in.dat, ss_in.dat"
    )


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] in ("-h", "--help"):
        usage()
        raise SystemExit(0)

    op = sys.argv[1] if len(sys.argv) > 1 else "all"
    if op not in ("keygen", "encaps", "decaps", "kgdecaps", "all"):
        usage()
        raise SystemExit(2)

    seed_d = hextolen(sys.argv[2], 32) if len(sys.argv) > 2 else bytes(32)
    seed_z = hextolen(sys.argv[3], 32) if len(sys.argv) > 3 else bytes(32)
    msg = hextolen(sys.argv[4], 32) if len(sys.argv) > 4 else bytes(32)

    ml_kem = ML_KEM("ML-KEM-1024")

    ek, dk = ml_kem.keygen_internal(seed_d, seed_z)
    ss, ct = ml_kem.encaps_internal(ek, msg)
    ss_dec = ml_kem.decaps_internal(dk, ct)

    if ss != ss_dec:
        raise SystemExit("internal ML-KEM self-check failed")

    print("# op:", op)
    print("# seed_d:", seed_d.hex())
    print("# seed_z:", seed_z.hex())
    print("# msg:", msg.hex())
    print("# ek:", ek.hex())
    print("# dk:", dk.hex())
    print("# ct:", ct.hex())
    print("# ss:", ss.hex())

    write_fn("seed_d_in.dat", seed_d)
    write_fn("seed_z_in.dat", seed_z)
    write_fn("msg_in.dat", msg)
    write_fn("ek_in.dat", ek)
    write_fn("dk_in.dat", dk)
    write_fn("ct_in.dat", ct)
    write_fn("ss_in.dat", ss)
