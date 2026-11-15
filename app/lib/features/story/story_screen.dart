import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/feelings.dart';
import '../../core/game.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../../core/stories.dart';
import 'story_picture.dart';

/// 小故事 (docs/design.md 「這是什麼心情」): a picture and a sentence; 小雨
/// has no face yet. Several answers can be right: picking one gives 小雨
/// that face, the other right ones say 「也可以」. Then 怎麼辦 (three good
/// ways to help), and the card for the grown-up.
class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({super.key});

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

enum _Phase { ask, answered, help, helped }

class _StoryScreenState extends ConsumerState<StoryScreen> {
  Story? _story;
  late Question _q;
  Feeling? _picked;
  HelpWay? _help;
  final _tried = <Feeling>{};
  var _phase = _Phase.ask;
  Timer? _toCalm;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final g = ref.read(gameProvider);
    _story = g.nextStory();
    final s = _story;
    if (s != null) _q = storyQuestion(s, g.settings, ref.read(randomProvider));
    _picked = null;
    _help = null;
    _tried.clear();
    _phase = _Phase.ask;
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  @override
  void dispose() {
    _toCalm?.cancel();
    super.dispose();
  }

  String get _line {
    final s = _story!;
    return switch (_phase) {
      _Phase.ask => '${s.line}\n${Strings.storyAsk}',
      _Phase.answered => _answerLine,
      _Phase.help => Strings.helpAsk(_picked!, _picked!.pleasant),
      _Phase.helped => _help!.result,
    };
  }

  String get _answerLine {
    final big = ref.read(gameProvider).settings.level == Level.big;
    final others = [for (final f in _q.options) if (_q.isRight(f) && f != _picked) f];
    return '${Strings.storyRight(_picked!, others)}${big ? '\n${Strings.ifYou}' : ''}';
  }

  void _say() {
    if (mounted && _story != null) speak(ref, _line.replaceAll('\n', ''));
  }

  void _pick(Feeling f) {
    if (_phase != _Phase.ask) return;
    sfx(ref, f.sound);
    if (!_q.isRight(f)) {
      sfx(ref, 'try');
      setState(() => _tried.add(f));
      speak(ref, Strings.storyWrong(f), en: f.en);
      return;
    }
    final story = _story!;
    ref.read(gameProvider.notifier).change((g) => g.toldStory(story.id));
    setState(() {
      _picked = f;
      _phase = _Phase.answered;
    });
    sfx(ref, 'right');
    _say();
    // 小小: an angry answer goes straight on to calming down (docs/design.md).
    if (ref.read(gameProvider).settings.level == Level.small && f == Feeling.angry) {
      _toCalm = Timer(const Duration(milliseconds: 4500), () {
        if (mounted && _phase == _Phase.answered) context.go('/calm?way=balloon');
      });
    }
  }

  void _toHelp() {
    _toCalm?.cancel();
    setState(() => _phase = _Phase.help);
    sfx(ref, 'pop');
    _say();
  }

  void _helped(HelpWay w) {
    setState(() {
      _help = w;
      _phase = _Phase.helped;
    });
    sfx(ref, w.sound);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) sfx(ref, 'sparkle');
    });
    _say();
  }

  void _next() {
    _toCalm?.cancel();
    sfx(ref, 'page');
    setState(_load);
  }

  void _talk() {
    _toCalm?.cancel();
    context.go('/talk?story=${_story!.id}&feeling=${_picked!.name}');
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    if (story == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const Scaffold(body: SkyBg(child: SizedBox()));
    }
    final cards = ref.watch(gameProvider.select((g) => g.settings.cards));
    final xiaoyu = switch (_phase) {
      _Phase.ask => null,
      _Phase.helped => _picked!.pleasant ? Feeling.happy : Feeling.calm,
      _ => _picked,
    };
    return WithMusic(
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
                    TopBar(title: _phase.index >= _Phase.help.index ? Strings.whatToDo : Strings.story, onBack: () => context.go('/'), onSpeak: _say),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: box.maxHeight * .36),
                        child: StoryPicture(story: story, feeling: xiaoyu, helper: _help),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SpeakBubble(text: _line, onTap: _say, size: 18)),
                    const SizedBox(height: 10),
                    Expanded(child: _bottom(w, box.maxHeight, cards)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _bottom(double w, double h, bool cards) {
    switch (_phase) {
      case _Phase.ask:
      case _Phase.answered:
        final big = _q.options.length > 2;
        final size = math.min((w - 60) / 2, h * (big ? .14 : .2));
        return Column(children: [
          Expanded(
            child: Center(
              child: Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
                for (final f in _q.options)
                  FeelingCard(
                    feeling: f,
                    size: size,
                    mark: _phase == _Phase.ask
                        ? (_tried.contains(f) ? CardMark.faded : CardMark.none)
                        : (f == _picked ? CardMark.picked : (_q.isRight(f) ? CardMark.also : CardMark.faded)),
                    onTap: () => _pick(f),
                  ),
              ]),
            ),
          ),
          SizedBox(
            height: 76,
            child: _phase == _Phase.answered
                ? Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, children: [
                    if (ref.read(gameProvider).settings.level == Level.small && _picked == Feeling.angry)
                      PillButton(label: Strings.goCalm, color: Mallow.mint, height: 54, onTap: () => context.go('/calm?way=balloon'))
                    else
                      PillButton(label: Strings.whatToDo, color: Mallow.coral, height: 54, onTap: _toHelp),
                    if (cards) PillButton(label: Strings.talk, color: Mallow.yellow, height: 54, onTap: _talk),
                  ])
                : null,
          ),
        ]);
      case _Phase.help:
        return HelpChoices(ways: _picked!.pleasant ? HelpWay.cheer : HelpWay.comfort, onPick: _helped);
      case _Phase.helped:
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            if (cards) PillButton(label: Strings.talk, color: Mallow.yellow, onTap: _talk),
            PillButton(label: Strings.nextStory, icon: Icons.arrow_forward_rounded, onTap: _next),
            PillButton(label: Strings.home, color: Colors.white, icon: Icons.home_rounded, onTap: () => context.go('/')),
          ]),
          const SizedBox(height: 14),
          const Text(Strings.shareNote, style: TextStyle(fontSize: 13, color: Mallow.inkSoft)),
        ]);
    }
  }
}

/// The three good ways to help (怎麼辦): none of them is wrong.
class HelpChoices extends StatelessWidget {
  const HelpChoices({super.key, required this.ways, required this.onPick});

  final List<HelpWay> ways;
  final void Function(HelpWay) onPick;

  static const _colors = [Mallow.pink, Mallow.blue, Mallow.mint];
  static const _icons = {
    HelpWay.hug: Icons.favorite_rounded,
    HelpWay.ask: Icons.chat_bubble_rounded,
    HelpWay.adult: Icons.escalator_warning_rounded,
    HelpWay.clap: Icons.celebration_rounded,
    HelpWay.praise: Icons.thumb_up_rounded,
    HelpWay.share: Icons.favorite_rounded,
  };

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < ways.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PillButton(key: ValueKey('help-${ways[i].name}'), label: ways[i].zh, color: _colors[i], icon: _icons[ways[i]], height: 58, expand: true, sound: null, onTap: () => onPick(ways[i])),
          ),
          const SizedBox(height: 10),
        ],
        const Text(Strings.helpAllGood, style: TextStyle(fontSize: 13, color: Mallow.inkSoft)),
        const SizedBox(height: 2),
        const Text(Strings.shareNote, style: TextStyle(fontSize: 13, color: Mallow.inkSoft)),
      ]);
}
