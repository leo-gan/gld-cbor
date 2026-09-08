from std.testing import TestSuite, assert_true

from cbor import DecodeError, WireReader, WireWriter


def test_facade_imports() raises:
    var _k = DecodeError.KIND_EOF
    assert_true(_k == 1)
    var enc = WireWriter()
    enc.write_bool(True)
    var buf = enc^.finish()
    var dec = WireReader(buf)
    var head = dec.read_head()
    assert_true(head[0] == 7)
    assert_true(head[1] == UInt64(21))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
