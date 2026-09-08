from std.collections import List, Optional, Span

from cbor import (
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


struct Document(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var id: String
    var n: Int64
    var meta: Meta

    def __init__(out self):
        self.id = String()
        self.n = Int64(0)
        self.meta = Meta()

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
        w.write_map_len(n)
        w.write_tstr("id")
        w.write_tstr(self.id)
        w.write_tstr("n")
        w.write_int(self.n)
        w.write_tstr("meta")
        self.meta.encode_to(w, options)

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
            if key == "id":
                self.id = tmp.texts[Int(tmp.nodes[vn].a)]
            if key == "n":
                self.n = tmp.nodes[vn].a
            if key == "meta":
                pass

