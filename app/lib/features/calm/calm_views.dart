import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/cloud.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/calm.dart';
import '../../core/feelings.dart';
import '../../core/looks.dart';
import '../../core/providers.dart';
import '../../core/stories.dart';

/// One calming way, played with raw pointer events (a touch counts at once;
/// dragging follows the finger without waiting). Every way ends by itself
/// after [CalmWay.goal] times; 棉棉 goes from [CalmWay.from] to 安心 as it goes.
class CalmActivity extends StatelessWidget {
  const CalmActivity({super.key, required this.way, required this.onDone, this.shake = true});

  final CalmWay way;
  final VoidCallback onDone;
  final bool shake;

  @override
  Widget build(BuildContext context) => switch (way) {
        CalmWay.balloon => BalloonView(onDone: onDone),
        CalmWay.count => CountView(onDone: onDone),
        CalmWay.hug => HugView(onDone: onDone),
        CalmWay.pillow => PillowView(onDone: onDone, shake: shake),
        CalmWay.water => WaterView(onDone: onDone),
        CalmWay.adult => AdultView(onDone: onDone),
      };
}

/// 棉棉 part of the way from [from] to 安心.
Widget calming(Feeling from, double progress, {double squash = 0, Key? key}) =>
    Cloud(key: key, look: Look.lerp(Look.of(from), Look.of(Feeling.calm), progress.clamp(0, 1)), squash: squash, duration: const Duration(milliseconds: 260));

// ---------------------------------------------------------------- 吹氣球深呼吸
/// Hold to breathe in (the balloon grows for four seconds), let go to
/// breathe out (it floats up as it gets smaller). Three breaths, then it
/// floats away. Let go too early and it just shrinks back: try again.
class BalloonView extends ConsumerStatefulWidget {
  const BalloonView({super.key, required this.onDone});

  final VoidCallback onDone;

  static const breathIn = Duration(seconds: 4);
  static const breathOut = Duration(milliseconds: 3600);

  @override
  ConsumerState<BalloonView> createState() => _BalloonViewState();
}

class _BalloonViewState extends ConsumerState<BalloonView> with TickerProviderStateMixin, HushOnLeave {
  late final _air = AnimationController(vsync: this, duration: BalloonView.breathIn);
  late final _away = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  var _breaths = 0, _out = false, _ended = false;
  int? _pointer;

  @override
  void dispose() {
    _air.dispose();
    _away.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent e) {
    if (_out || _ended || _pointer != null) return;
    _pointer = e.pointer;
    sfx(ref, 'breath_in');
    _air.forward();
    setState(() {});
  }

