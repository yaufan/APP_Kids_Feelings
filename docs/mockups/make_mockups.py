"""Design-stage sketches for 「心情小屋」 (feelings for 2-5 year olds).

    python3 make_mockups.py          # writes docs/mockups/*.png (needs Node.js + Playwright, shapely, Pillow)
    python3 make_mockups.py 3        # only one page: 0 = style page, 1..7 = a screen, c = contact sheet

Every picture is drawn here as SVG by code (no outside pictures, no emoji). render.js turns each page
into a PNG with Playwright's Chromium at 390x844, deviceScaleFactor 2. shapely does the shape maths.
The font is jf open-huninn from a sibling app's checkout.

    0_畫風選擇.png      the same front yard of the little house (棉棉 the cloud, the house, the sun, a
                        balloon, a pillow) in three styles: A 棉花糖雲朵風, B 氣球玩具風, C 粉筆黑板風
    1_小屋.png          home: 棉棉 at the door, today's feeling, the five rooms as big buttons
    2_認表情.png        name the feeling: a big angry 棉棉, four feeling tiles to pick from
    3_這是什麼心情.png  a short story (the toy car broke) after the child answered: 小雨 is sad now
    4_冷靜小屋.png      calm room: press and hold to blow up a balloon with a breath wave
    5_怎麼辦.png        what can you do: three kind things to pick from
    6_心情日記.png      the diary: pick today's feeling (14 for the older level), see the week
    7_家長一起說.png    the question card for the grown-up
    contact_sheet.png   screens 1-7 small, with titles

Style A 「棉花糖雲朵風」: every piece is a soft, matte, rounded shape with no outline, a gentle light
from the top left, a faint soft shadow. B 「氣球玩具風」: glossy inflated vinyl with a bright
highlight and a dark rim. C 「粉筆黑板風」: chalk on a dark green board, rough edges, white lines.
"""
import hashlib
import math
import pathlib
import subprocess
import sys
import tempfile

from shapely.geometry import LineString, Polygon
from shapely.geometry import box as sbox
from shapely.ops import unary_union

HERE = pathlib.Path(__file__).resolve().parent
FONT = pathlib.Path("/home/user/app_kids_falsecharge/app/assets/fonts/jf-openhuninn-2.1.ttf")
if not FONT.exists():
    for _c in ("app_kids_maze", "app_kids_live_circ", "app_kids_brainstorming", "app_kids_card_game", "app_kids_cook", "app_kids_paint_for_learning_writing"):
        _p = pathlib.Path("/home/user") / _c / "app" / "assets" / "fonts" / "jf-openhuninn-2.1.ttf"
        if _p.exists():
            FONT = _p
            break
SCRATCH = pathlib.Path("/dev/shm") if pathlib.Path("/dev/shm").is_dir() else pathlib.Path(tempfile.gettempdir())
W, H = 390, 844

# ---------------------------------------------------------------- colours (pastel marshmallow)
INK = "#4A3F5C"        # words: soft plum
SOFT = "#8C8299"
CREAM = "#FFF8EE"
WHITE = "#FFFFFF"
SKY1, SKY2 = "#E9E4FA", "#FFF4E6"     # the page background gradient
PINK = "#F9BBD0"
ROSE = "#F4A6B8"
YEL = "#FFE08A"
PEACH = "#FFC9A6"
MINT = "#B8EAD8"
BLUE = "#B5D4F4"
LILAC = "#D3C4F3"
GREEN = "#C8E6A6"
BOARD = "#2F4B41"
CHEEK = "#FF9FB0"

# one colour and one face per feeling
FEELINGS = {
    #  key:          (名字,   colour,    body,        eyes,     brow,  mouth,       blush, tears, sweat, extra)
    "happy":        ("開心", "#FFE08A", "round",     "happy",  0,     "bigsmile",  .7,    0,     0,     "sparkle"),
    "sad":          ("難過", "#A9C9F2", "droop",     "round",  22,    "frown",     .25,   2,     0,     ""),
    "angry":        ("生氣", "#F59A8C", "spiky",     "round",  -28,   "grit",      .4,    0,     0,     "steam"),
    "scared":       ("害怕", "#C9B8F0", "small",     "wide",   26,    "gape",      .2,    1,     0,     "shake"),
    "surprised":    ("驚訝", "#B2E8D6", "tall",      "wide",   -6,    "o",         .4,    0,     0,     "pop"),
    "shy":          ("害羞", "#F9BBD0", "round",     "happy",  8,     "smallsmile", 1.0,  0,     0,     "hands"),
    "nervous":      ("緊張", "#D9E3A2", "round",     "small",  18,    "wavy",      .3,    0,     1,     ""),
    "disappointed": ("失望", "#BFC8DA", "droop",     "half",   14,    "flat",      .2,    0,     0,     "sigh"),
    "proud":        ("得意", "#FFC48C", "round",     "happy",  -10,   "grin",      .6,    0,     0,     "star"),
    "tired":        ("累累的", "#D9CDE6", "flat",    "half",   10,    "smallsmile", .3,   0,     0,     "zz"),
    "bored":        ("無聊", "#DAD3C6", "flat",      "half",   0,     "flat",      .2,    0,     0,     "dots"),
    "jealous":      ("嫉妒", "#A9D48F", "round",     "side",   -14,   "pout",      .35,   0,     0,     ""),
    "calm":         ("安心", "#CDEBDC", "round",     "closed", 0,     "smile",     .5,    0,     0,     ""),
    "wronged":      ("委屈", "#E3C4E6", "droop",     "round",  20,    "wavy",      .55,   1,     0,     ""),
    "neutral":      ("",     "#F1EDF6", "round",     "round",  0,     "flat",      .3,    0,     0,     ""),
}
BASIC4 = ["happy", "sad", "angry", "scared"]
FINE14 = ["happy", "sad", "angry", "scared", "surprised", "shy", "nervous", "disappointed", "proud", "tired", "bored", "jealous", "calm", "wronged"]


# ---------------------------------------------------------------- defs registry
class Defs:
    def __init__(self):
        self.d = {}

    def add(self, key, svg):
        self.d.setdefault(key, svg)
        return key

    def svg(self):
        return "<defs>" + "".join(self.d.values()) + "</defs>"


D = Defs()


def _h(*parts):
    return hashlib.md5("|".join(map(str, parts)).encode()).hexdigest()[:10]


def _stops(stops):
    return "".join(f'<stop offset="{s[0]}" stop-color="{s[1]}"' + (f' stop-opacity="{s[2]}"' if len(s) > 2 else "") + "/>" for s in stops)


def lg(stops, x1=0, y1=0, x2=0, y2=1, user=False):
    k = "lg" + _h(stops, x1, y1, x2, y2, user)
    u = ' gradientUnits="userSpaceOnUse"' if user else ""
    D.add(k, f'<linearGradient id="{k}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"{u}>{_stops(stops)}</linearGradient>')
    return f"url(#{k})"


def rg(stops, cx=.5, cy=.5, r=.5, user=False):
    k = "rg" + _h(stops, cx, cy, r, user)
    u = ' gradientUnits="userSpaceOnUse"' if user else ""
    D.add(k, f'<radialGradient id="{k}" cx="{cx}" cy="{cy}" r="{r}"{u}>{_stops(stops)}</radialGradient>')
    return f"url(#{k})"


def blur(sd):
    k = "bl" + str(sd).replace(".", "_")
    D.add(k, f'<filter id="{k}" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="{sd}"/></filter>')
    return f"url(#{k})"


def clip_rect(x, y, w, h, r=0):
    k = "cp" + _h(x, y, w, h, r)
    D.add(k, f'<clipPath id="{k}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}"/></clipPath>')
    return f"url(#{k})"


def _rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mixc(a, b, t):
    ra, rb = _rgb(a), _rgb(b)
    return "#" + "".join(f"{round(ra[i] + (rb[i] - ra[i]) * t):02X}" for i in range(3))


def darker(c, t=.25):
    return mixc(c, "#000000", t)


def lighter(c, t=.35):
    return mixc(c, "#FFFFFF", t)


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


# ================================================================ GEOMETRY
def ellp(cx, cy, rx, ry=None, n=48, rot=0.0):
    ry = rx if ry is None else ry
    a = math.radians(rot)
    ca, sa = math.cos(a), math.sin(a)
    out = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x, y = rx * math.cos(t), ry * math.sin(t)
        out.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    return out


