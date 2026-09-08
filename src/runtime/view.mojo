from std.collections import Span

from runtime.error import DecodeError
from wire.reader import WireReader


def decode_tstr_span[
    origin: ImmOrigin
](buf: Span[Byte, origin]) raises DecodeError -> StringSpan[origin]:
    """Decode one definite text string as a view into `buf`. Trailing bytes are an error."""
    var r = WireReader(buf)
    var sl = r.read_text_span()
    if r.remaining() > 0:
        raise DecodeError(DecodeError.KIND_TRAILING, r.position())
    return sl
