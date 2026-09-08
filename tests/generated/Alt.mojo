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


struct Alt(Copyable, Movable, Defaultable, Deinitable, CborDatum):
    var tag: Int
    var v0: Int64
    var v1: String

    def __init__(out self):
        self.tag = 0
        self.v0 = Int64(0)
        self.v1 = String()

    def encoded_len(self, options: EncodeOptions) -> Int:
        var w = WireWriter()
        self.encode_to(w, options)
        var b = w^.finish()
        return len(b)

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        if self.tag == 0:
            w.write_int(self.v0)
        elif self.tag == 1:
            w.write_tstr(self.v1)

    def _from_node(mut self, tmp: CborValue, idx: Int) raises DecodeError:
        var vn = idx
        var node = tmp.nodes[idx]
        if node.kind == CK_INT or node.kind == CK_UINT:
            self.tag = 0
            self.v0 = tmp.nodes[vn].a
            return
        elif node.kind == CK_TEXT:
            self.tag = 1
            self.v1 = tmp.texts[Int(tmp.nodes[vn].a)]
            return
        raise DecodeError(DecodeError.KIND_TYPE, 0)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var tmp = CborValue()
        var root = decode_item(r, tmp)
        self._from_node(tmp, root)