  Future<void> _up(PointerEvent e) async {
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (_out || _ended) return;
    _air.stop();
    if (_air.value < .7) {
      speak(ref, Strings.holdLonger);
      await _air.animateBack(0, duration: const Duration(milliseconds: 500));
      if (mounted) setState(() {});
      return;
    }
    setState(() => _out = true);
    sfx(ref, 'breath_out');
    await _air.animateBack(0, duration: BalloonView.breathOut, curve: Curves.easeInOut);
    if (!mounted) return;
    setState(() {
      _out = false;
      _breaths++;
    });
    if (_breaths >= CalmWay.balloon.goal) {
      setState(() => _ended = true);
      sfx(ref, 'float');
      _air.value = 1;
      await _away.forward();
      if (mounted) widget.onDone();
    } else {
      sfx(ref, 'chime');
      speak(ref, Strings.breaths(_breaths + 1));
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
        key: const ValueKey('hold'),
        container: true,
        button: true,
        label: Strings.holdIn.replaceAll('\n', ''),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: AnimatedBuilder(
            animation: Listenable.merge([_air, _away]),
            builder: (context, _) => LayoutBuilder(builder: (context, box) {
              final a = _air.value;
              final progress = (_breaths + (_out ? (1 - a) : a * .4)) / CalmWay.balloon.goal;
              final maxB = math.min(box.maxWidth * .5, box.maxHeight * .5);
              final size = maxB * (.42 + .58 * a);
              final rise = _out ? (1 - a) * 26 : 0.0;
              return Stack(clipBehavior: Clip.none, children: [
                Positioned(
                  left: box.maxWidth / 2 - size * .31 + box.maxWidth * .1,
                  top: box.maxHeight * .32 - size * .6 - rise - _away.value * box.maxHeight * .9,
                  width: size * .62,
                  height: size,
                  child: Opacity(opacity: (1 - _away.value).clamp(0, 1), child: const Art('calm/balloon')),
                ),
                Positioned(
                  left: box.maxWidth * .02,
                  top: box.maxHeight * .3,
                  width: box.maxWidth * .36,
                  child: calming(CalmWay.balloon.from, progress, squash: -a * .5),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  top: box.maxHeight * .58,
                  height: 46,
                  child: CustomPaint(painter: _Wave(_out ? .5 + (1 - a) * .5 : a * .5)),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  top: box.maxHeight * .58 + 48,
                  child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(Strings.inhale, style: TextStyle(fontSize: 14, color: Mallow.inkSoft)),
                    Text(Strings.exhale, style: TextStyle(fontSize: 14, color: Mallow.inkSoft)),
                  ]),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(
                    child: AnimatedScale(
                      scale: _pointer != null ? 1.08 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: math.min(124, box.maxHeight * .26),
                        height: math.min(124, box.maxHeight * .26),
                        alignment: Alignment.center,
                        decoration: mallowBox(_out ? Mallow.blue : Mallow.green, radius: 62),
                        child: Text(
                          _out ? Strings.breatheOut : (_pointer != null ? Strings.breatheIn : Strings.holdIn),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white, height: 1.25),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 4,
                  child: Row(children: [
                    for (var i = 0; i < CalmWay.balloon.goal; i++)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        width: 18,
                        height: 18,
                        decoration: mallowBox(i < _breaths ? Mallow.pink : Colors.white, radius: 9, shadow: false),
                      ),
                  ]),
                ),
              ]);
            }),
          ),
        ),
      );
}

/// The breathing wave: up while breathing in, down while breathing out, a
/// dot where the breath is.
class _Wave extends CustomPainter {
  _Wave(this.at);

  final double at;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path();
    double y(double t) => size.height / 2 - math.sin(t * 2 * math.pi - math.pi / 2) * size.height * .38;
    for (var i = 0; i <= 60; i++) {
      final t = i / 60;
      i == 0 ? p.moveTo(0, y(t)) : p.lineTo(t * size.width, y(t));
    }
    canvas.drawPath(
        p,
        Paint()
          ..color = Mallow.green.withValues(alpha: .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(at * size.width, y(at)), 11, Paint()..color = Mallow.green);
    canvas.drawCircle(Offset(at * size.width - 3, y(at) - 3), 3.5, Paint()..color = Colors.white.withValues(alpha: .7));
  }

  @override
  bool shouldRepaint(_Wave old) => old.at != at;
}

// ---------------------------------------------------------------- 數到四
/// Four clouds: tap them one by one, each says the next number.
class CountView extends ConsumerStatefulWidget {
  const CountView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<CountView> createState() => _CountViewState();
}

class _CountViewState extends ConsumerState<CountView> with HushOnLeave {
  final _numbers = <int, int>{};

