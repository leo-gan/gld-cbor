#!/usr/bin/env python3
"""Encode a small Message-shaped map, a two-item sequence, or [1,2,3]."""
from __future__ import annotations

import sys

import cbor2

mode = sys.argv[1] if len(sys.argv) > 1 else "message"
if mode == "message":
    obj = {"f_bool": True, "f_int": 150, "f_uint": 7, "f_float": 1.5, "f_text": "hi"}
    sys.stdout.buffer.write(cbor2.dumps(obj))
elif mode == "seq":
    sys.stdout.buffer.write(cbor2.dumps(1) + cbor2.dumps(2))
elif mode == "diag":
    sys.stdout.buffer.write(cbor2.dumps([1, 2, 3]))
else:
    raise SystemExit("usage: encode_ref.py [message|seq|diag]")
