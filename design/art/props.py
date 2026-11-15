"""冷靜小屋's things (app/assets/art/calm/) and the pictures on the house's five doors and small
buttons (app/assets/art/icons/).

calm/: balloon, teddy, pillow, cup, numcloud (a puffy cloud for 數到四; the app writes the number),
heart (the hug), way_<balloon|count|hug|pillow|water|adult> (the six ways' buttons).
icons/: door_<faces|story|calm|help|diary> (the five rooms), cloud_small (a diary day not written).

    python3 build.py props
"""
import sys

sys.dont_write_bytecode = True

import math  # noqa: E402

import kit  # noqa: E402
import mianmian  # noqa: E402
from kit import (BLUE, CREAM, INK, LILAC, MINT, PEACH, PINK, ROSE, WHITE, YELLOW, Ctx, circle, ellipse, heart, lt,  # noqa: E402
                 rrect, smooth, star)

CALM = kit.ART / "calm"
ICONS = kit.ART / "icons"
BEAR = "#E3BE96"
BALLOON = "#F7A6BE"


# ---------------------------------------------------------------- 冷靜小屋's things
def balloon_shape(cx, cy, r):
    body = smooth([(cx, cy - r * 1.12), (cx + r * .78, cy - r * .82), (cx + r, cy - r * .05), (cx + r * .72, cy + r * .72),
                   (cx + r * .2, cy + r * 1.08), (cx, cy + r * 1.12), (cx - r * .2, cy + r * 1.08), (cx - r * .72, cy + r * .72),
                   (cx - r, cy - r * .05), (cx - r * .78, cy - r * .82)], .55)
    knot = kit.poly([(cx - r * .13, cy + r * 1.2), (cx + r * .13, cy + r * 1.2), (cx, cy + r * 1.06)])
    return body, knot


def balloon(c, cx, cy, r, col=BALLOON, string=True, face=True):
    body, knot = balloon_shape(cx, cy, r)
    if string:
        pts = [(cx + r * .12 * math.sin(i / 10 * math.pi * 2), cy + r * 1.2 + r * 1.0 * i / 10) for i in range(11)]
        c.stroke(kit.path(pts), "#B9A7D9", max(2, r * .045), op=.9)
    c.mallow(body, col, lift=.7)
    c.mallow(knot, kit.dk(col, .08), shadow=False, sheen=False)
    c.flat(ellipse(cx - r * .38, cy - r * .5, r * .16, r * .3).rotate(25, cx - r * .38, cy - r * .5), WHITE, op=.55)
    if face:
        c.face(cx, cy + r * .05, r * .2, "smile", blush=.55)


def teddy(c, cx, cy, s=1.0):
    """A teddy bear sitting, about 140 s wide, its middle at (cx, cy)."""
    B = BEAR
    e = lambda x, y, rx, ry=None: ellipse(cx + x * s, cy + y * s, rx * s, (ry or rx) * s)  # noqa: E731
    c.mallow(e(-34, -54, 16) + e(34, -54, 16), B)                   # ears
    c.flat(e(-34, -54, 8) + e(34, -54, 8), "#F6C9C0", op=.9)
    c.mallow(e(0, 34, 46, 40), B)                                     # body
    c.mallow(e(0, 40, 26, 22), lt(B, .45), shadow=False)             # tummy
    c.mallow(e(-40, 52, 15, 13) + e(40, 52, 15, 13), B, shadow=False)  # feet
    c.mallow(e(-46, 18, 13, 16) + e(46, 18, 13, 16), B, shadow=False)  # arms
    c.mallow(e(0, -22, 44, 38), B)                                    # head
    c.mallow(e(0, -10, 16, 12), lt(B, .5), shadow=False)             # snout
    c.flat(e(0, -15, 5, 3.6), INK)
    c.stroke(kit.arc(cx - 3 * s, cy - 10 * s, 3 * s, 20, 160) + kit.arc(cx + 3 * s, cy - 10 * s, 3 * s, 20, 160), INK, 2 * s)
    c.flat(e(-15, -27, 3.4) + e(15, -27, 3.4), INK)
    c.flat(e(-26, -14, 6, 3.6) + e(26, -14, 6, 3.6), kit.CHEEK, op=.6)
    c.mallow(kit.heart(cx + 24 * s, cy + 32 * s, 14 * s), ROSE, shadow=False)


