import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/cloud.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/calm.dart';
import '../../core/feelings.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../../core/stories.dart';
import 'calm_views.dart';

/// 冷靜小屋 (docs/design.md): six ways to calm down, each a little thing to
/// really do with 棉棉 doing it too, 棉棉's face going from upset to 安心.
/// Opened from parent mode it has no time limit; walked into from the house
/// it is play time, and when the time runs out the way being done is
/// finished first (RestGuard). 找大人 ends the visit and sends the child to a
/// real grown-up.
class CalmScreen extends ConsumerStatefulWidget {
  const CalmScreen({super.key, this.start});

  /// Opened straight on one way (from 怎麼辦).
  final CalmWay? start;

  @override
  ConsumerState<CalmScreen> createState() => _CalmScreenState();
}

class _CalmScreenState extends ConsumerState<CalmScreen> with HushOnLeave {
  late CalmWay? _way = widget.start;
  var _finished = false;
  final _done = <CalmWay>[];
  CalmWay? _best;
  var _hug = 0;

  /// The way being done holds off the rest (calmBusyProvider) until it is
  /// finished and 棉棉's hug has been seen and heard.
  late final Busy _busy;
  Later? _release;

  @override
  void initState() {
    super.initState();
    _busy = ref.read(calmBusyProvider);
    if (_way != null) _busy.start(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  @override
  void dispose() {
    _release?.cancel();
    _busy.end(this);
    super.dispose();
  }

  void _letGo() {
    _release?.cancel();
    _release = null;
    _busy.end(this);
  }

  String get _line {
    final w = _way;
    if (w == null) return Strings.calmPick;
    if (!_finished) return w.howTo;
    if (w == CalmWay.adult) return '${Strings.adultHere}\n${Strings.goFindAdult}';
    if (_best != null) return Strings.calmBestSaid(_best!);
    return Strings.calmDone;
  }

  Future<void> _say() => mounted ? speak(ref, _line.replaceAll('\n', '')) : Future.value();

  void _open(CalmWay w) {
    sfx(ref, 'whoosh');
    _release?.cancel();
    _busy.start(this);
    setState(() {
      _way = w;
      _finished = false;
      _best = null;
    });
    _say();
  }

  void _finish() {
    final w = _way!;
    ref.read(gameProvider.notifier).change((g) => g.calmed(ref.read(clockProvider)(), w));
    setState(() {
      _finished = true;
      if (!_done.contains(w)) _done.add(w);
      _hug++;
    });
    sfx(ref, w == CalmWay.adult ? 'chime' : 'hug');
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) sfx(ref, 'feel_calm');
    });
    _release?.cancel();
    _release = Later(const Duration(seconds: 3), _letGo, after: _say(), atMost: const Duration(seconds: 8));
  }

  void _pickBest(CalmWay w) {
    ref.read(gameProvider.notifier).change((g) => g.best(ref.read(clockProvider)(), w));
    setState(() => _best = w);
    sfx(ref, 'ding');
    _say();
  }

  void _back() {
    if (_way != null && !_finished && widget.start == null) {
      _letGo();
      setState(() => _way = null);
      _say();
      return;
    }
    context.go('/');
  }

  void _again() {
    _letGo();
    setState(() => _way = null);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameProvider.select((g) => g.settings));
    return WithMusic(
      music: Music.calm,
      child: Scaffold(
        body: SkyBg(
          top: const Color(0xFFE2F3EC),
          bottom: const Color(0xFFF3EEFB),
          child: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final w = math.min(box.maxWidth, 560.0);
              return Center(
                child: SizedBox(
                  width: w,
                  child: Column(children: [
                    TopBar(title: Strings.calm, onBack: _back, homeIcon: _finished || _way == null, onSpeak: _say),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SpeakBubble(text: _line, onTap: _say, size: 18)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _way == null
                          ? _picker(s.calmWays, w)
                          : (_finished
                              ? _finishedView(s.level == Level.big)
                              : CalmActivity(key: ValueKey(_way), way: _way!, onDone: _finish, shake: s.shake)),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _picker(List<CalmWay> ways, double w) => Column(children: [
        SizedBox(height: w * .34, child: const Bob(amount: 3, child: Cloud(feeling: Feeling.nervous))),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            crossAxisCount: ways.length > 4 ? 3 : (ways.length == 3 ? 3 : 2),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: .86,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final way in ways)
                Semantics(
                  key: ValueKey('way-${way.name}'),
                  container: true,
                  button: true,
                  label: way.zh,
                  excludeSemantics: true,
                  onTap: () => _open(way),
                  child: Pressable(
                    onTap: () => _open(way),
                    sound: null,
                    child: Container(
                      decoration: mallowBox(Colors.white, radius: 24),
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                      child: Column(children: [
                        Expanded(child: Art('calm/way_${way.art}')),
                        const SizedBox(height: 4),
                        FittedBox(child: Text(way.zh, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Mallow.ink))),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ]);

  Widget _finishedView(bool big) {
    final adult = _way == CalmWay.adult;
    return Column(children: [
      Expanded(
        child: LayoutBuilder(builder: (context, box) {
          final size = math.min(box.maxWidth * .6, box.maxHeight * .95);
          return Stack(alignment: Alignment.center, children: [
            if (adult)
              Positioned(
                right: box.maxWidth * .04,
                bottom: 0,
                width: size * .95,
                child: const Cloud(kind: CloudKind.grownup, tint: Color(0xFFFFDDBE), flip: true),
              ),
            Positioned(
              left: adult ? box.maxWidth * .08 : null,
              bottom: 0,
              width: adult ? size * .7 : size,
              child: _HugBounce(trigger: _hug, child: const Cloud(key: ValueKey('mianmian-calm'), feeling: Feeling.calm)),
            ),
            if (!adult) Positioned(top: 0, width: 54, height: 50, child: Bob(amount: 5, child: Art('calm/heart', key: ValueKey('heart-$_hug')))),
          ]);
        }),
      ),
      if (big && !adult && _done.length >= 2) ...[
        const Text(Strings.calmBest, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Mallow.ink)),
        const SizedBox(height: 6),
        Wrap(spacing: 10, children: [
          for (final w in _done)
            Semantics(
              key: ValueKey('best-${w.name}'),
              container: true,
              button: true,
              label: '${Strings.calmBest} ${w.zh}',
              excludeSemantics: true,
              onTap: () => _pickBest(w),
              child: Pressable(
                onTap: () => _pickBest(w),
                sound: null,
                child: Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(6),
                  decoration: mallowBox(Colors.white, radius: 31, ring: _best == w ? Mallow.green : null),
                  child: Art('calm/way_${w.art}'),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 10),
      ],
      Padding(
        padding: const EdgeInsets.only(bottom: 14, top: 6),
        child: Wrap(spacing: 12, runSpacing: 10, alignment: WrapAlignment.center, children: [
          if (!adult) PillButton(label: Strings.calmAgain, color: Mallow.mint, icon: Icons.refresh_rounded, onTap: _again),
          PillButton(label: Strings.home, icon: Icons.home_rounded, onTap: () => context.go('/')),
        ]),
      ),
    ]);
  }
}

/// 棉棉's hug: it comes close (grows a little) and settles.
class _HugBounce extends StatefulWidget {
  const _HugBounce({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<_HugBounce> createState() => _HugBounceState();
}

class _HugBounceState extends State<_HugBounce> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void didUpdateWidget(_HugBounce old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          final s = 1 + .12 * math.sin(t * math.pi) * (1 - t * .5);
          return Transform.scale(scale: s, alignment: Alignment.bottomCenter, child: child);
        },
        child: widget.child,
      );
}
