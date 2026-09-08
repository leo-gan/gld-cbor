#!/usr/bin/env bash
# Generate testdata CDDL into tests/generated/.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
mkdir -p tests/generated
if command -v pixi >/dev/null 2>&1; then
  MOJO=(pixi run mojo)
elif command -v mojo >/dev/null 2>&1; then
  MOJO=(mojo)
else
  echo "mojo not found; run scripts/ci-setup.sh" >&2
  exit 1
fi
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --cddl testdata/cddl/benchmark_v2.cddl --out tests/generated
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --cddl testdata/cddl/longlist.cddl --out tests/generated
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --cddl testdata/cddl/mutual_ab.cddl --out tests/generated
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --cddl testdata/cddl/keywords.cddl --out tests/generated
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --cddl testdata/cddl/union.cddl --out tests/generated
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --cddl testdata/cddl/intkeys.cddl --out tests/generated
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --cddl testdata/cddl/tuple.cddl --out tests/generated
