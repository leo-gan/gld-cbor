from std.testing import TestSuite, assert_equal, assert_true

from cddl.model import CT_STRUCT
from cddl.parse import parse_cddl


def test_parse_message() raises:
    var text = String(
        "Message = {\n  f_bool: bool,\n  f_int: int,\n  f_text: tstr,\n}\n"
    )
    var doc = parse_cddl(text)
    assert_equal(len(doc.def_names), 1)
    assert_equal(doc.def_names[0], "Message")
    var ty = doc.types[doc.def_types[0]]
    assert_equal(ty.kind, CT_STRUCT)
    assert_equal(ty.members_count, 3)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
