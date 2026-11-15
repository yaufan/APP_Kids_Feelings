import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/feelings.dart';
import '../core/looks.dart';
import '../core/providers.dart';
import '../core/sounds.dart';
import '../core/stories.dart';
import 'cloud.dart';
import 'theme.dart';

/// A drawing from assets/art/ (nothing at all if it is missing).
class Art extends StatelessWidget {
  const Art(this.path, {super.key, this.fit = BoxFit.contain, this.alignment = Alignment.center});

  /// Under assets/art/, without ".svg" (house/sun).
  final String path;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/art/$path.svg', fit: fit, alignment: alignment, excludeFromSemantics: true, errorBuilder: (_, _, _) => const SizedBox.expand());
}

/// Says a line out loud (if the parent left the voice on), with the English
/// after it when that is on.
void speak(WidgetRef ref, String zh, {String? en}) {
  final s = ref.read(gameProvider).settings;
  if (!s.voice) return;
  ref.read(voiceProvider).say(zh, en: s.english ? en : null);
}

void sfx(WidgetRef ref, String name) => ref.read(soundsProvider).play(name);

/// Shrinks a little while pressed and fires when the finger lifts on it
/// (raw pointer events: a touch counts at once, no gesture to wait for).
class Pressable extends ConsumerStatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.sound = 'tap'});

  final Widget child;
  final VoidCallback? onTap;
  final String? sound;

  @override
  ConsumerState<Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<Pressable> {
  int? _pointer;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: enabled && _pointer == null ? (e) => setState(() => _pointer = e.pointer) : null,
      onPointerCancel: (e) {
        if (e.pointer == _pointer) setState(() => _pointer = null);
      },
      onPointerUp: (e) {
        if (e.pointer != _pointer) return;
        setState(() => _pointer = null);
        final box = context.findRenderObject() as RenderBox?;
        if (!enabled || box == null || !(Offset.zero & box.size).inflate(12).contains(e.localPosition)) return;
        final s = widget.sound;
        if (s != null) ref.read(soundsProvider).play(s);
        widget.onTap!();
      },
      child: AnimatedScale(scale: _pointer != null ? 0.93 : 1, duration: const Duration(milliseconds: 90), child: widget.child),
    );
  }
}

/// A soft marshmallow block: lit from the top left, a soft shadow below.
BoxDecoration mallowBox(Color color, {double radius = 26, bool shadow = true, Color? ring}) => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(color, Colors.white, .45)!, color, Color.lerp(color, Mallow.shade, .08)!],
        stops: const [0, .55, 1],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: ring == null ? null : Border.all(color: ring, width: 4),
      boxShadow: shadow ? [BoxShadow(color: Mallow.shade.withValues(alpha: .16), offset: const Offset(0, 6), blurRadius: 14)] : null,
    );

/// A round button with an icon.
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.label, required this.icon, this.onTap, this.size = 50, this.color = Colors.white, this.sound = 'tap'});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final String? sound;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          onTap: onTap,
          sound: sound,
          child: Container(
            width: size,
            height: size,
            decoration: mallowBox(color, radius: size / 2),
            child: Icon(icon, size: size * 0.52, color: color == Colors.white ? Mallow.ink : Colors.white),
          ),
        ),
      );
}

/// A wide soft pill with a word (and an icon or a picture).
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, this.onTap, this.color = Mallow.green, this.icon, this.height = 58, this.sound = 'tap', this.expand = false});

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final double height;
  final String? sound;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final light = color.computeLuminance() > .6;
    final fg = light ? Mallow.ink : Colors.white;
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        sound: sound,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: height * 0.42),
          decoration: mallowBox(color, radius: height / 2),
          child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: height * 0.44, color: fg), const SizedBox(width: 8)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: height * 0.34, fontWeight: FontWeight.w700, color: fg))),
          ]),
        ),
      ),
    );
  }
}

/// A speech bubble with a speaker: tap to hear it again.
class SpeakBubble extends StatelessWidget {
  const SpeakBubble({super.key, required this.text, this.onTap, this.size = 19});

  final String text;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: onTap != null,
        label: text,
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          onTap: onTap,
          sound: null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
            decoration: mallowBox(Colors.white, radius: 24),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: size * 1.7,
                height: size * 1.7,
                decoration: mallowBox(Mallow.green, radius: size, shadow: false),
                child: Icon(Icons.volume_up_rounded, color: Colors.white, size: size),
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: Mallow.ink, height: 1.35))),
            ]),
          ),
        ),
      );
}

/// The bar at the top of a room: back (or home), the room's name, the speaker.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.onBack, this.onSpeak, this.homeIcon = false, this.leading});

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onSpeak;
  final bool homeIcon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: Row(children: [
          leading ?? (onBack == null ? const SizedBox(width: 50) : RoundButton(label: homeIcon ? '回小屋' : '回去', icon: homeIcon ? Icons.home_rounded : Icons.chevron_left_rounded, onTap: onBack, size: 46)),
          Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Mallow.ink))),
          if (onSpeak != null) RoundButton(label: '再聽一次', icon: Icons.volume_up_rounded, onTap: onSpeak, size: 46, color: Mallow.mint, sound: null) else const SizedBox(width: 46),
        ]),
      );
}

