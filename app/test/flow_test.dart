import 'package:feelings_house/app/cloud.dart';
import 'package:feelings_house/app/widgets.dart';
import 'package:feelings_house/core/calm.dart';
import 'package:feelings_house/core/feelings.dart';
import 'package:feelings_house/core/stories.dart';
import 'package:feelings_house/features/calm/calm_views.dart';
import 'package:feelings_house/features/parent/parent_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A visit as a child (and a parent) would play it, through every room, on a
/// phone and a tablet, with screenshots in `build/screenshots/<device>/`.
void main() {
  setUpAll(loadFonts);

  for (final MapEntry(key: device, value: (size, ratio)) in {'phone': (const Size(1080, 2340), 2.75), 'tablet': (const Size(1620, 2160), 2.0)}.entries) {
    testWidgets('a visit to the feelings house ($device)', (tester) async {
      final app = await TestApp.start(tester, size: size, ratio: ratio, seed: 4);
      Future<void> shot(String name) => shoot(tester, device, name);
      Feeling stage() => tester.widget<Cloud>(find.descendant(of: find.byKey(const ValueKey('stage')), matching: find.byType(Cloud))).feeling!;

      // The house: 棉棉 says hello; tap it and it says how it feels.
      expect(app.location, '/');
      await app.settle(800);
      expect(app.voice.said.first, '你好！今天的心情怎麼樣呢？');
      await shot('01_home');
      await app.tapLabel('棉棉');
      expect(app.voice.said.last, '我現在覺得開心。');
      expect(app.sounds.played, contains('feel_happy'));

      // 認表情 at 小小: two cards; a wrong one first (nothing lost, a hint), then the right one.
      await app.tapLabel('認表情', ms: 700);
      expect(app.location, '/faces');
      expect(find.byType(FeelingCard), findsNWidgets(2));
      await shot('02_faces_small');
      var target = stage();
      final wrong = tester.widgetList<FeelingCard>(find.byType(FeelingCard)).map((c) => c.feeling).firstWhere((f) => f != target);
      await app.tapLabel(wrong.zh);
      expect(app.sounds.played.last, 'try');
      expect(app.voice.said.last, startsWith('我不是${wrong.zh}喔'));
      await app.tapLabel(target.zh, ms: 3000);
      expect(app.voice.said.last, '對，我在${target.zh}！');
      await shot('03_faces_right');
      await app.tapLabel('下一個', ms: 600);
      expect(stage(), isNot(target), reason: 'never the same face twice in a row');
      await app.tapLabel('回小屋', ms: 700);
      expect(app.location, '/');

      // 大 from here on.
      app.change((g) => g.copyWith(settings: g.settings.copyWith(level: Level.big)));
      await app.settle();
      await app.tapLabel('認表情', ms: 700);
      expect(find.byType(FeelingCard), findsNWidgets(4));
      target = stage();
      await app.tapLabel(target.zh, ms: 1200);
      await shot('04_faces_big');
      await app.tapLabel('回小屋', ms: 700);

      // 小故事: no face yet; a wrong card, then a right one; the others say 也可以.
      await app.tapLabel('小故事', ms: 900);
      expect(app.location, '/story');
      final story = stories.first;
      expect(app.voice.said.last, contains(story.line));
      await shot('05_story');
      final cards = tester.widgetList<FeelingCard>(find.byType(FeelingCard)).map((c) => c.feeling).toList();
      final no = cards.firstWhere((f) => !story.right.contains(f));
      await app.tapLabel(no.zh);
      expect(app.voice.said.last, startsWith('小雨不是${no.zh}'));
      await app.tapLabel(story.right.first.zh, ms: 1200);
      expect(app.game.told, [story.id]);
      expect(find.text('也可以'), findsNWidgets(story.right.length - 1));
      await shot('06_story_answered');

      // 怎麼辦: three good ways; 抱抱小雨 and 小雨 feels better.
      await app.tapLabel('怎麼辦？', ms: 800);
      expect(find.byKey(const ValueKey('help-hug')), findsOneWidget);
      await shot('07_story_help');
      await app.tapLabel('抱抱小雨', ms: 1500);
      expect(app.sounds.played, contains('hug'));
      await shot('08_story_helped');

      // 家長一起說: the story's card, then the feeling's card.
      await app.tapLabel('家長一起說', ms: 900);
      expect(app.location, '/talk');
      expect(find.text('「${story.card.ask}」'), findsOneWidget);
      await shot('09_talk');
      await app.tapLabel('下一個問題', ms: 600);
      expect(find.text('「${feelingCards[story.right.first]!.ask}」'), findsOneWidget);
      await app.tapLabel('回小屋', ms: 800);

      // The 怎麼辦 room: a friend, then 「如果你很生氣」 → a calming way.
      await app.tapLabel('怎麼辦', ms: 900);
      expect(app.location, '/help');
      await shot('10_help_room');
      await app.tapLabel('問：你還好嗎？', ms: 1200);
      await app.tapLabel('下一個', ms: 800);
      expect(app.voice.said.last, '如果你很生氣，可以怎麼做？');
      await shot('11_help_self');
      await tester.tap(find.byKey(const ValueKey('self-pillow')));
      await app.settle(900);
      expect(app.location, '/calm');

      // 搥枕頭: tapping thumps, and a shake does too.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const ValueKey('pillow')));
        await app.settle(250);
      }
      app.shakes.shake();
      await app.settle(250);
      await shot('12_calm_pillow');
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('pillow')));
        await app.settle(250);
      }
      expect(app.sounds.played.where((s) => s == 'thump').length, 8);
      await app.settle(1500);
      expect(app.game.entry(app.now)!.calm[CalmWay.pillow], 1);
      await app.tapLabel('回小屋', ms: 800);

      // 冷靜小屋 from its door: six ways.
      await app.tapLabel('冷靜小屋', ms: 900);
      expect(find.byKey(const ValueKey('way-water')), findsOneWidget);
      await shot('13_calm');
      // 吹氣球: hold to breathe in, let go to breathe out; letting go too soon is fine.
      await app.tapLabel('吹氣球', ms: 700);
      await hold(app, find.byKey(const ValueKey('hold')), 800);
      await app.settle(700);
      expect(app.voice.said.last, '再慢慢吸一次，按久一點');
      for (var i = 0; i < 3; i++) {
        final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('hold'))));
        for (var t = 0; t < 42; t++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (i == 1) await shot('14_calm_balloon');
        await g.up();
        await app.settle(5000);
      }
      await app.settle(2400);
      expect(app.sounds.played, containsAll(['breath_in', 'breath_out', 'float']));
      expect(find.text('我冷靜下來了，謝謝你陪我！'), findsOneWidget);
      await shot('15_calm_done');

      // 數到四.
      await app.tapLabel('再做一個', ms: 600);
      await app.tapLabel('數到四', ms: 700);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(ValueKey('count-$i')));
        await app.settle(300);
        if (i == 2) await shot('16_calm_count');
      }
      await app.settle(2200);
      expect(app.sounds.played, containsAll(['count_1', 'count_2', 'count_3', 'count_4']));
      // 哪一個最有用？ (大, after two ways)
      await app.tapLabel('哪一個最有用？ 數到四', ms: 600);
      expect(app.game.entry(app.now)!.best, CalmWay.count);

      // 抱抱布偶: drag the teddy up to 棉棉.
      await app.tapLabel('再做一個', ms: 600);
      await app.tapLabel('抱抱布偶', ms: 700);
      final teddy = tester.getCenter(find.byKey(const ValueKey('teddy')));
      await dragFinger(app, teddy, tester.getCenter(find.descendant(of: find.byType(HugView), matching: find.byType(Cloud)).first));
      await app.settle(1200);
      await shot('17_calm_hug');
      await app.settle(4200);
      expect(app.sounds.played, contains('heartbeat'));

      // 喝口水: just tap the cup.
      await app.tapLabel('再做一個', ms: 600);
      await app.tapLabel('喝口水', ms: 700);
      await tester.tap(find.byKey(const ValueKey('cup')));
      await app.settle(1600);
      await shot('18_calm_water');
      await app.settle(2600);
      expect(app.sounds.played.where((s) => s == 'gulp').length, 3);

      // 找大人: the grown-up comes, and the child is sent to a real one.
      await app.tapLabel('再做一個', ms: 600);
      await app.tapLabel('找大人', ms: 700);
      await app.tapLabel('請大人來', ms: 3600);
      expect(app.voice.said.last, contains('現在換你去找大人'));
      expect(find.bySemanticsLabel('再做一個'), findsNothing, reason: '找大人 ends this visit to 冷靜小屋');
      await shot('19_calm_adult');
      await app.tapLabel('回小屋', ms: 800);

      // 心情日記: today's feeling, this week, and tell the grown-ups.
      app.change((g) => g.feel(DateTime(2026, 11, 10), Feeling.sad).feel(DateTime(2026, 11, 11), Feeling.angry).feel(DateTime(2026, 11, 12), Feeling.calm));
      await app.tapLabel('心情日記', ms: 900);
      expect(app.voice.said.last, '今天，你的心情是？');
      await tester.tap(find.byKey(const ValueKey('diary-proud')));
      await app.settle(900);
      expect(app.game.today(app.now), Feeling.proud);
      expect(app.voice.said.last, '今天你是得意的！去說給爸爸媽媽聽。');
      await shot('20_diary');
      await app.tapLabel('說給爸爸媽媽聽', ms: 3000);
      expect(app.voice.said, contains('爸爸媽媽，我今天覺得得意。'));
      expect(app.location, '/talk');
      await shot('21_talk_feeling');
      await app.tapLabel('回小屋', ms: 900);
      expect(app.voice.said.last, isNot(contains('今天你是得意的')), reason: 'hello is said once per start');
      await shot('22_home_today');

      // Parent mode: the diary week, the settings, 冷靜小屋 at once.
      ParentPass.grant();
      app.go('/parent');
      await app.settle(800);
      expect(find.textContaining('星期五：得意'), findsOneWidget);
      await shot('23_parent');
      await tester.tap(find.byKey(const ValueKey('level-small')));
      await app.settle();
      expect(app.game.settings.level, Level.small);
      await tester.tap(find.byKey(const ValueKey('open-calm')));
      await app.settle(900);
      expect(app.location, '/calm');
      expect(find.byKey(const ValueKey('way-water')), findsNothing, reason: '小小 has three ways');
      await shot('24_calm_small');

      // 冷靜小屋 has no time limit; once out of it, the play time is up.
      app.now = app.now.add(const Duration(minutes: 16));
      await app.settle(2600);
      expect(app.location, '/calm');
      await app.tapLabel('回小屋', ms: 600);
      await app.settle(2600);
      expect(app.location, '/rest');
      expect(app.voice.said.last, contains('換你去做了！去跟爸爸媽媽說說你今天的心情。'));
      await shot('25_rest');
      await app.end();
    }, timeout: const Timeout(Duration(minutes: 12)));
  }
}
