from std.collections import List
from std.testing import TestSuite, assert_equal

from bytes_util import bytes_of
from cbor import (
    SeqDecoder,
    decode_seq_values,
    decode_value,
    encode_seq_values,
    encode_value,
)


def test_empty_sequence() raises:
    var empty = List[Byte]()
    var items = decode_seq_values(empty)
    assert_equal(len(items), 0)


def test_two_item_sequence() raises:
    var buf = bytes_of(0x01, 0x02)
    var items = decode_seq_values(buf)
    assert_equal(len(items), 2)
    var a = encode_value(items[0])
    var b = encode_value(items[1])
    assert_equal(Int(a[0]), 0x01)
    assert_equal(Int(b[0]), 0x02)
    var again = encode_seq_values(items)
    assert_equal(len(again), 2)


def test_pull_decoder_skip() raises:
    var buf = bytes_of(0x01, 0x82, 0x02, 0x03, 0x04)
    var dec = SeqDecoder(buf)
    assert_equal(dec.has_more(), True)
    dec.skip()
    var v = dec.next_value()
    var again = encode_value(v)
    assert_equal(Int(again[0]), 0x82)
    var last = dec.next_value()
    var lastb = encode_value(last)
    assert_equal(Int(lastb[0]), 0x04)
    assert_equal(dec.has_more(), False)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