def rrect(x, y, w, h, r, n=8):
    r = min(r, w / 2, h / 2)
    out = []
    for cx, cy, a0 in ((x + w - r, y + r, -90), (x + w - r, y + h - r, 0), (x + r, y + h - r, 90), (x + r, y + r, 180)):
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n)
            out.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return out


def star_pts(Rr, r, cx=0.0, cy=0.0, n=5, rot=-90.0):
    out = []
    for i in range(2 * n):
        a = math.radians(rot + 180 * i / n)
        rr_ = Rr if i % 2 == 0 else r
        out.append((cx + rr_ * math.cos(a), cy + rr_ * math.sin(a)))
    return out


def heart_pts(cx, cy, s):
    out = []
    for i in range(60):
        t = 2 * math.pi * i / 60
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        out.append((cx + x * s / 16, cy + y * s / 16))
    return out


def soft(g, r):
    """Round the corners of a shape (convex ones, then concave ones)."""
    return g.buffer(-r, join_style=1).buffer(2 * r, join_style=1).buffer(-r, join_style=1)


def tf(pts, dx=0.0, dy=0.0, rot=0.0, s=1.0, sy=None):
    a = math.radians(rot)
    ca, sa = math.cos(a), math.sin(a)
    sy = s if sy is None else sy
    return [(x * s * ca - y * sy * sa + dx, x * s * sa + y * sy * ca + dy) for x, y in pts]


def G(x):
    if isinstance(x, (list, tuple)):
        return Polygon(x).buffer(0)
    return x


def dpts(pts, closed=True):
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + ("Z" if closed else "")


def dgeom(g):
    polys = list(g.geoms) if hasattr(g, "geoms") else [g]
    out = []
    for p in polys:
        if p.is_empty or p.geom_type != "Polygon":
            continue
        for ring in (p.exterior, *p.interiors):
            out.append(dpts(list(ring.coords)[:-1]))
    return "".join(out)


def P(pts):
    return Polygon(pts).buffer(0)


def R(x, y, w, h, r=4):
    return Polygon(rrect(x, y, w, h, r))


def E(cx, cy, rx, ry=None, rot=0.0):
    return Polygon(ellp(cx, cy, rx, ry, rot=rot))


def U(*gs):
    return unary_union([G(g) for g in gs])


def star_g(Rr, cx=0.0, cy=0.0, rot=-90.0, ratio=.5):
    return soft(Polygon(star_pts(Rr, Rr * ratio, cx, cy, 5, rot)), Rr * .12)


def heart_g(cx, cy, s):
    return Polygon(heart_pts(cx, cy, s))


# ================================================================ THE THREE STYLES
STYLE = "mallow"       # "mallow" (A), "balloon" (B), "chalk" (C)
K = 1.0                # screen pixels per drawing unit (place() keeps it right so blur and strokes keep their size)


def place(x, y, s, fn, *a, rot=0.0, **kw):
    global K
    old = K
    K = old * s
    try:
        inner = fn(*a, **kw)
    finally:
        K = old
    r = f" rotate({rot:.1f})" if rot else ""
    return f'<g transform="translate({x:.1f} {y:.1f}){r} scale({s:.4f})">{inner}</g>'


def ink():
    return "#F6F2EA" if STYLE == "chalk" else INK


def mallow(g, col, sh=1):
    """A marshmallow: soft matte volume, no outline, light from the top left, a faint soft shadow."""
    d = dgeom(g.simplify(.15 / K))
    o = ""
    if sh:
        dy = 4 * sh
        o += f'<path d="{d}" fill="#5A4A6E" fill-rule="evenodd" opacity=".16" transform="translate({dy * .25 / K:.2f} {dy / K:.2f})" filter="{blur(round(3.5 * sh / K, 2))}"/>'
    o += f'<path d="{d}" fill="{rg([(0, lighter(col, .42)), (.62, col), (1, darker(col, .1))], .36, .3, .82)}" fill-rule="evenodd"/>'
    o += f'<path d="{d}" fill="{lg([(0, "#FFFFFF", .45), (.5, "#FFFFFF", 0)])}" fill-rule="evenodd"/>'
    o += f'<path d="{d}" fill="{lg([(.55, "#4A3A5A", 0), (1, "#4A3A5A", .12)])}" fill-rule="evenodd"/>'
    return o


def balloon(g, col, sh=1):
    """Glossy inflated vinyl: saturated colour, a dark rim, a bright specular highlight."""
    d = dgeom(g.simplify(.15 / K))
    x0, y0, x1, y1 = g.bounds
    w, h = x1 - x0, y1 - y0
    col = mixc(col, "#FF5FA8" if col in (PINK, ROSE) else col, 0)
    sat = darker(lighter(col, -.0), .0)
    o = ""
    if sh:
        dy = 5 * sh
        o += f'<path d="{d}" fill="#3A2A4E" fill-rule="evenodd" opacity=".28" transform="translate({dy * .4 / K:.2f} {dy / K:.2f})" filter="{blur(round(3 * sh / K, 2))}"/>'
    o += f'<path d="{d}" fill="{rg([(0, lighter(sat, .18)), (.55, sat), (.86, darker(sat, .28)), (1, darker(sat, .42))], .4, .36, .72)}" fill-rule="evenodd"/>'
    o += f'<path d="{d}" fill="{lg([(0, "#FFFFFF", 0), (1, "#FFFFFF", .28)], 0, 0, 1, 1)}" fill-rule="evenodd"/>'
    o += f'<ellipse cx="{x0 + w * .3:.1f}" cy="{y0 + h * .2:.1f}" rx="{max(2, w * .13):.1f}" ry="{max(1.2, h * .07):.1f}" fill="#FFFFFF" opacity=".92" transform="rotate(-28 {x0 + w * .3:.1f} {y0 + h * .2:.1f})"/>'
    o += f'<circle cx="{x0 + w * .46:.1f}" cy="{y0 + h * .12:.1f}" r="{max(1, w * .03):.1f}" fill="#FFFFFF" opacity=".85"/>'
    return o


def chalk_f():
    k = round(K, 3)
    key = "ck" + _h(k)
    D.add(key, f'<filter id="{key}" x="-.1" y="-.1" width="1.2" height="1.2" color-interpolation-filters="sRGB">'
               f'<feTurbulence type="fractalNoise" baseFrequency="{.5 * k:.3f}" numOctaves="2" seed="4" result="n"/>'
               f'<feColorMatrix in="n" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 0.9 0.4" result="na"/>'
               f'<feComposite in="SourceGraphic" in2="na" operator="in" result="m"/>'
               f'<feTurbulence type="fractalNoise" baseFrequency="{.05 * k:.4f}" numOctaves="2" seed="2" result="w"/>'
               f'<feDisplacementMap in="m" in2="w" scale="{2 / k:.2f}" xChannelSelector="R" yChannelSelector="G"/></filter>')
    return f"url(#{key})"


def chalk(g, col, sh=1):
    """Chalk on the board: a pastel smudge of colour with a rough white chalk line round it."""
    d = dgeom(g.simplify(.3 / K))
    cc = lighter(col, .1)
    o = f'<g filter="{chalk_f()}">'
    o += f'<path d="{d}" fill="{cc}" fill-rule="evenodd" opacity=".9"/>'
    o += f'<path d="{d}" fill="none" stroke="#F8F4EC" stroke-width="{2.4 / K:.2f}" stroke-linejoin="round" opacity=".9"/>'
    return o + "</g>"


def body(shape, col, sh=1):
    g = G(shape)
    if g.is_empty:
        return ""
    if STYLE == "balloon":
        return balloon(g, col, sh)
    if STYLE == "chalk":
        return chalk(g, col, sh)
    return mallow(g, col, sh)


def flat(shape, col, op=1.0):
    """A painted-on detail with no volume (eyes, blush, dots)."""
    g = G(shape)
    if g.is_empty:
        return ""
    f = f' filter="{chalk_f()}"' if STYLE == "chalk" else ""
    return f'<path d="{dgeom(g)}" fill="{col}" fill-rule="evenodd" opacity="{op}"{f}/>'


def line(d, col, w, op=1.0, cap="round", dash=None):
    k = K
    da = f' stroke-dasharray="{dash[0] / k:.2f} {dash[1] / k:.2f}"' if dash else ""
    f = f' filter="{chalk_f()}"' if STYLE == "chalk" else ""
    return f'<path d="{d}" fill="none" stroke="{col}" stroke-opacity="{op}" stroke-width="{w / k:.2f}" stroke-linecap="{cap}" stroke-linejoin="round"{da}{f}/>'


