import 'dart:ui' show Color, lerpDouble;

import 'feelings.dart';

/// One round puff of 棉棉's cloud body, in the cloud's own units: about 140
/// wide, the middle at (0, 0), the bottom near y = 44. [tip] (0..1) pulls
/// the puff's top into a point (生氣's spiky edge).
class Puff {
  const Puff(this.x, this.y, this.rx, this.ry, {this.rot = 0, this.tip = 0});

  final double x, y, rx, ry;

  /// Turn in degrees (the top of the puff points this way from up).
  final double rot;
  final double tip;

  static Puff lerp(Puff a, Puff b, double t) => Puff(
        _l(a.x, b.x, t),
        _l(a.y, b.y, t),
        _l(a.rx, b.rx, t),
        _l(a.ry, b.ry, t),
        rot: _l(a.rot, b.rot, t),
        tip: _l(a.tip, b.tip, t),
      );
}

double _l(double a, double b, double t) => lerpDouble(a, b, t)!;

/// The little things drawn around 棉棉 for a feeling.
enum Extra { sparkle, steam, shake, pop, hands, star, zz, sigh, dots, question }

/// Every number that draws 棉棉's face and body for one feeling (docs/design.md:
/// 臉是用參數畫的). Two looks blend with [lerp], so 棉棉 can change slowly from
/// one feeling to another (from 生氣 back to 安心).
class Look {
  const Look({
    required this.color,
    required this.puffs,
    this.brow = 0,
    this.browOn = 0,
    this.eyeR = 7,
    this.eyeArc = 0,
    this.eyeShut = 0,
    this.lid = 0,
    this.look = 0,
    this.mouthCurve = 0,
    this.mouthOpen = 0,
    this.mouthW = 10,
    this.teeth = 0,
    this.wavy = 0,
    this.mouthO = 0,
    this.blush = .3,
    this.tears = 0,
    this.tearDrop = 0,
    this.sweat = 0,
    this.faceY = 0,
    this.extras = const {},
  });

  final Color color;

  /// Always [puffCount] puffs, so any two bodies can blend.
  final List<Puff> puffs;

  /// Eyebrow tilt: above 0 the inner ends go up (worried, sad), below 0 they
  /// press down (angry). [browOn] 0 hides the brows.
  final double brow, browOn;

  /// Round eyes of radius [eyeR]; [eyeArc] turns them into happy ^ arcs,
  /// [eyeShut] into calm closed ‿ arcs, [lid] lowers a heavy lid over the top
  /// half; [look] moves the eyes (and the mouth a little) sideways.
  final double eyeR, eyeArc, eyeShut, lid, look;

  /// Mouth: -1 a frown … 1 a smile; [mouthOpen] fills it; [mouthW] is half its
  /// width; [teeth] shows a row of teeth; [wavy] makes it wobble; [mouthO]
  /// makes it a round "O".
  final double mouthCurve, mouthOpen, mouthW, teeth, wavy, mouthO;
  final double blush;

  /// Two streams of tears (難過); one tear still in the eye (委屈); sweat drops.
  final double tears, tearDrop, sweat;

  /// Moves the whole face up or down.
  final double faceY;

  /// How much of each extra shows (0..1).
  final Map<Extra, double> extras;

  static const puffCount = 8;

  /// Where the face's features sit.
  static const eyeX = 20.0, eyeY = -8.0;

  double extra(Extra e) => extras[e] ?? 0;

  /// The top of the body near the middle (where 棉棉's curl or 小雨's drop sits).
  double get top {
    var t = 0.0;
    for (final p in puffs) {
      if (p.x.abs() < 30) t = t < p.y - p.ry ? t : p.y - p.ry;
    }
    return t;
  }

  Look copyWith({Color? color, Map<Extra, double>? extras, double? mouthCurve, double? eyeShut}) => Look(
        color: color ?? this.color,
        puffs: puffs,
        brow: brow,
        browOn: browOn,
        eyeR: eyeR,
        eyeArc: eyeArc,
        eyeShut: eyeShut ?? this.eyeShut,
        lid: lid,
        look: look,
        mouthCurve: mouthCurve ?? this.mouthCurve,
        mouthOpen: mouthOpen,
        mouthW: mouthW,
        teeth: teeth,
        wavy: wavy,
        mouthO: mouthO,
        blush: blush,
        tears: tears,
        tearDrop: tearDrop,
        sweat: sweat,
        faceY: faceY,
        extras: extras ?? this.extras,
      );

