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


struct Alt(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var tag: Int
    var v0: Int64
    var v1: String

    def __init__(out self):
        self.tag = 0
        self.v0 = Int64(0)
        self.v1 = String()

    def encoded_len(self, options: EncodeOptions) -> Int:
        if self.tag == 0:
            var n = 0
            n += encoded_int_len(self.v0)
            return n
        elif self.tag == 1:
            var n = 0
            n += encoded_tstr_len(self.v1.byte_length())
            return n
        return 0

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        if self.tag == 0:
            w.write_int(self.v0)
        elif self.tag == 1:
            w.write_tstr(self.v1)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _hb = r.peek_head_byte()
        var _maj = _hb >> 5
        var _ai = _hb & 0x1F
        if _maj == 0 or _maj == 1:
            self.tag = 0
            self.v0 = r.read_int64()
            return
        elif _maj == 3:
            self.tag = 1
            self.v1 = r.read_tstr()
            return
        raise DecodeError(DecodeError.KIND_TYPE, r.position())
