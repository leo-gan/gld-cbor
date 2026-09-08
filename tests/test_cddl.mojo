from std.testing import TestSuite, assert_equal, assert_true

from cddl.model import (
    CT_CONTROL,
    CT_GENERIC,
    CT_REGEXP,
    CT_SOCKET,
    CT_STRUCT,
    CT_UNWRAP,
)
from cddl.parse import parse_cddl, parse_cddl_file
from cddl.regexp import regexp_fullmatch


def test_parse_message() raises:
    var text = String(
        "Message = {\n  f_bool: bool,\n  f_int: int,\n  f_text: tstr,\n}\n"
    )
    var doc = parse_cddl(text)
    assert_equal(len(doc.def_names), 1)
    assert_equal(doc.def_names[0], "Message")
    var ty = doc.types[doc.def_types[0]]
    assert_equal(ty.kind, CT_STRUCT)
    assert_equal(ty.members_count, 3)


def test_socket_plugs() raises:
    var text = String("$t = int\n$t /= tstr\n")
    var doc = parse_cddl(text)
    assert_equal(len(doc.socket_names), 1)
    assert_equal(doc.socket_names[0], "t")
    assert_equal(doc.socket_count[0], 2)
    var ty = doc.types[doc.def_types[0]]
    assert_equal(ty.kind, CT_SOCKET)


def test_generic_app() raises:
    var text = String("pair = map<int, tstr>\n")
    var doc = parse_cddl(text)
    var ty = doc.types[doc.def_types[0]]
    assert_equal(ty.kind, CT_GENERIC)
    assert_equal(ty.name, "map")
    assert_equal(ty.members_count, 2)


def test_regexp_control() raises:
    var text = String("id = tstr .regexp \"[A-Z][0-9]+\"\n")
    var doc = parse_cddl(text)
    var ty = doc.types[doc.def_types[0]]
    assert_equal(ty.kind, CT_REGEXP)
    assert_true(regexp_fullmatch(ty.name, "A12"))
    assert_equal(regexp_fullmatch(ty.name, "12"), False)


def test_regexp_star() raises:
    assert_true(regexp_fullmatch("a*b", "aaab"))
    assert_true(regexp_fullmatch("a*b", "b"))
    assert_equal(regexp_fullmatch("a*b", "c"), False)


def test_unwrap() raises:
    var text = String("G = ( a: int )\nM = { ~G, b: tstr }\n")
    var doc = parse_cddl(text)
    var m = doc.types[doc.def_types[1]]
    assert_equal(m.kind, CT_STRUCT)
    var first = doc.types[doc.members[m.members_start].type_idx]
    assert_equal(first.kind, CT_UNWRAP)


def test_controls_parse() raises:
    var text = String(
        "f = uint .bits flags\n"
        + "g = uint .ibits flags\n"
        + "h = int .and uint\n"
        + "i = int .within number\n"
        + "j = bstr .andcbor Message\n"
    )
    var doc = parse_cddl(text)
    assert_equal(len(doc.def_names), 5)
    for k in range(5):
        assert_equal(doc.types[doc.def_types[k]].kind, CT_CONTROL)


def test_regexp_backref_and_lookaround() raises:
    assert_true(regexp_fullmatch("(a+)-\\1", "aa-aa"))
    assert_equal(regexp_fullmatch("(a+)-\\1", "aa-a"), False)
    assert_true(regexp_fullmatch("a(?=b)b", "ab"))
    assert_true(regexp_fullmatch("a(?!c)b", "ab"))
    assert_true(regexp_fullmatch("a(?<=a)b", "ab"))
    assert_true(regexp_fullmatch("a{2,3}", "aaa"))
    assert_equal(regexp_fullmatch("a{2,3}", "a"), False)
    assert_true(regexp_fullmatch("\\d\\D", "1x"))
    assert_true(regexp_fullmatch("\\ba\\b", "a"))


def test_include_nested() raises:
    var doc = parse_cddl_file("testdata/cddl/nested_parent.cddl")
    var names = 0
    for i in range(len(doc.def_names)):
        if doc.def_names[i] == "Leaf":
            names += 1
        if doc.def_names[i] == "Mid":
            names += 1
        if doc.def_names[i] == "NestedHolder":
            names += 1
    assert_equal(names, 3)


def test_import_export_catalog() raises:
    var doc = parse_cddl_file("testdata/cddl/import_parent.cddl")
    var leaf = 0
    var holder = 0
    for i in range(len(doc.def_names)):
        if doc.def_names[i] == "Leaf":
            leaf += 1
        if doc.def_names[i] == "Holder":
            holder += 1
    assert_equal(leaf, 1)
    assert_equal(holder, 1)


def test_include_one_file() raises:
    var doc = parse_cddl_file("testdata/cddl/include_parent.cddl")
    var names = 0
    for i in range(len(doc.def_names)):
        if doc.def_names[i] == "Leaf":
            names += 1
        if doc.def_names[i] == "Holder":
            names += 1
    assert_equal(names, 2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
