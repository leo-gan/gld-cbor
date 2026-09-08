from std.collections import List
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

from bytes_util import bytes_of
from cbor import (
    CK_ARRAY,
    CK_INT,
    CK_MAP,
    CK_TEXT,
    DecodeError,
    EncodeOptions,
    decode_strict,
    decode_value,
    encode_value,
)


def _hex_roundtrip(values: List[Int]) raises:
    var buf = List[Byte]()
    for i in range(len(values)):
        buf.append(Byte(values[i]))
    var v = decode_value(buf)
    var out = encode_value(v, EncodeOptions.identity)
    assert_equal(len(out), len(buf))
    for i in range(len(buf)):
        assert_equal(Int(out[i]), Int(buf[i]))


def test_uint_and_nint() raises:
    var v = decode_value(bytes_of(0x18, 0x18))
    assert_equal(v.nodes[v.root].kind, CK_INT)
    assert_equal(v.nodes[v.root].a, Int64(24))
    var v2 = decode_value(bytes_of(0x20))
    assert_equal(v2.nodes[v2.root].a, Int64(-1))


def test_text() raises:
    # "I" is 0x61 0x49
    var v = decode_value(bytes_of(0x61, 0x49))
    assert_equal(v.nodes[v.root].kind, CK_TEXT)
    assert_equal(v.texts[Int(v.nodes[v.root].a)], "I")


def test_array() raises:
    # [1, 2] = 0x82 0x01 0x02
    var v = decode_value(bytes_of(0x82, 0x01, 0x02))
    assert_equal(v.nodes[v.root].kind, CK_ARRAY)
    assert_equal(Int(v.nodes[v.root].b), 2)
    var out = encode_value(v)
    assert_equal(Int(out[0]), 0x82)
    assert_equal(Int(out[1]), 0x01)
    assert_equal(Int(out[2]), 0x02)


def test_indefinite_array_identity() raises:
    var buf = bytes_of(0x9F, 0x01, 0x02, 0xFF)
    var v = decode_value(buf)
    assert_true((v.nodes[v.root].flags & 1) != 0)
    var out = encode_value(v, EncodeOptions.identity)
    assert_equal(len(out), 4)
    assert_equal(Int(out[0]), 0x9F)
    var pref = encode_value(v, EncodeOptions.preferred)
    assert_equal(Int(pref[0]), 0x82)


def test_map_preferred_no_sort() raises:
    # {"z": 1, "aa": 2} in that insertion order
    # a1 61 7a 01 62 61 61 02  would be 1-pair... two pairs: a2
    var buf = bytes_of(
        0xA2,
        0x61, 0x7A, 0x01,
        0x62, 0x61, 0x61, 0x02,
    )
    var v = decode_value(buf)
    assert_equal(v.nodes[v.root].kind, CK_MAP)
    var pref = encode_value(v, EncodeOptions.preferred)
    assert_equal(Int(pref[0]), 0xA2)
    assert_equal(Int(pref[1]), 0x61)
    assert_equal(Int(pref[2]), 0x7A)
    var cde = encode_value(v, EncodeOptions.cde)
    # encoded "z" = 61 7a sorts before encoded "aa" = 62 61 61
    assert_equal(Int(cde[1]), 0x61)
    assert_equal(Int(cde[2]), 0x7A)


def test_trailing_rejected() raises:
    with assert_raises(contains="kind=10"):
        _ = decode_value(bytes_of(0x01, 0x02))


def test_empty_array() raises:
    var v = decode_value(bytes_of(0x80))
    assert_equal(Int(v.nodes[v.root].b), 0)


def test_half_one() raises:
    # RFC 8949 Appendix A: 1.0 = f9 3c 00
    var v = decode_value(bytes_of(0xF9, 0x3C, 0x00))
    var out = encode_value(v, EncodeOptions.identity)
    assert_equal(Int(out[0]), 0xF9)
    assert_equal(Int(out[1]), 0x3C)
    assert_equal(Int(out[2]), 0x00)
    var pref = encode_value(v, EncodeOptions.preferred)
    assert_equal(Int(pref[0]), 0xF9)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
