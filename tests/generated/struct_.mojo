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


struct struct_(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var fn_: Int64
    var var_: String

    def __init__(out self):
        self.fn_ = Int64(0)
        self.var_ = String()

    def __init__(out self, var fn_: Int64, var var_: String):
        self.fn_ = fn_^
        self.var_ = var_^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        n += encoded_head_len(UInt64(2))
        n += encoded_tstr_len(2)
        n += encoded_int_len(self.fn_)
        n += encoded_tstr_len(3)
        n += encoded_tstr_len(self.var_.byte_length())
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        w.write_map_len(2)
        w.write_tstr("fn")
        w.write_int(self.fn_)
        w.write_tstr("var")
        w.write_tstr(self.var_)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if r.bytes_eq(_ks, _kn, "fn"):
                self.fn_ = r.read_int64()
            elif r.bytes_eq(_ks, _kn, "var"):
                self.var_ = r.read_tstr()
            else:
                r.skip_item()
