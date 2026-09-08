from std.testing import TestSuite, assert_equal, assert_true

from cbor import decode_diag, encode_diag, encode_value


def test_diag_int_and_array() raises:
    var v = decode_diag("[1, 2, 3]")
    var d = encode_diag(v)
    assert_true(d.byte_length() > 0)
    var buf = encode_value(v)
    assert_equal(Int(buf[0]), 0x83)


def test_diag_map_and_text() raises:
    var v = decode_diag("{\"a\": 1}")
    var buf = encode_value(v)
    assert_equal(Int(buf[0]), 0xA1)


def test_diag_tag() raises:
    var v = decode_diag("1(1363896240)")
    var buf = encode_value(v)
    assert_equal(Int(buf[0]), 0xC1)


def test_diag_bools() raises:
    var v = decode_diag("true")
    var buf = encode_value(v)
    assert_equal(Int(buf[0]), 0xF5)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
