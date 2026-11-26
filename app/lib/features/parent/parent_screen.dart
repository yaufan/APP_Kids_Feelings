import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/version.dart';
import '../../app/widgets.dart';
import '../../core/feelings.dart';
import '../../core/game.dart';
import '../../core/providers.dart';
import 'parent_gate.dart';

/// Parent mode (after the gate): the age, the play time, 冷靜小屋 at once
/// (no time limit, not play time), the cards for grown-ups, the pillow
/// shake, which feelings, sounds, the diary week, ideas for real life, the
/// full version. The back key, five minutes without a touch or the app going
/// to the background take it back to the house.
class ParentScreen extends ConsumerWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ParentIdle(
        onClose: () => context.go('/'),
        child: BackTo(onBack: () => context.go('/'), child: _page(context, ref)),
      );

  Widget _page(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    final s = g.settings;
    final game = ref.read(gameProvider.notifier);
    final now = ref.read(clockProvider)();

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 15, color: Mallow.inkSoft, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...children,
              ]),
            ),
          ),
        );

    Widget toggle(String label, bool value, void Function(bool)? set, {Key? key, String? note}) => SwitchListTile(
          key: key,
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(fontSize: 17)),
          subtitle: note == null ? null : Text(note, style: const TextStyle(fontSize: 13, color: Mallow.inkSoft)),
          value: value,
          onChanged: set,
        );

    Widget chips<T>(List<T> values, T selected, String Function(T) label, void Function(T) pick, String keyOf) => Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in values)
            ChoiceChip(
              key: ValueKey('$keyOf-${v is Enum ? v.name : v}'),
              label: Text(label(v), style: const TextStyle(fontSize: 16)),
              selected: v == selected,
              onSelected: (_) => pick(v),
              selectedColor: const Color(0xFFE3D8FA),
              showCheckmark: false,
            ),
        ]);

    const note = TextStyle(fontSize: 14, height: 1.5, color: Mallow.inkSoft);
    final week = g.week(now);
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final most = g.mostFelt(monthStart, monthEnd);
    final mostCalm = g.mostCalm(monthStart, monthEnd);
    final written = week.where((d) => d.$2 != null).toList();

    return Scaffold(
      backgroundColor: Mallow.parentBg,
      appBar: AppBar(
        backgroundColor: Mallow.parentBg,
        title: const Text(Strings.parentTitle),
        leading: IconButton(icon: const Icon(Icons.close_rounded), tooltip: Strings.back, onPressed: () => context.go('/')),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        section(Strings.calm, [
          const Text(Strings.openCalmNote, style: note),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('open-calm'),
            onPressed: () => context.go('/calm'),
            icon: const Icon(Icons.spa_rounded),
            label: const Text(Strings.openCalm),
          ),
        ]),
        section(Strings.age, [
          chips(Level.values, s.level, Strings.levelLine, (v) => game.settings((x) => x.copyWith(level: v)), 'level'),
          const SizedBox(height: 10),
          const Text(Strings.ageNote, style: note),
        ]),
        section(Strings.playTime, [
          chips(Settings.minuteChoices, s.minutes, Strings.minutes, (v) => game.settings((x) => x.copyWith(minutes: v)), 'minutes'),
          const SizedBox(height: 10),
          const Text(Strings.playTimeNote, style: note),
          if (g.resting(now)) ...[
            const SizedBox(height: 10),
            const Text(Strings.resting, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            FilledButton(
              key: const ValueKey('play-on'),
              onPressed: () {
                game.change((g) => g.playOn());
                ref.read(sessionStartProvider.notifier).restart();
                context.go('/');
              },
              child: const Text(Strings.playOn),
            ),
          ],
        ]),
        section(Strings.diaryTitle, [
          if (written.isEmpty) const Text(Strings.diaryNone, style: note),
          for (var i = 0; i < 7; i++)
            if (week[i].$2 case final e?)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (e.feeling != null) SizedBox(width: 30, height: 26, child: FaceIcon(e.feeling!)) else const SizedBox(width: 30),
                  const SizedBox(width: 8),
                  Expanded(child: Text(Strings.dayLine(Days.weekdayZh[i], e.feeling, e.calm, e.best), style: const TextStyle(fontSize: 16, height: 1.4))),
                ]),
              ),
          if (most != null) Text(Strings.mostFelt(most), style: const TextStyle(fontSize: 15, color: Mallow.coral, fontWeight: FontWeight.w700)),
          if (mostCalm != null) Text(Strings.mostCalm(mostCalm), style: const TextStyle(fontSize: 15, color: Mallow.green, fontWeight: FontWeight.w700)),
        ]),
        section(Strings.talkCards, [
          toggle(Strings.talkCardsSwitch, s.cards, (v) => game.settings((x) => x.copyWith(cards: v)), key: const ValueKey('cards')),
          toggle(Strings.shake, s.shake, (v) => game.settings((x) => x.copyWith(shake: v)), key: const ValueKey('shake'), note: Strings.shakeNote),
        ]),
        if (s.level == Level.big && s.full)
          section(Strings.feelingsTitle, [
            const Text(Strings.feelingsNote, style: note),
            if (Feeling.basics.where((b) => !s.hidden.contains(b)).length <= Settings.minBasics)
              const Padding(padding: EdgeInsets.only(top: 4), child: Text(Strings.feelingsMin, style: TextStyle(fontSize: 14, color: Mallow.coral))),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final f in Feeling.values)
                FilterChip(
                  key: ValueKey('feeling-${f.name}'),
                  label: Text(f.zh, style: const TextStyle(fontSize: 16)),
                  selected: !s.hidden.contains(f),
                  onSelected: s.canHideNow(f) ? (on) => game.settings((x) => x.copyWith(hidden: on ? ({...x.hidden}..remove(f)) : {...x.hidden, f})) : null,
                  selectedColor: const Color(0xFFD8F0E6),
                ),
            ]),
          ]),
        section(Strings.sound, [
          toggle(Strings.music, s.music, (v) => game.settings((x) => x.copyWith(music: v)), key: const ValueKey('music')),
          toggle(Strings.effects, s.sounds, (v) => game.settings((x) => x.copyWith(sounds: v)), key: const ValueKey('effects')),
          toggle(Strings.voice, s.voice, (v) => game.settings((x) => x.copyWith(voice: v)), key: const ValueKey('voice')),
          toggle(Strings.english, s.english, (v) => game.settings((x) => x.copyWith(english: v)), key: const ValueKey('english')),
        ]),
        section(Strings.together, [
          for (final t in Strings.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.favorite_rounded, size: 16, color: Mallow.rose)),
                const SizedBox(width: 8),
                Expanded(child: Text(t, style: const TextStyle(fontSize: 16, height: 1.45))),
              ]),
            ),
        ]),
        section(Strings.fullVersion, [
          const Text(Strings.fullNote, style: note),
          toggle(Strings.fullSwitch, s.full, (v) => game.settings((x) => x.copyWith(full: v)), key: const ValueKey('full')),
        ]),
        section(Strings.about, [
          const Text(Strings.privacy, style: TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 6),
          Text(Strings.version(appVersion), style: note),
        ]),
      ]),
    );
  }
}
