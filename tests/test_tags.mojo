from std.testing import TestSuite, assert_equal, assert_true

from bytes_util import bytes_of
from cbor import (
    BigFloat,
    DecimalFraction,
    EpochTime,
    decode_tag0,
    decode_tag1,
    decode_tag4,
    decode_tag5,
    decode_value,
    encode_tag0,
    encode_tag1,
    encode_tag4,
    encode_tag5,
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


def test_tag4_decimal() raises:
    # 27315 * 10^-2
    var buf = encode_tag4(DecimalFraction(Int64(-2), Int64(27315)))
    assert_equal(Int(buf[0]), 0xC4)
    var d = decode_tag4(decode_value(buf))
    assert_equal(d.exp, Int64(-2))
    assert_equal(d.mant, Int64(27315))


def test_tag5_bigfloat() raises:
    var buf = encode_tag5(BigFloat(Int64(2), Int64(3)))
    assert_equal(Int(buf[0]), 0xC5)
    var d = decode_tag5(decode_value(buf))
    assert_equal(d.exp, Int64(2))
    assert_equal(d.mant, Int64(3))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
