from std.testing import TestSuite, assert_equal, assert_true

from cbor import decode_diag, encode_diag, encode_diag_pretty, encode_value


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


def test_diag_pretty() raises:
    var v = decode_diag("[1, 2]")
    var p = encode_diag_pretty(v)
    assert_true(p.byte_length() > 3)
    var nl = 0
    var b = p.as_bytes()
    for i in range(len(b)):
        if Int(b[i]) == 10:
            nl += 1
    assert_true(nl >= 2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
