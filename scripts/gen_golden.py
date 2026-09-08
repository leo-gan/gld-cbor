#!/usr/bin/env python3
"""Write testdata/golden/*.bin from cbor2 and RFC 8949 Appendix A."""
from __future__ import annotations

import struct
from pathlib import Path

import cbor2

ROOT = Path(__file__).resolve().parents[1] / "testdata" / "golden"


def write(name: str, data: bytes) -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    (ROOT / f"{name}.bin").write_bytes(data)
    (ROOT / f"{name}.bin.hex").write_text(data.hex(" ") + "\n")


def main() -> None:
    write("int_0", cbor2.dumps(0))
    write("int_23", cbor2.dumps(23))
    write("int_24", cbor2.dumps(24))
    write("int_neg1", cbor2.dumps(-1))
    write("text_I", cbor2.dumps("I"))
    write("array_1_2", cbor2.dumps([1, 2]))
    # RFC 8949 Appendix A half-floats — not from default cbor2.
    write("half_1", b"\xf9\x3c\x00")
    write("half_neg0", b"\xf9\x80\x00")
    write("half_inf", b"\xf9\x7c\x00")
    write("half_nan", b"\xf9\x7e\x00")
    # extra half via struct if needed
    _ = struct.pack(">e", 1.0)
    write("indef_array_1_2", bytes.fromhex("9f0102ff"))
    write(
        "message_hi",
        cbor2.dumps(
            {
                "f_bool": True,
                "f_int": 150,
                "f_uint": 7,
                "f_float": 1.0,
                "f_text": "hi",
            }
        ),
    )
    print("wrote", ROOT)


if __name__ == "__main__":
    main()