  void _tap(int i) {
    if (_numbers.containsKey(i) || _numbers.length >= 4) return;
    final n = _numbers.length + 1;
    setState(() => _numbers[i] = n);
    sfx(ref, 'count_$n');
    speak(ref, n == 4 ? Strings.countDone : Strings.numbers[n - 1]);
    if (n == 4) {
      Future<void>.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) widget.onDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        const spots = [Offset(.17, .66), Offset(.36, .5), Offset(.62, .46), Offset(.83, .62)];
        final cw = math.min(w * .26, h * .3);
        return Stack(children: [
          Positioned(left: w * .25, top: 0, width: w * .5, child: calming(CalmWay.count.from, _numbers.length / 4)),
          for (var i = 0; i < 4; i++)
            Positioned(
              left: spots[i].dx * w - cw / 2,
              top: spots[i].dy * h,
              width: cw,
              height: cw * .75,
              child: Semantics(
                key: ValueKey('count-$i'),
                container: true,
                button: true,
                label: 'cloud $i',
                excludeSemantics: true,
                child: Pressable(
                  onTap: () => _tap(i),
                  sound: null,
                  child: Bob(
                    phase: i * .25,
                    amount: _numbers.containsKey(i) ? 0 : 4,
                    child: Stack(alignment: Alignment.center, children: [
                      const Positioned.fill(child: Art('calm/numcloud')),
                      Padding(
                        padding: EdgeInsets.only(top: cw * .12),
                        child: Text(_numbers.containsKey(i) ? '${_numbers[i]}' : '', style: TextStyle(fontSize: cw * .32, fontWeight: FontWeight.w700, color: Mallow.ink)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]);
      });
}

// ---------------------------------------------------------------- 抱抱布偶
/// Bring the teddy to 棉棉 (drag it there, or just tap it); then they hug
/// and rock slowly while the heartbeat slows down.
class HugView extends ConsumerStatefulWidget {
  const HugView({super.key, required this.onDone});

  final VoidCallback onDone;

  static const hold = Duration(seconds: 4);

  @override
  ConsumerState<HugView> createState() => _HugViewState();
}

class _HugViewState extends ConsumerState<HugView> with SingleTickerProviderStateMixin, HushOnLeave {
  late final _rock = AnimationController(vsync: this, duration: HugView.hold);
  Offset _drag = Offset.zero;
  Offset? _start;
  int? _pointer;
  var _arrived = false;
  final _beats = <Timer>[];

  @override
  void dispose() {
    _rock.dispose();
    for (final t in _beats) {
      t.cancel();
    }
    super.dispose();
  }

  void _down(PointerDownEvent e) {
    if (_arrived || _pointer != null) return;
    _pointer = e.pointer;
    _start = e.position;
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer || _start == null) return;
    setState(() => _drag = e.position - _start!);
  }

  void _up(PointerEvent e, Offset teddyAt, Offset target, double reach) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    final moved = _drag.distance;
    if (moved < 14 || (teddyAt + _drag - target).distance < reach) {
      _hug();
    } else {
      setState(() => _drag = Offset.zero);
    }
  }

  void _hug() {
    setState(() {
      _arrived = true;
      _drag = Offset.zero;
    });
    sfx(ref, 'hug');
    speak(ref, Strings.teddyHere);
    _rock.forward();
    var at = 600;
    for (var i = 0; i < 5; i++) {
      _beats.add(Timer(Duration(milliseconds: at), () {
        if (mounted) sfx(ref, 'heartbeat');
      }));
      at += 650 + i * 150;
    }
    Future<void>.delayed(HugView.hold + const Duration(milliseconds: 400), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final mmW = math.min(w * .52, h * .5);
        final mmCenter = Offset(w / 2, h * .08 + mmW * .45);
        final teddyW = math.min(w * .34, h * .32);
        final home = Offset(w * .22, h * .78);
        final teddyCenter = _arrived ? mmCenter + Offset(mmW * .05, mmW * .3) : home + _drag;
        return AnimatedBuilder(
          animation: _rock,
          builder: (context, _) {
            final rock = _arrived ? math.sin(_rock.value * math.pi * 4) * .08 * (1 - _rock.value * .5) : 0.0;
            return Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: mmCenter.dx - mmW / 2,
                top: h * .08,
                width: mmW,
                child: Transform.rotate(angle: rock, alignment: Alignment.bottomCenter, child: calming(CalmWay.hug.from, _rock.value, squash: _arrived ? .25 : 0)),
              ),
              AnimatedPositioned(
                duration: Duration(milliseconds: _pointer != null ? 0 : 600),
                curve: Curves.easeOutBack,
                left: teddyCenter.dx - teddyW / 2,
                top: teddyCenter.dy - teddyW * .53,
                width: teddyW * (_arrived ? .62 : 1),
                height: teddyW * 1.06 * (_arrived ? .62 : 1),
                child: Transform.rotate(
                  angle: rock,
                  child: Semantics(
                    key: const ValueKey('teddy'),
                    container: true,
                    button: true,
                    label: CalmWay.hug.zh,
                    excludeSemantics: true,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _down,
                      onPointerMove: _move,
                      onPointerUp: (e) => _up(e, home, mmCenter, mmW * .45),
                      onPointerCancel: (e) => _up(e, home, mmCenter, mmW * .45),
                      child: const Art('calm/teddy'),
                    ),
                  ),
                ),
              ),
              if (!_arrived)
                Positioned(
                  left: w * .45,
                  top: h * .74,
                  child: const Bob(amount: 5, child: Icon(Icons.arrow_upward_rounded, size: 38, color: Mallow.rose)),
                ),
            ]);
          },
        );
      });
}

// ---------------------------------------------------------------- 搥枕頭
/// Thump the pillow (tap it hard, or shake the phone if the parent turned
/// that on): it squashes and springs back, and 棉棉's red goes a bit each
/// time.
class PillowView extends ConsumerStatefulWidget {
  const PillowView({super.key, required this.onDone, this.shake = true});

