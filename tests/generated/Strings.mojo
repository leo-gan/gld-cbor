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


struct Strings(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var items: List[String]

    def __init__(out self):
        self.items = List[String]()

    def __init__(out self, var items: List[String]):
        self.items = items^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        n += encoded_head_len(UInt64(1))
        n += encoded_tstr_len(5)
        n += encoded_head_len(UInt64(len(self.items)))
        for _i in range(len(self.items)):
            n += encoded_tstr_len(self.items[_i].byte_length())
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        w.write_map_len(1)
        w.write_bytes(String("\x65\x69\x74\x65\x6d\x73").as_bytes())
        w.write_array_len(len(self.items))
        for _i in range(len(self.items)):
            w.write_tstr(self.items[_i])

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if _kn == 5:
                if r.bytes_eq(_ks, _kn, "items"):
                    var _lst = List[String]()
                    var _alen = r.read_array_len()
                    for _j in range(_alen):
                        _lst.append(r.read_tstr())
                    self.items = _lst^
                else:
                    r.skip_item()
            else:
                r.skip_item()
