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
    CT_UNWRAP,
    CddlDoc,
)
from runtime.error import DecodeError


def _starts(s: String, prefix: String) -> Bool:
    if s.byte_length() < prefix.byte_length():
        return False
    var a = s.as_bytes()
    var b = prefix.as_bytes()
    for i in range(len(b)):
        if Int(a[i]) != Int(b[i]):
            return False
    return True


def _cut(s: String, start: Int, end: Int) -> String:
    var b = s.as_bytes()
    try:
        return String(from_utf8=b[start:end])
    except _:
        return String()


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


def _lookup_named(doc: CddlDoc, name: String) -> Int:
    for i in range(len(doc.def_names)):
        if doc.def_names[i] == name:
            return doc.def_types[i]
    return -1


def _def_index(doc: CddlDoc, name: String) -> Int:
    for i in range(len(doc.def_names)):
        if doc.def_names[i] == name:
            return i
    return -1


def _resolve(doc: CddlDoc, idx: Int) -> Int:
    var t = doc.types[idx]
    if t.kind == CT_NAMED:
        var found = _lookup_named(doc, t.name)
        if found >= 0:
            return found
    if t.kind == CT_UNWRAP and t.inner >= 0:
        return _resolve(doc, t.inner)
    return idx


def _flatten_choice(doc: CddlDoc, idx: Int, mut out: List[Int]):
    var r = _resolve(doc, idx)
    var t = doc.types[r]
    if t.kind == CT_CHOICE:
        _flatten_choice(doc, t.inner, out)
        _flatten_choice(doc, t.inner2, out)
    else:
        out.append(r)


def _is_null_choice(doc: CddlDoc, idx: Int) -> Bool:
    var br = List[Int]()
    _flatten_choice(doc, idx, br)
    var nulls = 0
    var others = 0
    for i in range(len(br)):
        if doc.types[br[i]].kind == CT_NULL:
            nulls += 1
        else:
            others += 1
    return nulls == 1 and others == 1


def _nonnull_branch(doc: CddlDoc, idx: Int) -> Int:
    var br = List[Int]()
    _flatten_choice(doc, idx, br)
    for i in range(len(br)):
        if doc.types[br[i]].kind != CT_NULL:
            return br[i]
    return _resolve(doc, idx)


def _is_multi_choice(doc: CddlDoc, idx: Int) -> Bool:
    var r = _resolve(doc, idx)
    if doc.types[r].kind != CT_CHOICE:
        return False
    return not _is_null_choice(doc, idx)


def _unwrap_optional(doc: CddlDoc, type_idx: Int) -> Int:
    if _is_null_choice(doc, type_idx):
        return _nonnull_branch(doc, type_idx)
    return type_idx


def _is_optional_member(doc: CddlDoc, member_optional: Bool, type_idx: Int) -> Bool:
    if member_optional:
        return True
    return _is_null_choice(doc, type_idx)


def _collect_named_defs(doc: CddlDoc, type_idx: Int, mut out: List[Int]):
    var t0 = doc.types[type_idx]
    if t0.kind == CT_NAMED:
        var d = _def_index(doc, t0.name)
        if d >= 0:
            out.append(d)
        return
    var r = _resolve(doc, type_idx)
    var t = doc.types[r]
    if t.kind == CT_STRUCT:
        for m in range(t.members_count):
            _collect_named_defs(doc, doc.members[t.members_start + m].type_idx, out)
    elif t.kind == CT_ARRAY or t.kind == CT_UNWRAP or t.kind == CT_TAG:
        if t.inner >= 0:
            _collect_named_defs(doc, t.inner, out)
    elif t.kind == CT_CHOICE:
        _collect_named_defs(doc, t.inner, out)
        _collect_named_defs(doc, t.inner2, out)


def _def_reaches(doc: CddlDoc, src: Int, dst: Int, mut seen: List[Int]) -> Bool:
    if src == dst:
        return True
    for i in range(len(seen)):
        if seen[i] == src:
            return False
    seen.append(src)
    var refs = List[Int]()
    _collect_named_defs(doc, doc.def_types[src], refs)
    for i in range(len(refs)):
        if _def_reaches(doc, refs[i], dst, seen):
            return True
    return False


