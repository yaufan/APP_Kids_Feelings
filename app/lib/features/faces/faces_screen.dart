import 'dart:async';
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
import '../../core/looks.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';

/// 認表情 (docs/design.md): 棉棉 makes a face, the child picks the card. A
/// right card: 棉棉 nods, says it, then slowly turns happy again (the face
/// changing is the reward). A wrong card: nothing lost, 棉棉 says what it
/// isn't and its eyebrows jump as a hint.
class FacesScreen extends ConsumerStatefulWidget {
  const FacesScreen({super.key});

  @override
  ConsumerState<FacesScreen> createState() => _FacesScreenState();
}

class _FacesScreenState extends ConsumerState<FacesScreen> {
  late Question _q = _make(null);
  Feeling? _shown;
  final _tried = <Feeling>{};
  var _done = false, _hint = 0, _nod = 0;
  Timer? _later;

  Question _make(Feeling? last) => faceQuestion(ref.read(gameProvider).settings, ref.read(randomProvider), last: last);

  Feeling get _target => _q.right.single;

  @override
  void initState() {
    super.initState();
    _shown = _target;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  @override
  void dispose() {
    _later?.cancel();
    super.dispose();
  }

  void _ask() {
    if (mounted) speak(ref, Strings.facesAsk);
  }

  void _pick(Feeling f) {
    if (_done) return;
    sfx(ref, f.sound);
    if (_q.isRight(f)) {
      final big = ref.read(gameProvider).settings.level == Level.big;
      setState(() {
        _done = true;
        _nod++;
      });
      speak(ref, '${Strings.facesRight(f)}${big ? Strings.howKnow : ''}', en: f.en);
      _later = Timer(const Duration(milliseconds: 2200), () {
        if (!mounted) return;
        sfx(ref, 'sparkle');
        // Back to happy (or calm, when it was happy): the feeling passes.
        setState(() => _shown = f == Feeling.happy ? Feeling.calm : Feeling.happy);
      });
    } else {
      setState(() {
        _tried.add(f);
        _hint++;
      });
      sfx(ref, 'try');
      speak(ref, Strings.facesWrong(f, Look.of(_target).browOn > 0), en: f.en);
    }
  }

  void _next() {
    _later?.cancel();
    setState(() {
      _q = _make(_target);
      _shown = _target;
      _tried.clear();
      _done = false;
    });
    sfx(ref, 'pop');
    _ask();
  }

  @override
  Widget build(BuildContext context) {
    final big = ref.watch(gameProvider.select((g) => g.settings.level)) == Level.big;
    return WithMusic(
      music: Music.home,
      child: Scaffold(
        body: SkyBg(
          child: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final w = math.min(box.maxWidth, 560.0);
              final card = math.min((w - 60) / 2, box.maxHeight * (big ? .19 : .24));
              return Center(
                child: SizedBox(
                  width: w,
                  child: Column(children: [
                    TopBar(title: Strings.faces, onBack: () => context.go('/'), homeIcon: true, onSpeak: _ask),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: SpeakBubble(text: _done && big ? Strings.howKnow : Strings.facesAsk, onTap: _ask)),
                    Expanded(
                      child: Stack(alignment: Alignment.bottomCenter, children: [
                        Positioned(left: 10, right: 10, bottom: 0, height: w * .22, child: const Art('house/ground', fit: BoxFit.fill)),
                        Positioned(
                          bottom: w * .07,
                          width: math.min(w * .7, box.maxHeight * .36),
                          child: Wiggle(
                            key: const ValueKey('stage'),
                            trigger: _nod,
                            amount: .05,
                            child: Bob(amount: 3, child: Cloud(feeling: _shown, hint: _hint, duration: const Duration(milliseconds: 1400))),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text(_done ? '' : Strings.facesTap, style: const TextStyle(fontSize: 14, color: Mallow.inkSoft)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final f in _q.options)
                          FeelingCard(
                            feeling: f,
                            size: card,
                            mark: _done ? (_q.isRight(f) ? CardMark.picked : CardMark.faded) : (_tried.contains(f) ? CardMark.faded : CardMark.none),
                            onTap: () => _pick(f),
                          ),
                      ],
                    ),
                    SizedBox(
                      height: 84,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: !_done
                              ? const SizedBox.shrink()
                              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  PillButton(label: Strings.home, color: Colors.white, icon: Icons.home_rounded, onTap: () => context.go('/')),
                                  const SizedBox(width: 12),
                                  PillButton(label: Strings.nextOne, icon: Icons.arrow_forward_rounded, onTap: _next),
                                ]),
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
}
