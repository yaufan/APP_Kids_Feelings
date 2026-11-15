"""The little stories' pictures (app/assets/art/stories/): seven backgrounds (400 x 300, the app shows
them 4:3) and the things placed on them (lib/core/stories.dart's Prop: middle x, bottom y, width as
fractions of the picture; each prop file is drawn with its bottom at the bottom of its viewBox).
The clouds (小雨, the grown-ups, the friends) are painted by the app on top.

bg_<home|school|park|night|clinic|market|rain>; car, car_broken, blocks, blocks_fallen, slide,
door_open, table, milk, backpack, bandage, cake, gift, cart, drawing, robot, bed.

    python3 build.py scenes
"""
import sys

sys.dont_write_bytecode = True

import math  # noqa: E402

import kit  # noqa: E402
from kit import (BLUE, CORAL, CREAM, INK, LILAC, MINT, PEACH, PINK, ROSE, WHITE, YELLOW, Ctx, circle, ellipse, lt,  # noqa: E402
                 poly, rect, rrect, smooth)

OUT = kit.ART / "stories"
W, H = 400, 300
FLOOR = 214          # where the wall meets the floor


# ---------------------------------------------------------------- backgrounds
def room(c, wall_top, wall_bottom, floor_top, floor_bottom):
    c.fill(rect(0, 0, W, FLOOR + 6), c.linear(0, 0, 0, FLOOR, [(0, wall_top, 1), (1, wall_bottom, 1)]))
    c.fill(rect(0, FLOOR, W, H - FLOOR), c.linear(0, FLOOR, 0, H, [(0, floor_top, 1), (1, floor_bottom, 1)]))
    c.fill(rect(0, FLOOR - 2, W, 10), c.linear(0, FLOOR - 2, 0, FLOOR + 8, [(0, kit.SHADE, .10), (1, kit.SHADE, 0)]))


def window(c, x, y, w, h, sky_top, sky_bottom, frame=WHITE, curtains=PINK, extra=None):
    c.mallow(rrect(x - 8, y - 8, w + 16, h + 16, 18), frame, lift=.5)
    c.fill(rrect(x, y, w, h, 12), c.linear(0, y, 0, y + h, [(0, sky_top, 1), (1, sky_bottom, 1)]))
    if extra:
        extra(c)
    c.stroke(kit.path([(x + w / 2, y + 2), (x + w / 2, y + h - 2)]), frame, 5)
    c.stroke(kit.path([(x + 2, y + h / 2), (x + w - 2, y + h / 2)]), frame, 5)
    if curtains:
        for side in (0, 1):
            cx = x - 6 if side == 0 else x + w + 6
            cur = smooth([(cx - 14, y - 12), (cx + 14, y - 12), (cx + 12, y + h * .5), (cx + 18, y + h + 10), (cx - 12, y + h + 12), (cx - 10, y + h * .5)], .5)
            c.mallow(cur, curtains, shadow=False)


def plant(c, x, y, s=1.0):
    c.mallow(rrect(x - 14 * s, y - 26 * s, 28 * s, 26 * s, 8 * s), PEACH)
    for dx, dy, r in ((-10, -40, 13), (8, -46, 14), (0, -58, 12), (-2, -32, 10)):
        c.mallow(circle(x + dx * s, y + dy * s, r * s), "#B6DE9C", shadow=False)


def sky_clouds(c, pts, op=.75):
    for i, (x, y, w) in enumerate(pts):
        c.mallow(kit.puffs(x, y, w, w * .4, n=4, key=f"bg{i}{x}"), WHITE, shadow=False, shade=False, op=op)


def bg_home():
    c = Ctx(W, H)
    room(c, "#FFEFF3", "#FFE3EA", "#F6DDBF", "#EFCFAE")
    window(c, 46, 46, 110, 92, "#CFE8FF", "#EAF5FF", extra=lambda c: sky_clouds(c, [(84, 76, 50)]))
    c.mallow(rrect(250, 64, 72, 54, 14), LILAC, lift=.4)             # a picture on the wall
    c.mallow(circle(286, 88, 12), YELLOW, shadow=False)
    c.mallow(ellipse(200, 262, 150, 22), "#E6D8F7", shadow=False)       # a rug
    plant(c, 360, FLOOR + 12)
    return c.svg()


