import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/calm.dart';
import '../core/feelings.dart';
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

/// Keeps the parent's play time: when the sitting has gone on for the
/// minutes they set, 棉棉 yawns, the house lights come on and the child is
/// sent to tell a grown-up about the day; an hour later (or when a parent
/// says so) play can go on. 冷靜小屋 is never stopped (docs/design.md: 冷靜
/// 小屋不受時間限制). Away from the app for ten minutes counts as a rest.
class RestGuard extends ConsumerStatefulWidget {
  const RestGuard({super.key, required this.child});

  final Widget child;

  static const check = Duration(seconds: 2);
  static const awayIsRest = Duration(minutes: 10);

  @override
  ConsumerState<RestGuard> createState() => _RestGuardState();
}

class _RestGuardState extends ConsumerState<RestGuard> {
  Timer? _timer;
  AppLifecycleListener? _life;
  DateTime? _away;

  @override
  void initState() {
    super.initState();
    ref.read(sessionStartProvider);
    _timer = Timer.periodic(RestGuard.check, (_) => _check());
    _life = AppLifecycleListener(
      onHide: () => _away = ref.read(clockProvider)(),
      onShow: () {
        final away = _away;
        _away = null;
        if (away != null && ref.read(clockProvider)().difference(away) >= RestGuard.awayIsRest) ref.read(sessionStartProvider.notifier).restart();
        _check();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _life?.dispose();
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final now = ref.read(clockProvider)();
    final g = ref.read(gameProvider);
    final router = ref.read(routerProvider);
    final path = router.state.matchedLocation;
    if (path.startsWith('/parent') || path.startsWith('/calm')) return;
    if (g.restSince != null) {
      if (g.resting(now)) {
        if (path != '/rest') router.go('/rest');
        return;
      }
      ref.read(gameProvider.notifier).change((g) => g.playOn());
      ref.read(sessionStartProvider.notifier).restart();
      if (path == '/rest') router.go('/');
      return;
    }
    if (path == '/rest') return;
    if (now.difference(ref.read(sessionStartProvider)) >= Duration(minutes: g.settings.minutes)) {
      ref.read(gameProvider.notifier).change((g) => g.rest(now));
      router.go('/rest');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
