from std.testing import TestSuite, assert_equal

from cddl.parse import parse_cddl_file


def test_mutual_names() raises:
    var doc = parse_cddl_file("testdata/cddl/mutual_ab.cddl")
    var saw_a = 0
    var saw_b = 0
    for i in range(len(doc.def_names)):
        if doc.def_names[i] == "A":
            saw_a += 1
        if doc.def_names[i] == "B":
            saw_b += 1
    assert_equal(saw_a, 1)
    assert_equal(saw_b, 1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
