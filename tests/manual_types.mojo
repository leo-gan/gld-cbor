from std.collections import List, Optional, Span

from cbor import (
    CborDatum,
    DecodeError,
    EncodeOptions,
    WireReader,
    WireWriter,
    CK_INT,
    CK_MAP,
    CK_TEXT,
    CK_TRUE,
    CK_UINT,
)
from runtime.value import CborValue, decode_item, node_as_float


struct Message(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    """Hand-written Message matching testdata/cddl/benchmark_v2.cddl."""

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

    def __init__(
        out self,
        f_bool: Bool,
        f_int: Int64,
        f_uint: UInt64,
        f_float: Float64,
        f_text: String,
    ):
        self.f_bool = f_bool
        self.f_int = f_int
        self.f_uint = f_uint
        self.f_float = f_float
        self.f_text = f_text

    def encoded_len(self, options: EncodeOptions) -> Int:
        var w = WireWriter()
        self.encode_to(w, options)
        var b = w^.finish()
        return len(b)

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
                self.f_bool = tmp.nodes[vn].kind == CK_TRUE
            if key == "f_int":
                self.f_int = tmp.nodes[vn].a
            if key == "f_uint":
                var uv = tmp.nodes[vn]
                var uval = uv.b
                if uv.kind == CK_INT:
                    uval = UInt64(uv.a)
                self.f_uint = uval
            if key == "f_float":
                self.f_float = node_as_float(tmp, vn)
            if key == "f_text":
                self.f_text = tmp.texts[Int(tmp.nodes[vn].a)]
