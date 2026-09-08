#!/usr/bin/env python3
import sys

import cbor2

obj = {"f_bool": True, "f_int": 150, "f_uint": 7, "f_float": 1.0, "f_text": "hi"}
sys.stdout.buffer.write(cbor2.dumps(obj))
