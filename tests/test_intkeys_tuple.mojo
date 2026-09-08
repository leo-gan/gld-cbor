from std.testing import TestSuite, assert_equal, assert_true

from Compact import Compact
from Row import Row
from cbor import encode, decode


def test_compact_int_keys_roundtrip() raises:
    var m = Compact()
    m.k0 = True
    m.k1 = Int64(150)
    m.k2 = String("hi")
    var buf = encode(m)
    assert_equal(Int(buf[0]), 0xA3)
    assert_equal(Int(buf[1]), 0x00)
    var m2 = decode[Compact](buf)
    assert_true(m2.k0)
    assert_equal(m2.k1, Int64(150))
    assert_equal(m2.k2, String("hi"))


def test_row_tuple_roundtrip() raises:
    var r = Row()
    r.f_bool = True
    r.f_int = Int64(7)
    r.f_text = String("x")
    var buf = encode(r)
    assert_equal(Int(buf[0]), 0x83)
    var r2 = decode[Row](buf)
    assert_true(r2.f_bool)
    assert_equal(r2.f_int, Int64(7))
    assert_equal(r2.f_text, String("x"))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
