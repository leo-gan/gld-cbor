from std.collections import List, Optional, Span

from cbor import (
    Box,
    CborDatum,
    DecodeError,
    EncodeOptions,
    WireReader,
    WireWriter,
    decode_value,
    node_as_float,
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
        var w = WireWriter()
        self.encode_to(w, options)
        var b = w^.finish()
        return len(b)

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        var n = 0
        n += 1
        n += 1
        w.write_map_len(n)
        w.write_tstr("code")
        w.write_int(self.code)
        w.write_tstr("ok")
        w.write_bool(self.ok)

    def _from_node(mut self, tmp: CborValue, idx: Int) raises DecodeError:
        var node = tmp.nodes[idx]
        if node.kind != CK_MAP:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var pairs = Int(node.b)
        var k0 = Int(node.a)
        for i in range(pairs):
            var kn = tmp.nodes[tmp.kids[k0 + i * 2]]
            if kn.kind != CK_TEXT:
                continue
            var key = tmp.texts[Int(kn.a)]
            var vn = tmp.kids[k0 + i * 2 + 1]
            if key == "code":
                self.code = tmp.nodes[vn].a
            if key == "ok":
                self.ok = tmp.nodes[vn].kind == CK_TRUE

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var tmp = CborValue()
        var root = decode_item(r, tmp)
        self._from_node(tmp, root)
