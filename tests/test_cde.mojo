from std.testing import TestSuite, assert_equal, assert_raises

from bytes_util import bytes_of
from cbor import DecodeError, EncodeOptions, decode_strict, decode_value, encode_value


def test_cde_sorts_encoded_keys() raises:
    var buf = bytes_of(
        0xA2,
        0x61, 0x7A, 0x01,
        0x62, 0x61, 0x61, 0x02,
    )
    var v = decode_value(buf)
    var cde = encode_value(v, EncodeOptions.cde)
    assert_equal(Int(cde[1]), 0x61)
    assert_equal(Int(cde[2]), 0x7A)


def test_decode_strict_accepts_cde() raises:
    var buf = bytes_of(0x01)
    var v = decode_strict(buf)
    assert_equal(v.nodes[v.root].a, Int64(1))


def test_decode_strict_rejects_overlong() raises:
    with assert_raises(contains="kind=12"):
        _ = decode_strict(bytes_of(0x18, 0x01))


def test_cde_rejects_duplicate_keys() raises:
    var v = decode_value(bytes_of(0xA2, 0x61, 0x61, 0x01, 0x61, 0x61, 0x02))
    with assert_raises(contains="kind=11"):
        _ = encode_value(v, EncodeOptions.cde)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
