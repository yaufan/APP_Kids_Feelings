import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:feelings_house/core/calm.dart';
import 'package:feelings_house/core/feelings.dart';
import 'package:feelings_house/core/game.dart';
import 'package:feelings_house/core/looks.dart';
import 'package:feelings_house/core/stories.dart';
import 'package:feelings_house/core/store.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rules of docs/design.md: the feelings, the stories, the questions,
/// the calming ways, the diary and the save file.
void main() {
  const small = Settings();
  const big = Settings(level: Level.big);

  group('feelings', () {
    test('four for 小小, fourteen for 大, as docs/design.md lists them', () {
      expect(Feeling.values.map((f) => f.zh), ['開心', '難過', '生氣', '害怕', '驚訝', '害羞', '緊張', '失望', '得意', '累累的', '無聊', '嫉妒', '安心', '委屈']);
      expect(Level.small.feelings, [Feeling.happy, Feeling.sad, Feeling.angry, Feeling.scared]);
      expect(small.feelings, Level.small.feelings);
      expect(big.feelings, Feeling.values);
      expect(const Settings(level: Level.big, full: false).feelings, Feeling.basics, reason: 'the free version has the four basic ones');
    });

    test('similar feelings go both ways and are never the same feeling', () {
      expect(Feeling.sad.similar(Feeling.wronged), isTrue);
      expect(Feeling.wronged.similar(Feeling.sad), isTrue);
      expect(Feeling.sad.similar(Feeling.sad), isFalse);
      expect(Feeling.happy.similar(Feeling.scared), isFalse);
      for (final (a, b) in Feeling.similarPairs) {
        expect(a, isNot(b));
      }
    });

    test('a parent can turn feelings off, but not 開心 or 安心, and two always stay', () {
      final s = big.copyWith(hidden: {Feeling.scared, Feeling.jealous});
      expect(s.feelings, isNot(contains(Feeling.scared)));
      expect(s.feelings.length, 12);
      expect(Settings.canHide(Feeling.happy), isFalse);
      final read = Settings.fromJson({'hidden': ['happy', 'calm', 'scared', 'nothing']});
      expect(read.hidden, {Feeling.scared});
    });

    test('a hidden feeling never comes back, and two basic ones always stay', () {
      // Asking to hide three of the four: one comes back, and the settings say so.
      final s = small.copyWith(hidden: {Feeling.sad, Feeling.angry, Feeling.scared});
      expect(s.feelings.length, 2);
      expect(s.feelings.where(s.hidden.contains), isEmpty, reason: 'what parent mode shows as off is off');
      expect(Settings.fromJson({'hidden': ['sad', 'angry', 'scared', 'jealous']}).hidden, {Feeling.angry, Feeling.scared, Feeling.jealous});
      // Parent mode cannot switch off the one that would leave fewer than two.
      final two = big.copyWith(hidden: {Feeling.sad, Feeling.angry});
      expect(two.canHideNow(Feeling.scared), isFalse);
      expect(two.canHideNow(Feeling.angry), isTrue, reason: 'turning one back on is always fine');
      expect(two.canHideNow(Feeling.jealous), isTrue);
      expect(big.canHideNow(Feeling.happy), isFalse);
      // Whatever is hidden, at every level and in the free version.
      final all = {for (final f in Feeling.values) if (Settings.canHide(f)) f};
      for (final level in Level.values) {
        for (final full in [true, false]) {
          final x = Settings(level: level, full: full).copyWith(hidden: all);
          expect(x.feelings.length, greaterThanOrEqualTo(2), reason: '$level $full');
          expect(x.feelings.where(x.hidden.contains), isEmpty, reason: '$level $full');
        }
      }
    });
  });

  group('棉棉\'s faces', () {
    test('every feeling has a look with eight puffs, and blending ends where it should', () {
      for (final f in Feeling.values) {
        final l = Look.of(f);
        expect(l.puffs.length, Look.puffCount, reason: f.name);
        expect(Look.lerp(Look.neutral, l, 1).color, l.color);
        expect(Look.lerp(l, Look.neutral, 0).brow, l.brow);
        final mid = Look.lerp(l, Look.of(Feeling.calm), .5);
        expect(mid.puffs.length, Look.puffCount);
        for (final p in l.puffs) {
          expect(p.rx, greaterThan(0));
          expect(p.y + p.ry, lessThanOrEqualTo(48), reason: '${f.name}: the cloud stands on y = 44');
        }
      }
    });

    test('any two feelings differ in the eyebrows or the mouth (docs/design.md 測試)', () {
      List<double> brows(Look l) => [l.brow * l.browOn];
      List<double> mouth(Look l) => [l.mouthCurve, l.mouthOpen, l.mouthW, l.teeth, l.wavy, l.mouthO];
      bool differ(List<double> a, List<double> b) => [for (var i = 0; i < a.length; i++) (a[i] - b[i]).abs()].any((d) => d > 0.05);
      for (final a in Feeling.values) {
        for (final b in Feeling.values) {
          if (a.index >= b.index) continue;
          final la = Look.of(a), lb = Look.of(b);
          expect(differ(brows(la), brows(lb)) || differ(mouth(la), mouth(lb)), isTrue, reason: '${a.zh} and ${b.zh} look the same');
          expect(la.color, isNot(lb.color), reason: '${a.zh} and ${b.zh} have the same colour');
        }
      }
    });
  });

  group('stories', () {
    test('ids are different, every story has one to three right feelings and a card', () {
      expect(stories.length, greaterThanOrEqualTo(20));
      expect(stories.map((s) => s.id).toSet().length, stories.length);
      for (final s in stories) {
        expect(s.right.length, inInclusiveRange(1, 3), reason: s.id);
        expect(s.right.toSet().length, s.right.length, reason: s.id);
        expect(s.small.every((f) => f.basic), isTrue, reason: '${s.id}: 小小 only meets the four basic feelings');
        expect(s.small.every(s.right.contains), isTrue, reason: '${s.id}: 小小\'s answers are right at 大 too');
        expect(s.small.length, lessThanOrEqualTo(3));
        for (final t in [s.line, s.title, s.card.ask, s.card.say, s.card.tip]) {
          expect(t.trim(), isNotEmpty, reason: s.id);
        }
      }
    });

    test('every story has a right feeling at each level it is told at; most are told at 小小', () {
      for (final level in Level.values) {
        final s = Settings(level: level);
        for (final story in s.shownStories) {
          expect(story.rightAt(level).where(s.feelings.contains), isNotEmpty, reason: '${story.id} at ${level.name}');
        }
      }
      expect(small.shownStories.length, greaterThanOrEqualTo(15));
      expect(big.shownStories.length, stories.length);
      expect(const Settings(full: false).shownStories, isEmpty, reason: 'the stories are in the full version');
    });

    test('every feeling has a card, and every feeling is the answer to some story at 大', () {
      for (final f in Feeling.values) {
        expect(feelingCards[f], isNotNull, reason: f.name);
        expect(stories.any((s) => s.right.contains(f)), isTrue, reason: '${f.zh} is never a story\'s answer');
      }
    });

    test('the questions: 小小 sees two basic cards, 大 four; wrong ones are never similar to a right one or to each other', () {
      for (final level in Level.values) {
        final s = Settings(level: level);
        for (final story in s.shownStories) {
          for (var seed = 0; seed < 25; seed++) {
            final q = storyQuestion(story, s, math.Random(seed));
            final why = '${story.id} at ${level.name}, seed $seed: ${q.options.map((f) => f.zh)}';
            expect(q.options.toSet().length, q.options.length, reason: why);
            expect(q.options.length, level == Level.small ? 2 : 4, reason: why);
            expect(q.right, isNotEmpty, reason: why);
            expect(q.options.toSet().containsAll(q.right), isTrue, reason: why);
            expect(story.rightAt(level).toSet().containsAll(q.right), isTrue, reason: why);
            if (level == Level.small) {
              expect(q.options.every((f) => f.basic), isTrue, reason: why);
              expect(q.right.length, 1, reason: why);
            } else {
              expect(q.right, story.right.toSet(), reason: '$why: every right one is offered at 大');
            }
            final wrong = q.options.where((f) => !story.rightAt(level).contains(f)).toList();
            expect(wrong, isNotEmpty, reason: why);
            for (final w in wrong) {
              expect(story.rightAt(level).any(w.similar), isFalse, reason: '$why: ${w.zh} is close to a right one');
              expect(wrong.any(w.similar), isFalse, reason: '$why: two close wrong ones');
            }
          }
        }
      }
    });
  });

  group('認表情', () {
    test('the cards never hold two similar feelings; 小小 only basic ones; the same face never twice in a row', () {
      for (final s in [small, big, big.copyWith(hidden: {Feeling.scared})]) {
        for (var seed = 0; seed < 200; seed++) {
          final r = math.Random(seed);
          final q = faceQuestion(s, r, last: Feeling.happy);
          final why = '${s.level.name} seed $seed: ${q.options.map((f) => f.zh)}';
          expect(q.options.length, s.level == Level.small ? 2 : 4, reason: why);
          expect(q.right.length, 1);
          expect(q.options, containsAll(q.right));
          expect(q.right.single, isNot(Feeling.happy), reason: why);
          expect(q.options.every(s.feelings.contains), isTrue, reason: why);
          for (final a in q.options) {
            expect(q.options.where((b) => a.similar(b)), isEmpty, reason: why);
          }
        }
      }
      expect(faceQuestion(big, math.Random(1), target: Feeling.wronged).options, isNot(contains(Feeling.sad)), reason: '難過 and 委屈 are never side by side');
    });
  });

  group('冷靜小屋', () {
    test('six ways, every one ends by itself; 小小 three; free two; for feelings three good ones', () {
      expect(CalmWay.values.length, 6);
      for (final w in CalmWay.values) {
        expect(w.goal, greaterThanOrEqualTo(1), reason: w.name);
        expect(w.howTo, isNotEmpty);
      }
      expect(small.calmWays, [CalmWay.balloon, CalmWay.hug, CalmWay.adult]);
      expect(big.calmWays, CalmWay.values);
      expect(const Settings(level: Level.big, full: false).calmWays, [CalmWay.balloon, CalmWay.adult]);
      for (final f in Feeling.values) {
        final ways = CalmWay.forFeeling(f);
        expect(ways.toSet().length, 3, reason: f.name);
      }
      expect(HelpWay.comfort.length, 3);
      expect(HelpWay.cheer.length, 3);
    });
  });

  group('the diary', () {
    test('a week starts on Monday, also across a month and a year', () {
      expect(Days.monday(DateTime(2026, 11, 15)), DateTime(2026, 11, 9), reason: 'a Sunday');
      expect(Days.monday(DateTime(2026, 11, 9, 23, 59)), DateTime(2026, 11, 9));
      expect(Days.monday(DateTime(2026, 1, 1)), DateTime(2025, 12, 29));
      final w = Days.week(DateTime(2026, 3, 1));
      expect(w.length, 7);
      expect(w.first, DateTime(2026, 2, 23));
      expect(w.last, DateTime(2026, 3, 1));
      for (var i = 1; i < 7; i++) {
        expect(w[i].weekday, w[i - 1].weekday + 1);
      }
      expect(Days.key(DateTime(2026, 3, 1, 22)), '2026-03-01');
      expect(Days.parse('2026-03-01'), DateTime(2026, 3, 1));
      expect(Days.parse('2026-02-30'), isNull);
      expect(Days.parse('nope'), isNull);
    });

    test('one feeling a day (picking again changes it); the week shows each day; most felt and most used', () {
      final mon = DateTime(2026, 11, 9, 9);
      var g = const Game().feel(mon, Feeling.sad).feel(mon.add(const Duration(hours: 5)), Feeling.happy);
      expect(g.today(mon), Feeling.happy);
      expect(g.diary.length, 1);
      g = g.feel(DateTime(2026, 11, 11), Feeling.angry).feel(DateTime(2026, 11, 12), Feeling.angry).calmed(DateTime(2026, 11, 12), CalmWay.pillow).calmed(DateTime(2026, 11, 12), CalmWay.pillow).calmed(DateTime(2026, 11, 13), CalmWay.balloon);
      g = g.best(DateTime(2026, 11, 12), CalmWay.pillow);
      final week = g.week(DateTime(2026, 11, 15));
      expect(week.map((d) => d.$2?.feeling), [Feeling.happy, null, Feeling.angry, Feeling.angry, null, null, null]);
      expect(week[3].$2!.calm[CalmWay.pillow], 2);
      expect(week[3].$2!.best, CalmWay.pillow);
      expect(g.mostFelt(DateTime(2026, 11, 1), DateTime(2026, 11, 30)), Feeling.angry);
      expect(g.mostCalm(DateTime(2026, 11, 1), DateTime(2026, 11, 30)), CalmWay.pillow);
      expect(g.mostFelt(DateTime(2026, 12, 1), DateTime(2026, 12, 31)), isNull);
      expect(g.week(DateTime(2026, 11, 16)).every((d) => d.$2 == null), isTrue, reason: 'a new week starts empty');
    });

    test('only the last days are kept', () {
      var g = const Game();
      final start = DateTime(2026, 1, 1);
      for (var i = 0; i < Game.keepDays + 30; i++) {
        g = g.feel(DateTime(start.year, start.month, start.day + i), Feeling.happy);
      }
      expect(g.diary.length, lessThanOrEqualTo(Game.keepDays + 1));
      expect(g.diary.keys, isNot(contains('2026-01-01')));
    });
  });

  group('the rest', () {
    test('an hour after the time ran out; a clock moved back does not lock the app', () {
      final g = const Game().rest(DateTime(2026, 11, 15, 10));
      expect(g.resting(DateTime(2026, 11, 15, 10, 30)), isTrue);
      expect(g.resting(DateTime(2026, 11, 15, 11)), isFalse);
      expect(g.resting(DateTime(2026, 11, 15, 9, 59)), isTrue, reason: 'the clock went back a minute: the rest does not end early');
      expect(g.resting(DateTime(2026, 11, 15, 8, 59)), isFalse, reason: 'the clock went back more than an hour');
      expect(g.resting(DateTime(2026, 11, 14, 10)), isFalse, reason: 'the clock went back a day');
      expect(const Game().resting(DateTime(2026, 11, 15)), isFalse);
    });

    test('the sitting ends with the rest and with playing on', () {
      final g = const Game().copyWith(sitting: Sitting(const Duration(minutes: 4), DateTime(2026, 11, 15, 10)));
      expect(g.rest(DateTime(2026, 11, 15, 10)).sitting, isNull);
      expect(g.playOn().sitting, isNull);
    });
  });

  group('the parent gate lock', () {
    test('three wrong answers lock it for 1, then 5, then 15 minutes; a right answer starts again', () {
      final t0 = DateTime(2026, 11, 15, 10);
      var lock = const GateLock();
      GateLock miss3(GateLock l, DateTime at) => l.wrong(at).wrong(at).wrong(at);
      lock = lock.wrong(t0).wrong(t0);
      expect(lock.until(t0), isNull, reason: 'two wrong answers do not lock it');
      lock = lock.wrong(t0);
      expect(lock.until(t0), t0.add(const Duration(minutes: 1)));
      final t1 = t0.add(const Duration(minutes: 2));
      expect(lock.until(t1), isNull);
      lock = miss3(lock, t1);
      expect(lock.until(t1), t1.add(const Duration(minutes: 5)));
      final t2 = t1.add(const Duration(minutes: 6));
      lock = miss3(lock, t2);
      expect(lock.until(t2), t2.add(const Duration(minutes: 15)));
      final t3 = t2.add(const Duration(minutes: 16));
      lock = miss3(lock, t3);
      expect(lock.until(t3), t3.add(const Duration(minutes: 15)), reason: 'never longer than fifteen minutes');
      expect(const GateLock().wrong(t3).until(t3), isNull, reason: 'a right answer starts again');
    });

    test('a clock moved back does not make a lock that never ends; it survives the save file', () {
      final t0 = DateTime(2026, 11, 15, 10);
      final lock = const GateLock().wrong(t0).wrong(t0).wrong(t0);
      expect(lock.until(t0.subtract(const Duration(hours: 3))), isNull);
      expect(lock.until(t0.add(const Duration(seconds: 30))), isNotNull);
      final back = Game.fromJson(jsonDecode(jsonEncode(const Game().copyWith(gate: lock).toJson())) as Map<String, dynamic>);
      expect(back.gate.until(t0.add(const Duration(seconds: 30))), t0.add(const Duration(minutes: 1)));
      expect(GateLock.fromJson({'misses': 9, 'locks': -2, 'since': 4}).until(t0), isNull);
    });
  });

  group('stories take turns', () {
    test('the next story is one not told yet; when all are told, the oldest again', () {
      var g = const Game(settings: Settings(level: Level.big));
      final seen = <String>{};
      for (var i = 0; i < stories.length; i++) {
        final s = g.nextStory()!;
        expect(seen.add(s.id), isTrue, reason: 'told twice before the others: ${s.id}');
        g = g.toldStory(s.id);
      }
      expect(g.nextStory()!.id, stories.first.id);
      final g2 = const Game();
      expect(g2.nextStory()!.small, isNotEmpty, reason: '小小 is not told a 大-only story');
    });
  });

  group('the save file', () {
    test('everything comes back the same', () {
      final g = const Game(settings: Settings(level: Level.big, minutes: 20, cards: false, shake: false, hidden: {Feeling.scared}, english: true, music: false, full: false))
          .feel(DateTime(2026, 11, 14), Feeling.proud)
          .calmed(DateTime(2026, 11, 14), CalmWay.balloon)
          .best(DateTime(2026, 11, 14), CalmWay.balloon)
          .toldStory('milk')
          .nextTurn()
          .rest(DateTime(2026, 11, 14, 10))
          .copyWith(sitting: Sitting(const Duration(minutes: 3), DateTime(2026, 11, 14, 9)), gate: GateLock(misses: 1, locks: 2, since: DateTime(2026, 11, 14, 8)));
      final back = Game.fromJson(jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>);
      expect(jsonEncode(back.toJson()), jsonEncode(g.toJson()));
      expect(back.settings.level, Level.big);
      expect(back.settings.hidden, {Feeling.scared});
      expect(back.today(DateTime(2026, 11, 14)), Feeling.proud);
      expect(back.told, ['milk']);
      expect(back.restSince, DateTime(2026, 11, 14, 10));
      expect(back.sitting!.played, const Duration(minutes: 3));
      expect(back.gate.locks, 2);
    });

    test('shaking the phone is off unless a parent turns it on', () {
      expect(const Settings().shake, isFalse);
      expect(Settings.fromJson(const {}).shake, isFalse);
      expect(Settings.fromJson(const {'shake': true}).shake, isTrue, reason: 'a parent who turned it on keeps it');
    });

    test('a broken or strange file gives a fresh, safe game', () {
      expect(Game.fromJson(null).diary, isEmpty);
      final g = Game.fromJson({
        'settings': {'level': 'huge', 'minutes': 999, 'cards': 'yes', 'hidden': 5},
        'diary': {'2026-11-14': {'feeling': 'grumpy', 'calm': {'balloon': -2, 'pillow': 3}}, 'yesterday': {'feeling': 'happy'}, '2026-11-15': 7},
        'restSince': 12,
        'told': ['milk', 'nothing', 3],
        'turn': -4,
        'sitting': {'played': -3, 'seen': 'later'},
      });
      expect(g.settings.level, Level.small);
      expect(g.settings.minutes, 15);
      expect(g.settings.cards, isTrue);
      expect(g.diary.keys, ['2026-11-14']);
      expect(g.diary['2026-11-14']!.feeling, isNull);
      expect(g.diary['2026-11-14']!.calm, {CalmWay.pillow: 3});
      expect(g.restSince, isNull);
      expect(g.told, ['milk']);
      expect(g.turn, 0);
      expect(g.sitting, isNull);
    });

    test('a file cut off halfway falls back to the save before', () async {
      final dir = Directory.systemTemp.createTempSync('feelings_store_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = FileStore(dir);
      expect(await store.read(), isNull);
      store.write(const Game().feel(DateTime(2026, 11, 14), Feeling.happy).toJson());
      await store.flush();
      store.write(const Game().feel(DateTime(2026, 11, 14), Feeling.sad).toJson());
      await store.flush();
      File('${dir.path}/feelings_house.json').writeAsStringSync('{"settings": {"lev');
      final back = Game.fromJson(await store.read());
      expect(back.today(DateTime(2026, 11, 14)), Feeling.happy, reason: 'the copy from the save before');
    });
  });
}
