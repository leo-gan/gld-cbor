from std.testing import TestSuite, assert_true

from cddl.model import CddlDoc
from cddl.parse import parse_cddl, parse_cddl_file
from codegen.emit import emit_all


def _bodies(doc: CddlDoc) raises -> String:
    var files = emit_all(doc)
    var all = String()
    var i = 0
    while i + 1 < len(files):
        all += files[i + 1]
        i += 2
    return all


def test_longlist_emits_box() raises:
    var doc = parse_cddl_file("testdata/cddl/longlist.cddl")
    var src = _bodies(doc)
    assert_true(src.find("Optional[Box[LongList]]") >= 0)
    assert_true(
        src.find(
            "def __init__(out self, var value: Int64, var next: Optional[Box[LongList]])"
        )
        >= 0
    )


def test_mutual_ab_emits_box() raises:
    var doc = parse_cddl_file("testdata/cddl/mutual_ab.cddl")
    var src = _bodies(doc)
    assert_true(src.find("Optional[Box[B]]") >= 0)
    assert_true(src.find("Optional[Box[A]]") >= 0)


def test_keywords_renamed() raises:
    var doc = parse_cddl_file("testdata/cddl/keywords.cddl")
    var src = _bodies(doc)
    assert_true(src.find("struct struct_") >= 0)
    assert_true(src.find("var fn_: Int64") >= 0)
    assert_true(src.find("var var_: String") >= 0)


def test_union_emits_tag() raises:
    var doc = parse_cddl_file("testdata/cddl/union.cddl")
    var src = _bodies(doc)
    assert_true(src.find("struct Alt") >= 0)
    assert_true(src.find("var tag: Int") >= 0)
    assert_true(src.find("var x: Alt") >= 0)


def test_hot_path_does_not_reencode_or_arena() raises:
    var doc = parse_cddl_file("testdata/cddl/benchmark_v2.cddl")
    var src = _bodies(doc)
    assert_true(src.find("encoded_head_len") >= 0)
    assert_true(src.find("take_definite_tstr") >= 0)
    assert_true(src.find("self.encode_to(w, options)") < 0)
    assert_true(src.find("var tmp = CborValue()") < 0)
    assert_true(src.find("w.write_map_len(5)") >= 0)
    assert_true(src.find("w.write_bytes(String(") >= 0)
    assert_true(src.find("if options.is_cde():") >= 0)
    assert_true(src.find("if _kn == ") >= 0)
    assert_true(src.find("var _expect = 0") >= 0)


def test_int_keys_emit_write_int() raises:
    var doc = parse_cddl_file("testdata/cddl/intkeys.cddl")
    var src = _bodies(doc)
    assert_true(src.find("var k0: Bool") >= 0)
    assert_true(src.find("w.write_int(Int64(0))") >= 0)
    assert_true(src.find("take_int_key") >= 0)
    assert_true(src.find("w.write_tstr(\"k0\")") < 0)


def test_tuple_emits_array() raises:
    var doc = parse_cddl_file("testdata/cddl/tuple.cddl")
    var src = _bodies(doc)
    assert_true(src.find("w.write_array_len(3)") >= 0)
    assert_true(src.find("read_array_len") >= 0)
    assert_true(src.find("w.write_map_len") < 0)


def test_non_optional_recursive_rejected() raises:
    var doc = parse_cddl(String("Loop = { inner: Loop }\n"))
    var threw = False
    try:
        _ = emit_all(doc)
    except _:
        threw = True
    assert_true(threw)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
