import 'dart:io';

import 'package:feelings_house/core/feelings.dart';
import 'package:feelings_house/core/game.dart';
import 'package:feelings_house/features/parent/parent_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Privacy and the parent gate (docs/design.md: no network, nothing leaves
/// the phone, parent mode only through the gate).
void main() {
  test('the app asks for no permissions and takes no links from other apps', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, isNot(contains('uses-permission')), reason: 'no internet, camera, location…');
    expect(manifest, contains('android:name="flutter_deeplinking_enabled" android:value="false"'));
    expect(manifest, contains('android:label="心情小屋"'));
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>FlutterDeepLinkingEnabled</key>\n\t<false/>'));
    expect(plist, isNot(contains('UsageDescription')), reason: 'no camera, microphone, motion… prompts');
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('source: system')));
    expect(File('android/app/build.gradle.kts').readAsStringSync(), contains('applicationId = "com.yaufan.feelingshouse"'));
  });

  test('the plugins ask for no permission either', () {
    final cache = Platform.environment['PUB_CACHE'] ?? '${Platform.environment['HOME']}/.pub-cache';
    final lock = File('pubspec.lock').readAsStringSync();
    final sensors = RegExp(r'sensors_plus:\n(?:.*\n)*?\s+version: "([^"]+)"').firstMatch(lock)!.group(1);
    final manifest = File('$cache/hosted/pub.dev/sensors_plus-$sensors/android/src/main/AndroidManifest.xml');
    if (manifest.existsSync()) expect(manifest.readAsStringSync(), isNot(contains('uses-permission')));
  });

  testWidgets('parent mode and unknown pages cannot be opened without the gate', (tester) async {
    final app = await TestApp.start(tester);
    app.go('/parent');
    await app.settle();
    expect(app.location, '/', reason: 'no pass from the gate');
    ParentPass.grant();
    app.go('/parent');
    await app.settle();
    expect(app.location, '/parent', reason: 'right after the gate');
    app.go('/');
    await app.settle();
    app.go('/parent');
    await app.settle();
    expect(app.location, '/', reason: 'the pass is used up');
    app.go('/talk?story=nothing');
    await app.settle();
    expect(app.location, '/');
    app.go('/calm?way=nothing');
    await app.settle();
    expect(app.location, '/calm');
    await app.end();
  });

  testWidgets('the free version keeps the stories and 怎麼辦 closed', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(full: false)));
    app.go('/story');
    await app.settle();
    expect(app.location, '/');
    await app.tapLabel('小故事');
    expect(app.location, '/');
    expect(app.voice.said.last, '完整版才有喔，請爸爸媽媽看看。');
    await app.tapLabel('認表情', ms: 700);
    expect(app.location, '/faces');
    await app.end();
  });

  testWidgets('a parent opens 冷靜小屋 during the rest and it has no time limit', (tester) async {
    final app = await TestApp.start(tester);
    app.change((g) => g.rest(app.now));
    await app.settle(2600);
    expect(app.location, '/rest');
    ParentPass.grant();
    app.go('/parent');
    await app.settle(600);
    app.go('/calm');
    await app.settle(2600);
    expect(app.location, '/calm', reason: 'the rest does not stop 冷靜小屋');
    app.go('/');
    await app.settle(2600);
    expect(app.location, '/rest', reason: 'out of 冷靜小屋, the rest goes on');
    await app.end();
  });

  testWidgets('怎麼辦 never asks about a feeling the parent turned off', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(level: Level.big)).copyWith(settings: const Settings(level: Level.big).copyWith(hidden: {Feeling.angry, Feeling.sad, Feeling.scared, Feeling.nervous})));
    app.go('/help');
    await app.settle(800);
    // Two basic feelings always stay on, so 難過 came back (and parent mode shows it on).
    expect(app.game.settings.hidden, {Feeling.angry, Feeling.scared, Feeling.nervous});
    await app.tapLabel('抱抱小雨', ms: 1200);
    await app.tapLabel('下一個', ms: 800);
    expect(app.voice.said.last, '如果你很難過，可以怎麼做？');
    for (final off in ['生氣', '害怕', '緊張']) {
      expect(app.voice.said.where((l) => l.startsWith('如果你很$off')), isEmpty);
    }
    await app.end();
  });

  testWidgets('with 生氣 off, 怎麼辦 asks about another feeling', (tester) async {
    final app = await TestApp.start(tester, game: const Game().copyWith(settings: const Settings(level: Level.big).copyWith(hidden: {Feeling.angry})));
    app.go('/help');
    await app.settle(800);
    await app.tapLabel('抱抱小雨', ms: 1200);
    await app.tapLabel('下一個', ms: 800);
    expect(app.voice.said.last, '如果你很難過，可以怎麼做？');
    await app.end();
  });
}
