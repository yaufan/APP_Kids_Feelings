import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feelings_house/app/app.dart';
import 'package:feelings_house/core/game.dart';
import 'package:feelings_house/core/providers.dart';
import 'package:feelings_house/core/shake.dart';
import 'package:feelings_house/core/sounds.dart';
import 'package:feelings_house/core/store.dart';
import 'package:feelings_house/core/voice.dart';

final shotKey = GlobalKey();

/// The app on a phone screen, starting from [game].
class TestApp {
  TestApp(this.tester, this.store, this.sounds, this.voice);

  final WidgetTester tester;
  final MemoryStore store;
  final RecordingSounds sounds;
  final RecordingVoice voice;
  final shakes = TestShakes();
  DateTime now = DateTime(2026, 11, 13, 10);

  ProviderContainer get container => ProviderScope.containerOf(tester.element(find.byType(FeelingsApp)));
  Game get game => container.read(gameProvider);
  void change(Game Function(Game g) f) => container.read(gameProvider.notifier).change(f);

  static Future<TestApp> start(WidgetTester tester, {Game game = const Game(), Size size = const Size(1080, 2340), double ratio = 2.75, String at = '/', int seed = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    final store = MemoryStore();
    final app = TestApp(tester, store, RecordingSounds(), RecordingVoice());
    await tester.pumpWidget(RepaintBoundary(
      key: shotKey,
      child: ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          savedGameProvider.overrideWithValue(game),
          randomProvider.overrideWithValue(math.Random(seed)),
          soundsProvider.overrideWithValue(app.sounds),
          voiceProvider.overrideWithValue(app.voice),
          clockProvider.overrideWithValue(() => app.now),
          shakesProvider.overrideWithValue(app.shakes),
        ],
        child: const FeelingsApp(),
      ),
    ));
    if (at != '/') app.go(at);
    await app.settle();
    return app;
  }

  void go(String location) => container.read(routerProvider).go(location);

  String get location => container.read(routerProvider).state.matchedLocation;

  /// Lets the pictures load and the screen move on [ms] milliseconds.
  Future<void> settle([int ms = 400]) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(Duration(milliseconds: ms ~/ 6));
    }
  }

  Future<void> tapLabel(String label, {int ms = 400}) async {
    await tester.tap(find.bySemanticsLabel(label).last);
    await settle(ms);
  }

  /// Scrolls a list until [label] shows, then taps it.
  Future<void> scrollTap(String label, {int ms = 400}) async {
    final f = find.bySemanticsLabel(label);
    if (f.evaluate().isEmpty || !tester.getRect(f.last).overlaps(Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio)) {
      await tester.scrollUntilVisible(f, 120, scrollable: find.byType(Scrollable).first);
      await settle(200);
    }
    await tapLabel(label, ms: ms);
  }

  Future<void> end() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Real fonts for screenshots instead of the test font's boxes.
Future<void> loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/home/user/flutter';
  final fonts = {
    'MaterialIcons': ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'],
    'Huninn': ['assets/fonts/jf-openhuninn-2.1.ttf'],
    'Roboto': ['assets/fonts/jf-openhuninn-2.1.ttf'],
  };
  for (final MapEntry(key: family, value: paths) in fonts.entries) {
    final loader = FontLoader(family);
    for (final path in paths.where((p) => File(p).existsSync())) {
      loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  }
}

Future<void> shoot(WidgetTester tester, String device, String name) => tester.runAsync(() async {
      final boundary = shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/screenshots/$device/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });

/// Shakes sent by the test.
class TestShakes implements Shakes {
  final _c = StreamController<void>.broadcast();

  void shake() => _c.add(null);

  @override
  Stream<void> get shakes => _c.stream;
}

/// Holds a finger down on [finder] for [ms] milliseconds, frame by frame.
Future<void> hold(TestApp app, Finder finder, int ms) async {
  final g = await app.tester.startGesture(app.tester.getCenter(finder));
  await app.tester.pump(const Duration(milliseconds: 50));
  for (var t = 0; t < ms; t += 100) {
    await app.tester.pump(const Duration(milliseconds: 100));
  }
  await g.up();
  await app.tester.pump(const Duration(milliseconds: 50));
}

/// Drags a finger from [from] to [to] in small steps (raw pointer moves).
Future<void> dragFinger(TestApp app, Offset from, Offset to) async {
  final g = await app.tester.startGesture(from);
  await app.tester.pump(const Duration(milliseconds: 30));
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 8)!);
    await app.tester.pump(const Duration(milliseconds: 20));
  }
  await g.up();
  await app.tester.pump(const Duration(milliseconds: 30));
}
