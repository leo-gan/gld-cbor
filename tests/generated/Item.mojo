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


struct Item(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var name: String
    var qty: Int64

    def __init__(out self):
        self.name = String()
        self.qty = Int64(0)

    def __init__(out self, var name: String, var qty: Int64):
        self.name = name^
        self.qty = qty^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        n += encoded_head_len(UInt64(2))
        n += encoded_tstr_len(4)
        n += encoded_tstr_len(self.name.byte_length())
        n += encoded_tstr_len(3)
        n += encoded_int_len(self.qty)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        w.write_map_len(2)
        if options.is_cde():
            w.write_bytes(String("\x63\x71\x74\x79").as_bytes())
            w.write_int(self.qty)
            w.write_bytes(String("\x64\x6e\x61\x6d\x65").as_bytes())
            w.write_tstr(self.name)
        else:
            w.write_bytes(String("\x64\x6e\x61\x6d\x65").as_bytes())
            w.write_tstr(self.name)
            w.write_bytes(String("\x63\x71\x74\x79").as_bytes())
            w.write_int(self.qty)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if _kn == 4:
                if r.bytes_eq(_ks, _kn, "name"):
                    self.name = r.read_tstr()
                else:
                    r.skip_item()
            elif _kn == 3:
                if r.bytes_eq(_ks, _kn, "qty"):
                    self.qty = r.read_int64()
                else:
                    r.skip_item()
            else:
                r.skip_item()
