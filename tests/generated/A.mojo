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


struct A(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var b: Optional[Box[B]]

    def __init__(out self):
        self.b = Optional[Box[B]]()

    def __init__(out self, var b: Optional[Box[B]]):
        self.b = b^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        var _pairs = 0
        if self.b:
            _pairs += 1
        n += encoded_head_len(UInt64(_pairs))
        if self.b:
            n += encoded_tstr_len(1)
            n += self.b.value()[].encoded_len(options)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        var n = 0
        if self.b:
            n += 1
        w.write_map_len(n)
        if self.b:
            w.write_bytes(String("\x61\x62").as_bytes())
            self.b.value()[].encode_to(w, options)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        var _expect = 0
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if _expect == 0 and r.bytes_eq(_ks, _kn, "b"):
                var _c = B()
                _c.decode_from(r)
                self.b = Optional[Box[B]](Box(_c^))
                _expect = 1
            else:
                if _kn == 1:
                    if r.bytes_eq(_ks, _kn, "b"):
                        var _c = B()
                        _c.decode_from(r)
                        self.b = Optional[Box[B]](Box(_c^))
                    else:
                        r.skip_item()
                else:
                    r.skip_item()
