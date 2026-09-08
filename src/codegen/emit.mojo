from std.collections import List

from cddl.model import (
    CT_ANY,
    CT_ARRAY,
    CT_BOOL,
    CT_BSTR,
    CT_CHOICE,
    CT_FLOAT,
    CT_INT,
    CT_NAMED,
    CT_NULL,
    CT_STRUCT,
    CT_TAG,
    CT_TSTR,
    CT_UINT,
    CddlDoc,
)
from runtime.error import DecodeError


def _mojo_ident(name: String) -> String:
    if (
        name == "struct"
        or name == "fn"
        or name == "var"
        or name == "def"
        or name == "trait"
    ):
        return name + "_"
    return name


def _kind_name(doc: CddlDoc, idx: Int) raises DecodeError -> String:
    var t = doc.types[idx]
    if t.kind == CT_BOOL:
        return String("Bool")
    if t.kind == CT_INT:
        return String("Int64")
    if t.kind == CT_UINT:
        return String("UInt64")
    if t.kind == CT_TSTR:
        return String("String")
    if t.kind == CT_BSTR:
        return String("List[Byte]")
    if t.kind == CT_FLOAT:
        return String("Float64")
    if t.kind == CT_NAMED:
        return _mojo_ident(t.name)
    if t.kind == CT_ARRAY:
        return String("List[") + _kind_name(doc, t.inner) + "]"
    if t.kind == CT_CHOICE:
        var a = doc.types[t.inner]
        var b = doc.types[t.inner2]
        if a.kind == CT_NULL:
            return String("Optional[") + _kind_name(doc, t.inner2) + "]"
        if b.kind == CT_NULL:
            return String("Optional[") + _kind_name(doc, t.inner) + "]"
        raise DecodeError(DecodeError.KIND_CDDL, 0)
    if t.kind == CT_TAG:
        if t.tag == UInt64(0):
            return String("String")
        if t.tag == UInt64(1):
            return String("EpochTime")
        if t.tag == UInt64(2):
            return String("BigUint")
        if t.tag == UInt64(3):
            return String("BigNint")
        if t.tag == UInt64(32):
            return String("Uri")
        return String("CborValue")
    if t.kind == CT_ANY:
        return String("CborValue")
    raise DecodeError(DecodeError.KIND_CDDL, 0)


def _is_optional_member(doc: CddlDoc, member_optional: Bool, type_idx: Int) -> Bool:
    if member_optional:
        return True
    var t = doc.types[type_idx]
    if t.kind == CT_CHOICE:
        if doc.types[t.inner].kind == CT_NULL or doc.types[t.inner2].kind == CT_NULL:
            return True
    return False


def _unwrap_optional(doc: CddlDoc, type_idx: Int) -> Int:
    var t = doc.types[type_idx]
    if t.kind == CT_CHOICE:
        if doc.types[t.inner].kind == CT_NULL:
            return t.inner2
        if doc.types[t.inner2].kind == CT_NULL:
            return t.inner
    return type_idx


def _lookup_named(doc: CddlDoc, name: String) -> Int:
    for i in range(len(doc.def_names)):
        if doc.def_names[i] == name:
            return doc.def_types[i]
    return -1


def _resolve(doc: CddlDoc, idx: Int) -> Int:
    var t = doc.types[idx]
    if t.kind == CT_NAMED:
        var found = _lookup_named(doc, t.name)
        if found >= 0:
            return found
    return idx


