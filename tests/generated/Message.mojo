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


struct Message(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var f_bool: Bool
    var f_int: Int64
    var f_uint: UInt64
    var f_float: Float64
    var f_text: String

    def __init__(out self):
        self.f_bool = False
        self.f_int = Int64(0)
        self.f_uint = UInt64(0)
        self.f_float = 0.0
        self.f_text = String()

    def __init__(out self, var f_bool: Bool, var f_int: Int64, var f_uint: UInt64, var f_float: Float64, var f_text: String):
        self.f_bool = f_bool^
        self.f_int = f_int^
        self.f_uint = f_uint^
        self.f_float = f_float^
        self.f_text = f_text^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        n += encoded_head_len(UInt64(5))
        n += encoded_tstr_len(6)
        n += 1
        n += encoded_tstr_len(5)
        n += encoded_int_len(self.f_int)
        n += encoded_tstr_len(6)
        n += encoded_uint_len(self.f_uint)
        n += encoded_tstr_len(7)
        n += encoded_float_preferred_len(self.f_float)
        n += encoded_tstr_len(6)
        n += encoded_tstr_len(self.f_text.byte_length())
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        w.write_map_len(5)
        w.write_tstr("f_bool")
        w.write_bool(self.f_bool)
        w.write_tstr("f_int")
        w.write_int(self.f_int)
        w.write_tstr("f_uint")
        w.write_uint(self.f_uint)
        w.write_tstr("f_float")
        w.write_float_preferred(self.f_float)
        w.write_tstr("f_text")
        w.write_tstr(self.f_text)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if r.bytes_eq(_ks, _kn, "f_bool"):
                self.f_bool = r.read_bool()
            elif r.bytes_eq(_ks, _kn, "f_int"):
                self.f_int = r.read_int64()
            elif r.bytes_eq(_ks, _kn, "f_uint"):
                self.f_uint = r.read_uint64()
            elif r.bytes_eq(_ks, _kn, "f_float"):
                self.f_float = r.read_float64()
            elif r.bytes_eq(_ks, _kn, "f_text"):
                self.f_text = r.read_tstr()
            else:
                r.skip_item()
