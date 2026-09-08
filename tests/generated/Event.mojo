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
        if options.is_cde():
            w.write_bytes(String("\x62\x6f\x6b").as_bytes())
            w.write_bool(self.ok)
            w.write_bytes(String("\x64\x63\x6f\x64\x65").as_bytes())
            w.write_int(self.code)
        else:
            w.write_bytes(String("\x64\x63\x6f\x64\x65").as_bytes())
            w.write_int(self.code)
            w.write_bytes(String("\x62\x6f\x6b").as_bytes())
            w.write_bool(self.ok)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if _kn == 4:
                if r.bytes_eq(_ks, _kn, "code"):
                    self.code = r.read_int64()
                else:
                    r.skip_item()
            elif _kn == 2:
                if r.bytes_eq(_ks, _kn, "ok"):
                    self.ok = r.read_bool()
                else:
                    r.skip_item()
            else:
                r.skip_item()
