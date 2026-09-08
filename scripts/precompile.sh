#!/usr/bin/env bash
# Precompile published packages into /tmp/mojo-cbor-pkg.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
out="${MOJO_CBOR_PKG:-/tmp/mojo-cbor-pkg}"
mkdir -p "$out"
if command -v pixi >/dev/null 2>&1; then
  MOJO=(pixi run mojo)
elif command -v mojo >/dev/null 2>&1; then
  MOJO=(mojo)
else
  echo "mojo not found; run scripts/ci-setup.sh" >&2
  exit 1
fi
"${MOJO[@]}" precompile -I src src/wire -o "$out/wire.mojoc"
"${MOJO[@]}" precompile -I src src/cddl -o "$out/cddl.mojoc"
"${MOJO[@]}" precompile -I src src/runtime -o "$out/runtime.mojoc"
"${MOJO[@]}" precompile -I src src/diag -o "$out/diag.mojoc"
"${MOJO[@]}" precompile -I src src/cbor -o "$out/cbor.mojoc"
"${MOJO[@]}" build -I src src/codegen/cli.mojo -o "$out/gld-cborgen-mojo"
echo "wrote $out"
