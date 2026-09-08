from std.collections import List, Span

from runtime.error import DecodeError
from runtime.options import EncodeOptions
from wire.reader import WireReader
from wire.writer import WireWriter


trait CborDatum(Copyable, Movable, Defaultable, Deinitable):
    def encoded_len(self, options: EncodeOptions) -> Int:
        ...

    def encode_to(self, mut w: WireWriter, options: EncodeOptions):
        ...

    def decode_from[
        origin: ImmOrigin
    ](mut self, mut r: WireReader[origin]) raises DecodeError:
        ...


def encode[
    T: CborDatum
](value: T, options: EncodeOptions = EncodeOptions.preferred) -> List[Byte]:
    var cap = value.encoded_len(options)
    if cap < 1:
        cap = 1
    var w = WireWriter(capacity=cap)
    value.encode_to(w, options)
    return w^.finish()


def decode[
    T: CborDatum, origin: ImmOrigin
](buf: Span[Byte, origin]) raises DecodeError -> T:
    var msg = T()
    var r = WireReader[origin](buf)
    msg.decode_from(r)
    if r.remaining() > 0:
        raise DecodeError(DecodeError.KIND_TRAILING, r.position())
    return msg^
