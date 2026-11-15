import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/cloud.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/feelings.dart';
import '../../core/sounds.dart';
import '../../core/stories.dart';

/// 家長一起說 (docs/design.md): a card for the grown-up after a story or the
/// diary: a question to ask the child, what to say together, and a small
/// tip. It can be read out, there is a next question, and it can always be
/// skipped (回小屋).
class TalkScreen extends ConsumerStatefulWidget {
  const TalkScreen({super.key, this.story, this.feeling});

  final Story? story;
  final Feeling? feeling;

  @override
  ConsumerState<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends ConsumerState<TalkScreen> {
  late final List<TalkCard> _cards = [?widget.story?.card, if (widget.feeling != null) feelingCards[widget.feeling]!];
  var _at = 0;

  TalkCard get _card => _cards[_at];

  void _read() => speak(ref, '${Strings.ask}：${_card.ask}${Strings.say}：${_card.say}');

  void _next() {
    sfx(ref, 'page');
    setState(() => _at = (_at + 1) % _cards.length);
  }

  @override
  Widget build(BuildContext context) => WithMusic(
        music: Music.story,
        child: Scaffold(
          body: SkyBg(
            child: SafeArea(
              child: LayoutBuilder(builder: (context, box) {
                final w = math.min(box.maxWidth, 560.0);
                Widget tag(String t, Color c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: mallowBox(c, radius: 14, shadow: false),
                      child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Mallow.ink)),
                    );
                return Center(
                  child: SizedBox(
                    width: w,
                    child: Column(children: [
                      TopBar(title: Strings.talk, onBack: () => context.go('/'), homeIcon: true, onSpeak: _read),
                      tag(Strings.forGrownUps, Mallow.yellow),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              key: ValueKey(_at),
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                              decoration: mallowBox(Colors.white, radius: 26),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                tag(Strings.ask, Mallow.mint),
                                const SizedBox(height: 8),
                                Text('「${_card.ask}」', style: const TextStyle(fontSize: 21, height: 1.5, fontWeight: FontWeight.w700, color: Mallow.ink)),
                                const Divider(height: 26),
                                tag(Strings.say, Mallow.peach),
                                const SizedBox(height: 8),
                                Text(_card.say, style: const TextStyle(fontSize: 18, height: 1.6, color: Mallow.ink)),
                                const SizedBox(height: 14),
                                Text('${Strings.tip}：${_card.tip}', style: const TextStyle(fontSize: 15, height: 1.5, color: Mallow.inkSoft)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: math.min(150, box.maxHeight * .18),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Flexible(child: Cloud(kind: CloudKind.grownup, tint: Color(0xFFCDEBDC))),
                          Padding(padding: const EdgeInsets.only(bottom: 70), child: SizedBox(width: 30, height: 28, child: Art('calm/heart'))),
                          Flexible(child: FractionallySizedBox(widthFactor: .8, child: Cloud(feeling: widget.feeling ?? Feeling.happy))),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                        child: Row(children: [
                          Expanded(child: PillButton(label: Strings.readOut, color: Colors.white, icon: Icons.volume_up_rounded, expand: true, height: 52, sound: null, onTap: _read)),
                          const SizedBox(width: 12),
                          Expanded(child: PillButton(label: Strings.nextCard, color: Colors.white, icon: Icons.arrow_forward_rounded, expand: true, height: 52, onTap: _cards.length > 1 ? _next : null)),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                        child: PillButton(label: Strings.home, icon: Icons.home_rounded, expand: true, height: 54, onTap: () => context.go('/')),
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