  static Look lerp(Look a, Look b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    return Look(
      color: Color.lerp(a.color, b.color, t)!,
      puffs: [for (var i = 0; i < puffCount; i++) Puff.lerp(a.puffs[i], b.puffs[i], t)],
      brow: _l(a.brow, b.brow, t),
      browOn: _l(a.browOn, b.browOn, t),
      eyeR: _l(a.eyeR, b.eyeR, t),
      eyeArc: _l(a.eyeArc, b.eyeArc, t),
      eyeShut: _l(a.eyeShut, b.eyeShut, t),
      lid: _l(a.lid, b.lid, t),
      look: _l(a.look, b.look, t),
      mouthCurve: _l(a.mouthCurve, b.mouthCurve, t),
      mouthOpen: _l(a.mouthOpen, b.mouthOpen, t),
      mouthW: _l(a.mouthW, b.mouthW, t),
      teeth: _l(a.teeth, b.teeth, t),
      wavy: _l(a.wavy, b.wavy, t),
      mouthO: _l(a.mouthO, b.mouthO, t),
      blush: _l(a.blush, b.blush, t),
      tears: _l(a.tears, b.tears, t),
      tearDrop: _l(a.tearDrop, b.tearDrop, t),
      sweat: _l(a.sweat, b.sweat, t),
      faceY: _l(a.faceY, b.faceY, t),
      extras: {
        for (final e in Extra.values)
          if (a.extra(e) > 0 || b.extra(e) > 0) e: _l(a.extra(e), b.extra(e), t),
      },
    );
  }

  /// 棉棉 in each feeling (ported from docs/mockups/make_mockups.py's table).
  static Look of(Feeling f) => _looks[f]!;

  /// No feeling yet (小雨 at the start of a story, with a "?").
  static const neutral = Look(color: Color(0xFFDCE9F8), puffs: Bodies.round, mouthCurve: 0, mouthW: 9, blush: .3);

  static const _looks = <Feeling, Look>{
    Feeling.happy: Look(color: Color(0xFFFFE08A), puffs: Bodies.round, eyeArc: 1, mouthCurve: 1, mouthOpen: 1, mouthW: 15, blush: .7, extras: {Extra.sparkle: 1}),
    Feeling.sad: Look(color: Color(0xFFA9C9F2), puffs: Bodies.droop, brow: 22, browOn: 1, mouthCurve: -.8, mouthW: 11, blush: .25, tears: 1, faceY: 6),
    Feeling.angry: Look(color: Color(0xFFF59A8C), puffs: Bodies.spiky, brow: -28, browOn: 1, mouthCurve: -.55, mouthOpen: .8, mouthW: 14, teeth: 1, blush: .4, extras: {Extra.steam: 1}),
    Feeling.scared: Look(color: Color(0xFFC9B8F0), puffs: Bodies.small, brow: 26, browOn: 1, eyeR: 9, mouthCurve: -.6, mouthOpen: 1, mouthW: 10, blush: .2, tearDrop: .6, extras: {Extra.shake: 1}),
    Feeling.surprised: Look(color: Color(0xFFB2E8D6), puffs: Bodies.tall, brow: -6, browOn: 1, eyeR: 9, mouthO: 1, mouthW: 8, blush: .4, faceY: -4, extras: {Extra.pop: 1}),
    Feeling.shy: Look(color: Color(0xFFF9BBD0), puffs: Bodies.round, brow: 8, browOn: 1, eyeArc: 1, look: -3, mouthCurve: .7, mouthW: 6, blush: 1, extras: {Extra.hands: 1}),
    Feeling.nervous: Look(color: Color(0xFFD9E3A2), puffs: Bodies.round, brow: 18, browOn: 1, eyeR: 5.5, mouthW: 12, wavy: 1, blush: .3, sweat: 1),
    Feeling.disappointed: Look(color: Color(0xFFBFC8DA), puffs: Bodies.droop, brow: 14, browOn: 1, lid: 1, mouthCurve: -.15, mouthW: 9, blush: .2, faceY: 6, extras: {Extra.sigh: 1}),
    Feeling.proud: Look(color: Color(0xFFFFC48C), puffs: Bodies.proud, brow: -10, browOn: 1, eyeArc: 1, mouthCurve: 1, mouthOpen: .8, mouthW: 16, teeth: 1, blush: .6, faceY: -4, extras: {Extra.star: 1}),
    Feeling.tired: Look(color: Color(0xFFD9CDE6), puffs: Bodies.flat, brow: 10, browOn: .7, lid: 1, mouthCurve: .45, mouthW: 6, blush: .3, faceY: 4, extras: {Extra.zz: 1}),
    Feeling.bored: Look(color: Color(0xFFDAD3C6), puffs: Bodies.flat, lid: 1, look: 4, mouthCurve: 0, mouthW: 10, blush: .2, faceY: 4, extras: {Extra.dots: 1}),
    Feeling.jealous: Look(color: Color(0xFFA9D48F), puffs: Bodies.round, brow: -14, browOn: 1, eyeR: 6.5, lid: .45, look: 7, mouthCurve: -.6, mouthW: 6, blush: .35),
    Feeling.calm: Look(color: Color(0xFFCDEBDC), puffs: Bodies.round, eyeShut: 1, mouthCurve: .6, mouthW: 10, blush: .5),
    Feeling.wronged: Look(color: Color(0xFFE3C4E6), puffs: Bodies.droop, brow: 20, browOn: 1, mouthCurve: -.3, mouthW: 11, wavy: .7, blush: .55, tearDrop: 1, faceY: 6),
  };
}

