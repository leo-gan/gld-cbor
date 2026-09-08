# Why CBOR

[CBOR](https://en.wikipedia.org/wiki/CBOR) (Concise Binary Object
Representation) is a self-describing binary format defined by
[RFC 8949](https://www.rfc-editor.org/rfc/rfc8949.html). Every value starts with
a head byte that names the major type. A decoder does not need a schema to walk
an item.

A schema language, [CDDL](https://www.rfc-editor.org/rfc/rfc8610.html), is
optional. This library uses CDDL to generate Mojo structs. Schema-free work
uses `CborValue`.

This library implements that format in Mojo. It does not call libcbor. Python
`cbor2` is used only as a test oracle.

The rest of this page is the subset of RFC 8949 that the library implements,
written for a reader who has not used CBOR before. [Instructions](instructions.md)
shows how to install and generate code. [Examples](examples.md) shows the
matching Mojo calls.

## How an item is written

Every item starts with one **head byte**. The top three bits are the **major
type** (0–7). The low five bits are **additional information** (AI). AI either
*is* the value, or it says how many extra argument bytes follow.

| AI | Meaning |
| --- | --- |
| 0–23 | The value is the AI itself |
| 24 | One extra byte (unsigned 8-bit argument) |
| 25 | Two extra bytes (unsigned 16-bit, big-endian) |
| 26 | Four extra bytes (unsigned 32-bit, big-endian) |
| 27 | Eight extra bytes (unsigned 64-bit, big-endian) |
| 28–30 | Reserved. This library rejects them (`KIND_RESERVED_AI`) |
| 31 | Indefinite length. Legal only for majors 2, 3, 4, 5, and for the break byte |

Argument bytes are **big-endian**. That is the opposite of Avro and protobuf
fixed-width integers.

A short example: the unsigned integer 24 cannot fit in AI 0–23, so the bytes
are `18 18` (major 0, AI 24, then one extra byte whose value is 24).

## Major types

| Major | Name | What the argument means |
| --- | --- | --- |
| 0 | unsigned integer | the value |
| 1 | negative integer | the value `n` means `−1 − n` |
| 2 | byte string | length, or 31 for indefinite |
| 3 | text string | length in UTF-8 bytes, or 31 |
| 4 | array | item count, or 31 |
| 5 | map | pair count, or 31 |
| 6 | tag | tag number; then one nested item |
| 7 | simple / float | 20–23 simples; 25/26/27 half/float/double; 31 break |

## Integers

Major 0 is a non-negative integer. Major 1 is a negative integer written as
`−1 − n`, so `0x20` is −1 (major 1, AI 0).

This library stores a major-0 value that fits in `Int64` as kind `INT`. A
major-0 value in the range 2^63 … 2^64−1 is kind `UINT`. A major-1 value that
fits in `Int64` is kind `INT`. A value more negative than `Int64.MIN` is
`KIND_RANGE`.

An integer wider than 64 bits cannot arrive as a major 0 or 1 head, because
the head argument is at most eight bytes. Bigger integers arrive only as tags
2 and 3 wrapping a byte string.

Preferred write of an `Int64` uses major 0 when `v >= 0` and major 1 with
argument `−1 − v` when `v < 0`. Both use the shortest AI.

An **overlong** integer (for example AI 24 with a value that still fits in
0–23) is well-formed on read. Preferred and CDE write never emit overlong
integers.

## Floats

Major 7 with AI 25, 26, or 27 is an IEEE 754 floating-point number.

| AI | Width | Extra bytes |
| --- | --- | --- |
| 25 | binary16 (half) | 2 |
| 26 | binary32 | 4 |
| 27 | binary64 | 8 |

RFC 8949 Appendix A writes 1.0 as the half-float `f9 3c 00`. Default Python
`cbor2` writes a Python `float` as binary64, so half-float goldens in this
repo come from the RFC, not from that encoder.

`CborValue` keeps the original width and bit pattern on decode. Identity
encode writes those bits back. Preferred encode of a computed `Float64` uses
the shortest width that preserves the numeric value, including signed zero.

NaN is shortened only when the trailing payload bits are zero. Preferred and
CDE write of a zero-payload NaN is the half-float quiet NaN `f9 7e 00`. They
do not rewrite every NaN to that encoding. Identity write keeps the stored
width and payload. Infinity stays infinite at the shortest width that can
represent it (`f9 7c 00` / `f9 fc 00`).

dCBOR write rejects NaN and Infinity. An integer-valued float becomes an
integer under dCBOR, so `f9 3c 00` (1.0) is written as `01`.

## Simple values

Major 7 also holds the small constants and unassigned simples.

| Value | Meaning |
| --- | --- |
| 20 | false (`0xf4`) |
| 21 | true (`0xf5`) |
| 22 | null (`0xf6`) |
| 23 | undefined (`0xf7`) |
| 0–19 | unassigned simple; tiny AI only |
| 24–31 | reserved; no legal encoding |
| 32–255 | unassigned simple; AI 24 plus one byte |

RFC 8949 §3.3: `0xf8` followed by a byte less than `0x20` is not well-formed.
This library rejects that form on every decode (`KIND_SIMPLE`), not only on
strict decode.

**Break** is major 7, AI 31, byte `0xFF`. It is not a value. It only ends an
indefinite container. A break outside that context is `KIND_BREAK`.

dCBOR write rejects `undefined` and unassigned simples.

## Byte strings and text

A **definite** string is a head with length N, then N bytes. Text must be
well-formed UTF-8 (`KIND_UTF8`).

An **indefinite** string is a head with AI 31, then zero or more **definite**
chunks of the same major type, then break. A nested indefinite chunk is
`KIND_INDEF`. Mixed chunk majors are `KIND_TYPE`. For text, each chunk and
the concatenation must be valid UTF-8. A Unicode code point must not be split
across chunks.

Preferred and CDE write always emit one definite string. The encoder
concatenates chunks first.

A single string or the concatenated indefinite result is capped at
`MAX_ITEM_BYTES` (64_194_304).

`decode_tstr_span` returns a `StringSpan` into the input for a definite text
string. Indefinite text is still copied, because the chunks have to be joined.

## Arrays and maps

A definite array is a count N, then N items. A definite map is a count N,
then N key/value pairs (2N items).

An indefinite array or map is items until break. An indefinite map must end
on a pair boundary. A dangling key before break is `KIND_MAP_PAIR`.

A CBOR map is an ordered list of pairs. Keys may be any item, including
arrays. This is not a `Dict`. Duplicate keys are well-formed on generic
decode; all pairs are kept in order. Generated structs and `as_text_map` take
the last pair for a given text key.

Preferred write of a map uses a definite length and does **not** sort keys.
Pair order is the order stored in the arena, or the CDDL member order for a
generated struct.

CDE write sorts pairs by the **encoded key bytes** (the full preferred
encoding of the key, including the head). Encoded `"z"` (`61 7a`) sorts
before encoded `"aa"` (`62 61 61`). That is not UTF-8 content order.

dCBOR write uses the same key sort and requires text keys. A non-text key is
rejected.

Duplicate keys are a writer error (`KIND_DUP_KEY`) for `CborValue`.

## Tags

A tag is major 6, then one nested item. The tag number says how to interpret
that item. Nested tags are allowed. Nesting of arrays, maps, and tags is
capped at 100 (`KIND_DEPTH`).

Unknown tags stay as `CborTag(number, value)`. These eight have first-class
codecs:

| Tag | Content | Mojo type | Meaning |
| --- | --- | --- | --- |
| 0 | text | `String` | RFC 3339 date-time |
| 1 | int or float | `EpochTime` | seconds since the Unix epoch |
| 2 | byte string | `BigUint` | unsigned bignum, network-endian |
| 3 | byte string | `BigNint` | negative bignum; value is `−1 − n` |
| 4 | two-item array | `DecimalFraction` | mantissa × 10^exponent |
| 5 | two-item array | `BigFloat` | mantissa × 2^exponent |
| 24 | byte string | `EncodedCbor` | one nested CBOR item |
| 32 | text | `Uri` | URI |

Preferred and CDE encode of a number that fits `Int64` or `UInt64` uses major
0 or 1, not tags 2 or 3. `BigUint` and `BigNint` are always tagged, because
the caller asked for a bignum. Zero is an empty byte string (`c2 40` /
`c3 40`).

## Preferred encoding, CDE, identity, and dCBOR

Default `encode(...)` uses RFC 8949 §4.1 **preferred serialization**. Optional
write modes are §4.2.1 **core deterministic encoding** (CDE, aligned with
[draft-ietf-cbor-cde](https://datatracker.ietf.org/doc/draft-ietf-cbor-cde/)),
**identity** (keep the stored form), and **dCBOR** (a stricter deterministic
subset).

| Rule | Preferred (§4.1) | CDE (§4.2.1) | Identity | dCBOR |
| --- | --- | --- | --- | --- |
| Shortest integer AI | yes | yes | keep stored AI width | yes |
| Definite lengths only | yes | yes | keep `indef` bit | yes |
| Shortest float that preserves value | yes | yes | keep stored width and bits | yes; integer-valued floats become ints |
| Zero-payload NaN | `f97e00` | `f97e00` | keep stored bits | reject (`KIND_CDE`) |
| Non-zero NaN payload | shortest width that holds the payload | same | keep stored bits | reject |
| Infinity | shortest float | shortest float | keep stored bits | reject |
| Map key order | **no sort** (stored / CDDL order) | sort by **encoded key bytes** | no sort | CDE key sort |
| Text keys only | no | no | no | yes; other key kinds reject |
| Duplicate keys | reject on `CborValue` write | reject | reject | reject |
| Simple 0–23 | tiny AI | tiny AI | tiny AI | tiny AI |
| `undefined` / unassigned simples | written | written | written | reject |
| `0xf8` + byte `< 0x20` | never written; **not well-formed on any decode** | same | same | same |

`decode_strict` is not a fourth write mode. It decodes to `CborValue`,
re-encodes with CDE, and compares those bytes to the input. That accepts
every legal CDE encoding, including a non-`f97e00` NaN that §4.2.1 still
considers shortest.

dCBOR decode-time validation is not implemented. Only the write mode is.

## Sequences

[RFC 8742](https://www.rfc-editor.org/rfc/rfc8742.html) **CBOR Sequences** are
zero or more concatenated items with no extra framing. An empty buffer is a
valid empty sequence.

There is no trailing-garbage rule for a sequence. The decoder consumes items
until the buffer ends. A truncated final item is `KIND_EOF`.

Single-item `decode[T](buf)` still requires that the buffer contain exactly
one item. Leftover bytes are `KIND_TRAILING`.

`SeqDecoder` (`next_value` / `skip`) pulls one sequence item at a time
without buffering the rest.

## Diagnostic notation

Diagnostic notation is the text form used in the RFC examples. It is not
JSON. Arrays look similar (`[1, 2]`), but tags are `1(1363896240)`, byte
strings are `h'a1b2'`, and indefinite items use a leading `_`.

| Item | Diagnostic |
| --- | --- |
| unsigned | decimal |
| negative | decimal including the minus |
| byte string | `h'a1b2'` lowercase hex |
| text | `"…"` with RFC 8949 escapes |
| array | `[1, 2, 3]` |
| map | `{1: 2, "a": "b"}` |
| tag | `1(1363896240)` |
| false / true / null / undefined | those tokens |
| simple N | `simple(N)` |
| float | shortest decimal, or `Infinity` / `-Infinity` / `NaN` |
| indefinite | `[_ 1, 2]` / `{_ "a": 1}` / `(_ h'01', h'02')` / `(_ "a", "b")` |

`encode_diag` writes that compact form. `encode_diag_pretty` puts one array or
map item on each line.

Diag decode accepts integers (decimal or `0x` hex), floats, quoted text,
`h'…'` bytes, arrays, maps, tags, the simple tokens, indefinite `_`, `#` line
comments, and whitespace. It does not accept `b64'…'`, `<< >>` embedded CBOR,
or single-quoted text.

## Limits

| Cap | Value | Error |
| --- | --- | --- |
| Nesting depth (array / map / tag) | 100 | `KIND_DEPTH` |
| Single string or byte string | 64_194_304 | `KIND_RANGE` |
| Array or map pair count | 1_048_576 | `KIND_RANGE` |
| Sequence item count | 1_048_576 | `KIND_RANGE` |
