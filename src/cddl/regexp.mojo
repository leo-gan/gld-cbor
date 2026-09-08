from std.collections import List, Span

from runtime.error import DecodeError


struct _Re(Movable):
    var pat: List[Byte]
    var text: List[Byte]

    def __init__(out self, var pat: List[Byte], var text: List[Byte]):
        self.pat = pat^
        self.text = text^

    def _at(self, i: Int) -> Int:
        if i >= len(self.pat):
            return -1
        return Int(self.pat[i])

    def _txt(self, i: Int) -> Int:
        if i >= len(self.text):
            return -1
        return Int(self.text[i])


def _is_word(c: Int) -> Bool:
    if c >= 48 and c <= 57:
        return True
    if c >= 65 and c <= 90:
        return True
    if c >= 97 and c <= 122:
        return True
    return c == 95


def _is_space(c: Int) -> Bool:
    return c == 32 or c == 9 or c == 10 or c == 13


def _hex(c: Int) -> Int:
    if c >= 48 and c <= 57:
        return c - 48
    if c >= 97 and c <= 102:
        return c - 87
    if c >= 65 and c <= 70:
        return c - 55
    return -1


def _escape(re: _Re, pp: Int) raises DecodeError -> Tuple[Int, Int]:
    # returns (char_or_class, new_pp). class codes: -2=\d -3=\w -4=\s -5=not used
    if pp >= len(re.pat):
        raise DecodeError(DecodeError.KIND_CDDL, pp)
    var e = re._at(pp)
    if e == 100:  # d
        return (-2, pp + 1)
    if e == 119:  # w
        return (-3, pp + 1)
    if e == 115:  # s
        return (-4, pp + 1)
    if e == 110:  # n
        return (10, pp + 1)
    if e == 116:  # t
        return (9, pp + 1)
    if e == 114:  # r
        return (13, pp + 1)
    return (e, pp + 1)


def _class_match(re: _Re, pp: Int, ch: Int) raises DecodeError -> Tuple[Bool, Int]:
    # pp points just after '['
    var p = pp
    var neg = False
    if re._at(p) == 94:
        neg = True
        p += 1
    var ok = False
    if re._at(p) == -1:
        raise DecodeError(DecodeError.KIND_CDDL, p)
    while re._at(p) != 93 and re._at(p) != -1:
        var a: Int
        if re._at(p) == 92:
            var es = _escape(re, p + 1)
            a = es[0]
            p = es[1]
            if a == -2:
                if ch >= 48 and ch <= 57:
                    ok = True
                continue
            if a == -3:
                if _is_word(ch):
                    ok = True
                continue
            if a == -4:
                if _is_space(ch):
                    ok = True
                continue
        else:
            a = re._at(p)
            p += 1
        if re._at(p) == 45 and re._at(p + 1) != 93 and re._at(p + 1) != -1:
            p += 1
            var b = re._at(p)
            if b == 92:
                var es2 = _escape(re, p + 1)
                b = es2[0]
                p = es2[1]
            else:
                p += 1
            if ch >= a and ch <= b:
                ok = True
        else:
            if ch == a:
                ok = True
    if re._at(p) != 93:
        raise DecodeError(DecodeError.KIND_CDDL, p)
    if neg:
        ok = not ok
    return (ok, p + 1)


def _match_atom(re: _Re, pp: Int, tp: Int) raises DecodeError -> Tuple[Bool, Int, Int]:
    var c = re._at(pp)
    if c == -1:
        return (True, pp, tp)
    if c == 94:  # ^
        return (tp == 0, pp + 1, tp)
    if c == 36:  # $
        return (tp == len(re.text), pp + 1, tp)
    if c == 46:  # .
        if tp >= len(re.text):
            return (False, pp, tp)
        return (True, pp + 1, tp + 1)
    if c == 92:
        var es = _escape(re, pp + 1)
        var code = es[0]
        var np = es[1]
        if tp >= len(re.text):
            return (False, pp, tp)
        var ch = re._txt(tp)
        var ok = False
        if code == -2:
            ok = ch >= 48 and ch <= 57
        elif code == -3:
            ok = _is_word(ch)
        elif code == -4:
            ok = _is_space(ch)
        else:
            ok = ch == code
        if not ok:
            return (False, pp, tp)
        return (True, np, tp + 1)
    if c == 91:
        if tp >= len(re.text):
            return (False, pp, tp)
        var cm = _class_match(re, pp + 1, re._txt(tp))
        if not cm[0]:
            return (False, pp, tp)
        return (True, cm[1], tp + 1)
    if c == 40:
        var inner = _match_expr(re, pp + 1, tp)
        if not inner[0]:
            return (False, pp, tp)
        if re._at(inner[1]) != 41:
            raise DecodeError(DecodeError.KIND_CDDL, inner[1])
        return (True, inner[1] + 1, inner[2])
    if tp >= len(re.text) or re._txt(tp) != c:
        return (False, pp, tp)
    return (True, pp + 1, tp + 1)


