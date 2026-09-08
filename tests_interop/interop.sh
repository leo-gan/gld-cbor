#!/usr/bin/env bash
# Mojo ↔ official Python cbor2 interop for items, sequences, diagnostic
# bytes, and generated Message.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

python3 tests_interop/encode_ref.py message | python3 tests_interop/decode_ref.py >/dev/null
echo "interop python message self-round-trip ok"

python3 tests_interop/encode_ref.py seq | python3 tests_interop/decode_ref.py seq >/dev/null
echo "interop python sequence self-round-trip ok"

python3 tests_interop/encode_ref.py diag | python3 tests_interop/decode_ref.py >/dev/null
echo "interop python array self-round-trip ok"

if command -v pixi >/dev/null 2>&1; then
  MOJO=(pixi run mojo)
else
  MOJO=(mojo)
fi

mojo_out=$("${MOJO[@]}" run -I src -I tests -I tests/generated tests_interop/encode_mojo.mojo)
msghex=$(printf '%s\n' "$mojo_out" | awk '/^MSG /{print $2}')
seqhex=$(printf '%s\n' "$mojo_out" | awk '/^SEQ /{print $2}')
diaghex=$(printf '%s\n' "$mojo_out" | awk '/^DIAG /{print $2}')

echo "$msghex" | xxd -r -p | python3 tests_interop/decode_ref.py | grep -q "f_int"
echo "interop mojo→python Message ok"

echo "$seqhex" | xxd -r -p | python3 tests_interop/decode_ref.py seq | grep -q "1"
echo "interop mojo→python sequence ok"

echo "$diaghex" | xxd -r -p | python3 tests_interop/decode_ref.py | grep -q "1"
echo "interop mojo diag→python array ok"

echo "interop ok"