def tx(x, y, s, size=16, color=None, anchor="middle", extra="", op=1.0):
    color = color or ink()
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" fill="{color}" text-anchor="{anchor}" opacity="{op}" '
            f'font-family="Huninn, sans-serif" {extra}>{esc(s)}</text>')


# ================================================================ THE CLOUD CREATURE 棉棉
def cloud_geom(kind="round"):
    """The body of the cloud creature, about 130 wide, centre near (0, 0)."""
    base = E(0, 4, 58, 40)
    if kind == "round":
        g = U(base, E(-36, -12, 27, 25), E(-4, -24, 33, 30), E(30, -16, 27, 25), E(50, 6, 20, 18), E(-52, 8, 18, 16))
        return soft(g, 6)
    if kind == "flat":          # tired: squashed
        g = U(E(0, 8, 62, 32), E(-36, -4, 27, 20), E(-2, -12, 33, 24), E(32, -6, 27, 20), E(54, 12, 18, 13), E(-54, 12, 16, 12))
        return soft(g, 6)
    if kind == "droop":         # sad: flat top, bumps hanging down
        g = U(E(0, -4, 56, 34), E(-18, -26, 30, 19), E(18, -26, 28, 18), E(-32, 16, 25, 22), E(2, 22, 27, 24), E(34, 14, 23, 20))
        return soft(g, 6)
    if kind == "spiky":         # angry: spikes on top
        pts = []
        for i in range(13):
            a = math.radians(-172 + 164 * i / 12)
            rr_ = 70 if i % 2 == 0 else 50
            pts.append((rr_ * math.cos(a), 2 + rr_ * .9 * math.sin(a)))
        pts += [(56, 34), (-56, 34)]
        g = U(base, Polygon(pts), E(-50, 10, 16, 14), E(50, 10, 16, 14))
        return soft(g, 2.5)
    if kind == "small":         # scared: shrunk and wobbly
        g = U(E(0, 8, 46, 34))
        for i in range(9):
            a = math.radians(190 + 160 * i / 8)
            g = U(g, E(44 * math.cos(a), 8 + 30 * math.sin(a), 13 + (i % 2) * 4, 11 + (i % 2) * 4))
        return soft(g, 4)
    if kind == "tall":          # surprised: stretched up
        g = U(E(0, 0, 50, 50), E(-28, -32, 22, 20), E(6, -44, 24, 20), E(34, -28, 20, 18), E(-48, 10, 14, 13), E(48, 12, 14, 13))
        return soft(g, 6)
    return soft(base, 6)


