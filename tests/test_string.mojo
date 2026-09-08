from std.testing import TestSuite, assert_equal, assert_raises

from bytes_util import bytes_of
from cbor import CK_TEXT, DecodeError, decode_value


def test_one_char() raises:
    var v = decode_value(bytes_of(0x61, 0x49))
    assert_equal(v.nodes[v.root].kind, CK_TEXT)
    assert_equal(v.texts[Int(v.nodes[v.root].a)], "I")


def test_empty_text() raises:
    var v = decode_value(bytes_of(0x60))
    assert_equal(v.nodes[v.root].kind, CK_TEXT)
    assert_equal(v.texts[Int(v.nodes[v.root].a)], "")


def test_bad_utf8() raises:
    with assert_raises(contains="kind=5"):
        _ = decode_value(bytes_of(0x61, 0xFF))  # kind=5 UTF-8


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