def _same_scc(doc: CddlDoc, a: Int, b: Int) -> Bool:
    var s1 = List[Int]()
    var s2 = List[Int]()
    return _def_reaches(doc, a, b, s1) and _def_reaches(doc, b, a, s2)


def _named_def_of(doc: CddlDoc, type_idx: Int) -> Int:
    var t = doc.types[type_idx]
    if t.kind == CT_NAMED:
        return _def_index(doc, t.name)
    var r = _resolve(doc, type_idx)
    var tr = doc.types[r]
    if tr.kind == CT_NAMED:
        return _def_index(doc, tr.name)
    return -1


def _needs_box(doc: CddlDoc, owner_def: Int, type_idx: Int) -> Bool:
    if owner_def < 0:
        return False
    var d = _named_def_of(doc, type_idx)
    if d < 0:
        return False
    var rt = doc.types[_resolve(doc, doc.def_types[d])]
    if rt.kind != CT_STRUCT and rt.kind != CT_CHOICE:
        return False
    return _same_scc(doc, owner_def, d)


def _prelude_name(doc: CddlDoc, idx: Int) raises DecodeError -> String:
    var r = _resolve(doc, idx)
    var t = doc.types[r]
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
    if t.kind == CT_ANY:
        return String("CborValue")
    if t.kind == CT_TAG:
        if t.tag == UInt64(0):
            return String("String")
        if t.tag == UInt64(1):
            return String("EpochTime")
        if t.tag == UInt64(2):
            return String("BigUint")
        if t.tag == UInt64(3):
            return String("BigNint")
        if t.tag == UInt64(4):
            return String("DecimalFraction")
        if t.tag == UInt64(5):
            return String("BigFloat")
        if t.tag == UInt64(32):
            return String("Uri")
        return String("CborValue")
    if t.kind == CT_NAMED:
        return _mojo_ident(t.name)
    if t.kind == CT_ARRAY:
        return String("List[") + _prelude_name(doc, t.inner) + "]"
    raise DecodeError(DecodeError.KIND_CDDL, 0)


def _elem_type_name(
    doc: CddlDoc, owner_def: Int, elem_idx: Int
) raises DecodeError -> String:
    var inner = _unwrap_optional(doc, elem_idx)
    var n: String
    if doc.types[inner].kind == CT_NAMED:
        n = _mojo_ident(doc.types[inner].name)
    else:
        n = _prelude_name(doc, inner)
    if _needs_box(doc, owner_def, inner):
        return String("Box[") + n + "]"
    return n


def _field_type_name(
    doc: CddlDoc,
    owner_def: Int,
    type_idx: Int,
    optional: Bool,
    owner_name: String,
    field_name: String,
) raises DecodeError -> String:
    var inner = _unwrap_optional(doc, type_idx)
    var t = doc.types[inner]
    var base: String
    if t.kind == CT_NAMED:
        base = _mojo_ident(t.name)
    elif _is_multi_choice(doc, inner):
        base = _mojo_ident(owner_name) + "_" + _mojo_ident(field_name)
    else:
        var r = _resolve(doc, inner)
        var tr = doc.types[r]
        if tr.kind == CT_ARRAY:
            base = String("List[") + _elem_type_name(doc, owner_def, tr.inner) + "]"
        else:
            base = _prelude_name(doc, inner)
    if _needs_box(doc, owner_def, inner):
        var rr = _resolve(doc, inner)
        if doc.types[rr].kind != CT_ARRAY:
            base = String("Box[") + base + "]"
    if optional:
        return String("Optional[") + base + "]"
    return base


def _zero_expr(tn: String) -> String:
    if tn == "Bool":
        return String("False")
    if tn == "Int64":
        return String("Int64(0)")
    if tn == "UInt64":
        return String("UInt64(0)")
    if tn == "Float64":
        return String("0.0")
    if tn == "String":
        return String("String()")
    if tn == "List[Byte]":
        return String("List[Byte]()")
    if tn.byte_length() >= 9:
        # Optional[...] or List[...]
        return tn + "()"
    return tn + "()"


