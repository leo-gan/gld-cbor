from std.testing import TestSuite, assert_equal, assert_true

from bytes_util import bytes_of
from cbor import (
    EpochTime,
    decode_tag0,
    decode_tag1,
    decode_value,
    encode_tag0,
    encode_tag1,
)


def test_tag1_epoch() raises:
    # 1(1363896240) = c1 1a 514b67b0
    var buf = encode_tag1(EpochTime(1363896240.0))
    assert_equal(Int(buf[0]), 0xC1)
    var v = decode_value(buf)
    var t = decode_tag1(v)
    assert_true(t.sec == 1363896240.0)


def test_tag0_datetime() raises:
    var buf = encode_tag0("2013-03-21T20:04:00Z")
    assert_equal(Int(buf[0]), 0xC0)
    var v = decode_value(buf)
    var s = decode_tag0(v)
    assert_equal(s, "2013-03-21T20:04:00Z")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
