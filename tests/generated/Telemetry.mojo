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


struct Telemetry(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var values: List[Float64]

    def __init__(out self):
        self.values = List[Float64]()

    def encoded_len(self, options: EncodeOptions) -> Int:
        var w = WireWriter()
        self.encode_to(w, options)
        var b = w^.finish()
        return len(b)

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        var n = 0
        n += 1
        w.write_map_len(n)
        w.write_tstr("values")
        w.write_array_len(len(self.values))
        for _i in range(len(self.values)):
            w.write_float_preferred(self.values[_i])

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
            if key == "values":
                self.values = List[Float64]()
                var an = tmp.nodes[vn]
                if an.kind == CK_ARRAY:
                    var a0 = Int(an.a)
                    for _j in range(Int(an.b)):
                        self.values.append(node_as_float(tmp, tmp.kids[a0 + _j]))

