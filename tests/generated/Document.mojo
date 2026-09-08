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


struct Document(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var id: String
    var n: Int64
    var meta: Meta

    def __init__(out self):
        self.id = String()
        self.n = Int64(0)
        self.meta = Meta()

    def __init__(out self, var id: String, var n: Int64, var meta: Meta):
        self.id = id^
        self.n = n^
        self.meta = meta^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        n += encoded_head_len(UInt64(3))
        n += encoded_tstr_len(2)
        n += encoded_tstr_len(self.id.byte_length())
        n += encoded_tstr_len(1)
        n += encoded_int_len(self.n)
        n += encoded_tstr_len(4)
        n += self.meta.encoded_len(options)
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        w.write_map_len(3)
        if options.is_cde():
            w.write_bytes(String("\x61\x6e").as_bytes())
            w.write_int(self.n)
            w.write_bytes(String("\x62\x69\x64").as_bytes())
            w.write_tstr(self.id)
            w.write_bytes(String("\x64\x6d\x65\x74\x61").as_bytes())
            self.meta.encode_to(w, options)
        else:
            w.write_bytes(String("\x62\x69\x64").as_bytes())
            w.write_tstr(self.id)
            w.write_bytes(String("\x61\x6e").as_bytes())
            w.write_int(self.n)
            w.write_bytes(String("\x64\x6d\x65\x74\x61").as_bytes())
            self.meta.encode_to(w, options)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if _kn == 2:
                if r.bytes_eq(_ks, _kn, "id"):
                    self.id = r.read_tstr()
                else:
                    r.skip_item()
            elif _kn == 1:
                if r.bytes_eq(_ks, _kn, "n"):
                    self.n = r.read_int64()
                else:
                    r.skip_item()
            elif _kn == 4:
                if r.bytes_eq(_ks, _kn, "meta"):
                    var _c = Meta()
                    _c.decode_from(r)
                    self.meta = _c^
                else:
                    r.skip_item()
            else:
                r.skip_item()
