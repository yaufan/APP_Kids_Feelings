import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game.dart';
import 'shake.dart';
import 'sounds.dart';
import 'store.dart';
import 'voice.dart';

/// What time it is (tests and screenshots set it): the diary's day and the
/// play-time limit use it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Dice (tests give a seeded one).
final randomProvider = Provider<math.Random>((ref) => math.Random());

final storeProvider = Provider<GameStore>((ref) => MemoryStore());
final savedGameProvider = Provider<Game>((ref) => const Game());
final soundsProvider = Provider<Sounds>((ref) => const SilentSounds());
final voiceProvider = Provider<Voice>((ref) => const SilentVoice());
final shakesProvider = Provider<Shakes>((ref) => const NoShakes());

/// The game; every change is saved straight away.
final gameProvider = NotifierProvider<GameNotifier, Game>(GameNotifier.new);

class GameNotifier extends Notifier<Game> {
  @override
  Game build() => ref.read(savedGameProvider);

  void change(Game Function(Game g) f) {
    final next = f(state);
    if (identical(next, state)) return;
    state = next;
    ref.read(storeProvider).write(next.toJson());
  }

  void settings(Settings Function(Settings s) f) => change((g) => g.copyWith(settings: f(g.settings)));
}

/// When this sitting started (reset when a parent lets play go on, or after
/// ten minutes away). Time that was not play (parent mode, the background, a
/// calm room a parent opened) moves it later.
final sessionStartProvider = NotifierProvider<SessionStart, DateTime>(SessionStart.new);

class SessionStart extends Notifier<DateTime> {
  /// Away (or closed) this long, the next sitting is a new one.
  static const awayIsRest = Duration(minutes: 10);

  /// The app was closed during a sitting and opened again within
  /// [awayIsRest]: it goes on with it, and the time it was closed is not
  /// counted (a clock moved back meanwhile gives no extra time either).
  @override
  DateTime build() {
    final now = ref.read(clockProvider)();
    final s = ref.read(gameProvider).sitting;
    if (s != null && now.difference(s.seen) < awayIsRest) return now.subtract(s.played);
    return now;
  }

  void restart() => state = ref.read(clockProvider)();

  /// Moves the start by [d] (never later than now): later by time that was
  /// not the child's, earlier by as much as the phone's clock was moved
  /// back, so that gives no extra time.
  void shift(Duration d) {
    final now = ref.read(clockProvider)(), moved = state.add(d);
    state = moved.isAfter(now) ? now : moved;
  }
}

/// A calming way being done in a calm room a child walked into: when the
/// play time runs out, it is finished first (at most two minutes more,
/// RestGuard.finishCalm). The screen doing it holds it, so a screen going
/// away cannot let go of another one's.
final calmBusyProvider = Provider<Busy>((ref) => Busy());

class Busy {
  Object? _owner;

  bool get busy => _owner != null;

  void start(Object owner) => _owner = owner;

  void end(Object owner) {
    if (identical(_owner, owner)) _owner = null;
  }
}

/// Things said only once per app start (the welcome).
final onceProvider = Provider<Set<String>>((ref) => <String>{});
