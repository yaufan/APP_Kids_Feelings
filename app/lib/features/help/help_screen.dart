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
import '../story/story_picture.dart';
import '../story/story_screen.dart';

/// 怎麼辦 (docs/design.md): first a friend — 小雨 feels something, and the
/// child picks one of three good ways to help and sees it work; then the
/// child — 「如果你很生氣，可以怎麼做？」, and the calming way picked opens in
/// 冷靜小屋. Sharing and taking turns are left for real friends.
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  late final Story _story;
  late final Feeling _feels;
  /// The child's own feeling for the second round (null: none of them is
  /// on, so that round is skipped).
  late final Feeling? _self;
  HelpWay? _help;
  var _selfRound = false;

  @override
  void initState() {
    super.initState();
    final g = ref.read(gameProvider);
    final s = g.settings;
    final list = s.shownStories;
    _story = list[g.turn % list.length];
    _feels = _story.rightAt(s.level).firstWhere(s.feelings.contains);
    final selves = [Feeling.angry, Feeling.sad, Feeling.scared, if (s.level == Level.big) Feeling.nervous].where(s.feelings.contains).toList();
    _self = selves.isEmpty ? null : selves[g.turn % selves.length];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(gameProvider.notifier).change((g) => g.nextTurn());
      _say();
    });
  }

  String get _line => _selfRound ? Strings.selfAsk(_self!) : (_help?.result ?? '${_story.line}\n${Strings.helpAsk(_feels, _feels.pleasant)}');

  void _say() {
    if (mounted) speak(ref, _line.replaceAll('\n', ''));
  }

  void _helped(HelpWay w) {
    setState(() => _help = w);
    sfx(ref, w.sound);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) sfx(ref, 'sparkle');
    });
    _say();
  }

  void _toSelf() {
    setState(() => _selfRound = true);
    sfx(ref, 'pop');
    _say();
  }

  /// The ways to try for the child's own feeling, among the ones on offer.
  List<CalmWay> get _ways {
    final on = ref.read(gameProvider).settings.calmWays;
    final ways = [for (final w in CalmWay.forFeeling(_self!)) if (on.contains(w)) w];
    for (final w in on) {
      if (ways.length >= 3) break;
      if (!ways.contains(w)) ways.add(w);
    }
    return ways;
  }

  @override
  Widget build(BuildContext context) => WithMusic(
        music: Music.story,
        child: Scaffold(
          body: SkyBg(
            child: SafeArea(
              child: LayoutBuilder(builder: (context, box) {
                final w = math.min(box.maxWidth, 560.0);
                return Center(
                  child: SizedBox(
                    width: w,
                    child: Column(children: [
                      TopBar(title: Strings.whatToDo, onBack: () => context.go('/'), onSpeak: _say),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: box.maxHeight * .36),
                          child: _selfRound
                              ? AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: Container(
                                    decoration: mallowBox(Colors.white, radius: 26),
                                    padding: const EdgeInsets.all(18),
                                    child: Bob(amount: 3, child: Cloud(key: const ValueKey('self'), feeling: _self!)),
                                  ),
                                )
                              : StoryPicture(story: _story, feeling: _help == null ? _feels : (_feels.pleasant ? Feeling.happy : Feeling.calm), helper: _help),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SpeakBubble(text: _line, onTap: _say, size: 18)),
                      const SizedBox(height: 12),
                      Expanded(child: _bottom()),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
      );

  Widget _bottom() {
    if (_selfRound) {
      return Column(children: [
        for (final way in _ways) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Semantics(
              key: ValueKey('self-${way.name}'),
              container: true,
              button: true,
              label: way.zh,
              excludeSemantics: true,
              onTap: () => context.go('/calm?way=${way.name}'),
              child: Pressable(
                onTap: () => context.go('/calm?way=${way.name}'),
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: mallowBox(Mallow.mint, radius: 31),
                  child: Row(children: [
                    SizedBox(width: 48, height: 48, child: Art('calm/way_${way.art}')),
                    const SizedBox(width: 12),
                    Text(way.zh, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Mallow.ink)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const Text(Strings.selfNote, style: TextStyle(fontSize: 13, color: Mallow.inkSoft)),
      ]);
    }
    if (_help == null) return HelpChoices(ways: _feels.pleasant ? HelpWay.cheer : HelpWay.comfort, onPick: _helped);
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
        PillButton(label: Strings.home, color: Colors.white, icon: Icons.home_rounded, onTap: () => context.go('/')),
        if (_self != null) PillButton(label: Strings.nextOne, icon: Icons.arrow_forward_rounded, onTap: _toSelf),
      ]),
      const SizedBox(height: 14),
      const Text(Strings.shareNote, style: TextStyle(fontSize: 13, color: Mallow.inkSoft)),
    ]);
  }
}
