import 'package:feelings_house/app/app.dart';
import 'package:feelings_house/core/calm.dart';
import 'package:feelings_house/core/feelings.dart';
import 'package:feelings_house/core/game.dart';
import 'package:feelings_house/core/providers.dart';
import 'package:feelings_house/features/parent/parent_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// The things checked again after 0.1.0 (the code review): the back key,
/// the play time, 冷靜小屋 and the play time, parent screens closing by
/// themselves, the gate's lock, the shake in the background, the voice
/// between screens.
void main() {
  Future<void> minutes(TestApp app, int m) async {
    app.now = app.now.add(Duration(minutes: m));
    await app.settle(2600);
  }

  Future<void> hide(TestApp app) async {
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      app.tester.binding.handleAppLifecycleStateChanged(s);
    }
    await app.tester.pump();
  }

  Future<void> show(TestApp app) async {
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      app.tester.binding.handleAppLifecycleStateChanged(s);
    }
    await app.settle(2600);
  }

  /// What a parent's 「讓小朋友再玩一次」 does.
  Future<void> playOn(TestApp app) async {
    app.change((g) => g.playOn());
    app.container.read(sessionStartProvider.notifier).restart();
    app.go('/');
    await app.settle(2600);
  }

  Future<void> parentMode(TestApp app) async {
    ParentPass.grant();
    app.go('/parent');
    await app.settle(600);
    expect(app.location, '/parent');
  }

  group('the back key', () {
    testWidgets('goes where the screen\'s own back button goes, never out of the app', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call.method);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final app = await TestApp.start(tester, game: const Game(settings: Settings(level: Level.big)));
      Future<void> back() async {
        await tester.binding.handlePopRoute();
        await app.settle(800);
      }

      await back();
      expect(app.location, '/', reason: 'the house: nothing');
      for (final room in ['/faces', '/story', '/help', '/diary', '/calm']) {
        app.go(room);
        await app.settle(800);
        await back();
        expect(app.location, '/', reason: room);
      }
      // In 冷靜小屋, out of a way back to the six ways, as its own button.
      app.go('/calm');
      await app.settle(800);
      await app.tapLabel('吹氣球', ms: 700);
      await back();
      expect(app.location, '/calm');
      expect(find.byKey(const ValueKey('way-water')), findsOneWidget);
      await back();
      expect(app.location, '/');
      await parentMode(app);
      await back();
      expect(app.location, '/');
      app.change((g) => g.rest(app.now));
      await app.settle(2600);
      expect(app.location, '/rest');
      await back();
      expect(app.location, '/rest', reason: 'the rest stays');
      // The gate pops back to where it was opened.
      await app.tapLabel('家長', ms: 600);
      expect(find.byType(ParentGatePage), findsOneWidget);
      await back();
      expect(find.byType(ParentGatePage), findsNothing);
      expect(app.location, '/rest');
      expect(calls, isNot(contains('SystemNavigator.pop')), reason: 'the app never closed');
      await app.end();
    });
  });

  group('the play time', () {
    testWidgets('time in parent mode and at the gate is not play time', (tester) async {
      final app = await TestApp.start(tester);
      await minutes(app, 8);
      await parentMode(app);
      await minutes(app, 8);
      await tester.tap(find.byTooltip('回去'));
      await app.settle(2600);
      expect(app.location, '/', reason: 'eight minutes played, not sixteen');
      await app.tapLabel('家長', ms: 600);
      await minutes(app, 10);
      expect(find.byType(ParentGatePage), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('取消'));
      await app.settle(2600);
      expect(app.location, '/');
      await minutes(app, 6);
      expect(app.location, '/');
      await minutes(app, 1);
      expect(app.location, '/rest');
      await app.end();
    });

    testWidgets('time in the background is not play time; ten minutes away is a new sitting', (tester) async {
      final app = await TestApp.start(tester);
      await minutes(app, 10);
      await hide(app);
      app.now = app.now.add(const Duration(minutes: 9));
      await tester.pump(const Duration(seconds: 10));
      expect(app.location, '/', reason: 'no rest begins in the background');
      expect(app.game.sitting!.played, const Duration(minutes: 10), reason: 'saved when the app went away');
      await show(app);
      expect(app.location, '/');
      await minutes(app, 4);
      expect(app.location, '/');
      await minutes(app, 1);
      expect(app.location, '/rest');
      await playOn(app);
      expect(app.location, '/');
      await minutes(app, 14);
      await hide(app);
      app.now = app.now.add(const Duration(minutes: 10));
      await show(app);
      await minutes(app, 14);
      expect(app.location, '/', reason: 'a new sitting after ten minutes away');
      await app.end();
    });

    testWidgets('a clock moved back gives no extra time', (tester) async {
      final app = await TestApp.start(tester);
      await minutes(app, 10);
      app.now = app.now.subtract(const Duration(hours: 2));
      await app.settle(2600);
      await minutes(app, 5);
      expect(app.location, '/rest');
      await app.end();
    });

    testWidgets('closed and opened again within ten minutes, the sitting goes on', (tester) async {
      final now = DateTime(2026, 11, 13, 10);
      final app = await TestApp.start(tester, game: Game(sitting: Sitting(const Duration(minutes: 13), now.subtract(const Duration(minutes: 9)))));
      await minutes(app, 1);
      expect(app.location, '/');
      await minutes(app, 1);
      expect(app.location, '/rest', reason: 'thirteen minutes before, two now; the nine closed do not count');
      await app.end();
    });

    testWidgets('closed for ten minutes or more, a new sitting starts', (tester) async {
      final now = DateTime(2026, 11, 13, 10);
      final app = await TestApp.start(tester, game: Game(sitting: Sitting(const Duration(minutes: 14), now.subtract(const Duration(minutes: 10)))));
      await minutes(app, 14);
      expect(app.location, '/');
      await app.end();
    });

    testWidgets('the rest goes on after the app is closed and opened again', (tester) async {
      final app = await TestApp.start(tester, game: const Game().rest(DateTime(2026, 11, 13, 9, 30)));
      expect(app.location, '/rest');
      await minutes(app, 29);
      expect(app.location, '/rest');
      await minutes(app, 1);
      expect(app.location, '/');
      await app.end();
    });
  });

  group('冷靜小屋 and the play time', () {
    testWidgets('walked into from the house, it is play time; a way being done is finished first', (tester) async {
      final app = await TestApp.start(tester);
      await minutes(app, 14);
      await app.tapLabel('冷靜小屋', ms: 900);
      await app.tapLabel('抱抱布偶', ms: 700);
      await minutes(app, 2);
      expect(app.location, '/calm', reason: 'the hug being done is finished first');
      await tester.tap(find.byKey(const ValueKey('teddy')));
      await app.settle(5000);
      expect(app.game.entry(app.now)!.calm[CalmWay.hug], 1);
      expect(app.location, '/calm', reason: '棉棉\'s hug is seen first');
      await app.settle(5000);
      expect(app.location, '/rest', reason: 'after 棉棉\'s hug, the rest');
      await app.end();
    });

    testWidgets('on the six ways, the rest comes at once; a way not finished gets two minutes', (tester) async {
      final app = await TestApp.start(tester);
      await app.tapLabel('冷靜小屋', ms: 900);
      await minutes(app, 15);
      expect(app.location, '/rest');
      await playOn(app);
      await app.tapLabel('冷靜小屋', ms: 900);
      await app.tapLabel('吹氣球', ms: 700);
      await minutes(app, 16);
      expect(app.location, '/calm');
      await minutes(app, 1);
      expect(app.location, '/rest', reason: 'at most two minutes more');
      await app.end();
    });

    testWidgets('opened from parent mode, it has no limit and is not play time', (tester) async {
      final app = await TestApp.start(tester);
      await minutes(app, 10);
      await parentMode(app);
      await tester.tap(find.byKey(const ValueKey('open-calm')));
      await app.settle(900);
      expect(app.location, '/calm');
      await app.tapLabel('吹氣球', ms: 700);
      await app.tapLabel('回去', ms: 700);
      await minutes(app, 30);
      expect(app.location, '/calm');
      await app.tapLabel('回小屋', ms: 700);
      await app.settle(2600);
      expect(app.location, '/');
      await minutes(app, 4);
      expect(app.location, '/', reason: 'ten minutes played before, four now');
      // Walked into again from the house: play time again.
      await app.tapLabel('冷靜小屋', ms: 900);
      await minutes(app, 1);
      expect(app.location, '/rest');
      await app.end();
    });
  });

  group('parent screens close by themselves', () {
    testWidgets('the gate and parent mode after five minutes without a touch', (tester) async {
      final app = await TestApp.start(tester);
      await app.tapLabel('家長', ms: 600);
      expect(find.byType(ParentGatePage), findsOneWidget);
      await tester.pump(const Duration(minutes: 4));
      await tester.tap(find.byKey(const ValueKey('gate-key-0')));
      await tester.pump(const Duration(minutes: 4));
      expect(find.byType(ParentGatePage), findsOneWidget, reason: 'a touch starts the five minutes again');
      await tester.pump(const Duration(minutes: 1, seconds: 1));
      await app.settle(1200);
      expect(find.byType(ParentGatePage), findsNothing);
      await parentMode(app);
      await tester.pump(const Duration(minutes: 5, seconds: 1));
      await app.settle(800);
      expect(app.location, '/');
      app.go('/parent');
      await app.settle();
      expect(app.location, '/', reason: 'the pass is used up');
      await app.end();
    });

    testWidgets('the gate and parent mode when the app goes to the background', (tester) async {
      final app = await TestApp.start(tester);
      await app.tapLabel('家長', ms: 600);
      await hide(app);
      await show(app);
      expect(find.byType(ParentGatePage), findsNothing);
      await parentMode(app);
      await hide(app);
      await show(app);
      expect(app.location, '/');
      app.go('/parent');
      await app.settle();
      expect(app.location, '/', reason: 'a child opening the app meets the gate again');
      await app.end();
    });
  });

  group('the gate\'s lock', () {
    testWidgets('grows from one minute to five, is kept when the app restarts, and ends after a right answer', (tester) async {
      var app = await TestApp.start(tester);
      // 0 is never right (the answer is six to eighteen): three wrong
      // answers take at most six taps, and taps while locked do nothing.
      Future<void> wrong3() async {
        for (var i = 0; i < 6; i++) {
          await tester.tap(find.byKey(const ValueKey('gate-key-0')));
          await tester.pump(const Duration(milliseconds: 200));
        }
      }

      await app.tapLabel('家長', ms: 600);
      await wrong3();
      await app.settle();
      expect(find.textContaining('請等'), findsOneWidget);
      app.now = app.now.add(const Duration(minutes: 1, seconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('請等'), findsNothing);
      await wrong3();
      await app.settle();
      expect(find.text('請等 5 分鐘再試'), findsOneWidget);
      final saved = app.game, now = app.now;
      await app.end();
      app = await TestApp.start(tester, game: saved);
      app.now = now.add(const Duration(seconds: 30));
      await app.tapLabel('家長', ms: 600);
      expect(find.textContaining('請等'), findsOneWidget, reason: 'kept in the file');
      app.now = app.now.subtract(const Duration(hours: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('請等'), findsNothing, reason: 'a clock moved back does not lock for good');
      app.now = app.now.add(const Duration(hours: 1, minutes: 6));
      await tester.pump(const Duration(seconds: 2));
      final q = (find.textContaining('加').evaluate().first.widget as Text).data!.split(' ');
      const digits = {'三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9};
      for (final d in '${digits[q[0]]! + digits[q[2]]!}'.split('')) {
        await tester.tap(find.byKey(ValueKey('gate-key-$d')));
        await tester.pump(const Duration(milliseconds: 200));
      }
      await app.settle();
      expect(find.byType(ParentGatePage), findsNothing);
      expect(app.game.gate.locks, 0, reason: 'a right answer starts again');
      await app.end();
    });
  });

  group('the shake', () {
    testWidgets('off unless a parent turns it on, and not heard while the app is away', (tester) async {
      final app = await TestApp.start(tester, game: const Game(settings: Settings(level: Level.big)));
      app.go('/calm?way=pillow');
      await app.settle(800);
      app.shakes.shake();
      await app.settle();
      expect(app.sounds.played.where((s) => s == 'thump'), isEmpty, reason: 'off by default');
      expect(find.text('也可以搖一搖手機'), findsNothing);
      app.go('/');
      await app.settle(700);
      app.change((g) => g.copyWith(settings: g.settings.copyWith(shake: true)));
      app.go('/calm?way=pillow');
      await app.settle(800);
      app.shakes.shake();
      await app.settle();
      expect(app.sounds.played.where((s) => s == 'thump').length, 1);
      await hide(app);
      for (var i = 0; i < 9; i++) {
        app.shakes.shake();
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(app.sounds.played.where((s) => s == 'thump').length, 1, reason: 'a phone in a pocket is not a thump');
      await show(app);
      app.shakes.shake();
      await app.settle();
      expect(app.sounds.played.where((s) => s == 'thump').length, 2);
      expect(app.game.entry(app.now)?.calm[CalmWay.pillow], isNull);
      await app.end();
    });
  });

  group('the voice', () {
    testWidgets('a room left stops its own line, never the next room\'s first one', (tester) async {
      final app = await TestApp.start(tester);
      await app.settle(800);
      final before = app.voice.stops;
      await app.tapLabel('冷靜小屋', ms: 900);
      expect(app.voice.stops, before, reason: 'the house going away does not cut 冷靜小屋\'s first line');
      expect(app.voice.said.last, '選一個讓自己冷靜的方法');
      await app.tapLabel('回小屋', ms: 900);
      expect(app.voice.stops, before + 1, reason: '冷靜小屋\'s line stops when it is left');
      await app.end();
    });
  });

  test('ten minutes away is the same in the play-time keeper and the sitting', () {
    expect(RestGuard.awayIsRest, SessionStart.awayIsRest);
    expect(RestGuard.awayIsRest, const Duration(minutes: 10));
  });
}
