# Golden byte vectors

Integer, text, and array files are produced by `scripts/gen_golden.py` using
Python `cbor2`. Half-float and NaN files are RFC 8949 Appendix A. The
indefinite-array file is the RFC encoding `9f 01 02 ff`.

Do not hand-edit `.bin` files that the script owns. Regenerate with
`python3 scripts/gen_golden.py`.
