from std.testing import TestSuite, assert_equal, assert_true

from cbor import decode, encode
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
    var m2 = decode[Message](buf)
    assert_equal(m2.f_bool, True)
    assert_equal(m2.f_int, Int64(150))
    assert_equal(m2.f_uint, UInt64(7))
    assert_true(m2.f_float == 1.0)
    assert_equal(m2.f_text, "hi")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