  final VoidCallback onDone;
  final bool shake;

  @override
  ConsumerState<PillowView> createState() => _PillowViewState();
}

class _PillowViewState extends ConsumerState<PillowView> with SingleTickerProviderStateMixin, HushOnLeave {
  late final _squash = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  StreamSubscription<void>? _shakes;
  AppLifecycleListener? _life;
  var _count = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.shake) return;
    _listen();
    // The phone in a bag or a pocket is not a thump: the sensor is off
    // while the app is out of sight.
    _life = AppLifecycleListener(
      onHide: () {
        _shakes?.cancel();
        _shakes = null;
      },
      onShow: _listen,
    );
  }

  void _listen() {
    if (!mounted) return;
    _shakes ??= ref.read(shakesProvider).shakes.listen((_) => _thump());
  }

  @override
  void dispose() {
    _life?.dispose();
    _shakes?.cancel();
    _squash.dispose();
    super.dispose();
  }

  void _thump() {
    if (!mounted || _count >= CalmWay.pillow.goal) return;
    sfx(ref, 'thump');
    _squash.forward(from: 0);
    setState(() => _count++);
    if (_count >= CalmWay.pillow.goal) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) widget.onDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        return AnimatedBuilder(
          animation: _squash,
          builder: (context, _) {
            final s = math.sin(_squash.value * math.pi);
            return Stack(children: [
              Positioned(left: w * .27, top: 0, width: w * .46, child: calming(CalmWay.pillow.from, _count / CalmWay.pillow.goal, squash: s * .3)),
              Positioned(
                left: w * .1,
                right: w * .1,
                bottom: h * .1,
                height: h * .4,
                child: Semantics(
                  key: const ValueKey('pillow'),
                  container: true,
                  button: true,
                  label: CalmWay.pillow.zh,
                  excludeSemantics: true,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => _thump(),
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(1 + s * .1, 1 - s * .22, 1),
                      child: const Art('calm/pillow'),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(children: [
                  Text(Strings.pillowHit, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Mallow.ink)),
                  if (widget.shake) const Text(Strings.pillowShake, style: TextStyle(fontSize: 13, color: Mallow.inkSoft)),
                ]),
              ),
              Positioned(
                right: 16,
                top: 4,
                child: Wrap(spacing: 4, children: [
                  for (var i = 0; i < CalmWay.pillow.goal; i++) Icon(Icons.circle, size: 12, color: i < _count ? Mallow.coral : Colors.white),
                ]),
              ),
            ]);
          },
        );
      });
}

// ---------------------------------------------------------------- 喝口水
/// Bring the cup to 棉棉's mouth (drag it, or tap it): three gulps, and the
/// drops of sweat are gone.
class WaterView extends ConsumerStatefulWidget {
  const WaterView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<WaterView> createState() => _WaterViewState();
}

class _WaterViewState extends ConsumerState<WaterView> with HushOnLeave {
  Offset _drag = Offset.zero;
  Offset? _start;
  int? _pointer;
  var _arrived = false, _gulps = 0;

