from std.collections import List
from std.testing import TestSuite, assert_equal

from bytes_util import bytes_of
from cbor import decode_seq_values, decode_value, encode_seq_values, encode_value


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


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