def _header() -> String:
    var out = String()
    out += "from std.collections import List, Optional, Span\n\n"
    out += "from cbor import (\n"
    out += "    Box,\n"
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
    return out


def _emit_write_value(indent: String, access: String, tn: String) -> String:
    var out = String()
    if tn == "Bool":
        out += indent + "w.write_bool(" + access + ")\n"
    elif tn == "Int64":
        out += indent + "w.write_int(" + access + ")\n"
    elif tn == "UInt64":
        out += indent + "w.write_uint(" + access + ")\n"
    elif tn == "Float64":
        out += indent + "w.write_float_preferred(" + access + ")\n"
    elif tn == "String":
        out += indent + "w.write_tstr(" + access + ")\n"
    elif tn == "List[Byte]":
        out += indent + "w.write_bstr(" + access + ")\n"
    elif tn == "List[Float64]":
        out += indent + "w.write_array_len(len(" + access + "))\n"
        out += indent + "for _i in range(len(" + access + ")):\n"
        out += indent + "    w.write_float_preferred(" + access + "[_i])\n"
    elif tn == "List[String]":
        out += indent + "w.write_array_len(len(" + access + "))\n"
        out += indent + "for _i in range(len(" + access + ")):\n"
        out += indent + "    w.write_tstr(" + access + "[_i])\n"
    elif tn == "List[Int64]":
        out += indent + "w.write_array_len(len(" + access + "))\n"
        out += indent + "for _i in range(len(" + access + ")):\n"
        out += indent + "    w.write_int(" + access + "[_i])\n"
    elif _starts(tn, "List["):
        out += indent + "w.write_array_len(len(" + access + "))\n"
        out += indent + "for _i in range(len(" + access + ")):\n"
        var inner = _cut(tn, 5, tn.byte_length() - 1)
        if _starts(inner, "Box["):
            out += indent + "    " + access + "[_i][].encode_to(w, options)\n"
        else:
            out += indent + "    " + access + "[_i].encode_to(w, options)\n"
    elif _starts(tn, "Box["):
        out += indent + access + "[].encode_to(w, options)\n"
    else:
        out += indent + access + ".encode_to(w, options)\n"
    return out


