from std.collections import List
from std.testing import TestSuite, assert_equal, assert_raises

from bytes_util import bytes_of, hex_of
from runtime.error import DecodeError
from wire.head import read_head, shortest_ai, write_head
from wire.reader import WireReader
from wire.writer import WireWriter


def _round_uint(value: UInt64) raises:
    var enc = WireWriter()
    enc.write_uint(value)
    var buf = enc^.finish()
    var dec = WireReader(buf)
    var h = dec.read_head()
    assert_equal(h[0], 0)
    assert_equal(h[1], value)
    assert_equal(dec.remaining(), 0)


def test_tiny_and_extended_uints() raises:
    _round_uint(UInt64(0))
    _round_uint(UInt64(23))
    _round_uint(UInt64(24))
    _round_uint(UInt64(255))
    _round_uint(UInt64(256))
    _round_uint(UInt64(65535))
    _round_uint(UInt64(65536))


def test_rfc_appendix_a_integers() raises:
    # RFC 8949 Appendix A
    var enc = WireWriter()
    enc.write_int(Int64(0))
    var z = enc^.finish()
    assert_equal(Int(z[0]), 0x00)

    enc = WireWriter()
    enc.write_int(Int64(1))
    var one = enc^.finish()
    assert_equal(Int(one[0]), 0x01)

    enc = WireWriter()
    enc.write_int(Int64(10))
    var ten = enc^.finish()
    assert_equal(Int(ten[0]), 0x0A)

    enc = WireWriter()
    enc.write_int(Int64(23))
    var t23 = enc^.finish()
    assert_equal(Int(t23[0]), 0x17)

    enc = WireWriter()
    enc.write_int(Int64(24))
    var t24 = enc^.finish()
    assert_equal(len(t24), 2)
    assert_equal(Int(t24[0]), 0x18)
    assert_equal(Int(t24[1]), 0x18)

    enc = WireWriter()
    enc.write_int(Int64(-1))
    var n1 = enc^.finish()
    assert_equal(Int(n1[0]), 0x20)

    enc = WireWriter()
    enc.write_int(Int64(-10))
    var n10 = enc^.finish()
    assert_equal(Int(n10[0]), 0x29)

    enc = WireWriter()
    enc.write_int(Int64(-24))
    var n24 = enc^.finish()
    assert_equal(Int(n24[0]), 0x37)

    enc = WireWriter()
    enc.write_int(Int64(-25))
    var n25 = enc^.finish()
    assert_equal(Int(n25[0]), 0x38)
    assert_equal(Int(n25[1]), 0x18)


def test_shortest_ai() raises:
    assert_equal(shortest_ai(UInt64(23)), 23)
    assert_equal(shortest_ai(UInt64(24)), 24)
    assert_equal(shortest_ai(UInt64(255)), 24)
    assert_equal(shortest_ai(UInt64(256)), 25)


def test_overlong_uint_still_well_formed() raises:
    # AI 24 with value 1 is overlong but well-formed on read.
    var buf = bytes_of(0x18, 0x01)
    var dec = WireReader(buf)
    var h = dec.read_head()
    assert_equal(h[0], 0)
    assert_equal(h[1], UInt64(1))
    assert_equal(h[2], 24)


def test_reserved_ai() raises:
    var buf = bytes_of(0x1C)
    var dec = WireReader(buf)
    with assert_raises(contains="kind=2"):
        _ = dec.read_head()


def test_simple_f8_below_32_not_well_formed() raises:
    var buf = bytes_of(0xF8, 0x18)
    var dec = WireReader(buf)
    with assert_raises(contains="kind=16"):
        _ = dec.read_head()


def test_bool_and_null() raises:
    var enc = WireWriter()
    enc.write_false()
    enc.write_true()
    enc.write_null()
    enc.write_undefined()
    var buf = enc^.finish()
    assert_equal(Int(buf[0]), 0xF4)
    assert_equal(Int(buf[1]), 0xF5)
    assert_equal(Int(buf[2]), 0xF6)
    assert_equal(Int(buf[3]), 0xF7)


def test_truncated() raises:
    var buf = bytes_of(0x18)
    var dec = WireReader(buf)
    with assert_raises(contains="kind=1"):
        _ = dec.read_head()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