def bg_school():
    c = Ctx(W, H)
    room(c, "#E8F7EF", "#DDF1E6", "#F3D9B4", "#E9C79E")
    c.mallow(rrect(40, 40, 170, 104, 16), "#FFF6DD", lift=.5)          # the board with drawings
    for i, (x, y, col) in enumerate(((56, 56, PINK), (106, 52, BLUE), (154, 60, YELLOW), (70, 96, MINT), (126, 94, PEACH))):
        c.mallow(rrect(x, y, 40, 34, 8), col, shadow=False)
        c.flat(circle(x + 20, y + 15, 7), WHITE, op=.7)
    # a garland of little flags
    pts = [(230 + i * 20, 46 + 10 * math.sin(i / 8 * math.pi)) for i in range(9)]
    c.stroke(kit.path(pts), kit.SOFT, 2, op=.6)
    for i, (x, y) in enumerate(pts[:-1]):
        c.mallow(poly([(x + 3, y + 2), (x + 17, y + 2), (x + 10, y + 18)]), [PINK, YELLOW, BLUE, MINT][i % 4], shadow=False, shade=False)
    c.mallow(rrect(268, 116, 112, 98, 14), "#F7DDB9", lift=.6)          # cubbies
    for r in range(2):
        for col in range(3):
            c.mallow(rrect(276 + col * 34, 124 + r * 44, 28, 36, 8), "#FFF1DA", shadow=False, sheen=False)
    return c.svg()


def bg_park():
    c = Ctx(W, H)
    c.fill(rect(0, 0, W, H), c.linear(0, 0, 0, H, [(0, "#DDEBFF", 1), (1, "#FFF2E4", 1)]))
    sky_clouds(c, [(70, 50, 90), (300, 40, 110)])
    c.mallow(ellipse(60, 230, 180, 70), "#CDEBB4", shadow=False)
    c.mallow(ellipse(340, 226, 190, 74), "#C3E5A8", shadow=False)
    c.fill(rect(0, 228, W, 72), c.linear(0, 228, 0, H, [(0, "#C8E8AE", 1), (1, "#B5DC97", 1)]))
    for x, y, s in ((40, 150, 1.0), (360, 140, 1.15)):
        c.mallow(rrect(x - 7 * s, y, 14 * s, 70 * s, 6), "#D9B48F", shadow=False)
        c.mallow(circle(x, y - 6 * s, 30 * s) + circle(x - 22 * s, y + 10 * s, 22 * s) + circle(x + 22 * s, y + 10 * s, 22 * s), "#A9D98C", shadow=False)
    c.mallow(ellipse(200, 268, 120, 16), "#F2E2C2", shadow=False, shade=False)
    for x, col in ((120, PINK), (290, YELLOW), (250, LILAC)):
        c.mallow(circle(x, 246, 5), col, shadow=False)
    return c.svg()


def bg_night():
    c = Ctx(W, H)
    room(c, "#8A84C4", "#A39CD2", "#B9A7CF", "#A897C2")
    c.glow(110, 70, 120, "#FFE9A8", .18)
    def stars(c):
        c.mallow(circle(98, 70, 14), "#FFE9A8", shadow=False)
        c.flat(circle(104, 66, 12), "#5C5A9A")
        for x, y, r in ((60, 60, 4), (136, 54, 3), (124, 100, 3.5), (74, 108, 3)):
            c.sparkle(x, y, r, "#FFF1B8")
    window(c, 50, 40, 112, 88, "#4E4C8E", "#6D68AA", frame="#CFC6EE", curtains="#C7B7EA", extra=stars)
    c.glow(330, 196, 50, "#FFE08A", .5)                                 # a night light
    c.mallow(circle(330, 200, 14), "#FFE9A8", shadow=False)
    c.mallow(rrect(318, 210, 24, 8, 3), LILAC, shadow=False)
    return c.svg()


def bg_clinic():
    c = Ctx(W, H)
    room(c, "#E7F3FC", "#DCEDF9", "#E8E4F3", "#DAD4EC")
    c.mallow(rrect(40, 70, 90, 140, 14), WHITE, lift=.6)                 # a cabinet
    c.mallow(rrect(72, 92, 26, 8, 3) + rrect(81, 83, 8, 26, 3), ROSE, shadow=False)
    c.mallow(rrect(52, 130, 66, 28, 8) + rrect(52, 166, 66, 28, 8), "#F2F6FB", shadow=False, sheen=False)
    c.mallow(rrect(250, 50, 90, 70, 14), "#FFF6DD", lift=.4)              # an eye chart, in pictures
    for i, (x, y, r) in enumerate(((272, 70, 9), (300, 70, 9), (322, 70, 9), (282, 98, 6), (300, 98, 6), (318, 98, 6))):
        c.flat(circle(x, y, r), [PINK, BLUE, YELLOW, MINT, LILAC, PEACH][i])
    plant(c, 186, FLOOR + 10, .9)
    return c.svg()


