"""棉棉 (and 小雨, the grown-up) as SVG, for the app icon, the 找大人 picture and the contact sheets.

In the app 棉棉 is NOT a picture: app/lib/app/cloud_painter.dart draws it with a CustomPainter from the
numbers in app/lib/core/looks.dart, so one feeling can blend slowly into another (docs/art.md). This
file reads those same numbers out of looks.dart and draws them the same way (the same puffs, brows,
eyes, mouth, tears and extras), so the pictures made here always match the app.

    import mianmian
    c = kit.Ctx(200, 180)
    mianmian.draw(c, "happy", x=100, y=110, s=1.0)            # the cloud's middle at (x, y), s = scale
    mianmian.draw(c, "neutral", kind="xiaoyu", extras={"question": 1})
    python3 mianmian.py sheet OUT.png                          # every feeling, as a contact sheet
"""
import sys

sys.dont_write_bytecode = True

import math  # noqa: E402
import re  # noqa: E402

import kit  # noqa: E402
from kit import INK, CHEEK, MOUTH, WHITE, Shape, circle, ellipse, lt  # noqa: E402

LOOKS = kit.ROOT / "app" / "lib" / "core" / "looks.dart"
TEAR = "#6AA6EC"
EX, EY = 20.0, -8.0
KAPPA = kit.KAPPA


# ---------------------------------------------------------------- reading looks.dart
def _num(s):
    return float(s)


def read_looks():
    """{feeling name: params dict} and {'neutral': ...} from looks.dart."""
    src = LOOKS.read_text()
    bodies = {}
    for m in re.finditer(r"static const (\w+) = \[(.*?)\];", src, re.S):
        puffs = []
        for p in re.finditer(r"Puff\(([^)]*)\)", m.group(2)):
            parts = [x.strip() for x in p.group(1).split(",")]
            pos = [float(x) for x in parts if ":" not in x]
            kw = {k.strip(): float(v) for k, v in (x.split(":") for x in parts if ":" in x)}
            puffs.append(dict(x=pos[0], y=pos[1], rx=pos[2], ry=pos[3], rot=kw.get("rot", 0.0), tip=kw.get("tip", 0.0)))
        if puffs:
            bodies[m.group(1)] = puffs
    looks = {}
    pat = re.compile(r"(?:Feeling\.(\w+):|static const (neutral) =) Look\((.*?)\)[,;]?\n")
    for m in pat.finditer(src):
        name = m.group(1) or m.group(2)
        body = m.group(3)
        p = dict(brow=0, browOn=0, eyeR=7, eyeArc=0, eyeShut=0, lid=0, look=0, mouthCurve=0, mouthOpen=0, mouthW=10, teeth=0,
                 wavy=0, mouthO=0, blush=.3, tears=0, tearDrop=0, sweat=0, faceY=0, extras={})
        p["color"] = "#" + re.search(r"Color\(0xFF([0-9A-Fa-f]{6})\)", body).group(1).upper()
        p["puffs"] = bodies[re.search(r"Bodies\.(\w+)", body).group(1)]
        ex = re.search(r"extras: \{(.*?)\}", body)
        if ex:
            p["extras"] = {k: _num(v) for k, v in re.findall(r"Extra\.(\w+): ([\d.]+)", ex.group(1))}
            body = body.replace(ex.group(0), "")
        for k, v in re.findall(r"(\w+): (-?[\d.]+)\b", body):
            if k in p:
                p[k] = _num(v)
        looks[name] = p
    if len(looks) != 15:
        raise SystemExit(f"mianmian: read {len(looks)} looks from looks.dart, expected 14 feelings and neutral")
    return looks


LOOKS_DATA = None


def look(name):
    global LOOKS_DATA
    if LOOKS_DATA is None:
        LOOKS_DATA = read_looks()
    return LOOKS_DATA[name]


# ---------------------------------------------------------------- the body
def puff_shape(p):
    """An ellipse (4 cubic pieces, clockwise) whose top can be pulled to a point (tip)."""
    x, y, rx, ry, rot, tip = p["x"], p["y"], p["rx"], p["ry"], p["rot"], p["tip"]
    k = KAPPA
    top = -ry * (1 + .25 * tip)
    kt = k * (1 - tip)
    pts = [("M", rx, 0),
           ("C", rx, ry * k, rx * k, ry, 0, ry),
           ("C", -rx * k, ry, -rx, ry * k, -rx, 0),
           ("C", -rx, -ry * k * (1 - .5 * tip), -rx * kt, top, 0, top),
           ("C", rx * kt, top, rx, -ry * k * (1 - .5 * tip), rx, 0),
           ("Z",)]
    s = Shape(pts)
    return s.rotate(rot, 0, 0).move(x, y)