def _emit_read_value(
    indent: String, dest: String, tn: String, opt: Bool
) raises DecodeError -> String:
    var out = String()
    if tn == "Bool":
        if opt:
            out += indent + dest + " = Optional[Bool](tmp.nodes[vn].kind == CK_TRUE)\n"
        else:
            out += indent + dest + " = tmp.nodes[vn].kind == CK_TRUE\n"
    elif tn == "Int64":
        if opt:
            out += indent + dest + " = Optional[Int64](tmp.nodes[vn].a)\n"
        else:
            out += indent + dest + " = tmp.nodes[vn].a\n"
    elif tn == "UInt64":
        out += indent + "var uv = tmp.nodes[vn]\n"
        out += indent + "var uval = uv.b\n"
        out += indent + "if uv.kind == CK_INT:\n"
        out += indent + "    uval = UInt64(uv.a)\n"
        if opt:
            out += indent + dest + " = Optional[UInt64](uval)\n"
        else:
            out += indent + dest + " = uval\n"
    elif tn == "Float64":
        if opt:
            out += indent + dest + " = Optional[Float64](node_as_float(tmp, vn))\n"
        else:
            out += indent + dest + " = node_as_float(tmp, vn)\n"
    elif tn == "String":
        if opt:
            out += indent + dest + " = Optional[String](tmp.texts[Int(tmp.nodes[vn].a)])\n"
        else:
            out += indent + dest + " = tmp.texts[Int(tmp.nodes[vn].a)]\n"
    elif tn == "List[Byte]":
        out += indent + dest + " = List[Byte]()\n"
        out += indent + "var bn = tmp.nodes[vn]\n"
        out += indent + "if bn.kind == CK_BYTES:\n"
        out += indent + "    var b0 = Int(bn.a)\n"
        out += indent + "    for _j in range(Int(bn.b)):\n"
        out += indent + "        " + dest + ".append(tmp.bytes[b0 + _j])\n"
    elif tn == "List[Float64]":
        out += indent + dest + " = List[Float64]()\n"
        out += indent + "var an = tmp.nodes[vn]\n"
        out += indent + "if an.kind == CK_ARRAY:\n"
        out += indent + "    var a0 = Int(an.a)\n"
        out += indent + "    for _j in range(Int(an.b)):\n"
        out += indent + "        " + dest + ".append(node_as_float(tmp, tmp.kids[a0 + _j]))\n"
    elif tn == "List[String]":
        out += indent + dest + " = List[String]()\n"
        out += indent + "var an = tmp.nodes[vn]\n"
        out += indent + "if an.kind == CK_ARRAY:\n"
        out += indent + "    var a0 = Int(an.a)\n"
        out += indent + "    for _j in range(Int(an.b)):\n"
        out += (
            indent
            + "        "
            + dest
            + ".append(tmp.texts[Int(tmp.nodes[tmp.kids[a0 + _j]].a)])\n"
        )
    elif tn == "List[Int64]":
        out += indent + dest + " = List[Int64]()\n"
        out += indent + "var an = tmp.nodes[vn]\n"
        out += indent + "if an.kind == CK_ARRAY:\n"
        out += indent + "    var a0 = Int(an.a)\n"
        out += indent + "    for _j in range(Int(an.b)):\n"
        out += indent + "        " + dest + ".append(tmp.nodes[tmp.kids[a0 + _j]].a)\n"
    elif _starts(tn, "List["):
        var inner = _cut(tn, 5, tn.byte_length() - 1)
        out += indent + dest + " = " + tn + "()\n"
        out += indent + "var an = tmp.nodes[vn]\n"
        out += indent + "if an.kind == CK_ARRAY:\n"
        out += indent + "    var a0 = Int(an.a)\n"
        out += indent + "    for _j in range(Int(an.b)):\n"
        if _starts(inner, "Box["):
            var rec = _cut(inner, 4, inner.byte_length() - 1)
            out += indent + "        var _c = " + rec + "()\n"
            out += indent + "        _c._from_node(tmp, tmp.kids[a0 + _j])\n"
            out += indent + "        " + dest + ".append(Box(_c^))\n"
        else:
            out += indent + "        var _c = " + inner + "()\n"
            out += indent + "        _c._from_node(tmp, tmp.kids[a0 + _j])\n"
            out += indent + "        " + dest + ".append(_c^)\n"
    elif _starts(tn, "Box["):
        var rec2 = _cut(tn, 4, tn.byte_length() - 1)
        out += indent + "var _c = " + rec2 + "()\n"
        out += indent + "_c._from_node(tmp, vn)\n"
        if opt:
            out += indent + dest + " = Optional[" + tn + "](Box(_c^))\n"
        else:
            out += indent + dest + " = Box(_c^)\n"
    else:
        out += indent + "var _c = " + tn + "()\n"
        out += indent + "_c._from_node(tmp, vn)\n"
        if opt:
            out += indent + dest + " = Optional[" + tn + "](_c^)\n"
        else:
            out += indent + dest + " = _c^\n"
    return out


