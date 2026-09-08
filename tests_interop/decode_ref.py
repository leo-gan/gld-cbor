#!/usr/bin/env python3
"""Decode one CBOR item, or a sequence when argv is 'seq'."""
from __future__ import annotations

import sys

import cbor2

data = sys.stdin.buffer.read()
if len(sys.argv) > 1 and sys.argv[1] == "seq":
    import io

    items = []
    off = 0
    while off < len(data):
        buf = io.BytesIO(data[off:])
        items.append(cbor2.CBORDecoder(buf).decode())
        off += buf.tell()
    print(items)
else:
    print(cbor2.loads(data))
