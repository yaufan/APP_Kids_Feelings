import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/feelings.dart';
import '../core/looks.dart';
import '../core/stories.dart';

/// The colours of the faces (design/art/kit.py and mianmian.py use the same).
abstract final class FaceInk {
  static const ink = Color(0xFF4A3F5C);
  static const cheek = Color(0xFFFF9FB0);
  static const mouth = Color(0xFFB5405C);
  static const tongue = Color(0xFFF28BA0);
  static const tear = Color(0xFF6AA6EC);
  static const shade = Color(0xFF5A4A6E);
  static const gold = Color(0xFFFFD54F);
}

Color _lt(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color _dk(Color c, double t) => Color.lerp(c, FaceInk.shade, t)!;

/// Paints 棉棉 (or 小雨, a grown-up, a friend) from a [Look]: the cloud body
/// made of puffs, lit softly from the top left like a marshmallow, and the
/// face drawn from its numbers (docs/art.md: 棉棉 is not a picture). The box
/// is 200 × 180 cloud units, the cloud's middle at (100, 110), its bottom
/// near y = 154. design/art/mianmian.py draws the same thing as SVG.
class CloudPainter extends CustomPainter {
  CloudPainter(this.look, {this.kind = CloudKind.mianmian, this.browLift = 0, this.squash = 0, this.shadow = true});

  final Look look;
  final CloudKind kind;

  /// Lifts the eyebrows (the hint after a wrong card: 「再看看我的眉毛」).
  final double browLift;

  /// Squashes the cloud (a pillow thump, a hug): -1..1.
  final double squash;
  final bool shadow;

  static const box = Size(200, 180);
  static const middle = Offset(100, 110);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / box.width;
    canvas.save();
    canvas.scale(k);
    canvas.translate(middle.dx, middle.dy);
    final l = look;
    final ex = l.extras;
    if ((ex[Extra.shake] ?? 0) > 0) _shake(canvas, ex[Extra.shake]!);
    if (shadow) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 46), width: 104, height: 16),
        Paint()..shader = ui.Gradient.radial(const Offset(0, 46), 52, [FaceInk.shade.withValues(alpha: .22), FaceInk.shade.withValues(alpha: 0)]),
      );
    }
    canvas.save();
    if (squash != 0) {
      canvas.translate(0, 44);
      canvas.scale(1 + squash * .12, 1 - squash * .14);
      canvas.translate(0, -44);
    }
    final body = Path();
    for (final p in l.puffs) {
      body.addPath(puffPath(p), Offset.zero);
    }
    _mallow(canvas, body, l.color);
    final top = l.top;
    switch (kind) {
      case CloudKind.mianmian:
        final tuft = Path()
          ..addOval(Rect.fromCenter(center: Offset(-6, top - 1), width: 18, height: 14))
          ..addOval(Rect.fromCenter(center: Offset(4, top - 7), width: 14, height: 12));
        _mallow(canvas, tuft, _lt(l.color, .25), shade: false);
      case CloudKind.xiaoyu:
        _mallow(canvas, dropPath(0, top - 20, 14, 20), const Color(0xFF7FB3EA), shade: false);
      case CloudKind.pal:
        for (final s in const [-1.0, 1.0]) {
          _mallow(canvas, Path()..addOval(Rect.fromCircle(center: Offset(s * 34, top + 14), radius: 9)), _lt(l.color, .3), shade: false);
        }
      case CloudKind.baby:
        _mallow(canvas, Path()..addOval(Rect.fromCircle(center: Offset(0, top - 3), radius: 6)), _lt(l.color, .3), shade: false);
      case CloudKind.grownup:
        break;
    }
    _face(canvas);
    _extras(canvas);
    canvas.restore();
    canvas.restore();
  }

  /// One puff: an ellipse whose top can be pulled to a point.
  static Path puffPath(Puff p) {
    const kk = 0.5522847498;
    final rx = p.rx, ry = p.ry, tip = p.tip;
    final top = -ry * (1 + .25 * tip);
    final kt = kk * (1 - tip);
    final side = ry * kk * (1 - .5 * tip);
    final path = Path()
      ..moveTo(rx, 0)
      ..cubicTo(rx, ry * kk, rx * kk, ry, 0, ry)
      ..cubicTo(-rx * kk, ry, -rx, ry * kk, -rx, 0)
      ..cubicTo(-rx, -side, -rx * kt, top, 0, top)
      ..cubicTo(rx * kt, top, rx, -side, rx, 0)
      ..close();
    final m = Matrix4.identity()
      ..translateByDouble(p.x, p.y, 0, 1)
      ..rotateZ(p.rot * math.pi / 180);
    return path.transform(m.storage);
  }

  /// A water drop pointing up: the tip at (x, y).
  static Path dropPath(double x, double y, double w, double h) {
    const kk = 0.5522847498;
    final r = w / 2, cy = y + h - r;
    return Path()
      ..moveTo(x, y)
      ..cubicTo(x + r * .4, y + h * .35, x + r, cy - r * .6, x + r, cy)
      ..cubicTo(x + r, cy + r * kk, x + r * kk, cy + r, x, cy + r)
      ..cubicTo(x - r * kk, cy + r, x - r, cy + r * kk, x - r, cy)
      ..cubicTo(x - r, cy - r * .6, x - r * .4, y + h * .35, x, y)
      ..close();
  }

  /// A soft lump: lit from the top left, a white sheen on top, a faint shade below.
  static void _mallow(Canvas canvas, Path path, Color col, {bool shade = true, double opacity = 1}) {
    final b = path.getBounds();
    final r = math.max(b.width, b.height) * .82;
    Color a(Color c) => c.withValues(alpha: c.a * opacity);
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.radial(Offset(b.left + b.width * .34, b.top + b.height * .28), r, [a(_lt(col, .45)), a(col), a(_dk(col, .12))], [0, .62, 1]),
    );
    canvas.drawPath(path, Paint()..shader = ui.Gradient.linear(b.topCenter, b.bottomCenter, [Colors.white.withValues(alpha: .5 * opacity), Colors.white.withValues(alpha: 0)], [0, .48]));
    if (shade) {
      canvas.drawPath(path, Paint()..shader = ui.Gradient.linear(b.topCenter, b.bottomCenter, [FaceInk.shade.withValues(alpha: 0), FaceInk.shade.withValues(alpha: .14 * opacity)], [.55, 1]));
    }
  }

  static Paint _line(Color c, double w, double op) => Paint()
    ..color = c.withValues(alpha: (c.a * op).clamp(0, 1))
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Paint _fill(Color c, double op) => Paint()..color = c.withValues(alpha: (c.a * op).clamp(0, 1));

  static List<Offset> _quad(Offset p0, Offset c, Offset p1, [int steps = 16]) => [
        for (var i = 0; i <= steps; i++)
          () {
            final t = i / steps;
            return p0 * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + p1 * (t * t);
          }(),
      ];

  static Path _poly(List<Offset> pts, {bool close = false}) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    if (close) p.close();
    return p;
  }

  void _face(Canvas canvas) {
    final l = look;
    final ey = Look.eyeY + l.faceY;
    final lk = l.look;
    const ink = FaceInk.ink;
    if (l.browOn > 0) {
      for (final s in const [-1.0, 1.0]) {
        final bx = s * Look.eyeX + lk;
        final yi = ey - 17 - l.brow * .22 - browLift, yo = ey - 17 + l.brow * .22 - browLift;
        canvas.drawPath(_poly(_quad(Offset(bx - s * 8, yi), Offset(bx, (yi + yo) / 2 - 3), Offset(bx + s * 8, yo))), _line(ink, 3.4, l.browOn));
      }
    }
    final r = l.eyeR;
    final round = math.max(0.0, 1 - l.eyeArc - l.eyeShut);
    for (final s in const [-1.0, 1.0]) {
      final ex = s * Look.eyeX + lk;
      if (round > 0) {
        if (l.lid > 0) {
          final yl = ey - r + l.lid * r * .85;
          final a = math.asin(((yl - ey) / r).clamp(-1.0, 1.0));
          final pts = [for (var i = 0; i <= 20; i++) Offset(ex + r * math.cos(a + (math.pi - 2 * a) * i / 20), ey + r * math.sin(a + (math.pi - 2 * a) * i / 20))];
          canvas.drawPath(_poly(pts, close: true), _fill(ink, round));
          canvas.drawLine(Offset(ex - r - 1, yl), Offset(ex + r + 1, yl), _line(ink, 2.4, round * math.min(1, l.lid * 1.5)));
        } else {
          canvas.drawCircle(Offset(ex, ey), r, _fill(ink, round));
          canvas.drawCircle(Offset(ex - r * .32, ey - r * .32), r * .36, _fill(Colors.white, round));
          canvas.drawCircle(Offset(ex + r * .3, ey + r * .35), r * .16, _fill(Colors.white, round * .9));
        }
      }
      if (l.eyeArc > 0) canvas.drawPath(_poly(_quad(Offset(ex - 7, ey + 2.5), Offset(ex, ey - 9), Offset(ex + 7, ey + 2.5))), _line(ink, 3.2, l.eyeArc));
      if (l.eyeShut > 0) canvas.drawPath(_poly(_quad(Offset(ex - 7, ey - 1.5), Offset(ex, ey + 7), Offset(ex + 7, ey - 1.5))), _line(ink, 3, l.eyeShut));
    }
    final blush = _fill(FaceInk.cheek, math.min(1, .22 + .6 * l.blush));
    canvas.drawOval(Rect.fromCenter(center: Offset(-Look.eyeX - 8 + lk, ey + 12), width: 18, height: 11), blush);
    canvas.drawOval(Rect.fromCenter(center: Offset(Look.eyeX + 8 + lk, ey + 12), width: 18, height: 11), blush);
    if (l.tears > 0) {
      for (final s in const [-1.0, 1.0]) {
        final tx = s * Look.eyeX + lk + s * 5;
        final p = Path()
          ..moveTo(tx - 3.5, ey + 6)
          ..lineTo(tx + 3.5, ey + 6)
          ..quadraticBezierTo(tx + 5, ey + 22, tx + 4.5, ey + 28)
          ..quadraticBezierTo(tx + 3, ey + 36, tx, ey + 36)
          ..quadraticBezierTo(tx - 3, ey + 36, tx - 4.5, ey + 28)
          ..quadraticBezierTo(tx - 5, ey + 22, tx - 3.5, ey + 6)
          ..close();
        canvas.drawPath(p, _fill(FaceInk.tear, .95 * l.tears));
        canvas.drawOval(Rect.fromCenter(center: Offset(tx - 1.5, ey + 17), width: 2.4, height: 8), _fill(Colors.white, .8 * l.tears));
      }
    }
    if (l.tearDrop > 0) canvas.drawPath(dropPath(Look.eyeX + lk + 7, ey + 5, 8, 13), _fill(FaceInk.tear, l.tearDrop));
    if (l.sweat > 0) {
      canvas.drawPath(dropPath(50, -34, 10, 16), _fill(FaceInk.tear, l.sweat));
      canvas.drawPath(dropPath(60, -12, 7, 11), _fill(FaceInk.tear, l.sweat));
    }
    // The mouth.
    final my = ey + 20, mx = lk * .6, w = l.mouthW, d = l.mouthCurve * 10;
    if (l.mouthO > 0) canvas.drawOval(Rect.fromCenter(center: Offset(mx, my + 3), width: 14, height: 18), _fill(FaceInk.mouth, l.mouthO));
    final rest = 1 - l.mouthO;
    if (rest <= 0) return;
    final open = l.mouthOpen;
    if (open < 1) {
      if (l.wavy > 0) {
        final pts = [
          for (var i = 0; i <= 24; i++)
            () {
              final t = -1 + 2 * i / 24;
              return Offset(mx + w * t, my + d * .9 * (1 - t * t) + l.wavy * 2.4 * math.sin(t * math.pi * 3));
            }(),
        ];
        canvas.drawPath(_poly(pts), _line(ink, 3, rest * (1 - open)));
      } else {
        canvas.drawPath(_poly(_quad(Offset(mx - w, my), Offset(mx, my + d * 1.8), Offset(mx + w, my))), _line(ink, 3.1, rest * (1 - open)));
      }
    }
    if (open > 0) {
      final upC = d >= 0 ? my - 2 : my + d * 2.0, loC = d >= 0 ? my + d * 2.2 + 4 * open : my + 6 * open;
      final up = _quad(Offset(mx - w, my), Offset(mx, upC), Offset(mx + w, my));
      final lo = _quad(Offset(mx - w, my), Offset(mx, loC), Offset(mx + w, my));
      canvas.drawPath(_poly([...up, ...lo.reversed], close: true), _fill(FaceInk.mouth, rest * open));
      if (l.mouthCurve > 0) canvas.drawOval(Rect.fromCenter(center: Offset(mx, my + d * .9 + 1), width: w, height: 8.4), _fill(FaceInk.tongue, rest * open));
      if (l.teeth > 0) {
        final topEdge = <Offset>[], bottomEdge = <Offset>[];
        for (var i = 0; i < up.length; i++) {
          if (i < up.length * .15 || i > up.length * .85) continue;
          topEdge.add(up[i]);
          bottomEdge.add(Offset(up[i].dx, math.min(up[i].dy + 4.5, lo[i].dy)));
        }
        if (topEdge.isNotEmpty) canvas.drawPath(_poly([...topEdge, ...bottomEdge.reversed], close: true), _fill(Colors.white, rest * open * l.teeth));
      }
    }
  }

  void _shake(Canvas canvas, double v) {
    const c = Color(0xFF9D8BCB);
    for (final s in const [-1.0, 1.0]) {
      final x = s * 64;
      canvas.drawPath(Path()
        ..moveTo(x + s * 6, -20)
        ..cubicTo(x + s * 12, -12, x + s * 12, 4, x + s * 6, 12), _line(c, 2.6, .8 * v));
      canvas.drawPath(Path()
        ..moveTo(x + s * 14, -14)
        ..cubicTo(x + s * 19, -8, x + s * 19, 4, x + s * 14, 10), _line(c, 2.6, .8 * v));
    }
  }

  static void sparkle(Canvas canvas, Offset c, double r, Color col, double op) {
    const k = .16;
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..cubicTo(c.dx + r * k, c.dy - r * k, c.dx + r * k, c.dy - r * k, c.dx + r, c.dy)
      ..cubicTo(c.dx + r * k, c.dy + r * k, c.dx + r * k, c.dy + r * k, c.dx, c.dy + r)
      ..cubicTo(c.dx - r * k, c.dy + r * k, c.dx - r * k, c.dy + r * k, c.dx - r, c.dy)
      ..cubicTo(c.dx - r * k, c.dy - r * k, c.dx - r * k, c.dy - r * k, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(p, _fill(col, op));
  }

  static Path _star(Offset c, double outer) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = (-90 + 36 * i) * math.pi / 180;
      final rr = i.isEven ? outer : outer * .48;
      final q = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }

  void _extras(Canvas canvas) {
    final e = look.extras;
    double v(Extra x) => e[x] ?? 0;
    if (v(Extra.sparkle) > 0) {
      sparkle(canvas, const Offset(-60, -44), 7, FaceInk.gold, v(Extra.sparkle));
      sparkle(canvas, const Offset(62, -30), 5, FaceInk.gold, v(Extra.sparkle));
    }
    if (v(Extra.steam) > 0) {
      for (final x in const [-30.0, 30.0]) {
        for (final (dx, y0, h) in const [(-8.0, -62.0, 32.0), (6.0, -58.0, 28.0)]) {
          canvas.drawPath(_poly([for (var i = 0; i <= 10; i++) Offset(x + dx + 4 * math.sin(i / 10 * math.pi * 2), y0 - h * i / 10)]), _line(const Color(0xFFE06A5A), 3, .85 * v(Extra.steam)));
        }
      }
    }
    if (v(Extra.pop) > 0) {
      for (final (a, b) in const [(Offset(-66, -50), Offset(-76, -60)), (Offset(66, -50), Offset(76, -60)), (Offset(0, -76), Offset(0, -88)), (Offset(-40, -72), Offset(-45, -83)), (Offset(40, -72), Offset(45, -83))]) {
        canvas.drawLine(a, b, _line(const Color(0xFF5EC3A4), 3.4, v(Extra.pop)));
      }
    }
    if (v(Extra.hands) > 0) {
      for (final s in const [-1.0, 1.0]) {
        final m = Matrix4.identity()
          ..translateByDouble(s * 30 + look.look, 6, 0, 1)
          ..rotateZ(s * -20 * math.pi / 180);
        _mallow(canvas, (Path()..addOval(Rect.fromCenter(center: Offset.zero, width: 26, height: 22))).transform(m.storage), _lt(look.color, .2), opacity: v(Extra.hands));
      }
    }
    if (v(Extra.star) > 0) {
      _mallow(canvas, _star(const Offset(0, 28), 10), FaceInk.gold, shade: false, opacity: v(Extra.star));
      for (final (c, r) in const [(Offset(-58, -42), 6.0), (Offset(60, -40), 5.0), (Offset(40, -70), 5.0)]) {
        sparkle(canvas, c, r, FaceInk.gold, v(Extra.star));
      }
    }
    if (v(Extra.zz) > 0) {
      List<Offset> z(double x, double y, double s) => [Offset(x - s * .4, y - s * .4), Offset(x + s * .4, y - s * .4), Offset(x - s * .4, y + s * .4), Offset(x + s * .4, y + s * .4)];
      canvas.drawPath(_poly(z(56, -44, 12)), _line(FaceInk.ink, 2.6, v(Extra.zz)));
      canvas.drawPath(_poly(z(68, -60, 9)), _line(FaceInk.ink, 2.2, .7 * v(Extra.zz)));
    }
    if (v(Extra.sigh) > 0) {
      canvas.drawPath(Path()
        ..moveTo(58, 6)
        ..cubicTo(66, 2, 72, 8, 72, 12)
        ..cubicTo(74, 18, 78, 18, 82, 16), _line(const Color(0xFF8C97AD), 3, .8 * v(Extra.sigh)));
    }
    if (v(Extra.dots) > 0) {
      for (final c in const [Offset(50, -46), Offset(60, -52), Offset(70, -58)]) {
        canvas.drawCircle(c, 3.2, _fill(const Color(0xFF9C948A), v(Extra.dots)));
      }
    }
    if (v(Extra.question) > 0) {
      final q = v(Extra.question);
      _mallow(canvas, Path()..addOval(Rect.fromCircle(center: const Offset(46, -64), radius: 16)), Colors.white, opacity: q);
      canvas.drawPath(Path()
        ..moveTo(40, -69)
        ..cubicTo(40, -77, 52, -77, 52, -69)
        ..cubicTo(52, -64, 46, -64, 46, -59), _line(FaceInk.ink, 3.2, q));
      canvas.drawCircle(const Offset(46, -53), 2.2, _fill(FaceInk.ink, q));
    }
  }

  @override
  bool shouldRepaint(CloudPainter old) => old.look != look || old.kind != kind || old.browLift != browLift || old.squash != squash || old.shadow != shadow;
}