def emit_union(
    doc: CddlDoc, name: String, type_idx: Int, owner_def: Int
) raises DecodeError -> String:
    var br = List[Int]()
    _flatten_choice(doc, type_idx, br)
    var rec = 0
    var first_plain = -1
    for i in range(len(br)):
        if doc.types[br[i]].kind == CT_NULL:
            continue
        if _needs_box(doc, owner_def, br[i]):
            rec += 1
        elif first_plain < 0:
            first_plain = i
    if rec == len(br) and rec > 0:
        raise DecodeError(DecodeError.KIND_CDDL, 0)
    if first_plain < 0:
        first_plain = 0
    var uname = _mojo_ident(name)
    var out = _header()
    out += "struct " + uname + "(Copyable, Movable, Defaultable, Deinitable, CborDatum):\n"
    out += "    var tag: Int\n"
    var tns = List[String]()
    for i in range(len(br)):
        var tn = _prelude_name(doc, br[i])
        if _needs_box(doc, owner_def, br[i]):
            tn = String("Box[") + tn + "]"
        tns.append(tn)
        out += "    var v" + String(i) + ": " + tn + "\n"
    out += "\n    def __init__(out self):\n"
    out += "        self.tag = " + String(first_plain) + "\n"
    for i in range(len(br)):
        out += "        self.v" + String(i) + " = " + _zero_expr(tns[i]) + "\n"
    out += "\n    def encoded_len(self, options: EncodeOptions) -> Int:\n"
    out += "        var w = WireWriter()\n"
    out += "        self.encode_to(w, options)\n"
    out += "        var b = w^.finish()\n"
    out += "        return len(b)\n\n"
    out += "    def encode_to(self, mut w: WireWriter, options: EncodeOptions):\n"
    for i in range(len(br)):
        if i == 0:
            out += "        if self.tag == 0:\n"
        else:
            out += "        elif self.tag == " + String(i) + ":\n"
        out += _emit_write_value(String("            "), "self.v" + String(i), tns[i])
    out += "\n    def _from_node(mut self, tmp: CborValue, idx: Int) raises DecodeError:\n"
    out += "        var vn = idx\n"
    out += "        var node = tmp.nodes[idx]\n"
    for i in range(len(br)):
        var k = doc.types[br[i]].kind
        var cond = String("True")
        if k == CT_INT or k == CT_UINT:
            cond = String("node.kind == CK_INT or node.kind == CK_UINT")
        elif k == CT_TSTR:
            cond = String("node.kind == CK_TEXT")
        elif k == CT_BSTR:
            cond = String("node.kind == CK_BYTES")
        elif k == CT_BOOL:
            cond = String("node.kind == CK_TRUE or node.kind == CK_FALSE")
        elif k == CT_FLOAT:
            cond = String(
                "node.kind == CK_FLOAT16 or node.kind == CK_FLOAT32 or node.kind == CK_FLOAT64"
            )
        elif k == CT_STRUCT:
            cond = String("node.kind == CK_MAP")
        elif k == CT_ARRAY:
            cond = String("node.kind == CK_ARRAY")
        if i == 0:
            out += "        if " + cond + ":\n"
        else:
            out += "        elif " + cond + ":\n"
        out += "            self.tag = " + String(i) + "\n"
        out += _emit_read_value(String("            "), "self.v" + String(i), tns[i], False)
        out += "            return\n"
    out += "        raise DecodeError(DecodeError.KIND_TYPE, 0)\n\n"
    out += "    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:\n"
    out += "        var tmp = CborValue()\n"
    out += "        var root = decode_item(r, tmp)\n"
    out += "        self._from_node(tmp, root)\n"
    return out


