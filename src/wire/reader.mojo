from std.collections import List, Span

from runtime.error import DecodeError
from wire.head import (
    AI_INDEF,
    MAX_COUNT,
    MAX_DEPTH,
    MAX_ITEM_BYTES,
    read_head,
)
from wire.utf8 import string_from_utf8


struct WireReader[origin: ImmOrigin](Movable):
    var data: Span[Byte, Self.origin]
    var pos: Int
    var depth: Int
    var max_depth: Int

    def __init__(
        out self,
        data: Span[Byte, Self.origin],
        *,
        depth: Int = 0,
        max_depth: Int = MAX_DEPTH,
    ):
        self.data = data
        self.pos = 0
        self.depth = depth
        self.max_depth = max_depth

    def remaining(self) -> Int:
        return len(self.data) - self.pos

    def position(self) -> Int:
        return self.pos

    def read_head(mut self) raises DecodeError -> Tuple[Int, UInt64, Int]:
        return read_head(self.data, self.pos)

    def peek_break(self) -> Bool:
        if self.pos >= len(self.data):
            return False
        return Int(self.data[self.pos]) == 0xFF

    def read_break_or_item(mut self) raises DecodeError -> Bool:
        if self.pos >= len(self.data):
            raise DecodeError(DecodeError.KIND_EOF, self.pos)
        if Int(self.data[self.pos]) == 0xFF:
            self.pos += 1
            return True
        return False

    def enter(mut self) raises DecodeError:
        if self.depth >= self.max_depth:
            raise DecodeError(DecodeError.KIND_DEPTH, self.pos)
        self.depth += 1

    def leave(mut self):
        if self.depth > 0:
            self.depth -= 1

    def read_exact(mut self, n: Int) raises DecodeError -> List[Byte]:
        if n < 0 or n > MAX_ITEM_BYTES:
            raise DecodeError(DecodeError.KIND_RANGE, self.pos)
        if n > self.remaining():
            raise DecodeError(DecodeError.KIND_EOF, self.pos)
        var out = List[Byte](capacity=n)
        for i in range(n):
            out.append(self.data[self.pos + i])
        self.pos += n
        return out^

    def read_text_exact(mut self, n: Int) raises DecodeError -> String:
        var at = self.pos
        if n < 0 or n > MAX_ITEM_BYTES:
            raise DecodeError(DecodeError.KIND_RANGE, at)
        if n > self.remaining():
            raise DecodeError(DecodeError.KIND_EOF, at)
        var start = self.pos
        self.pos += n
        return string_from_utf8(self.data[start : start + n], at)

    def check_count(self, n: UInt64) raises DecodeError:
        if n > UInt64(MAX_COUNT):
            raise DecodeError(DecodeError.KIND_RANGE, self.pos)

    def require_definite_len(self, major: Int, ai: Int) raises DecodeError:
        if ai == AI_INDEF:
            if major != 2 and major != 3 and major != 4 and major != 5:
                raise DecodeError(DecodeError.KIND_INDEF, self.pos)