/// Blends between two looks.
class LookTween extends Tween<Look> {
  LookTween({super.begin, super.end});

  @override
  Look lerp(double t) => Look.lerp(begin!, end!, t);
}

/// A cloud character feeling something, changing smoothly when the feeling
/// changes (docs/design.md: 小朋友看得到「心情是會變的」). [hint] lifts the
/// eyebrows each time it changes; [squash] presses the cloud down.
class Cloud extends StatefulWidget {
  const Cloud({
    super.key,
    this.feeling,
    this.look,
    this.kind = CloudKind.mianmian,
    this.tint,
    this.extras = const {},
    this.hint = 0,
    this.squash = 0,
    this.duration = const Duration(milliseconds: 900),
    this.shadow = true,
    this.flip = false,
  });

  /// The feeling (null: [look], or no feeling yet).
  final Feeling? feeling;
  final Look? look;
  final CloudKind kind;

  /// Keeps this colour whatever the feeling (a grown-up, a friend).
  final Color? tint;

  /// Extras added on top of the feeling's own (小雨's 「？」).
  final Map<Extra, double> extras;
  final int hint;
  final double squash;
  final Duration duration;
  final bool shadow;
  final bool flip;

  Look get target {
    var l = look ?? (feeling == null ? Look.neutral : Look.of(feeling!));
    if (kind == CloudKind.grownup && feeling == null && look == null) l = Look.of(Feeling.calm);
    if (tint != null || extras.isNotEmpty) l = l.copyWith(color: tint, extras: {...l.extras, ...extras});
    return l;
  }

