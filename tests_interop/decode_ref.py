#!/usr/bin/env python3
import sys

import cbor2

data = sys.stdin.buffer.read()
print(cbor2.loads(data))