def _eye(cx, cy, kind, s=1.0):
    r = 7 * s
    c = ink()
    if kind == "happy":
        return line(f"M{cx - r:.1f},{cy + r * .35:.1f} Q{cx:.1f},{cy - r * 1.3:.1f} {cx + r:.1f},{cy + r * .35:.1f}", c, 3.2 * s)
    if kind == "closed":
        return line(f"M{cx - r:.1f},{cy - r * .2:.1f} Q{cx:.1f},{cy + r * 1.0:.1f} {cx + r:.1f},{cy - r * .2:.1f}", c, 3 * s)
    rr_ = {"wide": 9 * s, "small": 5.5 * s, "half": 7 * s}.get(kind, r)
    if kind == "side":
        return (f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{r * 1.25:.1f}" ry="{r:.1f}" fill="#FFFFFF"/>'
                f'<circle cx="{cx + r * .5:.1f}" cy="{cy + r * .1:.1f}" r="{r * .62:.1f}" fill="{c}"/>'
                f'<circle cx="{cx + r * .32:.1f}" cy="{cy - r * .15:.1f}" r="{r * .2:.1f}" fill="#FFFFFF"/>')
    o = f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{rr_:.1f}" fill="{c}"/>'
    if kind == "half":
        k = "cpe" + _h(cx, cy, rr_)
        D.add(k, f'<clipPath id="{k}"><rect x="{cx - rr_ - 2:.1f}" y="{cy - rr_ * .15:.1f}" width="{2 * rr_ + 4:.1f}" height="{rr_ * 2:.1f}"/></clipPath>')
        o = f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{rr_:.1f}" fill="{c}" clip-path="url(#{k})"/>'
        o += line(f"M{cx - rr_:.1f},{cy - rr_ * .15:.1f} h{2 * rr_:.1f}", c, 2.4 * s)
        return o
    if STYLE != "chalk":
        o += f'<circle cx="{cx - rr_ * .32:.1f}" cy="{cy - rr_ * .32:.1f}" r="{rr_ * .36:.1f}" fill="#FFFFFF"/>'
        o += f'<circle cx="{cx + rr_ * .3:.1f}" cy="{cy + rr_ * .35:.1f}" r="{rr_ * .16:.1f}" fill="#FFFFFF" opacity=".9"/>'
    return o


_cur_col = "#FFFFFF"


def creature(feel="happy", friend=False, look=0.0):
    """棉棉 (or the friend 小雨) feeling something. Drawn round (0, 0), about 130 wide; feet at y = 44."""
    global _cur_col
    name, col, kind, eyes, brow, mouth, blush, tears, sweat, extra = FEELINGS[feel]
    if friend and feel == "neutral":
        col = "#DCE9F8"
    _cur_col = col
    c = ink()
    g = cloud_geom(kind)
    o = []
    if extra == "shake":
        for sgn in (-1, 1):
            x = sgn * 62
            o.append(line(f"M{x + sgn * 6},-20 q{sgn * 6},16 0,32 M{x + sgn * 14},-14 q{sgn * 6},12 0,24", "#9D8BCB", 2.6, .8))
    o.append(body(g, col, sh=2))
    # the little tuft on top (棉棉) or the raindrop clip (小雨), so the two can be told apart in every mood
    top = min(y for x, y in g.exterior.coords)
    if friend:
        o.append(body(P([(0, top - 18), (7, top - 6), (0, top + 2), (-7, top - 6)]).buffer(2.5, join_style=1), "#7FB3EA", sh=0))
    else:
        o.append(body(U(E(-6, top - 2, 9, 7), E(4, top - 8, 7, 6)), lighter(col, .25), sh=0))
    # face
    ex, ey = 20, -8 + (6 if kind == "droop" else 0) + (-4 if kind == "tall" else 0)
    # brows
    if brow:
        for sgn in (-1, 1):
            x = sgn * ex + look
            inner, outer = x - sgn * 8, x + sgn * 8
            yi, yo = ey - 17 - brow * .22, ey - 17 + brow * .22
            o.append(line(f"M{inner:.1f},{yi:.1f} Q{x:.1f},{(yi + yo) / 2 - 3:.1f} {outer:.1f},{yo:.1f}", c, 3.4))
    o.append(_eye(-ex + look, ey, eyes) + _eye(ex + look, ey, eyes))
    # blush
    o.append(flat(U(E(-ex - 8 + look, ey + 12, 9, 5.5), E(ex + 8 + look, ey + 12, 9, 5.5)), CHEEK, .22 + .6 * blush))
    # mouth
    my = ey + 20
    mx = look
    if mouth == "bigsmile":
        o.append(f'<path d="M{mx - 15},{my - 2} Q{mx},{my + 22} {mx + 15},{my - 2}Z" fill="#B5405C"/>' + flat(E(mx, my + 8, 8, 4.5), "#F28BA0"))
    elif mouth == "smile":
        o.append(line(f"M{mx - 10},{my} Q{mx},{my + 9} {mx + 10},{my}", c, 3))
    elif mouth == "smallsmile":
        o.append(line(f"M{mx - 6},{my + 1} Q{mx},{my + 6} {mx + 6},{my + 1}", c, 3))
    elif mouth == "grin":
        o.append(f'<path d="M{mx - 16},{my - 1} Q{mx},{my + 16} {mx + 16},{my - 1}Z" fill="#B5405C"/>' + flat(R(mx - 12, my - 1, 24, 6, 2).intersection(E(mx, my + 2, 16, 10)), "#FFFFFF"))
    elif mouth == "frown":
        o.append(line(f"M{mx - 11},{my + 6} Q{mx},{my - 5} {mx + 11},{my + 6}", c, 3.2))
    elif mouth == "flat":
        o.append(line(f"M{mx - 9},{my + 2} L{mx + 9},{my + 2}", c, 3))
    elif mouth == "grit":
        o.append(f'<path d="M{mx - 14},{my + 6} Q{mx},{my - 6} {mx + 14},{my + 6}Z" fill="#B5405C"/>')
        o.append(flat(R(mx - 12, my - 1, 24, 5, 1.5).intersection(P([(mx - 14, my + 6), (mx, my - 6), (mx + 14, my + 6)])), "#FFFFFF"))
    elif mouth == "gape":
        o.append(f'<path d="M{mx - 10},{my + 8} Q{mx},{my - 8} {mx + 10},{my + 8} Q{mx},{my + 12} {mx - 10},{my + 8}Z" fill="#B5405C"/>')
    elif mouth == "o":
        o.append(flat(E(mx, my + 3, 7, 9), "#B5405C"))
    elif mouth == "wavy":
        o.append(line(f"M{mx - 12},{my + 2} q3,-4 6,0 t6,0 t6,0", c, 3))
    elif mouth == "pout":
        o.append(line(f"M{mx - 6},{my + 4} Q{mx},{my - 1} {mx + 6},{my + 4}", c, 3.2))
    # tears, sweat
    if tears:
        for sgn in (-1, 1):
            x = sgn * ex + look + sgn * 5
            if tears == 2:
                o.append(flat(P([(x - 3.5, ey + 6), (x + 3.5, ey + 6), (x + 4.5, ey + 30), (x, ey + 36), (x - 4.5, ey + 30)]).buffer(1.5, join_style=1), "#8FC2F5", .95))
                o.append(flat(E(x - 1.5, ey + 16, 1.2, 4), "#FFFFFF", .8))
            else:
                o.append(flat(P([(x, ey + 8), (x + 4, ey + 16), (x, ey + 20), (x - 4, ey + 16)]).buffer(1.2, join_style=1), "#8FC2F5"))
    if sweat:
        o.append(flat(P([(48, -30), (55, -18), (48, -12), (41, -18)]).buffer(1.5, join_style=1), "#8FC2F5"))
        o.append(flat(P([(58, -8), (63, 0), (58, 4), (53, 0)]).buffer(1, join_style=1), "#8FC2F5"))
    # extras
    if extra == "sparkle":
        o.append(sparkle(-60, -44, 7) + sparkle(62, -30, 5))
    elif extra == "steam":
        for x in (-30, 30):
            o.append(line(f"M{x - 8},-62 q4,-8 0,-16 q-4,-8 0,-16 M{x + 6},-58 q4,-7 0,-14", "#E06A5A", 3, .85))
    elif extra == "pop":
        o.append(line("M-66,-50 l-10,-10 M66,-50 l10,-10 M0,-76 l0,-12 M-40,-72 l-5,-11 M40,-72 l5,-11", "#5EC3A4", 3.4))
    elif extra == "hands":
        for sgn in (-1, 1):
            o.append(body(E(sgn * 30 + look, 6, 13, 11, rot=sgn * -20), lighter(col, .2), sh=1))
    elif extra == "star":
        o.append(body(star_g(9, 0, 26), "#FFD54F", sh=1))
        o.append(sparkle(-58, -42, 6, "#FFD54F") + sparkle(60, -40, 5, "#FFD54F") + sparkle(40, -70, 5, "#FFD54F"))
    elif extra == "zz":
        o.append(tx(56, -44, "z", 18, c) + tx(68, -60, "z", 14, c, op=.7))
    elif extra == "sigh":
        o.append(line("M30,16 q10,-2 14,6 q3,6 10,4", "#8C97AD", 3, .8))
    elif extra == "dots":
        o.append(flat(U(E(50, -46, 3.2), E(60, -52, 3.2), E(70, -58, 3.2)), "#9C948A"))
    return "".join(o)


def sparkle(cx, cy, r, c="#FFE08A", op=1.0):
    return (f'<path d="M{cx},{cy - r} Q{cx + r * .16},{cy - r * .16} {cx + r},{cy} Q{cx + r * .16},{cy + r * .16} {cx},{cy + r} '
            f'Q{cx - r * .16},{cy + r * .16} {cx - r},{cy} Q{cx - r * .16},{cy - r * .16} {cx},{cy - r}Z" fill="{c}" opacity="{op}"/>')


def feel_icon(feel, friend=False):
    """A tiny version for buttons and the diary."""
    return place(0, 0, .3, creature, feel, friend)


# ================================================================ THINGS
def house(x, y, w=200, h=150):
    """The little house, drawn with its floor at y and centred on x."""
    o = []
    wall = R(x - w / 2, y - h * .62, w, h * .62, 18)
    o.append(body(wall, CREAM, sh=2))
    roof = soft(P([(x - w / 2 - 18, y - h * .58), (x, y - h * 1.02), (x + w / 2 + 18, y - h * .58)]), 10)
    o.append(body(roof, PINK, sh=2))
    o.append(body(R(x + w * .18, y - h * .96, 22, 28, 7), ROSE, sh=1))             # chimney
    o.append(body(U(E(x + w * .29, y - h * 1.08, 10, 8), E(x + w * .35, y - h * 1.2, 8, 7)), "#FFFFFF", sh=0))
    o.append(body(E(x, y - h * .42, 22, 22), BLUE, sh=1))                          # round window
    o.append(line(f"M{x - 16},{y - h * .42} h32 M{x},{y - h * .42 - 16} v32", "#FFFFFF", 3))
    o.append(body(R(x - w * .18 - 20, y - h * .5, 40, 30, 8), LILAC, sh=1))         # a square window with a curtain
    o.append(body(E(x - w * .18, y - h * .5 + 6, 16, 8), "#FFFFFF", sh=0))
    o.append(body(R(x + w * .2 - 20, y - h * .5, 40, 30, 8), LILAC, sh=1))
    o.append(body(E(x + w * .2, y - h * .5 + 6, 16, 8), "#FFFFFF", sh=0))
    door = U(R(x - 28, y - 62, 56, 62, 8), E(x, y - 62, 28, 24))
    o.append(body(door, PEACH, sh=1))
    o.append(flat(E(x + 14, y - 30, 4), "#E0906A"))
    o.append(body(E(x, y + 2, w * .36, 10), MINT, sh=0))                             # doormat
    return "".join(o)


def sun(cx, cy, r=26):
    o = [body(E(cx, cy, r), YEL, sh=1)]
    o.append(line("".join(f"M{cx + (r + 8) * math.cos(math.radians(a)):.1f},{cy + (r + 8) * math.sin(math.radians(a)):.1f} "
                          f"L{cx + (r + 16) * math.cos(math.radians(a)):.1f},{cy + (r + 16) * math.sin(math.radians(a)):.1f} " for a in range(0, 360, 45)), "#FFC96B" if STYLE != "chalk" else "#FFE9A8", 4))
    o.append(_eye(cx - 9, cy - 2, "happy", .7) + _eye(cx + 9, cy - 2, "happy", .7))
    o.append(line(f"M{cx - 5},{cy + 8} Q{cx},{cy + 13} {cx + 5},{cy + 8}", ink(), 2.4))
    o.append(flat(U(E(cx - 14, cy + 6, 5, 3), E(cx + 14, cy + 6, 5, 3)), CHEEK, .6))
    return "".join(o)


def ground_cloud(x, y, w, h):
    g = U(R(x, y, w, h, 24), *[E(x + w * t, y + 4, w * .11, h * .5) for t in (.1, .3, .5, .7, .9)])
    return body(soft(g, 8), "#FFFFFF" if STYLE != "chalk" else "#DDE7E2", sh=1)


def sky_bg(w=W, h=H, extra_clouds=True):
    if STYLE == "chalk":
        o = f'<rect width="{w}" height="{h}" fill="{BOARD}"/>'
        k = "smudge"
        D.add(k, '<filter id="smudge" x="0" y="0" width="1" height="1"><feTurbulence type="fractalNoise" baseFrequency="0.012" numOctaves="3" seed="11" result="n"/>'
                 '<feColorMatrix in="n" type="matrix" values="0 0 0 0 0.9  0 0 0 0 0.9  0 0 0 0 0.85  0 0 0 0.16 -0.02"/></filter>')
        return o + f'<rect width="{w}" height="{h}" fill="#000" filter="url(#smudge)"/>'
    o = f'<rect width="{w}" height="{h}" fill="{lg([(0, SKY1), (1, SKY2)])}"/>'
    if extra_clouds:
        for cx, cy, s in ((60, 120, .5), (330, 80, .4), (300, 300, .35), (40, 420, .3)):
            o += f'<g opacity=".45">{body(soft(U(E(cx, cy, 60 * s, 26 * s), E(cx - 25 * s, cy - 14 * s, 28 * s, 24 * s), E(cx + 18 * s, cy - 18 * s, 32 * s, 28 * s)), 6), "#FFFFFF", sh=0)}</g>'
    return o


def balloon_shape(cx, cy, r, col, string=True, knot=True):
    g = soft(U(E(cx, cy, r, r * 1.15), P([(cx - r * .14, cy + r * 1.05), (cx + r * .14, cy + r * 1.05), (cx, cy + r * 1.3)])), r * .08)
    o = body(g, col, sh=2)
    if string:
        o += line(f"M{cx},{cy + r * 1.28} q{r * .3},{r * .4} 0,{r * .8} t0,{r * .8}", "#9D8BCB", 2.4, .9)
    return o


def pillow(cx, cy, w=70, h=42, col=LILAC):
    g = soft(U(R(cx - w / 2, cy - h / 2, w, h, 14), E(cx - w / 2 + 6, cy - h / 2 + 6, 10, 8), E(cx + w / 2 - 6, cy - h / 2 + 6, 10, 8),
               E(cx - w / 2 + 6, cy + h / 2 - 6, 10, 8), E(cx + w / 2 - 6, cy + h / 2 - 6, 10, 8)), 5)
    return body(g, col, sh=1) + line(f"M{cx - w * .3},{cy} q{w * .15},-6 {w * .3},0 t{w * .3},0", lighter(col, .5), 3, .9)


def teddy(cx, cy, s=1.0):
    o = []
    bc = "#D9B48F"
    o.append(body(E(cx, cy + 20 * s, 22 * s, 20 * s), bc, sh=1))
    o.append(body(U(E(cx - 16 * s, cy - 14 * s, 9 * s), E(cx + 16 * s, cy - 14 * s, 9 * s)), bc, sh=0))
    o.append(body(E(cx, cy, 22 * s, 20 * s), bc, sh=1))
    o.append(flat(E(cx, cy + 6 * s, 9 * s, 7 * s), lighter(bc, .5)))
    o.append(flat(E(cx, cy + 4 * s, 3.5 * s, 2.5 * s), INK))
    o.append(flat(U(E(cx - 8 * s, cy - 3 * s, 2.6 * s), E(cx + 8 * s, cy - 3 * s, 2.6 * s)), INK))
    o.append(body(U(E(cx - 24 * s, cy + 16 * s, 8 * s, 7 * s), E(cx + 24 * s, cy + 16 * s, 8 * s, 7 * s)), bc, sh=0))
    return "".join(o)


def cup(cx, cy, s=1.0):
    g = U(R(cx - 14 * s, cy - 18 * s, 28 * s, 36 * s, 6 * s))
    o = body(g, BLUE, sh=1)
    o += body(E(cx + 17 * s, cy - 2 * s, 8 * s, 9 * s).difference(E(cx + 17 * s, cy - 2 * s, 4 * s, 5 * s)), BLUE, sh=0)
    o += flat(E(cx, cy - 18 * s, 13 * s, 4 * s), lighter(BLUE, .5))
    return o


def grownup(cx, cy, s=1.0, col="#CFE3F7"):
    """A big calm cloud: the grown-up."""
    return place(cx, cy, s, creature, "calm")


def toy_car(cx, cy, s=1.0, broken=False):
    o = []
    bodyc = "#F28B9B"
    if broken:
        left = P([(cx - 34 * s, cy), (cx - 34 * s, cy - 14 * s), (cx - 22 * s, cy - 14 * s), (cx - 14 * s, cy - 26 * s), (cx - 4 * s, cy - 26 * s), (cx - 8 * s, cy - 12 * s), (cx - 10 * s, cy)]).buffer(2 * s, join_style=1)
        right = P([(cx + 4 * s, cy - 26 * s), (cx + 12 * s, cy - 26 * s), (cx + 20 * s, cy - 14 * s), (cx + 34 * s, cy - 14 * s), (cx + 34 * s, cy), (cx + 2 * s, cy), (cx + 0 * s, cy - 12 * s)]).buffer(2 * s, join_style=1)
        o.append(place(0, 0, 1, lambda: body(left, bodyc, sh=1), rot=0))
        o.append(f'<g transform="translate({6 * s} {2 * s}) rotate(14 {cx + 18 * s} {cy})">{body(right, bodyc, sh=1)}</g>')
        o.append(body(E(cx - 22 * s, cy + 2 * s, 8 * s), INK if STYLE != "chalk" else "#8E9AA6", sh=0))
        o.append(body(E(cx + 26 * s, cy + 6 * s, 8 * s), INK if STYLE != "chalk" else "#8E9AA6", sh=0))
        o.append(body(E(cx + 48 * s, cy - 10 * s, 7 * s), INK if STYLE != "chalk" else "#8E9AA6", sh=1))
        o.append(line(f"M{cx - 2 * s},{cy - 30 * s} l-4,-8 M{cx + 4 * s},{cy - 32 * s} l1,-9 M{cx + 10 * s},{cy - 30 * s} l5,-7", "#9D8BCB", 2.4))
        return "".join(o)
    car = P([(cx - 34 * s, cy), (cx - 34 * s, cy - 14 * s), (cx - 22 * s, cy - 14 * s), (cx - 14 * s, cy - 26 * s), (cx + 12 * s, cy - 26 * s), (cx + 20 * s, cy - 14 * s), (cx + 34 * s, cy - 14 * s), (cx + 34 * s, cy)]).buffer(2 * s, join_style=1)
    o.append(body(car, bodyc, sh=1))
    o.append(flat(R(cx - 10 * s, cy - 22 * s, 18 * s, 9 * s, 3 * s), lighter(BLUE, .3)))
    o.append(body(U(E(cx - 20 * s, cy + 2 * s, 8 * s), E(cx + 20 * s, cy + 2 * s, 8 * s)), INK, sh=0))
    return "".join(o)


# ================================================================ UI BITS
def pill(x, y, w, h, col, label="", size=18, tcol=None, sh=1, icon=""):
    o = body(R(x, y, w, h, h / 2), col, sh=sh)
    if icon:
        o += icon
    if label:
        o += tx(x + w / 2 + (14 if icon else 0), y + h / 2 + size * .36, label, size, tcol or ink())
    return o


def round_btn(cx, cy, r, col, inner="", sh=1):
    return body(E(cx, cy, r), col, sh=sh) + inner


def i_speaker(cx, cy, col=None, s=1.0):
    col = col or ink()
    g = P(tf([(-12, -5), (-6, -5), (2, -12), (2, 12), (-6, 5), (-12, 5)], cx - 2 * s, cy, s=s)).buffer(1.4 * s, join_style=1)
    w = (f"M{cx + 4.5 * s:.1f},{cy - 5 * s:.1f} A{8 * s},{8 * s} 0 0 1 {cx + 4.5 * s:.1f},{cy + 5 * s:.1f} "
         f"M{cx + 8.5 * s:.1f},{cy - 10 * s:.1f} A{14 * s},{14 * s} 0 0 1 {cx + 8.5 * s:.1f},{cy + 10 * s:.1f}")
    return flat(g, col) + line(w, col, 2.6 * s)


def i_lock(cx, cy, col=None, s=1.0):
    col = col or SOFT
    return (line(f"M{cx - 5 * s:.1f},{cy - 1 * s:.1f} V{cy - 6 * s:.1f} A{5 * s},{5 * s} 0 0 1 {cx + 5 * s:.1f},{cy - 6 * s:.1f} V{cy - 1 * s:.1f}", col, 2.6 * s)
            + flat(R(cx - 8 * s, cy - 2 * s, 16 * s, 13 * s, 3 * s), col))


def i_back(cx, cy, col=None, s=1.0):
    col = col or ink()
    return line(f"M{cx + 6 * s},{cy - 9 * s} L{cx - 5 * s},{cy} L{cx + 6 * s},{cy + 9 * s}", col, 3.6 * s)


def i_home(cx, cy, col=None, s=1.0):
    col = col or ink()
    g = P(tf([(-13, 0), (0, -12), (13, 0), (9, 0), (9, 11), (-9, 11), (-9, 0)], cx, cy, s=s)).buffer(1.6 * s, join_style=1)
    return flat(g, col) + flat(R(cx - 3.5 * s, cy + 3 * s, 7 * s, 8 * s, 2.5 * s), "#FFFFFF" if STYLE != "chalk" else BOARD)


def i_check(cx, cy, s=1.0, col="#FFFFFF"):
    return line(f"M{cx - 7 * s:.1f},{cy:.1f} L{cx - 2 * s:.1f},{cy + 5.5 * s:.1f} L{cx + 8 * s:.1f},{cy - 6 * s:.1f}", col, 3.6 * s)


def finger(x, y, rot=-25.0):
    """A see-through grown-up fingertip pressing at (x, y)."""
    g = LineString([(0, 0), (0, 96)]).buffer(24, cap_style=1)
    d = dgeom(g)
    return (f'<g transform="translate({x:.1f} {y:.1f}) rotate({rot})">'
            f'<circle cx="0" cy="0" r="34" fill="#FFFFFF" opacity=".35"/>'
            f'<path d="{d}" fill="#FFE1CF" fill-opacity=".62" stroke="#D99D82" stroke-opacity=".55" stroke-width="2"/>'
            f'<path d="M-12,-8 Q0,-17 12,-8 L12,8 Q0,14 -12,8Z" fill="#FFFFFF" fill-opacity=".55"/>'
            f'<path d="M-16,10 Q-18,40 -14,64" stroke="#FFFFFF" stroke-opacity=".55" stroke-width="4" fill="none" stroke-linecap="round"/></g>')


def bubble(x, y, w, h, text, size=18, tail=("bottom", .3), speaker=True, lines=None):
    """A speech bubble with a speaker icon; lines = list of strings for several lines."""
    g = R(x, y, w, h, 22)
    side, t = tail
    if side == "bottom":
        g = U(g, P([(x + w * t - 12, y + h - 4), (x + w * t + 12, y + h - 4), (x + w * t, y + h + 16)]))
    elif side == "top":
        g = U(g, P([(x + w * t - 12, y + 4), (x + w * t + 12, y + 4), (x + w * t, y - 16)]))
    o = body(soft(g, 3), "#FFFFFF" if STYLE != "chalk" else "#4B6A5E", sh=1)
    tx0 = x + 18
    if speaker:
        o += round_btn(x + 26, y + h / 2, 17, MINT, i_speaker(x + 26, y + h / 2, s=.75), sh=0)
        tx0 = x + 52
    lines = lines or [text]
    n = len(lines)
    for i, ln in enumerate(lines):
        yy = y + h / 2 + size * .36 + (i - (n - 1) / 2) * (size * 1.35)
        o += tx(tx0, yy, ln, size, ink(), "start")
    return o


def topbar(title, left="back", right="speaker"):
    o = []
    if left == "back":
        o.append(round_btn(34, 44, 24, "#FFFFFF" if STYLE != "chalk" else "#4B6A5E", i_back(34, 44)))
    elif left == "lock":
        o.append(pill(12, 22, 84, 44, "#FFFFFF" if STYLE != "chalk" else "#4B6A5E", "家長", 17, SOFT, icon=i_lock(34, 44)))
    if right == "speaker":
        o.append(round_btn(356, 44, 24, MINT, i_speaker(356, 44)))
    if title:
        o.append(tx(195, 53, title, 24, ink()))
    return "".join(o)


def feel_tile(x, y, w, h, feel, chosen=False, dim=False, friend=False, also=False):
    col = FEELINGS[feel][1]
    bg = "#FFFFFF" if STYLE != "chalk" else "#4B6A5E"
    o = ""
    if chosen:
        o += f'<rect x="{x - 5}" y="{y - 5}" width="{w + 10}" height="{h + 10}" rx="{min(w, h) / 2 + 2}" fill="none" stroke="#5EC3A4" stroke-width="5"/>'
    o += f'<g opacity="{.5 if dim else 1}">' + body(R(x, y, w, h, 26), bg, sh=1)
    o += f'<g clip-path="{clip_rect(x, y, w, h, 26)}">' + place(x + w / 2, y + h * .42, h / 150, creature, feel, friend) + "</g>"
    o += tx(x + w / 2, y + h - 14, FEELINGS[feel][0], 20, ink()) + "</g>"
    if chosen:
        o += round_btn(x + w - 12, y + 10, 15, "#5EC3A4", i_check(x + w - 12, y + 10, .9), sh=0)
    if also:
        o += pill(x + w / 2 - 34, y - 10, 68, 24, "#FFF1B8", "也可以", 13, "#8A6A1F", sh=0)
    return o


def page(body_svg, bg=None, w=W, h=H):
    css = (f"@font-face {{ font-family: Huninn; src: url('file://{FONT}'); }}"
           f"* {{ margin: 0; padding: 0; }} body {{ width: {w}px; height: {h}px; overflow: hidden; background: {bg or SKY2}; }}")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{D.svg()}{body_svg}</svg>'
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{svg}</body></html>'


def render(html, out, w, h, scale):
    with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
        p = pathlib.Path(tmp) / "page.html"
        p.write_text(html)
        subprocess.run(["node", str(HERE / "render.js"), str(p), str(out), str(w), str(h), str(scale)], check=True)
    if pathlib.Path(out).stat().st_size > 450_000:
        from PIL import Image
        im = Image.open(out).convert("RGB")
        im.quantize(colors=256, method=Image.Quantize.MEDIANCUT, kmeans=2, dither=Image.Dither.FLOYDSTEINBERG).save(out, optimize=True)


# ================================================================ THE SHARED SCENE (style page and the home screen)
def yard_scene(x, y, w, h, big=False):
    """The front yard: sky, the house, the sun, 棉棉 at the door, a balloon, a pillow. Clipped to (x, y, w, h)."""
    o = [f'<g clip-path="{clip_rect(x, y, w, h, 18)}">']
    if STYLE == "chalk":
        o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{BOARD}"/>')
        o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#000" filter="url(#smudge)"/>' if "smudge" in D.d else "")
    else:
        o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{lg([(0, "#DCD4F6"), (1, "#FFF1E0")])}"/>')
    s = w / 330
    floor = y + h * .86
    o.append(sun(x + w * .85, y + h * .18, 22 * s))
    o.append(ground_cloud(x - 20, floor - 6, w + 40, h * .3))
    o.append(place(x + w * .36, floor, s * .78, house, 0, 0, 230, 170))
    o.append(place(x + w * .78, floor - 42 * s, s, creature, "happy"))
    o.append(balloon_shape(x + w * .1, y + h * .42, 20 * s, ROSE))
    o.append(pillow(x + w * .12, floor - 16 * s, 54 * s, 32 * s))
    o.append("</g>")
    return "".join(o)


def style_sheet():
    global STYLE
    ph = 1226
    o = [f'<rect width="{W}" height="{ph}" fill="#F7F2EA"/>']
    o.append(tx(195, 58, "選一個畫風", 30, INK))
    o.append(tx(195, 90, "同一個小屋門口，三種畫法", 16, SOFT))
    bands = [("A 棉花糖雲朵風（建議）", "軟軟圓圓、霧面沒有框線，像棉花糖和雲。", "mallow"),
             ("B 氣球玩具風", "亮亮的充氣玩具：有反光點、邊邊比較深。", "balloon"),
             ("C 粉筆黑板風", "深綠黑板上的粉筆畫：粉粉的顏色、白線條。", "chalk")]
    y = 116
    for title, desc, st in bands:
        hh = 346
        STYLE = "mallow"
        if st == "mallow":
            o.append(f'<rect x="12" y="{y - 4}" width="366" height="{hh + 8}" rx="28" fill="#5EC3A4"/>')
            o.append(f'<rect x="16" y="{y}" width="358" height="{hh}" rx="24" fill="#FFFFFF"/>')
            o.append(f'<rect x="270" y="{y - 14}" width="92" height="30" rx="15" fill="#5EC3A4"/>' + tx(316, y + 7, "我建議這個", 14, "#FFFFFF"))
        else:
            o.append(f'<rect x="16" y="{y + 4}" width="358" height="{hh}" rx="24" fill="#E9DED3"/><rect x="16" y="{y}" width="358" height="{hh}" rx="24" fill="#FFFFFF"/>')
        o.append(tx(34, y + 40, title, 22, INK, "start"))
        o.append(tx(34, y + 68, desc, 13.5, "#6E5C52", "start"))
        STYLE = st
        if st == "chalk":
            sky_bg(1, 1, False)   # registers the smudge filter
        o.append(yard_scene(30, y + 88, 330, 240))
        STYLE = "mallow"
        y += hh + 22
    return page("".join(o), "#F7F2EA", W, ph), ph


# ================================================================ SCREENS
def screen_home():
    o = [sky_bg()]
    o.append(topbar("心情小屋", "lock", "speaker"))
    o.append(pill(16, 86, 130, 36, "#FFFFFF", "", sh=1))
    o.append(place(38, 104, .16, creature, "happy") + tx(88, 111, "今天：開心", 15, INK))
    # the yard
    o.append(ground_cloud(-30, 404, 450, 70))
    o.append(sun(56, 212, 24))
    o.append(place(150, 410, 1.0, house, 0, 0, 230, 170))
    o.append(place(300, 365, .95, creature, "happy"))
    o.append(balloon_shape(42, 300, 22, ROSE))
    o.append(bubble(118, 150, 252, 64, "", 17, ("bottom", .72), True, ["你好！今天的心情", "怎麼樣呢？"]))
    # five rooms
    rooms = [("認表情", YEL, lambda cx, cy: place(cx, cy, .28, creature, "surprised")),
             ("小故事", BLUE, lambda cx, cy: toy_car(cx, cy + 10, .55)),
             ("冷靜小屋", MINT, lambda cx, cy: balloon_shape(cx, cy - 4, 14, ROSE)),
             ("怎麼辦", PEACH, lambda cx, cy: body(heart_g(cx, cy + 2, 16), ROSE, sh=1))]
    for i, (name, col, ic) in enumerate(rooms):
        r, c = divmod(i, 2)
        x, y = 22 + c * 178, 486 + r * 118
        o.append(body(R(x, y, 168, 104, 28), col, sh=2))
        o.append(ic(x + 44, y + 50))
        o.append(tx(x + 118, y + 60, name, 22, INK))
    o.append(body(R(22, 722, 346, 72, 36), LILAC, sh=2))
    for i, f in enumerate(["happy", "sad", "neutral", "neutral"]):
        o.append(place(58 + i * 30, 758, .13, creature, f))
    o.append(tx(260, 766, "心情日記", 22, INK))
    o.append(tx(195, 826, "每次玩 10 分鐘，玩完換你去做", 12, SOFT))
    return page("".join(o))


def screen_faces():
    o = [sky_bg()]
    o.append(topbar("認表情"))
    o.append(bubble(40, 86, 310, 60, "棉棉現在是什麼心情？", 19, ("bottom", .5)))
    o.append(ground_cloud(40, 352, 310, 46))
    o.append(place(195, 300, 1.35, creature, "angry"))
    o.append(tx(195, 436, "點一個，聽聽看", 15, SOFT))
    for i, f in enumerate(BASIC4):
        r, c = divmod(i, 2)
        o.append(feel_tile(28 + c * 174, 456 + r * 168, 160, 150, f))
    o.append(tx(195, 820, "小小（2～3 歲）：先認這四種", 12, SOFT))
    return page("".join(o))


def screen_story():
    o = [sky_bg()]
    o.append(topbar("小故事"))
    # the scene card
    o.append(body(R(20, 84, 350, 250, 26), "#FFFFFF", sh=2))
    o.append(f'<g clip-path="{clip_rect(20, 84, 350, 250, 26)}">')
    o.append(f'<rect x="20" y="84" width="350" height="250" fill="{lg([(0, "#FFF4E2"), (1, "#F5E6F8")])}"/>')
    o.append(body(R(20, 274, 350, 60, 0), "#F3D9C4", sh=0))                  # the floor
    o.append(body(R(50, 110, 90, 70, 10), BLUE, sh=1) + flat(R(58, 118, 74, 54, 6), "#EAF6FF"))   # window
    o.append(body(R(250, 140, 100, 44, 10), PEACH, sh=1) + body(R(258, 184, 10, 90, 4), "#E0B08A", sh=0) + body(R(332, 184, 10, 90, 4), "#E0B08A", sh=0))  # a table
    o.append(place(0, 0, 1, toy_car, 300, 273, .7, True))
    o.append(place(150, 262, .72, creature, "sad", True))
    o.append("</g>")
    o.append(bubble(20, 350, 350, 82, "", 17, ("top", .4), True, ["小雨最喜歡的小車車壞掉了。", "小雨現在是什麼心情？"]))
    # answer tiles (after the child picked 難過)
    tiles = [("sad", True, False, False), ("angry", False, False, True), ("happy", False, True, False), ("disappointed", False, False, True)]
    for i, (f, ch, dim, also) in enumerate(tiles):
        r, c = divmod(i, 2)
        o.append(feel_tile(28 + c * 174, 468 + r * 140, 160, 122, f, ch, dim, True, also))
    o.append(pill(50, 764, 290, 54, "#FFF1B8", "家長一起說", 20, "#8A6A1F", icon=round_btn(86, 791, 21, "#FFFFFF", place(80, 794, .17, creature, "calm") + place(98, 798, .11, creature, "happy"), sh=0)))
    return page("".join(o))


def screen_calm():
    o = [sky_bg()]
    o.append(topbar("冷靜小屋"))
    o.append(bubble(40, 86, 310, 60, "按住，慢慢吸氣～", 19, ("bottom", .5)))
    # the balloon getting big
    o.append(f'<circle cx="195" cy="290" r="150" fill="{rg([(0, "#FFFFFF", .7), (1, "#FFFFFF", 0)])}"/>')
    o.append(balloon_shape(195, 268, 92, ROSE, string=False))
    o.append(tx(195, 278, "吸～", 30, "#FFFFFF"))
    o.append(line("M195,386 q-6,14 -24,22 q-16,6 -34,4", "#9D8BCB", 2.6, .9))
    o.append(place(100, 440, .75, creature, "nervous"))
    # the breath wave
    o.append(body(R(40, 468, 310, 56, 28), "#FFFFFF", sh=1))
    wave = "M62,496 " + " ".join(f"Q{62 + 36 * i + 18},{496 + (-18 if i % 2 == 0 else 18)} {62 + 36 * (i + 1)},496" for i in range(8))
    o.append(line(wave, MINT, 5))
    o.append(line("M62,496 Q80,478 98,496 Q116,514 134,496 Q152,478 170,496 Q188,514 206,496", "#5EC3A4", 5))
    o.append(flat(E(206, 496, 7), "#5EC3A4"))
    o.append(tx(90, 548, "吸氣", 14, SOFT) + tx(300, 548, "吐氣", 14, SOFT))
    # the big hold button
    o.append(body(E(195, 640, 66), "#5EC3A4", sh=2))
    o.append(tx(195, 632, "按住", 24, "#FFFFFF") + tx(195, 660, "吸氣", 20, "#FFFFFF"))
    o.append(finger(252, 676, -28))
    # the other ways
    ways = [("吹氣球", lambda cx, cy: balloon_shape(cx, cy - 4, 11, ROSE, False)),
            ("數到四", lambda cx, cy: tx(cx, cy + 7, "1234", 15, INK)),
            ("抱抱", lambda cx, cy: teddy(cx, cy - 4, .5)),
            ("搥枕頭", lambda cx, cy: pillow(cx, cy, 36, 22)),
            ("喝口水", lambda cx, cy: cup(cx, cy, .55)),
            ("找大人", lambda cx, cy: place(cx, cy, .2, creature, "calm"))]
    for i, (name, ic) in enumerate(ways):
        cx = 42 + i * 61
        o.append(round_btn(cx, 752, 26, "#FFFFFF" if i else "#FFE5EE", ic(cx, 752)))
        if i == 0:
            o.append(f'<circle cx="{cx}" cy="752" r="29" fill="none" stroke="#5EC3A4" stroke-width="4"/>')
        o.append(tx(cx, 800, name, 13, INK))
    return page("".join(o))


def screen_whatnow():
    o = [sky_bg()]
    o.append(topbar("怎麼辦？"))
    o.append(body(R(20, 84, 350, 210, 26), "#FFFFFF", sh=2))
    o.append(f'<g clip-path="{clip_rect(20, 84, 350, 210, 26)}">')
    o.append(f'<rect x="20" y="84" width="350" height="210" fill="{lg([(0, "#FFF4E2"), (1, "#F5E6F8")])}"/>')
    o.append(body(R(20, 240, 350, 60, 0), "#F3D9C4", sh=0))
    o.append(place(0, 0, 1, toy_car, 318, 242, .75, True))
    o.append(place(110, 222, .66, creature, "sad", True))
    o.append(place(228, 222, .62, creature, "neutral"))
    o.append(body(soft(U(R(190, 108, 64, 40, 14), P([(202, 144), (222, 144), (208, 160)])), 3), "#FFFFFF", sh=1))
    o.append(tx(222, 138, "？", 24, INK))
    o.append("</g>")
    o.append(bubble(20, 310, 350, 82, "", 17, ("top", .3), True, ["小雨好難過。", "你可以怎麼做呢？"]))
    acts = [("抱抱小雨", PINK, lambda cx, cy: place(cx - 16, cy + 8, .3, creature, "shy") + place(cx + 16, cy + 8, .3, creature, "sad", True)),
            ("問：你還好嗎？", BLUE, lambda cx, cy: body(soft(U(R(cx - 26, cy - 18, 52, 32, 12), P([(cx - 14, cy + 12), (cx - 2, cy + 12), (cx - 12, cy + 24)])), 2), "#FFFFFF", sh=1) + tx(cx, cy + 6, "你還好嗎", 11, INK)),
            ("去找大人", MINT, lambda cx, cy: place(cx + 10, cy + 6, .36, creature, "calm") + place(cx - 26, cy + 14, .22, creature, "neutral"))]
    for i, (name, col, ic) in enumerate(acts):
        y = 414 + i * 112
        o.append(body(R(28, y, 334, 96, 30), col, sh=2))
        o.append(round_btn(84, y + 48, 38, "#FFFFFF", ic(84, y + 48), sh=0))
        o.append(tx(236, y + 57, name, 22, INK))
    o.append(tx(195, 772, "三個都是好方法，點一個試試看", 14, SOFT))
    o.append(tx(195, 800, "分享和輪流，留給真的朋友一起練", 12, SOFT))
    return page("".join(o))


def screen_diary():
    o = [sky_bg()]
    o.append(topbar("心情日記", "home", "speaker"))
    o.append(round_btn(34, 44, 24, "#FFFFFF", i_home(34, 44)))
    o.append(bubble(40, 86, 310, 60, "今天，你的心情是？", 19, ("bottom", .5), True))
    cols = 5
    for i, f in enumerate(FINE14):
        r, c = divmod(i, cols)
        n_in_row = min(cols, len(FINE14) - r * cols)
        x, y = 16 + c * 73 + (cols - n_in_row) * 73 / 2, 164 + r * 92
        chosen = f == "happy"
        bg = "#FFFFFF"
        if chosen:
            o.append(f'<rect x="{x - 4}" y="{y - 4}" width="{66 + 8}" height="{84 + 8}" rx="22" fill="none" stroke="#5EC3A4" stroke-width="4"/>')
        o.append(body(R(x, y, 66, 84, 18), bg, sh=1))
        o.append(f'<g clip-path="{clip_rect(x, y, 66, 84, 18)}">' + place(x + 33, y + 36, .33, creature, f) + "</g>")
        o.append(tx(x + 33, y + 76, FEELINGS[f][0], 12.5, INK))
    # the week
    o.append(tx(195, 470, "這一個星期", 16, SOFT))
    days = ["一", "二", "三", "四", "五", "六", "日"]
    past = ["happy", "tired", "angry", "sad", "happy", None, None]
    for i, d in enumerate(days):
        cx = 42 + i * 51
        today = i == 4
        if today:
            o.append(body(E(cx, 530, 23), "#FFF1B8", sh=0))
        o.append(tx(cx, 498, d, 14, INK))
        if past[i]:
            o.append(place(cx, 530, .24, creature, past[i]))
        else:
            o.append(f'<circle cx="{cx}" cy="530" r="13" fill="none" stroke="#C9C2D6" stroke-width="2.5" stroke-dasharray="5 5"/>')
    # 棉棉 happy with a note
    o.append(ground_cloud(60, 650, 270, 40))
    o.append(place(130, 630, .62, creature, "happy"))
    o.append(bubble(186, 578, 186, 70, "", 15, ("bottom", .2), False, ["今天你是開心的！", "去說給爸爸媽媽聽"]))
    o.append(pill(50, 712, 290, 52, "#5EC3A4", "說給爸爸媽媽聽", 20, "#FFFFFF"))
    o.append(pill(50, 774, 290, 48, "#FFFFFF", "回小屋", 18, INK))
    return page("".join(o))


def screen_parent_talk():
    o = [sky_bg()]
    o.append(topbar("家長一起說"))
    o.append(pill(110, 86, 170, 32, "#FFF1B8", "這一頁給大人看", 14, "#8A6A1F", sh=0))
    # the card
    o.append(body(R(20, 134, 350, 390, 28), "#FFFFFF", sh=2))
    o.append(body(R(40, 150, 110, 30, 15), MINT, sh=0) + tx(95, 171, "問問孩子", 16, INK))
    o.append(tx(40, 226, "「你有沒有東西壞掉的時候？", 20, INK, "start"))
    o.append(tx(40, 258, "那時候你是什麼心情？」", 20, INK, "start"))
    o.append(line("M40,282 H350", "#E6E0F0", 2))
    o.append(body(R(40, 300, 110, 30, 15), PEACH, sh=0) + tx(95, 321, "可以一起說", 16, INK))
    o.append(tx(40, 372, "東西壞掉會難過，也會生氣。", 17, INK, "start"))
    o.append(tx(40, 402, "難過的時候可以說出來、", 17, INK, "start"))
    o.append(tx(40, 432, "可以抱抱，或是請大人幫忙。", 17, INK, "start"))
    o.append(line("M40,456 H350", "#E6E0F0", 2))
    o.append(tx(40, 494, "小提醒：先聽孩子說，不用急著教。", 14, SOFT, "start"))
    # the grown-up cloud and 棉棉 side by side
    o.append(ground_cloud(40, 652, 310, 46))
    o.append(place(130, 612, 1.0, creature, "calm"))
    o.append(place(265, 630, .62, creature, "happy"))
    o.append(body(heart_g(205, 560, 12), ROSE, sh=1))
    o.append(pill(40, 712, 150, 50, "#FFFFFF", "念出來", 18, INK, icon=i_speaker(70, 737, INK, .8)))
    o.append(pill(200, 712, 150, 50, "#FFFFFF", "下一個問題", 18, INK))
    o.append(pill(50, 774, 290, 50, "#5EC3A4", "回小屋", 18, "#FFFFFF"))
    return page("".join(o))


# ================================================================ CONTACT SHEET AND MAIN
def contact_sheet(names):
    cw_, ch_, gap, m = 232, 502, 24, 30
    per = 4
    rows = (len(names) + per - 1) // per
    w = per * cw_ + (per - 1) * gap + 2 * m
    rowh = ch_ + 64
    h = rows * rowh + 40
    items = []
    for i, n in enumerate(names):
        r, c = divmod(i, per)
        k = min(per, len(names) - r * per)
        x = m + c * (cw_ + gap) + (per - k) * (cw_ + gap) / 2
        y = 28 + r * rowh
        items.append(f'<div style="position:absolute;left:{x}px;top:{y}px;width:{cw_}px;text-align:center">'
                     f'<img src="file://{HERE / (n + ".png")}" style="width:{cw_}px;height:{ch_}px;border-radius:18px;box-shadow:0 6px 16px rgba(90,60,90,.2)">'
                     f'<div style="font:19px Huninn, sans-serif;color:{INK};margin-top:10px">{n.replace("_", " ")}</div></div>')
    css = f"@font-face {{ font-family: Huninn; src: url('file://{FONT}'); }} * {{ margin:0; padding:0 }} body {{ width:{w}px; height:{h}px; background:#F7F1EC; position:relative }}"
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{"".join(items)}</body></html>', w, h


SCREENS = {"1_小屋": screen_home, "2_認表情": screen_faces, "3_這是什麼心情": screen_story, "4_冷靜小屋": screen_calm,
           "5_怎麼辦": screen_whatnow, "6_心情日記": screen_diary, "7_家長一起說": screen_parent_talk}


def main(only=None):
    global D
    if only in (None, "0"):
        D = Defs()
        html, ph = style_sheet()
        render(html, HERE / "0_畫風選擇.png", W, ph, 2)
        print("0_畫風選擇")
    for name, make in SCREENS.items():
        if only not in (None, name.split("_")[0]):
            continue
        D = Defs()
        render(make(), HERE / f"{name}.png", W, H, 2)
        print(name)
    if only in (None, "c"):
        html, w, h = contact_sheet(list(SCREENS))
        render(html, HERE / "contact_sheet.png", w, h, 1.25)
        print("contact_sheet")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
