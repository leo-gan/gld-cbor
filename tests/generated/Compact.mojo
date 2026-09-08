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


struct Compact(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var k0: Bool
    var k1: Int64
    var k2: String

    def __init__(out self):
        self.k0 = False
        self.k1 = Int64(0)
        self.k2 = String()

    def __init__(out self, var k0: Bool, var k1: Int64, var k2: String):
        self.k0 = k0^
        self.k1 = k1^
        self.k2 = k2^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        n += encoded_head_len(UInt64(3))
        n += encoded_int_len(Int64(0))
        n += 1
        n += encoded_int_len(Int64(1))
        n += encoded_int_len(self.k1)
        n += encoded_int_len(Int64(2))
        n += encoded_tstr_len(self.k2.byte_length())
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        w.write_map_len(3)
        w.write_int(Int64(0))
        w.write_bool(self.k0)
        w.write_int(Int64(1))
        w.write_int(self.k1)
        w.write_int(Int64(2))
        w.write_tstr(self.k2)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        var _expect = 0
        for _i in range(_pairs):
            var _ik = Int64(0)
            if not r.take_int_key(_ik):
                r.skip_item()
                continue
            if _expect == 0 and _ik == Int64(0):
                self.k0 = r.read_bool()
                _expect = 1
            elif _expect == 1 and _ik == Int64(1):
                self.k1 = r.read_int64()
                _expect = 2
            elif _expect == 2 and _ik == Int64(2):
                self.k2 = r.read_tstr()
                _expect = 3
            else:
                if _ik == Int64(0):
                    self.k0 = r.read_bool()
                elif _ik == Int64(1):
                    self.k1 = r.read_int64()
                elif _ik == Int64(2):
                    self.k2 = r.read_tstr()
                else:
                    r.skip_item()