  void _down(PointerDownEvent e) {
    if (_arrived || _pointer != null) return;
    _pointer = e.pointer;
    _start = e.position;
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer || _start == null) return;
    setState(() => _drag = e.position - _start!);
  }

  void _up(PointerEvent e, Offset home, Offset mouth, double reach) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (_drag.distance < 14 || (home + _drag - mouth).distance < reach) {
      _drink();
    } else {
      setState(() => _drag = Offset.zero);
    }
  }

  Future<void> _drink() async {
    setState(() {
      _arrived = true;
      _drag = Offset.zero;
    });
    sfx(ref, 'pour');
    for (var i = 0; i < CalmWay.water.goal; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      sfx(ref, 'gulp');
      setState(() => _gulps++);
    }
    speak(ref, Strings.drink);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final mmW = math.min(w * .52, h * .5);
        final mouth = Offset(w * .42 + mmW * .2, h * .08 + mmW * .52);
        final cupW = math.min(w * .3, h * .26);
        final home = Offset(w * .78, h * .76);
        final at = _arrived ? mouth + Offset(cupW * .45, 0) : home + _drag;
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(left: w * .42 - mmW / 2, top: h * .08, width: mmW, child: calming(CalmWay.water.from, _gulps / CalmWay.water.goal)),
          AnimatedPositioned(
            duration: Duration(milliseconds: _pointer != null ? 0 : 600),
            curve: Curves.easeOutBack,
            left: at.dx - cupW / 2,
            top: at.dy - cupW * .43,
            width: cupW,
            height: cupW * .86,
            child: AnimatedRotation(
              turns: _arrived ? -.09 : 0,
              duration: const Duration(milliseconds: 500),
              child: Semantics(
                key: const ValueKey('cup'),
                container: true,
                button: true,
                label: CalmWay.water.zh,
                excludeSemantics: true,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _down,
                  onPointerMove: _move,
                  onPointerUp: (e) => _up(e, home, mouth, mmW * .35),
                  onPointerCancel: (e) => _up(e, home, mouth, mmW * .35),
                  child: const Art('calm/cup'),
                ),
              ),
            ),
          ),
          if (!_arrived)
            Positioned(left: w * .5, top: h * .66, child: const Bob(amount: 5, child: Icon(Icons.arrow_back_rounded, size: 38, color: Mallow.blue))),
        ]);
      });
}

// ---------------------------------------------------------------- 找大人
/// Tap to call a grown-up: the big calm cloud comes over and takes 棉棉's
/// hand. Then the app sends the child to a real grown-up.
class AdultView extends ConsumerStatefulWidget {
  const AdultView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<AdultView> createState() => _AdultViewState();
}

class _AdultViewState extends ConsumerState<AdultView> with HushOnLeave {
  var _called = false, _here = false;

  Future<void> _call() async {
    if (_called) return;
    setState(() => _called = true);
    sfx(ref, 'steps');
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _here = true);
    speak(ref, Strings.adultHere);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final mmW = math.min(w * .4, h * .42);
        final grownW = mmW * 1.35;
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(left: w * .08, top: h * .2, width: mmW, child: calming(CalmWay.adult.from, _here ? 1 : 0)),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1300),
            curve: Curves.easeInOut,
            left: _called ? w * .08 + mmW * .75 : w + 20,
            top: h * .2 - grownW * .25,
            width: grownW,
            child: const Cloud(kind: CloudKind.grownup, tint: Color(0xFFFFDDBE), flip: true),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Center(
              child: AnimatedOpacity(
                opacity: _called ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: Semantics(
                  key: const ValueKey('call-adult'),
                  container: true,
                  button: true,
                  label: Strings.callAdult,
                  excludeSemantics: true,
                  onTap: _call,
                  child: Pressable(
                    onTap: _call,
                    child: Container(
                      height: 76,
                      padding: const EdgeInsets.fromLTRB(10, 6, 26, 6),
                      decoration: mallowBox(Mallow.peach, radius: 38),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        AspectRatio(aspectRatio: 1, child: Art('calm/way_adult')),
                        SizedBox(width: 10),
                        Text(Strings.callAdult, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: Mallow.ink)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]);
      });
}
