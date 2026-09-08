from std.testing import TestSuite, assert_equal, assert_true

from bytes_util import bytes_of
from cbor import decode_value, encode_value
from runtime.options import EncodeOptions


def test_indefinite_array_identity() raises:
    var buf = bytes_of(0x9F, 0x01, 0x02, 0xFF)
    var v = decode_value(buf)
    assert_true((v.nodes[v.root].flags & 1) != 0)
    var out = encode_value(v, EncodeOptions.identity)
    assert_equal(len(out), 4)
    assert_equal(Int(out[0]), 0x9F)
    var pref = encode_value(v, EncodeOptions.preferred)
    assert_equal(Int(pref[0]), 0x82)


def test_indefinite_text_chunks() raises:
    # (_ "a", "b") = 7f 61 61 61 62 ff
    var v = decode_value(bytes_of(0x7F, 0x61, 0x61, 0x61, 0x62, 0xFF))
    var pref = encode_value(v, EncodeOptions.preferred)
    assert_equal(Int(pref[0]), 0x62)
    assert_equal(Int(pref[1]), 0x61)
    assert_equal(Int(pref[2]), 0x62)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
