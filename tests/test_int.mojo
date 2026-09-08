from std.testing import TestSuite, assert_equal

from bytes_util import bytes_of
from cbor import CK_INT, decode_value, encode_value
from runtime.options import EncodeOptions
from wire.head import shortest_ai
from wire.writer import WireWriter


def test_tiny_zero() raises:
    var v = decode_value(bytes_of(0x00))
    assert_equal(v.nodes[v.root].kind, CK_INT)
    assert_equal(v.nodes[v.root].a, Int64(0))


def test_twenty_four() raises:
    var v = decode_value(bytes_of(0x18, 0x18))
    assert_equal(v.nodes[v.root].a, Int64(24))


def test_neg_one() raises:
    var v = decode_value(bytes_of(0x20))
    assert_equal(v.nodes[v.root].a, Int64(-1))


def test_shortest_ai_preferred() raises:
    assert_equal(shortest_ai(UInt64(23)), 23)
    var enc = WireWriter()
    enc.write_int(Int64(24))
    var buf = enc^.finish()
    assert_equal(Int(buf[0]), 0x18)
    var out = encode_value(decode_value(buf), EncodeOptions.preferred)
    assert_equal(Int(out[0]), 0x18)


def test_overlong_still_well_formed() raises:
    var v = decode_value(bytes_of(0x18, 0x01))
    assert_equal(v.nodes[v.root].a, Int64(1))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