def bg_market():
    c = Ctx(W, H)
    room(c, "#FFF4E0", "#FFEBD0", "#E9E3F2", "#DCD3EA")
    for sx in (20, 214):
        c.mallow(rrect(sx, 50, 166, 164, 12), "#F3D7B4", lift=.5)
        for r in range(3):
            c.mallow(rrect(sx + 8, 62 + r * 50, 150, 8, 4), "#E2BF95", shadow=False, sheen=False)
            for k in range(5):
                col = [ROSE, YELLOW, "#B6DE9C", PEACH, BLUE][(k + r + sx) % 5]
                c.mallow(circle(sx + 24 + k * 30, 50 + r * 50, 11), col, shadow=False)
    return c.svg()


def bg_rain():
    c = Ctx(W, H)
    room(c, "#EAF0FA", "#DFE8F6", "#F2DEC4", "#E8CFB0")

    def rain(c):
        sky_clouds(c, [(170, 70, 110), (250, 64, 90)], op=.6)
        for i in range(16):
            x = 104 + (i * 37) % 200
            y = 92 + (i * 53) % 110
            c.stroke(kit.path([(x, y), (x - 4, y + 12)]), "#7FA6D9", 3, op=.7)
    window(c, 100, 46, 200, 150, "#AFC0D8", "#C9D6E8", curtains=BLUE, extra=rain)
    c.mallow(ellipse(200, 262, 140, 20), "#D7E6F7", shadow=False)
    c.mallow(rrect(330, 168, 34, 46, 12), "#F6C3CF", lift=.5)             # rain boots by the wall
    c.mallow(rrect(356, 172, 30, 42, 12), "#F6C3CF", lift=.5)
    return c.svg()


# ---------------------------------------------------------------- the things in the stories
def prop(w, h):
    return Ctx(w, h)


def car(broken=False):
    c = prop(140, 90)
    body = smooth([(14, 66), (14, 46), (34, 42), (48, 20), (92, 20), (106, 42), (126, 46), (126, 66)], .35)
    if not broken:
        c.mallow(body, "#F28B9B", lift=.5)
        c.mallow(rrect(56, 26, 30, 16, 5), "#D7ECFF", shadow=False, sheen=False)
        for x in (38, 102):
            c.mallow(circle(x, 70, 14), "#7A6E8C", shadow=False)
            c.flat(circle(x, 70, 5), "#D9D3E3")
        c.flat(circle(120, 54, 4), YELLOW)
        return c.svg()
    left = body.move(-6, 4).rotate(-8, 60, 66)
    right = body.move(14, 6).rotate(12, 80, 66)
    c.begin()
    c.mallow(kit.Shape(left.cmds), "#F28B9B", lift=.4)
    c.end()
    c.mallow(rrect(18, 54, 60, 18, 8), "#F28B9B", shadow=False)
    c.mallow(rrect(84, 50, 48, 20, 8), "#F28B9B")
    c.mallow(circle(34, 74, 13), "#7A6E8C", shadow=False)
    c.mallow(circle(122, 76, 13), "#7A6E8C")
    c.flat(circle(34, 74, 5) + circle(122, 76, 5), "#D9D3E3")
    for x0, y0, x1, y1 in ((78, 30, 74, 18), (84, 28, 86, 14), (90, 32, 98, 22)):
        c.stroke(kit.path([(x0, y0), (x1, y1)]), "#9D8BCB", 3)
    return c.svg()


def blocks(fallen=False):
    c = prop(140, 120)
    cols = [PINK, BLUE, YELLOW, MINT, LILAC, PEACH]
    if not fallen:
        for i, (x, y) in enumerate(((22, 82), (64, 82), (43, 46), (98, 82), (82, 46), (62, 10))):
            c.mallow(rrect(x, y, 34, 34, 9), cols[i], lift=.5)
            c.flat(circle(x + 17, y + 17, 6), WHITE, op=.6)
        return c.svg()
    for i, (x, y, a) in enumerate(((10, 84, -12), (50, 88, 8), (90, 82, 20), (30, 60, 30), (98, 52, -18), (64, 64, 40))):
        s = rrect(x, y, 32, 32, 9).rotate(a, x + 16, y + 16)
        c.mallow(s, cols[i], lift=.4)
    return c.svg()


