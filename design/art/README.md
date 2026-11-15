# design/art：心情小屋的圖（棉花糖雲朵風）

Every picture is a soft marshmallow lump: a pastel shape lit from the top left (a radial gradient), a
white sheen on its top half, a faint shade at its bottom and a soft shadow made of three see-through
copies (flutter_svg has no blur). No outlines anywhere. The contract with the app is `docs/art.md`.

## Draw
```python
import kit
c = kit.Ctx(120, 100)                               # viewBox 0 0 120 100
c.mallow(kit.rrect(8, 20, 100, 60, 24), kit.MINT)   # shadow + lit body + sheen + shade
c.mallow(kit.circle(60, 30, 12), kit.PINK, shadow=False)
c.flat(kit.circle(60, 30, 4), kit.WHITE, op=.8)     # flat paint
c.glow(60, 30, 40, "#FFE08A", .5)                   # a soft light
c.face(60, 50, 10, "happy")                         # happy / smile / calm / sleepy
kit.write_svg(path, c.svg())                        # checks the rules, then writes
```
Shapes: `rrect ellipse circle poly smooth blob cloud puffs star heart path arc`; `+` is a union.
Colours: `INK PINK ROSE YELLOW PEACH MINT BLUE LILAC GREEN CORAL SAND CREAM WHITE CHEEK MOUTH` and
`lt dk mix tone`. Randomness only via `kit.rnd(key)`.

棉棉 and the other clouds: `mianmian.draw(c, "sad", x, y, s, kind="xiaoyu")` reads the numbers in
`app/lib/core/looks.dart` (the app's CustomPainter draws from the same numbers).

## Commands (run in this folder)
```
python3 build.py all                    # house.py, props.py, scenes.py, then check
python3 build.py sheet OUT.png [dir]    # a contact sheet (house / calm / icons / stories)
python3 build.py fluttercheck           # real flutter_svg vs Chromium (~15 s)
python3 mianmian.py sheet OUT.png       # every feeling of 棉棉, 小雨, a grown-up, a friend
python3 icon.py preview OUT.png         # the app icon, with the sibling apps' icons
python3 icon.py export                  # the Android and iOS icons
```
Look at the sheet (Read tool) after every change. Deterministic: build twice, same bytes. No
`__pycache__` (every script sets `sys.dont_write_bytecode`). Do not run git here.