def body_shape(puffs):
    s = Shape()
    for p in puffs:
        s = s + puff_shape(p)
    return s


def top_of(puffs):
    t = 0.0
    for p in puffs:
        if abs(p["x"]) < 30:
            t = min(t, p["y"] - p["ry"])
    return t


# ---------------------------------------------------------------- helpers
def quad(p0, c, p1, steps=16):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1]) for t in (i / steps for i in range(steps + 1))]


def poly_open(points):
    return kit.path(points)


def drop(x, y, w, h):
    """A water drop pointing up: the tip at (x, y), h tall, w wide."""
    k = KAPPA
    r = w / 2
    cy = y + h - r
    return Shape([("M", x, y), ("C", x + r * .4, y + h * .35, x + r, cy - r * .6, x + r, cy),
                  ("C", x + r, cy + r * k, x + r * k, cy + r, x, cy + r),
                  ("C", x - r * k, cy + r, x - r, cy + r * k, x - r, cy),
                  ("C", x - r, cy - r * .6, x - r * .4, y + h * .35, x, y), ("Z",)])


def z_letter(x, y, s):
    return [(x - s * .4, y - s * .4), (x + s * .4, y - s * .4), (x - s * .4, y + s * .4), (x + s * .4, y + s * .4)]


# ---------------------------------------------------------------- the whole cloud
def draw(c, name="happy", x=100.0, y=110.0, s=1.0, kind="mianmian", color=None, extras=None, shadow=True):
    """Draws the cloud feeling `name` with its middle at (x, y), scaled s, into kit.Ctx c."""
    L = dict(look(name))
    if color:
        L["color"] = color
    if extras is not None:
        L["extras"] = {**L["extras"], **extras}
    col = L["color"]
    c.begin(f"translate({kit.n(x)} {kit.n(y)}) scale({s:.4f})")
    ex_ = L["extras"]
    # trembling lines behind (害怕)
    if ex_.get("shake", 0) > 0:
        for sg in (-1, 1):
            xx = sg * 64
            c.stroke(Shape([("M", xx + sg * 6, -20), ("C", xx + sg * 12, -12, xx + sg * 12, 4, xx + sg * 6, 12)]), "#9D8BCB", 2.6, op=.8 * ex_["shake"])
            c.stroke(Shape([("M", xx + sg * 14, -14), ("C", xx + sg * 19, -8, xx + sg * 19, 4, xx + sg * 14, 10)]), "#9D8BCB", 2.6, op=.8 * ex_["shake"])
    if shadow:
        c.fill(ellipse(0, 46, 52, 8), c.radial(0, 46, 52, [(0, kit.SHADE, .22), (1, kit.SHADE, 0)]))
    body = body_shape(L["puffs"])
    c.mallow(body, col, shadow=False)
    top = top_of(L["puffs"])
    # the marker on top
    if kind == "mianmian":
        c.mallow(ellipse(-6, top - 1, 9, 7) + ellipse(4, top - 7, 7, 6), lt(col, .25), shadow=False, shade=False)
    elif kind == "xiaoyu":
        c.mallow(drop(0, top - 20, 14, 20), "#7FB3EA", shadow=False, shade=False)
    elif kind == "pal":
        for sg in (-1, 1):
            c.mallow(circle(sg * 34, top + 14, 9), lt(col, .3), shadow=False, shade=False)
    elif kind == "baby":
        c.mallow(circle(0, top - 3, 6), lt(col, .3), shadow=False, shade=False)
    face(c, L, col)
    extras_(c, L, col)
    c.end()