def pillow(c, cx, cy, w, h, col=LILAC):
    x, y = cx - w / 2, cy - h / 2
    g = rrect(x, y, w, h, h * .38)
    for px, py in ((x + 10, y + 10), (x + w - 10, y + 10), (x + 10, y + h - 10), (x + w - 10, y + h - 10)):
        g = g + circle(px, py, h * .17)
    c.mallow(g, col, lift=.9)
    pts = [(cx - w * .3 + w * .6 * i / 12, cy + 5 * math.sin(i / 12 * math.pi * 2)) for i in range(13)]
    c.stroke(kit.path(pts), lt(col, .55), 4, op=.9)
    c.face(cx, cy - h * .12, h * .1, "calm", blush=.5)


def cup(c, cx, cy, s=1.0):
    """A blue cup of water with a little face, about 100 s wide."""
    w, h = 64 * s, 82 * s
    x, y = cx - w / 2, cy - h / 2
    c.stroke(kit.arc(cx + w / 2 - 2 * s, cy - 2 * s, 15 * s, -75, 75), kit.dk(BLUE, .08), 9 * s)
    body = kit.Shape([("M", x, y), ("L", x + w, y), ("L", x + w - 6 * s, y + h - 10 * s),
                      ("C", x + w - 7 * s, y + h, x + w - 12 * s, y + h, x + w - 16 * s, y + h),
                      ("L", x + 16 * s, y + h), ("C", x + 12 * s, y + h, x + 7 * s, y + h, x + 6 * s, y + h - 10 * s), ("Z",)])
    c.mallow(body, BLUE)
    c.mallow(ellipse(cx, y + 2 * s, w / 2 - 2 * s, 8 * s), "#D7ECFF", shadow=False, shade=False)
    c.flat(ellipse(cx - 8 * s, y + 1 * s, 12 * s, 3 * s), WHITE, op=.7)
    c.face(cx, cy + 10 * s, 9 * s, "smile")


def numcloud():
    c = Ctx(120, 90)
    c.mallow(kit.puffs(60, 52, 104, 60, n=4, key="num"), WHITE, lift=.8)
    return c.svg()


def heart_svg():
    c = Ctx(64, 60)
    c.mallow(heart(32, 30, 54), ROSE, lift=.6)
    c.flat(ellipse(20, 20, 6, 4).rotate(-30, 20, 20), WHITE, op=.6)
    return c.svg()


def calm_files():
    out = {}
    c = Ctx(160, 260)
    balloon(c, 80, 92, 66)
    out["balloon"] = c.svg()
    c = Ctx(160, 170)
    teddy(c, 80, 92)
    out["teddy"] = c.svg()
    c = Ctx(230, 150)
    pillow(c, 112, 72, 196, 112)
    out["pillow"] = c.svg()
    c = Ctx(140, 120)
    cup(c, 62, 60)
    out["cup"] = c.svg()
    out["numcloud"] = numcloud()
    out["heart"] = heart_svg()
    # the six ways' buttons, 100 x 100
    c = Ctx(100, 100)
    balloon(c, 50, 38, 26)
    out["way_balloon"] = c.svg()
    c = Ctx(100, 100)
    for i, (x, y) in enumerate(((22, 66), (40, 42), (62, 34), (82, 52))):
        c.mallow(kit.puffs(x, y, 30, 22, n=3, key=f"w{i}"), [MINT, YELLOW, PINK, LILAC][i], lift=.5)
        c.dots([(x - 6 + 4 * k, y + 2) for k in range(i + 1)][: i + 1], 1.9, INK, op=.7)
    out["way_count"] = c.svg()
    c = Ctx(100, 100)
    teddy(c, 50, 54, .62)
    out["way_hug"] = c.svg()
    c = Ctx(100, 100)
    pillow(c, 50, 54, 84, 54)
    out["way_pillow"] = c.svg()
    c = Ctx(100, 100)
    cup(c, 46, 52, .8)
    out["way_water"] = c.svg()
    c = Ctx(100, 100)
    mianmian.draw(c, "calm", x=36, y=62, s=.42, kind="grownup", color="#FFDDBE")
    mianmian.draw(c, "happy", x=72, y=72, s=.26, kind="mianmian", extras={"sparkle": 0})
    out["way_adult"] = c.svg()
    return out


