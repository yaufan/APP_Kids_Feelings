import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/cloud.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/feelings.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../parent/parent_gate.dart';

/// The front of the little house (docs/design.md 「畫面：心情小屋」): 棉棉 at
/// the door with today's feeling greets the child; five big doors below.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with HushOnLeave {
  var _wiggle = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(onceProvider).add('hello')) _greet();
    });
  }

  String get _line {
    final today = ref.read(gameProvider).today(ref.read(clockProvider)());
    return today == null ? Strings.hello : Strings.helloAgain(today);
  }

  void _greet() => speak(ref, _line);

  void _tapMianmian(Feeling f) {
    setState(() => _wiggle++);
    sfx(ref, f.sound);
    speak(ref, Strings.mianmianSays(f), en: f.en);
  }

  Future<void> _parent() async {
    if (!await showParentGate(context) || !mounted) return;
    context.go('/parent');
  }

  void _door(String path, bool open) {
    if (!open) {
      sfx(ref, 'try');
      speak(ref, Strings.locked);
      return;
    }
    sfx(ref, 'whoosh');
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final today = g.today(ref.read(clockProvider)());
    final full = g.settings.full;
    final feeling = today ?? Feeling.happy;
    return WithMusic(
      music: Music.home,
      child: Scaffold(
        body: SkyBg(
          child: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final w = math.min(box.maxWidth, 560.0);
              return Center(
                child: SizedBox(
                  width: w,
                  child: Column(children: [
                    TopBar(
                      title: Strings.appName,
                      leading: Semantics(
                        container: true,
                        button: true,
                        label: Strings.parent,
                        excludeSemantics: true,
                        onTap: _parent,
                        child: Pressable(
                          onTap: _parent,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: mallowBox(Colors.white, radius: 20),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.lock_outline_rounded, size: 18, color: Mallow.inkSoft),
                              SizedBox(width: 4),
                              Text(Strings.parent, style: TextStyle(fontSize: 15, color: Mallow.inkSoft)),
                            ]),
                          ),
                        ),
                      ),
                      onSpeak: _greet,
                    ),
                    Expanded(
                      flex: 11,
                      child: Stack(clipBehavior: Clip.none, children: [
                        Positioned(left: w * .04, top: 0, width: w * .2, height: w * .2, child: const Bob(amount: 3, period: 3000, child: Art('house/sun'))),
                        if (today != null)
                          Positioned(
                            right: 14,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
                              decoration: mallowBox(Colors.white, radius: 16),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                SizedBox(width: 30, child: FaceIcon(today)),
                                const SizedBox(width: 4),
                                Text(Strings.today(today), style: const TextStyle(fontSize: 14, color: Mallow.ink)),
                              ]),
                            ),
                          ),
                        Positioned(left: w * .26, right: 14, top: w * .1, child: Align(alignment: Alignment.centerRight, child: SpeakBubble(text: _line, onTap: _greet, size: 17))),
                        Positioned(left: -w * .05, right: -w * .05, bottom: 0, height: w * .26, child: const Art('house/ground', fit: BoxFit.fill)),
                        Positioned(left: w * .01, bottom: w * .1, width: w * .58, height: w * .5, child: const Art('house/house')),
                        Positioned(
                          right: w * .01,
                          bottom: w * .08,
                          width: w * .48,
                          child: Semantics(
                            key: const ValueKey('mianmian'),
                            container: true,
                            button: true,
                            label: '棉棉',
                            excludeSemantics: true,
                            onTap: () => _tapMianmian(feeling),
                            child: Pressable(
                              onTap: () => _tapMianmian(feeling),
                              sound: null,
                              child: Wiggle(trigger: _wiggle, child: Bob(amount: 3, child: Cloud(feeling: feeling))),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    Expanded(
                      flex: 9,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: Column(children: [
                          Expanded(
                            child: Row(children: [
                              Expanded(child: _Door(label: Strings.faces, art: 'icons/door_faces', color: Mallow.yellow, onTap: () => _door('/faces', true))),
                              const SizedBox(width: 12),
                              Expanded(child: _Door(label: Strings.story, art: 'icons/door_story', color: Mallow.blue, locked: !full, onTap: () => _door('/story', full))),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Row(children: [
                              Expanded(child: _Door(label: Strings.calm, art: 'icons/door_calm', color: Mallow.mint, onTap: () => _door('/calm', true))),
                              const SizedBox(width: 12),
                              Expanded(child: _Door(label: Strings.help, art: 'icons/door_help', color: Mallow.peach, locked: !full, onTap: () => _door('/help', full))),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          Expanded(child: _Door(label: Strings.diary, art: 'icons/door_diary', color: Mallow.lilac, wide: true, onTap: () => _door('/diary', true))),
                        ]),
                      ),
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

/// One of the five big doors: a picture first, the word for grown-ups.
class _Door extends StatelessWidget {
  const _Door({required this.label, required this.art, required this.color, required this.onTap, this.locked = false, this.wide = false});

  final String label;
  final String art;
  final Color color;
  final VoidCallback onTap;
  final bool locked;
  final bool wide;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          onTap: onTap,
          sound: null,
          child: Container(
            decoration: mallowBox(color, radius: 28),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(mainAxisAlignment: wide ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
              AspectRatio(aspectRatio: 1, child: Art(art)),
              const SizedBox(width: 6),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Mallow.ink)))),
              if (locked) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_rounded, size: 18, color: Mallow.inkSoft)),
            ]),
          ),
        ),
      );
}
