# Instructions

## Install Mojo 1.0.0

```bash
git clone https://github.com/leo-gan/gld-cbor.git
cd gld-cbor
pixi install
pixi run test
```

If `pixi install` fails with 401 on `conda.modular.com`, set `PREFIX_API_KEY`
in a local `.env` (never commit that file) and run `scripts/ci-setup.sh`.

After a conda install from prefix.dev:

```bash
pixi add --channel https://prefix.dev/leo-gan/leo-gan mojo-cbor
```

That installs `cbor.mojoc` (plus `wire` / `runtime` / `diag` / `cddl`) and
`gld-cborgen-mojo`.

## Generate Mojo from CDDL

Write an [RFC 8610](https://www.rfc-editor.org/rfc/rfc8610.html) CDDL schema,
then run the generator. After a conda install the command is
`gld-cborgen-mojo`. In a checkout:

```bash
pixi run mojo run -I src src/codegen/cli.mojo -- \
  --cddl testdata/cddl/benchmark_v2.cddl --out tests/generated
```

`pixi run generate` rebuilds the in-tree types from
`testdata/cddl/benchmark_v2.cddl`.

Optional members (`? field`) become `Optional[T]`. A two-branch choice with
`null` also becomes `Optional[T]`.

## Encode and decode

```mojo
from cbor import encode, decode
from Message import Message

var m = Message()
m.f_int = Int64(150)
var buf = encode(m)
var m2 = decode[Message](buf)
```

`from cbor import …` resolves with `mojo run -I src` in a checkout, or from
`cbor.mojoc` after the package is installed.

Schema-free items use `CborValue`:

```mojo
from cbor import decode_value, encode_value, EncodeOptions

var v = decode_value(buf)
var again = encode_value(v, EncodeOptions.cde)
```