# ---------------------------------------------------------------- the doors
def door(kind):
    c = Ctx(120, 120)
    if kind == "faces":
        mianmian.draw(c, "happy", x=40, y=58, s=.36, extras={"sparkle": 0})
        mianmian.draw(c, "sad", x=82, y=72, s=.32)
        mianmian.draw(c, "surprised", x=60, y=34, s=.26, extras={"pop": 0})
    elif kind == "story":
        # an open book with a little car on the page
        left = kit.Shape([("M", 60, 52), ("C", 46, 42, 26, 40, 12, 44), ("L", 12, 96), ("C", 26, 92, 46, 94, 60, 104), ("Z",)])
        right = left.flip(60)
        c.mallow(left + right, CREAM, lift=.7)
        c.stroke(kit.path([(60, 54), (60, 102)]), kit.SAND, 3)
        for x0, x1, y in ((20, 50, 58), (20, 46, 68), (70, 100, 58), (74, 100, 68)):
            c.stroke(kit.path([(x0, y), (x1, y + 2)]), kit.SAND, 3)
        c.mallow(rrect(30, 22, 50, 22, 10) + rrect(42, 12, 26, 16, 8), ROSE, shadow=False)
        c.mallow(circle(42, 46, 7) + circle(70, 46, 7), "#7A6E8C", shadow=False)
        c.flat(rrect(46, 15, 18, 9, 3), BLUE)
    elif kind == "calm":
        balloon(c, 48, 42, 28)
        balloon(c, 80, 56, 18, MINT, face=False)
    elif kind == "help":
        mianmian.draw(c, "calm", x=44, y=64, s=.36, extras={})
        mianmian.draw(c, "happy", x=80, y=70, s=.3, kind="xiaoyu", extras={"sparkle": 0})
        c.mallow(heart(62, 22, 22), ROSE, shadow=False)
    elif kind == "diary":
        c.mallow(rrect(22, 14, 76, 92, 14), LILAC, lift=.7)
        c.mallow(rrect(30, 20, 64, 80, 10), CREAM, shadow=False)
        c.flat(rrect(22, 14, 12, 92, 6), kit.dk(LILAC, .1))
        cols = [YELLOW, BLUE, kit.CORAL, MINT, PINK, lt(LILAC, .1)]
        for i in range(6):
            x, y = 46 + (i % 3) * 18, 38 + (i // 3) * 30
            c.mallow(circle(x - 4, y, 6) + circle(x + 4, y - 2, 6) + rrect(x - 9, y - 2, 18, 9, 4.5), cols[i], shadow=False, shade=False)
            c.dots([(x - 3, y + 1), (x + 3, y + 1)], 1.1, INK, op=.8)
    return c.svg()


def cloud_small():
    """A diary day nothing was written on: a pale dashed-looking cloud (dots round a cloud)."""
    c = Ctx(60, 50)
    c.mallow(kit.puffs(30, 30, 44, 30, n=3, key="day"), "#EDE7F5", shadow=False, shade=False, op=.7)
    return c.svg()


def build():
    n = 0
    for name, text in calm_files().items():
        kit.write_svg(CALM / f"{name}.svg", text)
        n += 1
    for kind in ("faces", "story", "calm", "help", "diary"):
        kit.write_svg(ICONS / f"door_{kind}.svg", door(kind))
        n += 1
    kit.write_svg(ICONS / "cloud_small.svg", cloud_small())
    print(f"props: {n + 1} files")


if __name__ == "__main__":
    build()
