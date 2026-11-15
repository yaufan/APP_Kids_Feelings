"""The little house and its sky (app/assets/art/house/): the house in the day and with its lights on,
the sun with a face, the moon, the cloud ground things stand on, a soft background cloud.

    python3 build.py house
"""
import sys

sys.dont_write_bytecode = True

import math  # noqa: E402

import kit  # noqa: E402
from kit import (BLUE, CREAM, INK, LILAC, MINT, PEACH, PINK, ROSE, WHITE, YELLOW, Ctx, circle, ellipse, lt, poly,  # noqa: E402
                 rrect, smooth)

OUT = kit.ART / "house"


def house(lit=False):
    """300 x 260: cream walls, a soft pink roof, a round window, two curtained windows, a peach door."""
    c = Ctx(300, 260)
    win = "#FFE7A3" if lit else BLUE
    if lit:
        c.glow(150, 150, 150, "#FFE7A3", .45)
    # chimney and its little cloud
    c.mallow(rrect(200, 40, 30, 50, 10), ROSE)
    c.mallow(circle(222, 30, 11) + circle(236, 18, 9) + circle(212, 22, 8), WHITE, shadow=False)
    # walls
    c.mallow(rrect(48, 104, 204, 130, 30), CREAM, lift=1.4)
    # roof: a soft triangle
    roof = smooth([(30, 118), (150, 28), (270, 118), (150, 128)], .35)
    c.mallow(roof, PINK, lift=1.2)
    c.flat(ellipse(120, 70, 40, 12).rotate(-35, 120, 70), WHITE, op=.35)
    # round window under the roof
    c.mallow(circle(150, 88, 18), win, shadow=False)
    c.stroke(kit.path([(136, 88), (164, 88)]), WHITE, 3, op=.9)
    c.stroke(kit.path([(150, 74), (150, 102)]), WHITE, 3, op=.9)
    # two windows with curtains
    for x in (72, 192):
        c.mallow(rrect(x, 128, 40, 36, 12), LILAC, shadow=False)
        c.mallow(rrect(x + 5, 133, 30, 26, 9), win, shadow=False, sheen=True)
        c.flat(ellipse(x + 20, 135, 16, 7), WHITE, op=.95)
        if lit:
            c.glow(x + 20, 146, 30, "#FFE08A", .35)
    # the door
    door = rrect(124, 156, 52, 78, 8) + circle(150, 162, 26)
    c.mallow(door, PEACH, shadow=False)
    c.flat(circle(165, 196, 4), "#E0906A")
    c.face(150, 182, 7, "calm" if lit else "smile", blush=.5)
    # doormat and two flowers
    c.mallow(ellipse(150, 238, 56, 9), MINT, shadow=False)
    for x, col in ((70, ROSE), (232, YELLOW)):
        c.stroke(kit.path([(x, 236), (x, 214)]), "#9BCB7E", 4)
        c.mallow(circle(x, 210, 9), col, shadow=False)
        c.flat(circle(x, 210, 3.5), WHITE, op=.9)
    return c.svg()


def sun():
    """120 x 120: a round sun with soft round rays and a happy face."""
    c = Ctx(120, 120)
    c.glow(60, 60, 58, "#FFE9A8", .7)
    for i in range(8):
        a = math.radians(i * 45)
        c.mallow(circle(60 + 44 * math.cos(a), 60 + 44 * math.sin(a), 6), "#FFD36B", shadow=False, shade=False)
    c.mallow(circle(60, 60, 32), YELLOW, shadow=False)
    c.face(60, 56, 10, "happy")
    return c.svg()


def moon():
    """100 x 100: a sleepy crescent moon with two little stars."""
    c = Ctx(100, 100)
    c.glow(48, 50, 48, "#FFF1B8", .5)
    moon = smooth([(52, 14), (74, 26), (82, 52), (66, 80), (40, 86), (24, 76), (44, 72), (58, 54), (56, 32)], .5)
    c.mallow(moon, "#FFE9A8", shadow=False)
    c.stroke(kit.arc(70, 48, 4, 20, 160), INK, 2.2)
    c.flat(ellipse(73, 57, 4, 2.5), kit.CHEEK, op=.6)
    c.sparkle(22, 26, 6, "#FFF1B8")
    c.sparkle(84, 84, 4, "#FFF1B8")
    return c.svg()


def ground():
    """400 x 110: the soft cloud ground (house, 棉棉 and the stage stand on it)."""
    c = Ctx(400, 110)
    g = rrect(10, 30, 380, 66, 33)
    for x, r in ((40, 30), (100, 38), (170, 34), (240, 40), (310, 34), (362, 28)):
        g = g + circle(x, 44, r)
    c.mallow(g, "#FBF7FF", lift=.6)
    return c.svg()


def puff():
    """300 x 120: a soft background cloud (drawn see-through over the sky)."""
    c = Ctx(300, 120)
    s = kit.puffs(150, 70, 260, 90, n=5, key="sky")
    c.mallow(s, WHITE, shadow=False, shade=False)
    return c.svg()


def build():
    out = {"house": house(), "house_lit": house(lit=True), "sun": sun(), "moon": moon(), "ground": ground(), "puff": puff()}
    for name, text in out.items():
        kit.write_svg(OUT / f"{name}.svg", text)
    print(f"house: {len(out)} files")


if __name__ == "__main__":
    build()
