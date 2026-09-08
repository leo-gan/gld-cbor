from std.collections import List

from cbor import CborValue, decode_diag, encode, encode_seq_values, encode_value
from Message import Message


def _hex(buf: List[Byte]) -> String:
    var digits = String("0123456789abcdef")
    var out = String()
    for i in range(len(buf)):
        var v = Int(buf[i])
        out += digits[byte = v >> 4]
        out += digits[byte = v & 15]
    return out


def main() raises:
    var m = Message()
    m.f_bool = True
    m.f_int = Int64(150)
    m.f_uint = UInt64(7)
    m.f_float = 1.5
    m.f_text = String("hi")
    print("MSG", _hex(encode(m)))
    var items = List[CborValue]()
    items.append(decode_diag("1"))
    items.append(decode_diag("2"))
    print("SEQ", _hex(encode_seq_values(items)))
    print("DIAG", _hex(encode_value(decode_diag("[1, 2, 3]"))))
