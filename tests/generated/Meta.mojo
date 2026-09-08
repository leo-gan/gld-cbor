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


struct Meta(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var note: Optional[String]

    def __init__(out self):
        self.note = Optional[String]()

    def __init__(out self, var note: Optional[String]):
        self.note = note^

    def encoded_len(self, options: EncodeOptions) -> Int:
        var n = 0
        var _pairs = 0
        if self.note:
            _pairs += 1
        n += encoded_head_len(UInt64(_pairs))
        if self.note:
            n += encoded_tstr_len(4)
            n += encoded_tstr_len(self.note.value().byte_length())
        return n

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        var n = 0
        if self.note:
            n += 1
        w.write_map_len(n)
        if self.note:
            w.write_tstr("note")
            w.write_tstr(self.note.value())

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var _pairs = r.read_map_len()
        for _i in range(_pairs):
            var _ks = 0
            var _kn = 0
            if not r.take_definite_tstr(_ks, _kn):
                r.skip_item()
                continue
            if r.bytes_eq(_ks, _kn, "note"):
                self.note = Optional[String](r.read_tstr())
            else:
                r.skip_item()
