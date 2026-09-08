from std.collections import List, Span

from runtime.error import DecodeError
from runtime.options import EncodeOptions
from runtime.value import (
    CK_BYTES,
    CK_FLOAT16,
    CK_FLOAT32,
    CK_FLOAT64,
    CK_INT,
    CK_TAG,
    CK_TEXT,
    CK_UINT,
    CborValue,
    decode_item,
    decode_value,
    encode_value,
)
from wire.half import f32_from_bits, f64_from_bits, half_to_f64
from wire.reader import WireReader
from wire.writer import WireWriter


struct EpochTime(Copyable, ImplicitlyCopyable, Movable):
    var sec: Float64

    def __init__(out self, sec: Float64 = 0.0):
        self.sec = sec


struct BigUint(Movable):
    var bytes: List[Byte]

    def __init__(out self):
        self.bytes = List[Byte]()

    def __init__(out self, var bytes: List[Byte]):
        self.bytes = bytes^


struct BigNint(Movable):
    var bytes: List[Byte]

    def __init__(out self):
        self.bytes = List[Byte]()

    def __init__(out self, var bytes: List[Byte]):
        self.bytes = bytes^


struct Uri(Copyable, ImplicitlyCopyable, Movable):
    var text: String

    def __init__(out self, text: String = ""):
        self.text = text


def _is_digit(b: Byte) -> Bool:
    var c = Int(b)
    return c >= 48 and c <= 57


def rfc3339_ok(text: String) -> Bool:
    var b = text.as_bytes()
    # YYYY-MM-DDThh:mm:ss ...
    if len(b) < 19:
        return False
    for i in range(4):
        if not _is_digit(b[i]):
            return False
    if Int(b[4]) != 45 or Int(b[7]) != 45:
        return False
    for i in range(5, 7):
        if not _is_digit(b[i]):
            return False
    for i in range(8, 10):
        if not _is_digit(b[i]):
            return False
    var t = Int(b[10])
    if t != 84 and t != 116:
        return False
    for i in range(11, 13):
        if not _is_digit(b[i]):
            return False
    if Int(b[13]) != 58 or Int(b[16]) != 58:
        return False
    for i in range(14, 16):
        if not _is_digit(b[i]):
            return False
    for i in range(17, 19):
        if not _is_digit(b[i]):
            return False
    return True


def _as_float(v: CborValue, idx: Int) raises DecodeError -> Float64:
    var n = v.nodes[idx]
    if n.kind == CK_INT:
        return Float64(n.a)
    if n.kind == CK_UINT:
        return Float64(n.b)
    if n.kind == CK_FLOAT16:
        return half_to_f64(UInt16(n.b))
    if n.kind == CK_FLOAT32:
        return Float64(f32_from_bits(UInt32(n.b)))
    if n.kind == CK_FLOAT64:
        return f64_from_bits(n.b)
    raise DecodeError(DecodeError.KIND_TAG, 0)


def decode_tag0(v: CborValue) raises DecodeError -> String:
    var n = v.nodes[v.root]
    if n.kind != CK_TAG or n.b != UInt64(0):
        raise DecodeError(DecodeError.KIND_TAG, 0)
    var c = v.nodes[n.c]
    if c.kind != CK_TEXT:
        raise DecodeError(DecodeError.KIND_TAG, 0)
    var s = v.texts[Int(c.a)]
    if not rfc3339_ok(s):
        raise DecodeError(DecodeError.KIND_TAG, 0)
    return s


def decode_tag1(v: CborValue) raises DecodeError -> EpochTime:
    var n = v.nodes[v.root]
    if n.kind != CK_TAG or n.b != UInt64(1):
        raise DecodeError(DecodeError.KIND_TAG, 0)
    return EpochTime(_as_float(v, n.c))


def _copy_bstr(v: CborValue, idx: Int) raises DecodeError -> List[Byte]:
    var n = v.nodes[idx]
    if n.kind != CK_BYTES:
        raise DecodeError(DecodeError.KIND_TAG, 0)
    var out = List[Byte]()
    var start = Int(n.a)
    var ln = Int(n.b)
    for i in range(ln):
        out.append(v.bytes[start + i])
    return out^


def decode_tag2(v: CborValue) raises DecodeError -> BigUint:
    var n = v.nodes[v.root]
    if n.kind != CK_TAG or n.b != UInt64(2):
        raise DecodeError(DecodeError.KIND_TAG, 0)
    return BigUint(_copy_bstr(v, n.c))


def decode_tag3(v: CborValue) raises DecodeError -> BigNint:
    var n = v.nodes[v.root]
    if n.kind != CK_TAG or n.b != UInt64(3):
        raise DecodeError(DecodeError.KIND_TAG, 0)
    return BigNint(_copy_bstr(v, n.c))


def decode_tag24(v: CborValue) raises DecodeError -> CborValue:
    var n = v.nodes[v.root]
    if n.kind != CK_TAG or n.b != UInt64(24):
        raise DecodeError(DecodeError.KIND_TAG, 0)
    var raw = _copy_bstr(v, n.c)
    return decode_value(raw)


def decode_tag32(v: CborValue) raises DecodeError -> Uri:
    var n = v.nodes[v.root]
    if n.kind != CK_TAG or n.b != UInt64(32):
        raise DecodeError(DecodeError.KIND_TAG, 0)
    var c = v.nodes[n.c]
    if c.kind != CK_TEXT:
        raise DecodeError(DecodeError.KIND_TAG, 0)
    var s = v.texts[Int(c.a)]
    if s.byte_length() == 0:
        raise DecodeError(DecodeError.KIND_TAG, 0)
    var bb = s.as_bytes()
    for i in range(len(bb)):
        if Int(bb[i]) == 32:
            raise DecodeError(DecodeError.KIND_TAG, 0)
    return Uri(s)


def encode_tag0(text: String) raises DecodeError -> List[Byte]:
    if not rfc3339_ok(text):
        raise DecodeError(DecodeError.KIND_TAG, 0)
    var w = WireWriter()
    w.write_tag(UInt64(0))
    w.write_tstr(text)
    return w^.finish()


def encode_tag1(t: EpochTime) -> List[Byte]:
    var w = WireWriter()
    w.write_tag(UInt64(1))
    var as_int = Int64(t.sec)
    if Float64(as_int) == t.sec:
        w.write_int(as_int)
    else:
        w.write_float_preferred(t.sec)
    return w^.finish()


def encode_tag2(b: BigUint) -> List[Byte]:
    var w = WireWriter()
    w.write_tag(UInt64(2))
    w.write_bstr(b.bytes)
    return w^.finish()


def encode_tag3(b: BigNint) -> List[Byte]:
    var w = WireWriter()
    w.write_tag(UInt64(3))
    w.write_bstr(b.bytes)
    return w^.finish()


def encode_tag24(inner: CborValue, options: EncodeOptions = EncodeOptions.preferred) raises DecodeError -> List[Byte]:
    var payload = encode_value(inner, options)
    var w = WireWriter()
    w.write_tag(UInt64(24))
    w.write_bstr(payload)
    return w^.finish()


def encode_tag32(u: Uri) raises DecodeError -> List[Byte]:
    if u.text.byte_length() == 0:
        raise DecodeError(DecodeError.KIND_TAG, 0)
    var w = WireWriter()
    w.write_tag(UInt64(32))
    w.write_tstr(u.text)
    return w^.finish()
