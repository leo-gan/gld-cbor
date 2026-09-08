# Examples

## Generated struct

```mojo
from cbor import encode, decode
from Message import Message

var m = Message()
m.f_bool = True
m.f_int = Int64(150)
m.f_text = String("hi")
var buf = encode(m)
var m2 = decode[Message](buf)
```

## CborValue

```mojo
from cbor import decode_value, encode_value, EncodeOptions

var v = decode_value(buf)
var preferred = encode_value(v)                 # RFC 8949 §4.1
var deterministic = encode_value(v, EncodeOptions.cde)  # §4.2.1
var same_form = encode_value(v, EncodeOptions.identity)
```

## Sequences

```mojo
from cbor import decode_seq_values, encode_seq_values

var items = decode_seq_values(buf)
var again = encode_seq_values(items)
```

An empty buffer is a valid empty sequence. Single-item `decode` still rejects
trailing bytes.

## Diagnostic notation

```mojo
from cbor import decode_diag, encode_diag

var v = decode_diag("[1, 2, 3]")
var text = encode_diag(v)
```

## Standard tags

```mojo
from cbor import encode_tag0, decode_tag0, decode_value

var buf = encode_tag0("2013-03-21T20:04:00Z")
var s = decode_tag0(decode_value(buf))
```
