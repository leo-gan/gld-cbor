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


struct Telemetry(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var values: List[Float64]

    def __init__(out self):
        self.values = List[Float64]()

    def __init__(out self, var values: List[Float64]):
        self.values = values^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        n += encoded_head_len(UInt64(1))
        n += encoded_tstr_len(6)
        n += encoded_head_len(UInt64(len(self.values)))
        for _i in range(len(self.values)):
            n += encoded_float_preferred_len(self.values[_i])
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        w.write_map_len(1)
        w.write_bytes(String("\x66\x76\x61\x6c\x75\x65\x73").as_bytes())
        w.write_array_len(len(self.values))
        for _i in range(len(self.values)):
            w.write_float_preferred(self.values[_i])

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if _kn == 6:
                if r.bytes_eq(_ks, _kn, "values"):
                    var _lst = List[Float64]()
                    var _alen = r.read_array_len()
                    for _j in range(_alen):
                        _lst.append(r.read_float64())
                    self.values = _lst^
                else:
                    r.skip_item()
            else:
                r.skip_item()
