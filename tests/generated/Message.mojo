from std.collections import List, Optional, Span

from cbor import (
    CborDatum,
    DecodeError,
    EncodeOptions,
    WireReader,
    WireWriter,
    decode_value,
    CK_ARRAY,
    CK_BYTES,
    CK_FALSE,
    CK_FLOAT16,
    CK_FLOAT32,
    CK_FLOAT64,
    CK_INT,
    CK_MAP,
    CK_TEXT,
    CK_TRUE,
    CK_UINT,
)
from runtime.value import decode_item, CborValue


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

    def encoded_len(self, options: EncodeOptions) -> Int:
        var w = WireWriter()
        self.encode_to(w, options)
        var b = w^.finish()
        return len(b)

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        var n = 0
        n += 1
        n += 1
        n += 1
        n += 1
        n += 1
        w.write_map_len(n)
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
        var tmp = CborValue()
        var root = decode_item(r, tmp)
        var node = tmp.nodes[root]
        if node.kind != CK_MAP:
            raise DecodeError(DecodeError.KIND_TYPE, r.position())
        var pairs = Int(node.b)
        var k0 = Int(node.a)
        for i in range(pairs):
            var kn = tmp.nodes[tmp.kids[k0 + i * 2]]
            if kn.kind != CK_TEXT:
                continue
            var key = tmp.texts[Int(kn.a)]
            var vn = tmp.kids[k0 + i * 2 + 1]
            if key == "f_bool":
                var vk = tmp.nodes[vn].kind
                self.f_bool = vk == CK_TRUE
            if key == "f_int":
                self.f_int = tmp.nodes[vn].a
            if key == "f_uint":
                var uv = tmp.nodes[vn]
                var uval = uv.b
                if uv.kind == CK_INT:
                    uval = UInt64(uv.a)
                self.f_uint = uval
            if key == "f_float":
                self.f_float = 0.0
            if key == "f_text":
                self.f_text = tmp.texts[Int(tmp.nodes[vn].a)]