def slide():
    c = prop(200, 240)
    c.mallow(rrect(26, 40, 14, 196, 6) + rrect(64, 40, 14, 196, 6), "#F3C38E", lift=.6)       # the ladder
    for y in range(64, 230, 30):
        c.mallow(rrect(34, y, 36, 8, 4), "#F3C38E", shadow=False)
    c.mallow(rrect(16, 26, 76, 22, 10), PEACH)                                                  # the top
    chute = kit.Shape([("M", 82, 30), ("C", 120, 40, 150, 150, 192, 220), ("L", 192, 238), ("L", 170, 238),
                       ("C", 140, 170, 112, 70, 82, 56), ("Z",)])
    c.mallow(chute, "#9EDBC8", lift=.8)
    return c.svg()


def door_open():
    c = prop(120, 200)
    c.mallow(rrect(6, 6, 108, 194, 18), "#F6E3CB", lift=.6)
    c.fill(rrect(16, 16, 88, 184, 12), c.linear(0, 16, 0, 200, [(0, "#FFF6D8", 1), (1, "#FFE9B6", 1)]))
    door = kit.poly([(16, 16), (52, 26), (52, 196), (16, 200)])
    c.mallow(door, PEACH, shadow=False)
    c.flat(circle(44, 112, 4), "#E0906A")
    return c.svg()


def table():
    c = prop(200, 120)
    c.mallow(rrect(40, 40, 14, 80, 6) + rrect(146, 40, 14, 80, 6), "#E7C9A5", lift=.6)
    c.mallow(ellipse(100, 36, 96, 24), "#F2D6B3", lift=.6)
    return c.svg()


def milk():
    c = prop(120, 80)
    c.mallow(smooth([(10, 70), (40, 60), (80, 64), (112, 70), (96, 78), (30, 78)], .6), WHITE, lift=.3)   # the spill
    cup_ = rrect(30, 20, 34, 46, 10).rotate(-75, 47, 43)
    c.mallow(cup_, BLUE, lift=.4)
    c.mallow(ellipse(70, 52, 8, 13).rotate(-75, 70, 52), WHITE, shadow=False)
    for x, y in ((90, 50), (100, 58)):
        c.mallow(circle(x, y, 4), WHITE, shadow=False)
    return c.svg()


def backpack():
    c = prop(100, 120)
    c.stroke(kit.arc(50, 30, 20, 190, 350), kit.dk(YELLOW, .15), 7)
    c.mallow(rrect(14, 24, 72, 94, 22), YELLOW, lift=.6)
    c.mallow(rrect(24, 66, 52, 38, 12), lt(YELLOW, .3), shadow=False)
    c.face(50, 44, 7, "smile")
    return c.svg()


def bandage():
    c = prop(80, 60)
    b = rrect(4, 18, 72, 26, 13).rotate(-18, 40, 31)
    c.mallow(b, "#F7D7C4", lift=.4)
    c.mallow(rrect(28, 22, 24, 18, 6).rotate(-18, 40, 31), "#FBE9DE", shadow=False)
    c.mallow(kit.heart(40, 30, 10), ROSE, shadow=False)
    return c.svg()


def cake():
    c = prop(120, 130)
    c.mallow(ellipse(60, 118, 52, 10), WHITE, shadow=False)
    c.mallow(rrect(16, 64, 88, 52, 18), PINK, lift=.6)
    c.mallow(smooth([(16, 72), (40, 64), (60, 70), (82, 62), (104, 72), (104, 84), (90, 80), (74, 90), (56, 80), (38, 90), (16, 82)], .5), CREAM, shadow=False)
    c.mallow(rrect(55, 34, 10, 30, 4), BLUE, shadow=False)
    c.glow(60, 28, 16, "#FFE08A", .7)
    c.mallow(smooth([(60, 14), (66, 26), (60, 34), (54, 26)], .6), "#FFC96B", shadow=False)
    for x, y, col in ((32, 96, YELLOW), (60, 102, MINT), (86, 96, LILAC)):
        c.flat(circle(x, y, 4), col)
    return c.svg()


