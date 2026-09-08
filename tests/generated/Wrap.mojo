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


struct Wrap(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var x: Alt

    def __init__(out self):
        self.x = Alt()

    def __init__(out self, var x: Alt):
        self.x = x^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        n += encoded_head_len(UInt64(1))
        n += encoded_tstr_len(1)
        n += self.x.encoded_len(options)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        w.write_map_len(1)
        w.write_tstr("x")
        self.x.encode_to(w, options)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if r.bytes_eq(_ks, _kn, "x"):
                var _c = Alt()
                _c.decode_from(r)
                self.x = _c^
            else:
                r.skip_item()
