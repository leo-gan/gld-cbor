#!/usr/bin/env bash
# Pipe a small map through Python cbor2 and back.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
python3 tests_interop/encode_ref.py | python3 tests_interop/decode_ref.py
echo "interop python round-trip ok"
