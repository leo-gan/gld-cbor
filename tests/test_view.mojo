from std.testing import TestSuite, assert_equal, assert_raises

from bytes_util import bytes_of
from cbor import DecodeError, WireReader, decode_tstr_span


def test_decode_tstr_span() raises:
    # "I" = 0x61 0x49
    var buf = bytes_of(0x61, 0x49)
    var sl = decode_tstr_span(buf)
    assert_equal(sl.byte_length(), 1)
    assert_equal(String(sl), "I")


def test_reader_text_span() raises:
    var buf = bytes_of(0x63, 0x61, 0x62, 0x63)
    var r = WireReader(buf)
    var sl = r.read_text_span()
    assert_equal(String(sl), "abc")
    assert_equal(r.remaining(), 0)


def test_indefinite_tstr_not_a_view() raises:
    var buf = bytes_of(0x7F, 0x61, 0x61, 0xFF)
    var r = WireReader(buf)
    with assert_raises(contains="kind=3"):
        _ = r.read_text_span()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
