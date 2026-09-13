from std.testing import TestSuite, assert_equal

from bytes_util import bytes_of
from cbor import CK_ARRAY, CK_MAP, decode_value, encode_value
from runtime.options import EncodeOptions


def test_array_two() raises:
    var v = decode_value(bytes_of(0x82, 0x01, 0x02))
    assert_equal(v.nodes[v.root].kind, CK_ARRAY)
    assert_equal(Int(v.nodes[v.root].b), 2)
    var out = encode_value(v)
    assert_equal(Int(out[0]), 0x82)


def test_empty_map() raises:
    var v = decode_value(bytes_of(0xA0))
    assert_equal(v.nodes[v.root].kind, CK_MAP)
    assert_equal(Int(v.nodes[v.root].b), 0)


def test_deeply_nested_array() raises:
    # RFC 8949 official vector nests ~508 arrays. Depth cap must accept that.
    var buf = List[Byte]()
    var i = 0
    while i < 508:
        buf.append(Byte(0x81))
        i += 1
    buf.append(Byte(0x00))
    var v = decode_value(buf)
    assert_equal(v.nodes[v.root].kind, CK_ARRAY)


def test_one_pair_text_key() raises:
    var v = decode_value(bytes_of(0xA1, 0x61, 0x61, 0x01))
    assert_equal(v.nodes[v.root].kind, CK_MAP)
    var out = encode_value(v, EncodeOptions.preferred)
    assert_equal(Int(out[0]), 0xA1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
