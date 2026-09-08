# Why CBOR

[CBOR](https://en.wikipedia.org/wiki/CBOR) (Concise Binary Object
Representation) is a self-describing binary format defined by
[RFC 8949](https://www.rfc-editor.org/rfc/rfc8949.html). Every value starts with
a head byte that names the major type. A decoder does not need a schema to walk
an item. A schema language, [CDDL](https://www.rfc-editor.org/rfc/rfc8610.html),
is optional and is what this library uses to generate Mojo structs.

This library implements that format in Mojo. It does not call libcbor. Python
`cbor2` is used only as a test oracle.

## Major types

| Major | Meaning |
| --- | --- |
| 0 | unsigned integer |
| 1 | negative integer (`−1 − n`) |
| 2 | byte string |
| 3 | text string (UTF-8) |
| 4 | array |
| 5 | map |
| 6 | tag, then one nested item |
| 7 | simple values and floats |

The extra argument after the head is **big-endian**. That is the opposite of
Avro and protobuf fixed-width integers.

## Preferred encoding and CDE

Default write is RFC 8949 §4.1 preferred serialization: shortest integer heads,
definite lengths, shortest float that keeps the value, **no map-key sort**.

Optional write is RFC 8949 §4.2.1 core deterministic encoding (CDE): preferred
plus sorting map keys by their encoded bytes. Encoded `"z"` sorts before
encoded `"aa"`.

## Sequences and diagnostic notation

[RFC 8742](https://www.rfc-editor.org/rfc/rfc8742.html) sequences are
concatenated items with no extra framing. Diagnostic notation is the text form
used in the RFC examples (`[1, 2]`, `h'a1b2'`, `1(1363896240)`).

## Standard tags

This library has first-class codecs for tags 0 (RFC 3339 date-time), 1 (epoch),
2 and 3 (bignums), 4 (decimal fraction), 5 (bigfloat), 24 (encoded CBOR), and
32 (URI). Other tags stay as `CborTag`.
