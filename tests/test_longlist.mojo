from std.testing import TestSuite, assert_equal, assert_true

from cddl.model import CT_STRUCT
from cddl.parse import parse_cddl_file
from codegen.emit import emit_all


def test_longlist_schema_and_box() raises:
    var doc = parse_cddl_file("testdata/cddl/longlist.cddl")
    assert_equal(doc.def_names[0], "LongList")
    var ty = doc.types[doc.def_types[0]]
    assert_equal(ty.kind, CT_STRUCT)
    var files = emit_all(doc)
    var src = files[1]
    assert_true(src.find("Optional[Box[LongList]]") >= 0)
    # Mojo 1.0 rejects compiling a struct that names itself through Box[Self].
    # The emitted source is the codegen contract; a compiled round-trip waits
    # on the language.


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