def face(c, L, col):
    ey = EY + L["faceY"]
    lk = L["look"]
    # brows
    if L["browOn"] > 0:
        for sg in (-1, 1):
            bx = sg * EX + lk
            inner, outer = bx - sg * 8, bx + sg * 8
            yi, yo = ey - 17 - L["brow"] * .22, ey - 17 + L["brow"] * .22
            c.stroke(poly_open(quad((inner, yi), (bx, (yi + yo) / 2 - 3), (outer, yo))), INK, 3.4, op=L["browOn"])
    r = L["eyeR"]
    w_round = max(0.0, 1 - L["eyeArc"] - L["eyeShut"])
    for sg in (-1, 1):
        ex = sg * EX + lk
        if w_round > 0:
            lid = L["lid"]
            if lid > 0:
                yl = ey - r + lid * r * .85
                # the part of the eye below the lid: a circle segment
                a = math.degrees(math.asin(max(-1, min(1, (yl - ey) / r))))
                pts = [(ex + r * math.cos(math.radians(t)), ey + r * math.sin(math.radians(t)))
                       for t in [a + (180 - 2 * a) * i / 20 for i in range(21)]]
                c.flat(kit.poly(pts), INK, op=w_round)
                c.stroke(kit.path([(ex - r - 1, yl), (ex + r + 1, yl)]), INK, 2.4, op=w_round * min(1, lid * 1.5))
            else:
                c.flat(circle(ex, ey, r), INK, op=w_round)
                c.flat(circle(ex - r * .32, ey - r * .32, r * .36), WHITE, op=w_round)
                c.flat(circle(ex + r * .3, ey + r * .35, r * .16), WHITE, op=w_round * .9)
        if L["eyeArc"] > 0:
            c.stroke(poly_open(quad((ex - 7, ey + 2.5), (ex, ey - 9), (ex + 7, ey + 2.5))), INK, 3.2, op=L["eyeArc"])
        if L["eyeShut"] > 0:
            c.stroke(poly_open(quad((ex - 7, ey - 1.5), (ex, ey + 7), (ex + 7, ey - 1.5))), INK, 3, op=L["eyeShut"])
    # blush
    c.flat(ellipse(-EX - 8 + lk, ey + 12, 9, 5.5) + ellipse(EX + 8 + lk, ey + 12, 9, 5.5), CHEEK, op=min(1, .22 + .6 * L["blush"]))
    # tears, the tear still in the eye, sweat
    if L["tears"] > 0:
        for sg in (-1, 1):
            tx = sg * EX + lk + sg * 5
            c.flat(kit.smooth([(tx - 3.5, ey + 6), (tx + 3.5, ey + 6), (tx + 4.5, ey + 28), (tx, ey + 36), (tx - 4.5, ey + 28)], .4), TEAR, op=.95 * L["tears"])
            c.flat(ellipse(tx - 1.5, ey + 17, 1.2, 4), WHITE, op=.8 * L["tears"])
    if L["tearDrop"] > 0:
        c.flat(drop(EX + lk + 7, ey + 5, 8, 13), TEAR, op=L["tearDrop"])
    if L["sweat"] > 0:
        c.flat(drop(50, -34, 10, 16), TEAR, op=L["sweat"])
        c.flat(drop(60, -12, 7, 11), TEAR, op=L["sweat"])
    # mouth
    my, mx, w, cv = ey + 20, lk * .6, L["mouthW"], L["mouthCurve"]
    d = cv * 10
    op_o = L["mouthO"]
    if op_o > 0:
        c.flat(ellipse(mx, my + 3, 7, 9), MOUTH, op=op_o)
    rest = 1 - op_o
    if rest <= 0:
        return
    opn = L["mouthOpen"]
    if opn < 1:
        if L["wavy"] > 0:
            pts = []
            for i in range(25):
                t = -1 + 2 * i / 24
                yy = my + d * .9 * (1 - t * t) + L["wavy"] * 2.4 * math.sin(t * math.pi * 3)
                pts.append((mx + w * t, yy))
            c.stroke(poly_open(pts), INK, 3, op=rest * (1 - opn))
        else:
            c.stroke(poly_open(quad((mx - w, my), (mx, my + d * 1.8), (mx + w, my))), INK, 3.1, op=rest * (1 - opn))
    if opn > 0:
        up, lo = mouth_edges(mx, my, w, d, opn)
        shape = kit.poly(up + lo[::-1])
        c.flat(shape, MOUTH, op=rest * opn)
        if cv > 0:
            c.flat(ellipse(mx, my + d * .9 + 1, w * .5, 4.2), "#F28BA0", op=rest * opn)
        if L["teeth"] > 0:
            band = teeth_band(up, lo)
            if band:
                c.flat(kit.poly(band), WHITE, op=rest * opn * L["teeth"])


def mouth_edges(mx, my, w, d, opn):
    """The top and bottom edges of an open mouth, left to right."""
    if d >= 0:
        up_c, lo_c = my - 2, my + d * 2.2 + 4 * opn
    else:
        up_c, lo_c = my + d * 2.0, my + 6 * opn
    return quad((mx - w, my), (mx, up_c), (mx + w, my)), quad((mx - w, my), (mx, lo_c), (mx + w, my))


