from std.testing import TestSuite, assert_equal, assert_true

from bytes_util import bytes_of
from cbor import decode, encode
from manual_types import Message


def test_message_roundtrip() raises:
    var m = Message(True, Int64(150), UInt64(7), 1.5, String("hi"))
    var buf = encode(m)
    var m2 = decode[Message](buf)
    assert_true(m2.f_bool)
    assert_equal(m2.f_int, Int64(150))
    assert_equal(m2.f_uint, UInt64(7))
    assert_true(m2.f_float == 1.5)
    assert_equal(m2.f_text, String("hi"))


def test_manual_reads_cbor2_golden() raises:
    # Official cbor2 bytes for the Message map (float is binary64).
    var buf = bytes_of(
        0xA5,
        0x66, 0x66, 0x5F, 0x62, 0x6F, 0x6F, 0x6C, 0xF5,
        0x65, 0x66, 0x5F, 0x69, 0x6E, 0x74, 0x18, 0x96,
        0x66, 0x66, 0x5F, 0x75, 0x69, 0x6E, 0x74, 0x07,
        0x67, 0x66, 0x5F, 0x66, 0x6C, 0x6F, 0x61, 0x74,
        0xFB, 0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x66, 0x66, 0x5F, 0x74, 0x65, 0x78, 0x74, 0x62, 0x68, 0x69,
    )
    var m = decode[Message](buf)
    assert_true(m.f_bool)
    assert_equal(m.f_int, Int64(150))
    assert_equal(m.f_uint, UInt64(7))
    assert_true(m.f_float == 1.0)
    assert_equal(m.f_text, String("hi"))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
