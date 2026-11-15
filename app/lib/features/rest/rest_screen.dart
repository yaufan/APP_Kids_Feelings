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

/// The play time is up (docs/design.md 「每次玩多久」): 棉棉 yawns, the sky
/// turns to sunset, the house lights come on, and the child is sent to the
/// grown-ups: 「換你去做了！去跟爸爸媽媽說說你今天的心情。」 Only a parent
/// (through the gate) or an hour's wait lets play go on.
class RestScreen extends ConsumerStatefulWidget {
  const RestScreen({super.key});

  @override
  ConsumerState<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends ConsumerState<RestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      sfx(ref, 'night');
      speak(ref, Strings.restLine.replaceAll('\n', ''));
    });
  }

  Future<void> _parent() async {
    if (!await showParentGate(context) || !mounted) return;
    ref.read(gameProvider.notifier).change((g) => g.playOn());
    ref.read(sessionStartProvider.notifier).restart();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) => WithMusic(
        music: Music.rest,
        child: Scaffold(
          body: SkyBg(
            top: Mallow.night1,
            bottom: Mallow.night2,
            clouds: false,
            child: SafeArea(
              child: LayoutBuilder(builder: (context, box) {
                final w = math.min(box.maxWidth, 560.0);
                return Center(
                  child: SizedBox(
                    width: w,
                    child: Column(children: [
                      Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.fromLTRB(0, 16, 26, 0), child: SizedBox(width: w * .2, height: w * .2, child: const Art('house/moon')))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          decoration: mallowBox(Colors.white, radius: 26),
                          child: const Column(children: [
                            Text(Strings.restTitle, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Mallow.ink)),
                            SizedBox(height: 8),
                            Text(Strings.restLine, textAlign: TextAlign.center, style: TextStyle(fontSize: 21, height: 1.5, color: Mallow.ink)),
                          ]),
                        ),
                      ),
                      Expanded(
                        child: Stack(children: [
                          Positioned(left: -w * .05, right: -w * .05, bottom: 0, height: w * .26, child: const Art('house/ground', fit: BoxFit.fill)),
                          Positioned(left: w * .04, bottom: w * .1, width: w * .5, height: w * .44, child: const Art('house/house_lit')),
                          Positioned(right: w * .04, bottom: w * .08, width: w * .42, child: const Bob(amount: 2, period: 3600, child: Cloud(feeling: Feeling.tired))),
                        ]),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 6, 18, 16),
                          child: Semantics(
                            container: true,
                            button: true,
                            label: Strings.parent,
                            excludeSemantics: true,
                            onTap: _parent,
                            child: Pressable(
                              onTap: _parent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: mallowBox(Colors.white.withValues(alpha: .85), radius: 22, shadow: false),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.lock_outline_rounded, color: Mallow.inkSoft, size: 20),
                                  SizedBox(width: 6),
                                  Text(Strings.parent, style: TextStyle(fontSize: 16, color: Mallow.inkSoft)),
                                ]),
                              ),
                            ),
                          ),
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
