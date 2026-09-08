from std.testing import TestSuite, assert_equal, assert_true

from cddl.model import CT_GENERIC, CT_REGEXP, CT_SOCKET, CT_STRUCT
from cddl.parse import parse_cddl
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


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