def gift():
    c = prop(100, 100)
    c.mallow(rrect(12, 40, 76, 58, 12), MINT, lift=.6)
    c.mallow(rrect(6, 30, 88, 20, 8), lt(MINT, .2), shadow=False)
    c.mallow(rrect(44, 30, 12, 68, 4), PINK, shadow=False)
    c.mallow(ellipse(36, 22, 14, 9).rotate(-20, 36, 22) + ellipse(64, 22, 14, 9).rotate(20, 64, 22), PINK, shadow=False)
    c.mallow(circle(50, 26, 6), ROSE, shadow=False)
    return c.svg()


def cart():
    c = prop(140, 120)
    c.stroke(kit.path([(8, 18), (26, 22), (40, 82), (116, 82)]), "#B9A7D9", 6)
    c.mallow(kit.poly([(28, 30), (126, 30), (114, 76), (40, 76)]), "#D7ECFF", lift=.5)
    for x in range(42, 124, 16):
        c.stroke(kit.path([(x, 34), (x - 2, 72)]), WHITE, 2.5, op=.8)
    c.mallow(circle(54, 52, 12) + circle(80, 48, 12), ROSE, shadow=False)
    c.mallow(circle(100, 50, 11), YELLOW, shadow=False)
    c.mallow(circle(50, 100, 11) + circle(108, 100, 11), "#7A6E8C", shadow=False)
    return c.svg()


def drawing():
    c = prop(100, 90)
    c.mallow(rrect(4, 4, 92, 82, 12), "#F6E0C2", lift=.5)
    c.fill(rrect(12, 12, 76, 66, 8), c.linear(0, 12, 0, 78, [(0, "#FFFDF6", 1), (1, "#FFF3DE", 1)]))
    c.mallow(circle(32, 32, 10), YELLOW, shadow=False)
    c.stroke(kit.path([(62, 70), (62, 46)]), "#9BCB7E", 3)
    c.mallow(circle(62, 42, 8) + circle(54, 48, 6) + circle(70, 48, 6), ROSE, shadow=False)
    c.stroke(kit.path([(14, 72), (86, 72)]), "#B6DE9C", 4)
    return c.svg()


def robot():
    c = prop(70, 100)
    c.stroke(kit.path([(35, 14), (35, 4)]), "#9D8BCB", 3)
    c.mallow(circle(35, 4, 4), CORAL, shadow=False)
    c.mallow(rrect(12, 12, 46, 36, 12), LILAC, lift=.5)
    c.flat(circle(26, 28, 4) + circle(44, 28, 4), INK)
    c.mallow(rrect(16, 50, 38, 34, 10), BLUE, lift=.5)
    c.mallow(rrect(18, 84, 12, 14, 5) + rrect(40, 84, 12, 14, 5), LILAC, shadow=False)
    c.mallow(circle(35, 64, 6), YELLOW, shadow=False)
    return c.svg()


def bed():
    c = prop(220, 130)
    c.mallow(rrect(6, 30, 24, 100, 10), "#E7C9A5", lift=.6)           # headboard
    c.mallow(rrect(10, 74, 206, 40, 14), "#F2D6B3", lift=.6)          # frame
    c.mallow(rrect(14, 60, 198, 26, 12), WHITE, shadow=False)         # mattress
    c.mallow(ellipse(56, 58, 30, 15), "#FFF6E8", shadow=False)        # pillow
    c.mallow(rrect(80, 52, 132, 36, 16), LILAC, shadow=False)         # blanket
    c.dots([(110, 66), (140, 74), (170, 64), (196, 72)], 4, WHITE, op=.7)
    return c.svg()


PROPS = {
    "car": lambda: car(), "car_broken": lambda: car(True), "blocks": lambda: blocks(), "blocks_fallen": lambda: blocks(True),
    "slide": slide, "door_open": door_open, "table": table, "milk": milk, "backpack": backpack, "bandage": bandage,
    "cake": cake, "gift": gift, "cart": cart, "drawing": drawing, "robot": robot, "bed": bed,
}
BGS = {"home": bg_home, "school": bg_school, "park": bg_park, "night": bg_night, "clinic": bg_clinic, "market": bg_market,
       "rain": bg_rain}


def build():
    for name, f in BGS.items():
        kit.write_svg(OUT / f"bg_{name}.svg", f(), (W, H))
    for name, f in PROPS.items():
        kit.write_svg(OUT / f"{name}.svg", f())
    print(f"scenes: {len(BGS)} backgrounds, {len(PROPS)} things")


if __name__ == "__main__":
    build()