def emit_struct(doc: CddlDoc, def_i: Int) raises DecodeError -> String:
    var name = _mojo_ident(doc.def_names[def_i])
    var ty = _resolve(doc, doc.def_types[def_i])
    var t = doc.types[ty]
    if t.kind != CT_STRUCT:
        raise DecodeError(DecodeError.KIND_CDDL, 0)
    var fields = List[String]()
    var types = List[String]()
    var opts = List[Bool]()
    var keys = List[String]()
    var inners = List[Int]()
    for m in range(t.members_count):
        var mem = doc.members[t.members_start + m]
        var opt = _is_optional_member(doc, mem.optional, mem.type_idx)
        var inner = _unwrap_optional(doc, mem.type_idx)
        if _needs_box(doc, def_i, inner) and not opt:
            var rr = _resolve(doc, inner)
            if doc.types[rr].kind != CT_ARRAY:
                raise DecodeError(DecodeError.KIND_CDDL, 0)
        var tn = _field_type_name(doc, def_i, mem.type_idx, opt, name, mem.name)
        fields.append(_mojo_ident(mem.name))
        types.append(tn)
        opts.append(opt)
        keys.append(mem.name)
        inners.append(inner)
    var out = _header()
    out += "struct " + name + "(Copyable, Movable, Defaultable, Deinitable, CborDatum):\n"
    for i in range(len(fields)):
        out += "    var " + fields[i] + ": " + types[i] + "\n"
    out += "\n    def __init__(out self):\n"
    for i in range(len(fields)):
        out += "        self." + fields[i] + " = " + _zero_expr(types[i]) + "\n"
    out += "\n    def __init__(out self"
    for i in range(len(fields)):
        out += ", var " + fields[i] + ": " + types[i]
    out += "):\n"
    for i in range(len(fields)):
        out += "        self." + fields[i] + " = " + fields[i] + "^\n"
    out += "\n    def encoded_len(self, options: EncodeOptions) -> Int:\n"
    out += "        var w = WireWriter()\n"
    out += "        self.encode_to(w, options)\n"
    out += "        var b = w^.finish()\n"
    out += "        return len(b)\n\n"
    out += "    def encode_to(self, mut w: WireWriter, options: EncodeOptions):\n"
    out += "        var n = 0\n"
    for i in range(len(fields)):
        if opts[i]:
            out += "        if self." + fields[i] + ":\n"
            out += "            n += 1\n"
        else:
            out += "        n += 1\n"
    out += "        w.write_map_len(n)\n"
    for i in range(len(fields)):
        var indent = String("        ")
        var access = "self." + fields[i]
        var write_tn = types[i]
        if opts[i]:
            out += "        if self." + fields[i] + ":\n"
            indent = String("            ")
            access = "self." + fields[i] + ".value()"
            # strip Optional[...]
            write_tn = _cut(types[i], 9, types[i].byte_length() - 1)
        out += indent + "w.write_tstr(\"" + keys[i] + "\")\n"
        out += _emit_write_value(indent, access, write_tn)
    out += "\n    def _from_node(mut self, tmp: CborValue, idx: Int) raises DecodeError:\n"
    out += "        var node = tmp.nodes[idx]\n"
    out += "        if node.kind != CK_MAP:\n"
    out += "            raise DecodeError(DecodeError.KIND_TYPE, 0)\n"
    out += "        var pairs = Int(node.b)\n"
    out += "        var k0 = Int(node.a)\n"
    out += "        for i in range(pairs):\n"
    out += "            var kn = tmp.nodes[tmp.kids[k0 + i * 2]]\n"
    out += "            if kn.kind != CK_TEXT:\n"
    out += "                continue\n"
    out += "            var key = tmp.texts[Int(kn.a)]\n"
    out += "            var vn = tmp.kids[k0 + i * 2 + 1]\n"
    for i in range(len(fields)):
        out += "            if key == \"" + keys[i] + "\":\n"
        var read_tn = types[i]
        var dest = "self." + fields[i]
        if opts[i]:
            read_tn = _cut(types[i], 9, types[i].byte_length() - 1)
        out += _emit_read_value(String("                "), dest, read_tn, opts[i])
    out += "\n    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:\n"
    out += "        var tmp = CborValue()\n"
    out += "        var root = decode_item(r, tmp)\n"
    out += "        self._from_node(tmp, root)\n"
    return out


def emit_all(doc: CddlDoc) raises DecodeError -> List[String]:
    var out = List[String]()
    for i in range(len(doc.def_names)):
        var ty = _resolve(doc, doc.def_types[i])
        if doc.types[ty].kind == CT_CHOICE and not _is_null_choice(doc, ty):
            out.append(_mojo_ident(doc.def_names[i]))
            out.append(emit_union(doc, doc.def_names[i], ty, i))
    for i in range(len(doc.def_names)):
        var ty2 = _resolve(doc, doc.def_types[i])
        if doc.types[ty2].kind != CT_STRUCT:
            continue
        var t = doc.types[ty2]
        var owner = _mojo_ident(doc.def_names[i])
        for m in range(t.members_count):
            var mem = doc.members[t.members_start + m]
            var inner = _unwrap_optional(doc, mem.type_idx)
            if doc.types[inner].kind != CT_NAMED and _is_multi_choice(doc, inner):
                var un = owner + "_" + _mojo_ident(mem.name)
                out.append(un)
                out.append(emit_union(doc, un, inner, i))
        out.append(owner)
        out.append(emit_struct(doc, i))
    return out^
