from cbor import WireWriter


def main():
    var enc = WireWriter()
    enc.write_int(Int64(150))
    var buf = enc^.finish()
    print("bytes", len(buf))
