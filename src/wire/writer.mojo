from std.collections import List, Span

from wire.head import write_break, write_head, write_head_raw
from wire.half import f32_to_bits, f64_to_bits, f64_to_half_bits, half_to_f64


struct WireWriter(Movable):
    """Appends CBOR bytes into one `List[Byte]`."""

    var buf: List[Byte]

    def __init__(out self, *, capacity: Int = 64):
        self.buf = List[Byte](capacity=capacity)

    def write_byte(mut self, b: Byte):
        self.buf.append(b)

    def write_head(mut self, major: Int, argument: UInt64):
        write_head(self.buf, major, argument)

    def write_head_raw(mut self, major: Int, ai: Int, argument: UInt64):
        write_head_raw(self.buf, major, ai, argument)

    def write_break(mut self):
        write_break(self.buf)

    def write_uint(mut self, v: UInt64):
        self.write_head(0, v)

    def write_nint_arg(mut self, n: UInt64):
        # major 1, argument n means value -1-n
        self.write_head(1, n)

    def write_int(mut self, v: Int64):
        if v >= Int64(0):
            self.write_uint(UInt64(v))
            return
        var mag = UInt64(-(v + Int64(1)))
        self.write_nint_arg(mag)

    def write_bstr[origin: ImmOrigin](mut self, data: Span[Byte, origin]):
        self.write_head(2, UInt64(len(data)))
        for i in range(len(data)):
            self.write_byte(data[i])

    def write_tstr(mut self, v: String):
        var b = v.as_bytes()
        self.write_head(3, UInt64(len(b)))
        for i in range(len(b)):
            self.write_byte(b[i])

    def write_array_len(mut self, n: Int):
        self.write_head(4, UInt64(n))

    def write_map_len(mut self, n: Int):
        self.write_head(5, UInt64(n))

    def write_tag(mut self, number: UInt64):
        self.write_head(6, number)

    def write_simple(mut self, n: Int):
        if n < 24:
            self.write_head(7, UInt64(n))
            return
        self.write_head(7, UInt64(n))

    def write_false(mut self):
        self.write_head(7, UInt64(20))

    def write_true(mut self):
        self.write_head(7, UInt64(21))

    def write_null(mut self):
        self.write_head(7, UInt64(22))

    def write_undefined(mut self):
        self.write_head(7, UInt64(23))

    def write_bool(mut self, v: Bool):
        if v:
            self.write_true()
        else:
            self.write_false()

    def write_float16_bits(mut self, bits: UInt16):
        self.write_head_raw(7, 25, UInt64(bits))

    def write_float32_bits(mut self, bits: UInt32):
        self.write_head_raw(7, 26, UInt64(bits))

    def write_float64_bits(mut self, bits: UInt64):
        self.write_head_raw(7, 27, bits)

    def write_float_preferred(mut self, v: Float64):
        var bits = f64_to_bits(v)
        var exp = Int((bits >> UInt64(52)) & UInt64(0x7FF))
        var frac = bits & ((UInt64(1) << UInt64(52)) - UInt64(1))
        if exp == 0x7FF and frac != UInt64(0):
            # zero-payload NaN → f97e00; otherwise keep shortest that holds payload
            if (frac << UInt64(12)) == UInt64(0):
                self.write_float16_bits(UInt16(0x7E00))
                return
        var h = f64_to_half_bits(v)
        var back = half_to_f64(h)
        if f64_to_bits(back) == bits or (exp == 0x7FF and frac == UInt64(0)):
            # infinities and exact half values
            if exp == 0x7FF and frac == UInt64(0):
                if (bits >> UInt64(63)) == UInt64(1):
                    self.write_float16_bits(UInt16(0xFC00))
                else:
                    self.write_float16_bits(UInt16(0x7C00))
                return
            if f64_to_bits(back) == bits:
                self.write_float16_bits(h)
                return
        var f32 = Float32(v)
        if f64_to_bits(Float64(f32)) == bits:
            self.write_float32_bits(f32_to_bits(f32))
            return
        self.write_float64_bits(bits)

    def finish(deinit self) -> List[Byte]:
        return self.buf^