def emit_struct(doc: CddlDoc, def_i: Int) raises DecodeError -> String:
    var name = _mojo_ident(doc.def_names[def_i])
    var ty = _resolve(doc, doc.def_types[def_i])
    var t = doc.types[ty]
    if t.kind != CT_STRUCT:
        raise DecodeError(DecodeError.KIND_CDDL, 0)
    var out = String()
    out += "from std.collections import List, Optional, Span\n\n"
    out += "from cbor import (\n"
    out += "    CborDatum,\n"
    out += "    DecodeError,\n"
    out += "    EncodeOptions,\n"
    out += "    WireReader,\n"
    out += "    WireWriter,\n"
    out += "    decode_value,\n"
    out += "    node_as_float,\n"
    out += "    CK_ARRAY,\n"
    out += "    CK_BYTES,\n"
    out += "    CK_FALSE,\n"
    out += "    CK_FLOAT16,\n"
    out += "    CK_FLOAT32,\n"
    out += "    CK_FLOAT64,\n"
    out += "    CK_INT,\n"
    out += "    CK_MAP,\n"
    out += "    CK_TEXT,\n"
    out += "    CK_TRUE,\n"
    out += "    CK_UINT,\n"
    out += ")\n"
    out += "from runtime.value import decode_item, CborValue\n\n\n"
    out += "struct " + name + "(Copyable, Movable, Defaultable, Deinitable, CborDatum):\n"
    for m in range(t.members_count):
        var mem = doc.members[t.members_start + m]
        var field = _mojo_ident(mem.name)
        var opt = _is_optional_member(doc, mem.optional, mem.type_idx)
        var inner = _unwrap_optional(doc, mem.type_idx)
        var tn = _kind_name(doc, inner)
        if opt:
            out += "    var " + field + ": Optional[" + tn + "]\n"
        else:
            out += "    var " + field + ": " + tn + "\n"
    out += "\n    def __init__(out self):\n"
    for m in range(t.members_count):
        var mem2 = doc.members[t.members_start + m]
        var field2 = _mojo_ident(mem2.name)
        var opt2 = _is_optional_member(doc, mem2.optional, mem2.type_idx)
        var inner2 = _unwrap_optional(doc, mem2.type_idx)
        var tn2 = _kind_name(doc, inner2)
        if opt2:
            out += "        self." + field2 + " = Optional[" + tn2 + "]()\n"
        elif tn2 == "Bool":
            out += "        self." + field2 + " = False\n"
        elif tn2 == "Int64":
            out += "        self." + field2 + " = Int64(0)\n"
        elif tn2 == "UInt64":
            out += "        self." + field2 + " = UInt64(0)\n"
        elif tn2 == "Float64":
            out += "        self." + field2 + " = 0.0\n"
        elif tn2 == "String":
            out += "        self." + field2 + " = String()\n"
        elif tn2 == "List[Byte]":
            out += "        self." + field2 + " = List[Byte]()\n"
        else:
            out += "        self." + field2 + " = " + tn2 + "()\n"
    out += "\n    def encoded_len(self, options: EncodeOptions) -> Int:\n"
    out += "        var w = WireWriter()\n"
    out += "        self.encode_to(w, options)\n"
    out += "        var b = w^.finish()\n"
    out += "        return len(b)\n\n"
    out += "    def encode_to(self, mut w: WireWriter, options: EncodeOptions):\n"
    out += "        var n = 0\n"
    for m in range(t.members_count):
        var mem3 = doc.members[t.members_start + m]
        var field3 = _mojo_ident(mem3.name)
        var opt3 = _is_optional_member(doc, mem3.optional, mem3.type_idx)
        if opt3:
            out += "        if self." + field3 + ":\n"
            out += "            n += 1\n"
        else:
            out += "        n += 1\n"
    out += "        w.write_map_len(n)\n"
    for m in range(t.members_count):
        var mem4 = doc.members[t.members_start + m]
        var field4 = _mojo_ident(mem4.name)
        var opt4 = _is_optional_member(doc, mem4.optional, mem4.type_idx)
        var inner4 = _unwrap_optional(doc, mem4.type_idx)
        var tn4 = _kind_name(doc, inner4)
        var indent = String("        ")
        if opt4:
            out += "        if self." + field4 + ":\n"
            indent = String("            ")
        out += indent + "w.write_tstr(\"" + mem4.name + "\")\n"
        var access = "self." + field4
        if opt4:
            access = "self." + field4 + ".value()"
        if tn4 == "Bool":
            out += indent + "w.write_bool(" + access + ")\n"
        elif tn4 == "Int64":
            out += indent + "w.write_int(" + access + ")\n"
        elif tn4 == "UInt64":
            out += indent + "w.write_uint(" + access + ")\n"
        elif tn4 == "Float64":
            out += indent + "w.write_float_preferred(" + access + ")\n"
        elif tn4 == "String":
            out += indent + "w.write_tstr(" + access + ")\n"
        elif tn4 == "List[Byte]":
            out += indent + "w.write_bstr(" + access + ")\n"
        elif tn4 == "List[Float64]":
            out += indent + "w.write_array_len(len(" + access + "))\n"
            out += indent + "for _i in range(len(" + access + ")):\n"
            out += indent + "    w.write_float_preferred(" + access + "[_i])\n"
        elif tn4 == "List[String]":
            out += indent + "w.write_array_len(len(" + access + "))\n"
            out += indent + "for _i in range(len(" + access + ")):\n"
            out += indent + "    w.write_tstr(" + access + "[_i])\n"
        elif tn4 == "List[Int64]":
            out += indent + "w.write_array_len(len(" + access + "))\n"
            out += indent + "for _i in range(len(" + access + ")):\n"
            out += indent + "    w.write_int(" + access + "[_i])\n"
        else:
            out += indent + access + ".encode_to(w, options)\n"
    out += "\n    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:\n"
    out += "        var tmp = CborValue()\n"
    out += "        var root = decode_item(r, tmp)\n"
    out += "        var node = tmp.nodes[root]\n"
    out += "        if node.kind != CK_MAP:\n"
    out += "            raise DecodeError(DecodeError.KIND_TYPE, r.position())\n"
    out += "        var pairs = Int(node.b)\n"
    out += "        var k0 = Int(node.a)\n"
    out += "        for i in range(pairs):\n"
    out += "            var kn = tmp.nodes[tmp.kids[k0 + i * 2]]\n"
    out += "            if kn.kind != CK_TEXT:\n"
    out += "                continue\n"
    out += "            var key = tmp.texts[Int(kn.a)]\n"
    out += "            var vn = tmp.kids[k0 + i * 2 + 1]\n"
    for m in range(t.members_count):
        var mem5 = doc.members[t.members_start + m]
        var field5 = _mojo_ident(mem5.name)
        var opt5 = _is_optional_member(doc, mem5.optional, mem5.type_idx)
        var inner5 = _unwrap_optional(doc, mem5.type_idx)
        var tn5 = _kind_name(doc, inner5)
        out += "            if key == \"" + mem5.name + "\":\n"
        if tn5 == "Bool":
            out += "                var vk = tmp.nodes[vn].kind\n"
            if opt5:
                out += "                self." + field5 + " = Optional[Bool](vk == CK_TRUE)\n"
            else:
                out += "                self." + field5 + " = vk == CK_TRUE\n"
        elif tn5 == "Int64":
            if opt5:
                out += "                self." + field5 + " = Optional[Int64](tmp.nodes[vn].a)\n"
            else:
                out += "                self." + field5 + " = tmp.nodes[vn].a\n"
        elif tn5 == "UInt64":
            out += "                var uv = tmp.nodes[vn]\n"
            out += "                var uval = uv.b\n"
            out += "                if uv.kind == CK_INT:\n"
            out += "                    uval = UInt64(uv.a)\n"
            if opt5:
                out += "                self." + field5 + " = Optional[UInt64](uval)\n"
            else:
                out += "                self." + field5 + " = uval\n"
        elif tn5 == "Float64":
            if opt5:
                out += "                self." + field5 + " = Optional[Float64](node_as_float(tmp, vn))\n"
            else:
                out += "                self." + field5 + " = node_as_float(tmp, vn)\n"
        elif tn5 == "String":
            if opt5:
                out += "                self." + field5 + " = Optional[String](tmp.texts[Int(tmp.nodes[vn].a)])\n"
            else:
                out += "                self." + field5 + " = tmp.texts[Int(tmp.nodes[vn].a)]\n"
        elif tn5 == "List[Float64]":
            out += "                self." + field5 + " = List[Float64]()\n"
            out += "                var an = tmp.nodes[vn]\n"
            out += "                if an.kind == CK_ARRAY:\n"
            out += "                    var a0 = Int(an.a)\n"
            out += "                    for _j in range(Int(an.b)):\n"
            out += (
                "                        self."
                + field5
                + ".append(node_as_float(tmp, tmp.kids[a0 + _j]))\n"
            )
        elif tn5 == "List[String]":
            out += "                self." + field5 + " = List[String]()\n"
            out += "                var an = tmp.nodes[vn]\n"
            out += "                if an.kind == CK_ARRAY:\n"
            out += "                    var a0 = Int(an.a)\n"
            out += "                    for _j in range(Int(an.b)):\n"
            out += (
                "                        self."
                + field5
                + ".append(tmp.texts[Int(tmp.nodes[tmp.kids[a0 + _j]].a)])\n"
            )
        else:
            out += "                pass\n"
    out += "\n"
    return out


def emit_all(doc: CddlDoc) raises DecodeError -> List[String]:
    # returns interleaved name, body, name, body...
    var out = List[String]()
    for i in range(len(doc.def_names)):
        var ty = _resolve(doc, doc.def_types[i])
        if doc.types[ty].kind == CT_STRUCT:
            out.append(_mojo_ident(doc.def_names[i]))
            out.append(emit_struct(doc, i))
    return out^