/// The soft lavender-to-peach sky with a few pale clouds drifting.
class SkyBg extends StatelessWidget {
  const SkyBg({super.key, required this.child, this.top = Mallow.sky1, this.bottom = Mallow.sky2, this.clouds = true});

  final Widget child;
  final Color top, bottom;
  final bool clouds;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom])),
        child: Stack(fit: StackFit.expand, children: [
          if (clouds) ...[
            const Positioned(left: -30, top: 90, width: 150, height: 60, child: Opacity(opacity: .55, child: Bob(amount: 3, period: 5200, child: Art('house/puff')))),
            const Positioned(right: -40, top: 230, width: 170, height: 68, child: Opacity(opacity: .45, child: Bob(amount: 4, period: 6100, phase: .4, child: Art('house/puff')))),
          ],
          child,
        ]),
      );
}

/// Plays [music] while this is on screen.
class WithMusic extends ConsumerStatefulWidget {
  const WithMusic({super.key, required this.music, required this.child});

  final Music music;
  final Widget child;

  @override
  ConsumerState<WithMusic> createState() => _WithMusicState();
}

class _WithMusicState extends ConsumerState<WithMusic> {
  late final Sounds _sounds = ref.read(soundsProvider);

  @override
  void initState() {
    super.initState();
    _sounds.hold(this, widget.music);
  }

  @override
  void dispose() {
    _sounds.release(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shakes its child side to side once each time [trigger] changes.
class Wiggle extends StatefulWidget {
  const Wiggle({super.key, required this.trigger, required this.child, this.amount = 0.08});

  final int trigger;
  final Widget child;
  final double amount;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void didUpdateWidget(Wiggle old) {
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
          return Transform.rotate(angle: math.sin(t * math.pi * 4) * (1 - t) * widget.amount, child: child);
        },
        child: widget.child,
      );
}

/// A gentle bob up and down (棉棉 breathing, clouds drifting).
class Bob extends StatefulWidget {
  const Bob({super.key, required this.child, this.phase = 0, this.amount = 4, this.period = 2400});

  final Widget child;
  final double phase;
  final double amount;
  final int period;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.period))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(offset: Offset(0, math.sin((_c.value + widget.phase) * 2 * math.pi) * widget.amount), child: child),
        child: widget.child,
      );
}

/// A small cloud face for a feeling (cards, the diary, buttons).
class FaceIcon extends StatelessWidget {
  const FaceIcon(this.feeling, {super.key, this.kind = CloudKind.mianmian});

  final Feeling feeling;
  final CloudKind kind;

  @override
  Widget build(BuildContext context) {
    final l = Look.of(feeling);
    // Little extras (tears, steam) stay; the far-out ones would be cut off.
    final keep = {for (final e in l.extras.entries) if (e.key == Extra.hands || e.key == Extra.star || e.key == Extra.steam) e.key: e.value};
    return AspectRatio(
      aspectRatio: CloudPainter.box.width / CloudPainter.box.height,
      child: CustomPaint(painter: CloudPainter(l.copyWith(extras: keep), kind: kind, shadow: false)),
    );
  }
}

/// How a feeling card looks after an answer.
enum CardMark { none, picked, also, faded }

/// A feeling card: 棉棉's small face and the word (docs/design.md: 心情卡).
class FeelingCard extends StatelessWidget {
  const FeelingCard({super.key, required this.feeling, this.onTap, this.mark = CardMark.none, this.size = 120});

  final Feeling feeling;
  final VoidCallback? onTap;
  final CardMark mark;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        key: ValueKey('card-${feeling.name}'),
        container: true,
        button: true,
        label: feeling.zh,
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          onTap: onTap,
          sound: null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: mark == CardMark.faded ? .4 : 1,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: size,
                height: size * 1.02,
                padding: EdgeInsets.fromLTRB(size * .06, size * .06, size * .06, size * .04),
                decoration: mallowBox(Colors.white, radius: size * .22, ring: mark == CardMark.picked ? Mallow.green : null),
                child: Column(children: [
                  Expanded(child: FaceIcon(feeling)),
                  Text(feeling.zh, style: TextStyle(fontSize: size * .17, fontWeight: FontWeight.w700, color: Mallow.ink)),
                ]),
              ),
              if (mark == CardMark.picked)
                Positioned(right: -6, top: -6, child: Container(width: 30, height: 30, decoration: mallowBox(Mallow.green, radius: 15), child: const Icon(Icons.check_rounded, color: Colors.white, size: 22))),
              if (mark == CardMark.also)
                Positioned(
                  right: 4,
                  top: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: mallowBox(Mallow.yellow, radius: 12, shadow: false),
                    child: const Text('也可以', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Mallow.ink)),
                  ),
                ),
            ]),
          ),
        ),
      );
}