def _quant(re: _Re, pp: Int) -> Tuple[Int, Int, Int]:
    # returns (min, max, new_pp) max -1 = inf
    var c = re._at(pp)
    if c == 42:
        return (0, -1, pp + 1)
    if c == 43:
        return (1, -1, pp + 1)
    if c == 63:
        return (0, 1, pp + 1)
    return (1, 1, pp)


def _factor_ends(re: _Re, pp: Int, tp: Int) raises DecodeError -> Tuple[Int, List[Int]]:
    """Return (pattern_after_factor, text positions after 0..n greedy matches)."""
    var atom_end = _atom_end(re, pp)
    var q = _quant(re, atom_end)
    var mn = q[0]
    var mx = q[1]
    var after = q[2]
    var pos = List[Int]()
    var cur = tp
    var count = 0
    if mn == 0:
        pos.append(cur)
    while mx < 0 or count < mx:
        var one = _match_atom(re, pp, cur)
        if not one[0]:
            break
        if one[2] == cur:
            break
        cur = one[2]
        count += 1
        if count >= mn:
            pos.append(cur)
    return (after, pos^)


def _atom_end(re: _Re, pp: Int) raises DecodeError -> Int:
    var c = re._at(pp)
    if c == 92:
        return _escape(re, pp + 1)[1]
    if c == 91:
        var i = pp + 1
        if re._at(i) == 94:
            i += 1
        while re._at(i) != 93 and re._at(i) != -1:
            if re._at(i) == 92:
                i = _escape(re, i + 1)[1]
            else:
                i += 1
        if re._at(i) != 93:
            raise DecodeError(DecodeError.KIND_CDDL, i)
        return i + 1
    if c == 40:
        var inner = _skip_expr(re, pp + 1)
        if re._at(inner) != 41:
            raise DecodeError(DecodeError.KIND_CDDL, inner)
        return inner + 1
    return pp + 1


def _skip_expr(re: _Re, pp: Int) raises DecodeError -> Int:
    var p = pp
    while True:
        var c = re._at(p)
        if c == -1 or c == 41 or c == 124:
            if c == 124:
                p = _skip_expr(re, p + 1)
                continue
            return p
        if c == 40:
            p = _atom_end(re, p)
            var q = _quant(re, p)
            p = q[2]
            continue
        p = _atom_end(re, p)
        var q2 = _quant(re, p)
        p = q2[2]


def _match_term(re: _Re, pp: Int, tp: Int) raises DecodeError -> Tuple[Bool, Int, Int]:
    var c = re._at(pp)
    if c == -1 or c == 41 or c == 124:
        return (True, pp, tp)
    var ends = _factor_ends(re, pp, tp)
    var after = ends[0]
    var i = len(ends[1]) - 1
    while i >= 0:
        var rest = _match_term(re, after, ends[1][i])
        if rest[0]:
            return rest
        i -= 1
    return (False, pp, tp)


def _match_expr(re: _Re, pp: Int, tp: Int) raises DecodeError -> Tuple[Bool, Int, Int]:
    var first = _match_term(re, pp, tp)
    if first[0] and (re._at(first[1]) != 124):
        return first
    # try alternatives; find '|' at this expr level
    var p = pp
    var last_fail = first
    while True:
        var term = _match_term(re, p, tp)
        if term[0] and re._at(term[1]) != 124:
            # this alternative consumed and next is end or )
            return term
        if term[0] and re._at(term[1]) == 124:
            # matched a prefix alt that still has | — if term ended at |, this alt succeeded only if we take it
            # _match_term stops before |. If it succeeded, this alt matches.
            return term
        # skip this alt
        var skip = _skip_expr_alt(re, p)
        if re._at(skip) != 124:
            return (False, pp, tp)
        p = skip + 1


def _skip_expr_alt(re: _Re, pp: Int) raises DecodeError -> Int:
    var p = pp
    while True:
        var c = re._at(p)
        if c == -1 or c == 41 or c == 124:
            return p
        p = _atom_end(re, p)
        var q = _quant(re, p)
        p = q[2]


def regexp_fullmatch(pattern: String, text: String) raises DecodeError -> Bool:
    """True when `pattern` matches all of `text`. Subset: concatenation, `|`, `*+?`, `.`, `[]`, `()`, `\\d\\w\\s`."""
    var pb = List[Byte]()
    var tb = List[Byte]()
    var ps = pattern.as_bytes()
    var ts = text.as_bytes()
    for i in range(len(ps)):
        pb.append(ps[i])
    for j in range(len(ts)):
        tb.append(ts[j])
    var ntext = len(tb)
    var re = _Re(pb^, tb^)
    var m = _match_expr(re, 0, 0)
    return m[0] and m[2] == ntext and (re._at(m[1]) == -1)
