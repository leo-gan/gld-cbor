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


struct Event(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var code: Int64
    var ok: Bool

    def __init__(out self):
        self.code = Int64(0)
        self.ok = False

    def __init__(out self, var code: Int64, var ok: Bool):
        self.code = code^
        self.ok = ok^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        n += encoded_head_len(UInt64(2))
        n += encoded_tstr_len(4)
        n += encoded_int_len(self.code)
        n += encoded_tstr_len(2)
        n += 1
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        w.write_map_len(2)
        w.write_tstr("code")
        w.write_int(self.code)
        w.write_tstr("ok")
        w.write_bool(self.ok)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if r.bytes_eq(_ks, _kn, "code"):
                self.code = r.read_int64()
            elif r.bytes_eq(_ks, _kn, "ok"):
                self.ok = r.read_bool()
            else:
                r.skip_item()
