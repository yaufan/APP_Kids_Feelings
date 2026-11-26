import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/cloud.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/feelings.dart';
import '../../core/game.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';

/// 心情日記 (docs/design.md): 「今天，你的心情是？」 The child taps a cloud,
/// 棉棉 becomes that feeling, and a big button says it to the grown-up.
/// Under it, this week: one little cloud a day, today shining, the days to
/// come dotted.
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> with HushOnLeave {
  Feeling? _picked;
  var _wiggle = 0;

  /// Going on after 「去跟爸爸媽媽說」 has been said.
  Later? _then;

  @override
  void dispose() {
    _then?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _picked = ref.read(gameProvider).today(ref.read(clockProvider)());
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  String get _line => _picked == null ? Strings.diaryAsk : Strings.diaryPicked(_picked!);

  void _say() {
    if (mounted) speak(ref, _line);
  }

  void _pick(Feeling f) {
    ref.read(gameProvider.notifier).change((g) => g.feel(ref.read(clockProvider)(), f));
    setState(() {
      _picked = f;
      _wiggle++;
    });
    sfx(ref, f.sound);
    speak(ref, Strings.diaryPicked(f), en: f.en);
  }

  void _tell() {
    final f = _picked;
    if (f == null) return;
    sfx(ref, 'ding');
    final said = speak(ref, Strings.toParents(f));
    final cards = ref.read(gameProvider).settings.cards;
    _then?.cancel();
    _then = Later(const Duration(milliseconds: 2600), () {
      if (mounted) context.go(cards ? '/talk?feeling=${f.name}' : '/');
    }, after: said);
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final now = ref.read(clockProvider)();
    final feelings = g.settings.feelings;
    final week = g.week(now);
    return WithMusic(
      music: Music.home,
      child: Scaffold(
        body: SkyBg(
          child: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final w = math.min(box.maxWidth, 560.0);
              final perRow = feelings.length > 4 ? 5 : 4;
              final cell = math.min((w - 32 - (perRow - 1) * 8) / perRow, box.maxHeight * (feelings.length > 4 ? .1 : .14));
              return Center(
                child: SizedBox(
                  width: w,
                  child: Column(children: [
                    TopBar(title: Strings.diary, onBack: () => context.go('/'), homeIcon: true, onSpeak: _say),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SpeakBubble(text: _line, onTap: _say, size: 18)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                      for (final f in feelings)
                        Semantics(
                          key: ValueKey('diary-${f.name}'),
                          container: true,
                          button: true,
                          label: '${Strings.diary} ${f.zh}',
                          excludeSemantics: true,
                          onTap: () => _pick(f),
                          child: Pressable(
                            onTap: () => _pick(f),
                            sound: null,
                            child: Container(
                              width: cell,
                              height: cell * 1.08,
                              padding: const EdgeInsets.fromLTRB(3, 4, 3, 2),
                              decoration: mallowBox(Colors.white, radius: cell * .24, ring: _picked == f ? Mallow.green : null),
                              child: Column(children: [
                                Expanded(child: FaceIcon(f)),
                                FittedBox(child: Text(f.zh, style: TextStyle(fontSize: math.max(12, cell * .16), color: Mallow.ink))),
                              ]),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    Text(Strings.thisWeek, style: const TextStyle(fontSize: 14, color: Mallow.inkSoft)),
                    const SizedBox(height: 4),
                    _Week(week: week, today: Days.key(now)),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: math.min(w * .5, box.maxHeight * .22 * 200 / 180),
                          child: Wiggle(trigger: _wiggle, child: Bob(amount: 3, child: Cloud(feeling: _picked ?? Feeling.calm))),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: AnimatedOpacity(
                        opacity: _picked == null ? .4 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: PillButton(label: Strings.tellParents, icon: Icons.record_voice_over_rounded, expand: true, height: 60, onTap: _picked == null ? null : _tell),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: PillButton(label: Strings.home, color: Colors.white, icon: Icons.home_rounded, expand: true, height: 50, onTap: () => context.go('/')),
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
}

/// Monday to Sunday: the feeling of each day, today with a ring, the days
/// to come as faint dotted clouds.
class _Week extends StatelessWidget {
  const _Week({required this.week, required this.today});

  final List<(DateTime, DiaryEntry?)> week;
  final String today;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(children: [
                Text(Days.weekdayZh[i], style: const TextStyle(fontSize: 13, color: Mallow.inkSoft)),
                const SizedBox(height: 2),
                Container(
                  key: ValueKey('week-$i'),
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: Days.key(week[i].$1) == today ? mallowBox(Mallow.yellow, radius: 14, shadow: false) : null,
                  padding: const EdgeInsets.all(3),
                  child: switch (week[i].$2?.feeling) {
                    final Feeling f => FaceIcon(f),
                    null => Days.key(week[i].$1).compareTo(today) > 0 ? const _Dotted() : const Opacity(opacity: .7, child: Art('icons/cloud_small')),
                  },
                ),
              ]),
            ),
        ]),
      );
}

/// A day still to come: a dotted outline of a cloud.
class _Dotted extends StatelessWidget {
  const _Dotted();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DotPainter(), size: Size.infinite);
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) * .36;
    final p = Paint()..color = Mallow.inkSoft.withValues(alpha: .45);
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * 2 * math.pi;
      canvas.drawCircle(c + Offset(math.cos(a) * r * 1.2, math.sin(a) * r * .8), 1.6, p);
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) => false;
}