/// The cloud bodies (make_mockups.py cloud_geom), eight puffs each.
abstract final class Bodies {
  static const round = [
    Puff(0, 4, 58, 40),
    Puff(-36, -12, 27, 25),
    Puff(-4, -24, 33, 30),
    Puff(30, -16, 27, 25),
    Puff(50, 6, 20, 18),
    Puff(-52, 8, 18, 16),
    Puff(-22, 16, 30, 26),
    Puff(22, 16, 30, 26),
  ];

  /// 得意: chest out, a little taller.
  static const proud = [
    Puff(0, 2, 60, 42),
    Puff(-36, -16, 27, 25),
    Puff(-4, -30, 33, 30),
    Puff(30, -20, 27, 25),
    Puff(52, 4, 20, 18),
    Puff(-54, 6, 18, 16),
    Puff(-22, 16, 30, 26),
    Puff(22, 16, 30, 26),
  ];

  /// 累累的、無聊: squashed.
  static const flat = [
    Puff(0, 10, 62, 32),
    Puff(-36, -2, 27, 20),
    Puff(-2, -10, 33, 24),
    Puff(32, -4, 27, 20),
    Puff(54, 14, 18, 13),
    Puff(-54, 14, 16, 12),
    Puff(-24, 18, 30, 22),
    Puff(24, 18, 30, 22),
  ];

  /// 難過、失望、委屈: the top flattened and the bumps hanging down.
  static const droop = [
    Puff(0, -2, 56, 34),
    Puff(-18, -24, 30, 19),
    Puff(4, -26, 26, 18),
    Puff(18, -24, 28, 18),
    Puff(34, 16, 23, 20),
    Puff(-32, 18, 25, 22),
    Puff(-12, 22, 25, 22),
    Puff(14, 22, 27, 24),
  ];

  /// 生氣: points on top.
  static const spiky = [
    Puff(0, 8, 60, 36),
    Puff(-26, -24, 13, 28, rot: -35, tip: 1),
    Puff(0, -32, 13, 30, tip: 1),
    Puff(26, -24, 13, 28, rot: 35, tip: 1),
    Puff(50, 10, 16, 14),
    Puff(-50, 10, 16, 14),
    Puff(-48, -8, 12, 24, rot: -70, tip: 1),
    Puff(48, -8, 12, 24, rot: 70, tip: 1),
  ];

  /// 害怕: shrunk and wobbly.
  static const small = [
    Puff(0, 12, 46, 32),
    Puff(-30, -6, 17, 15),
    Puff(-4, -16, 22, 19),
    Puff(24, -8, 17, 15),
    Puff(40, 12, 14, 13),
    Puff(-42, 12, 13, 12),
    Puff(-16, 20, 22, 18),
    Puff(16, 20, 22, 18),
  ];

  /// 驚訝: stretched up.
  static const tall = [
    Puff(0, 0, 50, 46),
    Puff(-28, -32, 22, 20),
    Puff(4, -44, 24, 22),
    Puff(32, -30, 20, 18),
    Puff(48, 12, 14, 13),
    Puff(-48, 10, 14, 13),
    Puff(-20, 18, 28, 26),
    Puff(20, 18, 28, 26),
  ];
}
