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


struct B(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var a: Optional[Box[A]]

    def __init__(out self):
        self.a = Optional[Box[A]]()

    def __init__(out self, var a: Optional[Box[A]]):
        self.a = a^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        var _pairs = 0
        if self.a:
            _pairs += 1
        n += encoded_head_len(UInt64(_pairs))
        if self.a:
            n += encoded_tstr_len(1)
            n += self.a.value()[].encoded_len(options)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        var n = 0
        if self.a:
            n += 1
        w.write_map_len(n)
        if self.a:
            w.write_tstr("a")
            self.a.value()[].encode_to(w, options)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if r.bytes_eq(_ks, _kn, "a"):
                var _c = A()
                _c.decode_from(r)
                self.a = Optional[Box[A]](Box(_c^))
            else:
                r.skip_item()