  @override
  State<Cloud> createState() => _CloudState();
}

class _CloudState extends State<Cloud> with TickerProviderStateMixin {
  late final _change = AnimationController(vsync: this, duration: widget.duration);
  late final _hint = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late Look _from = widget.target, _to = widget.target;

  @override
  void didUpdateWidget(Cloud old) {
    super.didUpdateWidget(old);
    final next = widget.target;
    if (next.color != _to.color || old.feeling != widget.feeling || old.look != widget.look || old.extras.length != widget.extras.length || old.kind != widget.kind) {
      _from = Look.lerp(_from, _to, Curves.easeInOut.transform(_change.value));
      _to = next;
      _change.forward(from: 0);
    }
    if (old.hint != widget.hint) _hint.forward(from: 0);
  }

  @override
  void dispose() {
    _change.dispose();
    _hint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: CloudPainter.box.width / CloudPainter.box.height,
        child: AnimatedBuilder(
          animation: Listenable.merge([_change, _hint]),
          builder: (_, _) {
            final t = _change.isAnimating || _change.value > 0 ? Curves.easeInOut.transform(_change.value) : 1.0;
            final look = Look.lerp(_from, _to, t);
            final lift = math.sin(_hint.value * math.pi * 3).abs() * (1 - _hint.value) * 7;
            return Transform.flip(
              flipX: widget.flip,
              child: CustomPaint(painter: CloudPainter(look, kind: widget.kind, browLift: lift, squash: widget.squash, shadow: widget.shadow)),
            );
          },
        ),
      );
}
