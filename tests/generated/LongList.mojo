from std.collections import List, Optional, Span

from cbor import (
    Box,
    CborDatum,
    DecodeError,
    EncodeOptions,
    WireReader,
    WireWriter,
    encoded_bstr_len,
    encoded_float_preferred_len,
    encoded_head_len,
    encoded_int_len,
    encoded_tstr_len,
    encoded_uint_len,
)


struct LongList(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var value: Int64
    var next: Optional[Box[LongList]]

    def __init__(out self):
        self.value = Int64(0)
        self.next = Optional[Box[LongList]]()

    def __init__(out self, var value: Int64, var next: Optional[Box[LongList]]):
        self.value = value^
        self.next = next^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        var _pairs = 1
        if self.next:
            _pairs += 1
        n += encoded_head_len(UInt64(_pairs))
        n += encoded_tstr_len(5)
        n += encoded_int_len(self.value)
        if self.next:
            n += encoded_tstr_len(4)
            n += self.next.value()[].encoded_len(options)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        var n = 1
        if self.next:
            n += 1
        w.write_map_len(n)
        w.write_tstr("value")
        w.write_int(self.value)
        if self.next:
            w.write_tstr("next")
            self.next.value()[].encode_to(w, options)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if r.bytes_eq(_ks, _kn, "value"):
                self.value = r.read_int64()
            elif r.bytes_eq(_ks, _kn, "next"):
                var _c = LongList()
                _c.decode_from(r)
                self.next = Optional[Box[LongList]](Box(_c^))
            else:
                r.skip_item()
