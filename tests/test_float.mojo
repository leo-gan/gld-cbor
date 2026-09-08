from std.testing import TestSuite, assert_equal

from bytes_util import bytes_of
from cbor import CK_FLOAT16, decode_value, encode_value
from runtime.options import EncodeOptions


def test_half_one() raises:
    var v = decode_value(bytes_of(0xF9, 0x3C, 0x00))
    assert_equal(v.nodes[v.root].kind, CK_FLOAT16)
    var ident = encode_value(v, EncodeOptions.identity)
    assert_equal(Int(ident[0]), 0xF9)
    assert_equal(Int(ident[1]), 0x3C)


def test_half_neg_zero() raises:
    var v = decode_value(bytes_of(0xF9, 0x80, 0x00))
    var ident = encode_value(v, EncodeOptions.identity)
    assert_equal(Int(ident[1]), 0x80)


def test_half_inf() raises:
    var v = decode_value(bytes_of(0xF9, 0x7C, 0x00))
    var ident = encode_value(v, EncodeOptions.identity)
    assert_equal(Int(ident[1]), 0x7C)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
