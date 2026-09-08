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


struct Row(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var f_bool: Bool
    var f_int: Int64
    var f_text: String

    def __init__(out self):
        self.f_bool = False
        self.f_int = Int64(0)
        self.f_text = String()

    def __init__(out self, var f_bool: Bool, var f_int: Int64, var f_text: String):
        self.f_bool = f_bool^
        self.f_int = f_int^
        self.f_text = f_text^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        n += encoded_head_len(UInt64(3))
        n += 1
        n += encoded_int_len(self.f_int)
        n += encoded_tstr_len(self.f_text.byte_length())
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        w.write_array_len(3)
        w.write_bool(self.f_bool)
        w.write_int(self.f_int)
        w.write_tstr(self.f_text)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _n = r.read_array_len()
        var _i = 0
        if _i >= _n:
            raise DecodeError(DecodeError.KIND_EOF, r.position())
        self.f_bool = r.read_bool()
        _i += 1
        if _i >= _n:
            raise DecodeError(DecodeError.KIND_EOF, r.position())
        self.f_int = r.read_int64()
        _i += 1
        if _i >= _n:
            raise DecodeError(DecodeError.KIND_EOF, r.position())
        self.f_text = r.read_tstr()
        _i += 1
        while _i < _n:
            r.skip_item()
            _i += 1