def teeth_band(up, lo):
    """A white row of teeth just under the top edge, never below the bottom edge."""
    n = len(up)
    top, bottom = [], []
    for i in range(n):
        if i < n * .15 or i > n * .85:
            continue
        x, yu = up[i]
        yl = lo[i][1]
        top.append((x, yu))
        bottom.append((x, min(yu + 4.5, yl)))
    return top + bottom[::-1] if top else None


def extras_(c, L, col):
    e = L["extras"]
    if e.get("sparkle"):
        c.sparkle(-60, -44, 7, "#FFD54F", e["sparkle"])
        c.sparkle(62, -30, 5, "#FFD54F", e["sparkle"])
    if e.get("steam"):
        for xx in (-30, 30):
            for dx, y0, hh in ((-8, -62, 32), (6, -58, 28)):
                pts = [(xx + dx + 4 * math.sin(i / 10 * math.pi * 2), y0 - hh * i / 10) for i in range(11)]
                c.stroke(poly_open(pts), "#E06A5A", 3, op=.85 * e["steam"])
    if e.get("pop"):
        for (x0, y0, x1, y1) in ((-66, -50, -76, -60), (66, -50, 76, -60), (0, -76, 0, -88), (-40, -72, -45, -83), (40, -72, 45, -83)):
            c.stroke(kit.path([(x0, y0), (x1, y1)]), "#5EC3A4", 3.4, op=e["pop"])
    if e.get("hands"):
        for sg in (-1, 1):
            c.mallow(ellipse(0, 0, 13, 11).rotate(sg * -20, 0, 0).move(sg * 30 + L["look"], 6), lt(col, .2), shadow=False, op=e["hands"])
    if e.get("star"):
        c.mallow(kit.star(0, 28, 10), "#FFD54F", shadow=False, op=e["star"])
        for (sx, sy, sr) in ((-58, -42, 6), (60, -40, 5), (40, -70, 5)):
            c.sparkle(sx, sy, sr, "#FFD54F", e["star"])
    if e.get("zz"):
        c.stroke(poly_open(z_letter(56, -44, 12)), INK, 2.6, op=e["zz"])
        c.stroke(poly_open(z_letter(68, -60, 9)), INK, 2.2, op=.7 * e["zz"])
    if e.get("sigh"):
        c.stroke(Shape([("M", 58, 6), ("C", 66, 2, 72, 8, 72, 12), ("C", 74, 18, 78, 18, 82, 16)]), "#8C97AD", 3, op=.8 * e["sigh"])
    if e.get("dots"):
        c.dots([(50, -46), (60, -52), (70, -58)], 3.2, "#9C948A", op=e["dots"])
    if e.get("question"):
        q = e["question"]
        c.mallow(circle(46, -64, 16), WHITE, shadow=False, op=q)
        c.stroke(Shape([("M", 40, -69), ("C", 40, -77, 52, -77, 52, -69), ("C", 52, -64, 46, -64, 46, -59)]), INK, 3.2, op=q)
        c.flat(circle(46, -53, 2.2), INK, op=q)


# ---------------------------------------------------------------- a contact sheet of every feeling
def sheet(out):
    import html
    import subprocess
    import tempfile
    names = list(look("happy") and LOOKS_DATA.keys())
    cells = []
    for nm in names:
        c = kit.Ctx(200, 180)
        draw(c, nm, kind="mianmian")
        cells.append((nm, c.svg()))
    for nm, kind, extra in (("neutral", "xiaoyu", {"question": 1}), ("sad", "xiaoyu", None), ("calm", "grownup", None), ("happy", "pal", None)):
        c = kit.Ctx(200, 180)
        draw(c, nm, kind=kind, extras=extra, color="#FFDDBE" if kind == "grownup" else ("#F9C6D6" if kind == "pal" else None))
        cells.append((f"{kind}:{nm}", c.svg()))
    body = "".join(f'<div style="display:inline-block;width:200px;text-align:center;font:14px sans-serif">{t}'
                   f'<div style="width:200px;height:180px">{html.unescape(s)}</div>{html.escape(nm)}</div>' for nm, (t, s) in zip([n for n, _ in cells], [("", s) for _, s in cells]))
    page = f'<html><body style="margin:10px;background:#FFF8EE;width:1040px">{body}</body></html>'
    with tempfile.TemporaryDirectory(dir="/dev/shm") as tmp:
        p = f"{tmp}/s.html"
        open(p, "w").write(page)
        subprocess.run(["node", str(kit.ROOT / "docs" / "mockups" / "render.js"), p, str(out), "1060", str(220 * ((len(cells) + 4) // 5) + 20), "1"], check=True)
    print(out)


if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "sheet":
        sheet(sys.argv[2])
    else:
        print(__doc__)
