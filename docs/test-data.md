# Test data

Files under `testdata/` are ordinary unit and interop material. They are not a
shared external suite and they are not a product schema.

| Tree | Why it exists |
| --- | --- |
| `testdata/cddl/` | CDDL schemas the generator and parser tests read |
| `testdata/golden/` | Oracle byte vectors plus `.hex` sidecars |
| `testdata/diag/` | Diagnostic-notation samples |
| `testdata/seq/` | Concatenated RFC 8742 sequences |

## CDDL schemas

| File | Why |
| --- | --- |
| `benchmark_v2.cddl` | `Message`, `Document`, `Telemetry`, and the other v2 shapes |
| `longlist.cddl` | Recursive optional record |
| `tags.cddl` | Standard tags 0, 1, 32 |

## Golden vectors

Integer, text, and map goldens come from Python `cbor2` via
`scripts/gen_golden.py`. Half-float, NaN, and Infinity bytes come from
RFC 8949 Appendix A. Do not hand-edit `.bin` files that the script owns.
Default `cbor2` writes Python `float` as binary64, so half-float goldens are
never taken from that encoder.

## Derived files

`tests/generated/` is the output of `gld-cborgen-mojo`.
`scripts/check-generated.sh` fails if those files drift.
