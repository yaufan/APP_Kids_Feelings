import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/calm.dart';
import '../core/feelings.dart';
import '../core/game.dart';
import '../core/providers.dart';
import '../core/stories.dart';
import '../features/calm/calm_screen.dart';
import '../features/diary/diary_screen.dart';
import '../features/faces/faces_screen.dart';
import '../features/help/help_screen.dart';
import '../features/home/home_screen.dart';
import '../features/parent/parent_gate.dart';
import '../features/parent/parent_screen.dart';
import '../features/rest/rest_screen.dart';
import '../features/story/story_screen.dart';
import '../features/talk/talk_screen.dart';
import 'strings.dart';
import 'theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final resting = ref.read(gameProvider).resting(ref.read(clockProvider)());
  final router = GoRouter(
    initialLocation: resting ? '/rest' : '/',
    // Always start here, whatever page another app asks the phone to open.
    overridePlatformDefaultLocation: true,
    redirect: (_, state) {
      final at = state.matchedLocation;
      final q = state.uri.queryParameters;
      if (at == '/parent' && !ParentPass.take()) return '/';
      final full = ref.read(gameProvider).settings.full;
      if ((at == '/story' || at == '/help') && !full) return '/';
      if (q['way'] != null && CalmWay.values.asNameMap()[q['way']] == null) return '/calm';
      if (at == '/talk' && stories.every((s) => s.id != q['story']) && Feeling.values.asNameMap()[q['feeling']] == null) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/faces', builder: (_, _) => const FacesScreen()),
      GoRoute(path: '/story', builder: (_, _) => const StoryScreen()),
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      GoRoute(path: '/calm', builder: (_, s) => CalmScreen(key: ValueKey(s.uri.toString()), start: CalmWay.values.asNameMap()[s.uri.queryParameters['way']])),
      GoRoute(path: '/diary', builder: (_, _) => const DiaryScreen()),
      GoRoute(
        path: '/talk',
        builder: (_, s) => TalkScreen(
          key: ValueKey(s.uri.toString()),
          story: stories.where((x) => x.id == s.uri.queryParameters['story']).firstOrNull,
          feeling: Feeling.values.asNameMap()[s.uri.queryParameters['feeling']],
        ),
      ),
      GoRoute(path: '/rest', builder: (_, _) => const RestScreen()),
      GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class FeelingsApp extends ConsumerWidget {
  const FeelingsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameProvider.select((g) => g.settings));
    ref.read(soundsProvider)
      ..music = settings.music
      ..effects = settings.sounds;
    return MaterialApp.router(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: MallowTheme.light(),
      locale: const Locale('zh', 'TW'),
      supportedLocales: const [Locale('zh', 'TW')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      builder: (_, child) => RestGuard(child: child ?? const SizedBox()),
    );
  }
}

/// Keeps the parent's play time (docs/design.md 「每次玩多久」): when the
/// sitting has gone on for the minutes they set, 棉棉 yawns, the house lights
/// come on and the child is sent to tell a grown-up about the day; an hour
/// later (or when a parent says so) play can go on.
///
/// Not play time: the parent gate, parent mode, a 冷靜小屋 a parent opened
/// from parent mode (no limit there either), and the app in the background
/// (ten minutes away, or closed, is a rest: a new sitting). A 冷靜小屋 the
/// child walked into is play time; when the time runs out there, the calming
/// way being done is finished first ([finishCalm] at most). A phone clock
/// moved back gives no extra time. The sitting is saved, so closing and
/// opening the app again does not start it afresh.
class RestGuard extends ConsumerStatefulWidget {
  const RestGuard({super.key, required this.child});

  final Widget child;

  static const check = Duration(seconds: 2);
  static const awayIsRest = SessionStart.awayIsRest;

  /// How long a calming way being done may go on after the time is up.
  static const finishCalm = Duration(minutes: 2);

  /// The sitting is saved this often (in checks: 30 seconds).
  static const saveEvery = 15;

  @override
  ConsumerState<RestGuard> createState() => _RestGuardState();
}

class _RestGuardState extends ConsumerState<RestGuard> {
  Timer? _timer;
  AppLifecycleListener? _life;
  late final GoRouter _router;

  /// When the app went out of sight.
  DateTime? _away;

  /// When the time stopped being play (a parent screen, a calm room a
  /// parent opened); it is given back to the child when it ends.
  DateTime? _offSince;

  /// The calm room showing now was opened from parent mode.
  var _parentCalm = false;
  var _path = '';

  /// The phone's clock at the last check (to notice it moved back).
  late DateTime _seen;
  var _checks = 0;

  DateTime get _now => ref.read(clockProvider)();

  SessionStart get _session => ref.read(sessionStartProvider.notifier);

  String get _at => _router.routerDelegate.currentConfiguration.isEmpty ? '' : _router.state.matchedLocation;

  /// A parent screen is showing: the gate or parent mode.
  bool get _parentSight => _path.startsWith('/parent') || ParentGatePage.showing.value > 0;

  @override
  void initState() {
    super.initState();
    ref.read(sessionStartProvider);
    _router = ref.read(routerProvider);
    _seen = _now;
    _path = _at;
    _router.routerDelegate.addListener(_routed);
    ParentGatePage.showing.addListener(_soon);
    _timer = Timer.periodic(RestGuard.check, (_) => _check());
    _life = AppLifecycleListener(
      onHide: () {
        _away = _now;
        _look();
        _remember();
      },
      onShow: () {
        final away = _away, now = _now;
        _away = null;
        if (away != null) {
          final gone = now.difference(away);
          if (gone >= RestGuard.awayIsRest) {
            _session.restart();
          } else {
            // A few minutes in the background are not play time either (a
            // clock moved back meanwhile makes [gone] negative and takes
            // that back too).
            _session.shift(gone);
          }
        }
        _seen = now;
        _look();
        _check();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _life?.dispose();
    _router.routerDelegate.removeListener(_routed);
    ParentGatePage.showing.removeListener(_soon);
    super.dispose();
  }

  void _routed() {
    if (!mounted) return;
    final from = _path, to = _at;
    _path = to;
    // Only the calm room a parent opened from parent mode is outside the
    // play time; coming back to the house ends it.
    _parentCalm = to.startsWith('/calm') && (from.startsWith('/parent') || (_parentCalm && from.startsWith('/calm')));
    _soon();
  }

  /// [_look] right after the screen being built or taken away (it changes
  /// the sitting, which may not change while widgets are being built).
  void _soon() => scheduleMicrotask(_look);

  /// Starts or ends the time that is not play (in sight only: the
  /// background is counted on return).
  void _look() {
    if (!mounted) return;
    final now = _now;
    final off = _away == null && (_parentSight || _parentCalm);
    if (off) {
      _offSince ??= now;
    } else if (_offSince != null) {
      final d = now.difference(_offSince!);
      _offSince = null;
      if (!d.isNegative) _session.shift(d);
    }
  }

  /// Moves the sitting (and the time off, so it is not given back twice)
  /// by [d].
  void _move(Duration d) {
    _session.shift(d);
    final o = _offSince;
    if (o != null) _offSince = o.add(d);
  }

  /// Saves how much of the sitting was play, so the app opened again soon
  /// goes on with it.
  void _remember() {
    if (!mounted) return;
    final g = ref.read(gameProvider);
    if (g.restSince != null) return;
    final now = _now;
    var played = now.difference(ref.read(sessionStartProvider));
    final o = _offSince;
    if (o != null) played -= now.difference(o);
    if (played.isNegative) played = Duration.zero;
    ref.read(gameProvider.notifier).change((g) => g.copyWith(sitting: Sitting(played, now)));
  }

  void _check() {
    // Nothing while the app is out of sight (its timer can go on in the
    // background): that time is not play, and it is looked at on return.
    if (!mounted || _away != null) return;
    final now = _now;
    if (now.isBefore(_seen)) _move(now.difference(_seen));
    _seen = now;
    _path = _at;
    _look();
    if (++_checks % RestGuard.saveEvery == 0) _remember();
    if (_parentSight || _parentCalm) return;
    final g = ref.read(gameProvider);
    final path = _path;
    if (g.restSince != null) {
      if (g.resting(now)) {
        if (path != '/rest') _router.go('/rest');
        return;
      }
      ref.read(gameProvider.notifier).change((g) => g.playOn());
      _session.restart();
      if (path == '/rest') _router.go('/');
      return;
    }
    if (path == '/rest') return;
    final over = now.difference(ref.read(sessionStartProvider)) - Duration(minutes: g.settings.minutes);
    if (over.isNegative) return;
    // A calming way being done is finished first (at most [finishCalm]).
    if (path.startsWith('/calm') && ref.read(calmBusyProvider).busy && over < RestGuard.finishCalm) return;
    ref.read(gameProvider.notifier).change((g) => g.rest(now));
    _router.go('/rest');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
