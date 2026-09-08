from std.collections import List, Span

from runtime.error import DecodeError
from runtime.options import EncodeOptions
from runtime.value import CborValue, decode_item, encode_value
from wire.head import MAX_COUNT
from wire.reader import WireReader
from wire.writer import WireWriter


def decode_seq_values[origin: ImmOrigin](buf: Span[Byte, origin]) raises DecodeError -> List[CborValue]:
    var r = WireReader(buf)
    var out = List[CborValue]()
    var n = 0
    while r.remaining() > 0:
        if n >= MAX_COUNT:
            raise DecodeError(DecodeError.KIND_RANGE, r.position())
        var v = CborValue()
        v.root = decode_item(r, v)
        out.append(v^)
        n += 1
    return out^


def encode_seq_values(
    items: List[CborValue], options: EncodeOptions = EncodeOptions.preferred
) raises DecodeError -> List[Byte]:
    var w = WireWriter()
    for i in range(len(items)):
        var one = encode_value(items[i], options)
        for j in range(len(one)):
            w.write_byte(one[j])
    return w^.finish()
