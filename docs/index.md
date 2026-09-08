# mojo-cbor

mojo-cbor is a [CBOR](https://en.wikipedia.org/wiki/CBOR) serializer written in
[Mojo](https://www.modular.com/mojo). The runtime and the code generator are
Mojo. They do not wrap libcbor or any other C, C++, or Rust CBOR library.

<div class="grid cards" markdown="1">

-   __Why CBOR__

    ---

    What CBOR is, how the head byte and major types work, and how preferred
    encoding, CDE, sequences, tags, and diagnostic notation fit together.

    [:octicons-arrow-right-24: Read Why CBOR](why-cbor.md)

-   __Instructions__

    ---

    Install Mojo 1.0.0 with pixi, write a CDDL schema, generate Mojo, run the
    tests, and publish this site.

    [:octicons-arrow-right-24: Open Instructions](instructions.md)

-   __Examples__

    ---

    Encode and decode generated types, `CborValue`, sequences, diagnostic
    notation, and CDE.

    [:octicons-arrow-right-24: See Examples](examples.md)

-   __Test data__

    ---

    What lives under `testdata/` (CDDL, oracle bytes, diagnostic samples) and
    why each file is there.

    [:octicons-arrow-right-24: Read Test data](test-data.md)

</div>
