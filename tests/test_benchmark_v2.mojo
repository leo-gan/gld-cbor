from std.testing import TestSuite, assert_equal, assert_true

from cbor import EncodeOptions, decode, encode
from Message import Message


def test_message_roundtrip() raises:
    var m = Message()
    m.f_bool = True
    m.f_int = Int64(150)
    m.f_uint = UInt64(7)
    m.f_float = 1.0
    m.f_text = String("hi")
    var buf = encode(m)
    assert_true(len(buf) > 0)
    assert_equal(m.encoded_len(EncodeOptions.preferred), len(buf))
    var m2 = decode[Message](buf)
    assert_equal(m2.f_bool, True)
    assert_equal(m2.f_int, Int64(150))
    assert_equal(m2.f_uint, UInt64(7))
    assert_true(m2.f_float == 1.0)
    assert_equal(m2.f_text, "hi")


def test_message_cde_key_order() raises:
    var m = Message()
    m.f_bool = True
    m.f_int = Int64(150)
    m.f_uint = UInt64(7)
    m.f_float = 1.0
    m.f_text = String("hi")
    var pref = encode(m)
    var cde = encode(m, EncodeOptions.cde)
    assert_equal(m.encoded_len(EncodeOptions.cde), len(cde))
    assert_equal(len(pref), len(cde))
    assert_equal(Int(pref[1]), 0x66)
    assert_equal(Int(cde[1]), 0x65)
    var m2 = decode[Message](cde)
    assert_equal(m2.f_bool, True)
    assert_equal(m2.f_int, Int64(150))
    assert_equal(m2.f_uint, UInt64(7))
    assert_true(m2.f_float == 1.0)
    assert_equal(m2.f_text, "hi")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
