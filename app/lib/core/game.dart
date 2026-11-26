import 'dart:math' as math;

import 'calm.dart';
import 'feelings.dart';
import 'stories.dart';

/// What a parent set (parent mode).
class Settings {
  const Settings({
    this.level = Level.small,
    this.minutes = 15,
    this.cards = true,
    this.shake = false,
    this.hidden = const {},
    this.english = false,
    this.music = true,
    this.sounds = true,
    this.voice = true,
    this.full = true,
  });

  final Level level;

  /// How long one sitting may be before a rest (冷靜小屋 opened from parent
  /// mode has no limit; the one a child walks into is play time).
  final int minutes;

  /// 家長一起說 cards after the stories and the diary.
  final bool cards;

  /// Shaking the phone thumps the pillow too (tapping always does). Off
  /// unless a parent turns it on: a child shaking hard can throw the phone.
  final bool shake;

  /// Feelings a parent turned off for now (「可以先關掉害怕」).
  final Set<Feeling> hidden;
  final bool english;
  final bool music;
  final bool sounds;
  final bool voice;

  /// The full version (everything); on while testing.
  final bool full;

  static const minuteChoices = [5, 10, 15, 20, 30];

  /// 開心 and 安心 always stay (the app comes back to them).
  static bool canHide(Feeling f) => f != Feeling.happy && f != Feeling.calm;

  /// At least this many basic feelings stay on, so 小小 (and the free
  /// version, which have only the basic four) always has a question with two
  /// cards. 大 always keeps 開心 and 安心.
  static const minBasics = 2;

  /// Whether a parent may turn [f] off now: never 開心 or 安心, and never the
  /// basic feeling that would leave fewer than [minBasics] (parent mode
  /// disables that switch: 「至少要留兩種」).
  bool canHideNow(Feeling f) => canHide(f) && (hidden.contains(f) || !f.basic || Feeling.basics.where((b) => !hidden.contains(b) && b != f).length >= minBasics);

  /// [hidden] made safe: anything that may not be hidden is turned back on,
  /// and basic feelings come back (first ones first) until [minBasics] show.
  static Set<Feeling> tidy(Set<Feeling> hidden) {
    final out = {for (final f in hidden) if (canHide(f)) f};
    for (final b in Feeling.basics) {
      if (Feeling.basics.where((x) => !out.contains(x)).length >= minBasics) break;
      out.remove(b);
    }
    return out;
  }

  /// The feelings the child meets: four at 小小 (and in the free version),
  /// fourteen at 大, minus the ones turned off. Never a hidden one: [tidy]
  /// (applied by [copyWith] and [Settings.fromJson]) keeps at least two.
  List<Feeling> get feelings {
    final base = level == Level.small || !full ? Feeling.basics : Feeling.values;
    return [for (final f in base) if (!hidden.contains(f)) f];
  }

  /// The calming ways on offer.
  List<CalmWay> get calmWays => !full ? CalmWay.free : (level == Level.small ? CalmWay.small : CalmWay.values);

  /// The stories told at this level (the full version only).
  List<Story> get shownStories => [
        if (full)
          for (final s in stories)
            if (s.rightAt(level).any(feelings.contains)) s,
      ];

  Settings copyWith({Level? level, int? minutes, bool? cards, bool? shake, Set<Feeling>? hidden, bool? english, bool? music, bool? sounds, bool? voice, bool? full}) => Settings(
        level: level ?? this.level,
        minutes: minutes ?? this.minutes,
        cards: cards ?? this.cards,
        shake: shake ?? this.shake,
        hidden: hidden == null ? this.hidden : tidy(hidden),
        english: english ?? this.english,
        music: music ?? this.music,
        sounds: sounds ?? this.sounds,
        voice: voice ?? this.voice,
        full: full ?? this.full,
      );

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'minutes': minutes,
        'cards': cards,
        'shake': shake,
        'hidden': [for (final f in hidden) f.name],
        'english': english,
        'music': music,
        'sounds': sounds,
        'voice': voice,
        'full': full,
      };

  factory Settings.fromJson(Map<String, dynamic> j) {
    final m = j['minutes'], hidden = j['hidden'];
    bool flag(String k, bool d) => j[k] is bool ? j[k] as bool : d;
    return Settings(
      level: Level.values.asNameMap()[j['level']] ?? Level.small,
      minutes: m is int && minuteChoices.contains(m) ? m : 15,
      cards: flag('cards', true),
      shake: flag('shake', false),
      hidden: tidy({
        if (hidden is List)
          for (final n in hidden) ?Feeling.values.asNameMap()[n],
      }),
      english: flag('english', false),
      music: flag('music', true),
      sounds: flag('sounds', true),
      voice: flag('voice', true),
      full: flag('full', true),
    );
  }
}

/// One day in the diary: the feeling the child picked (one a day; picking
/// again changes it) and the calming ways used that day.
class DiaryEntry {
  const DiaryEntry({this.feeling, this.calm = const {}, this.best});

  final Feeling? feeling;

  /// How many times each way was done.
  final Map<CalmWay, int> calm;

  /// 「哪一個最有用？」 (大).
  final CalmWay? best;

  DiaryEntry copyWith({Feeling? feeling, Map<CalmWay, int>? calm, CalmWay? best}) => DiaryEntry(feeling: feeling ?? this.feeling, calm: calm ?? this.calm, best: best ?? this.best);

  Map<String, dynamic> toJson() => {
        if (feeling != null) 'feeling': feeling!.name,
        'calm': {for (final e in calm.entries) e.key.name: e.value},
        if (best != null) 'best': best!.name,
      };

  static DiaryEntry? fromJson(dynamic j) {
    if (j is! Map) return null;
    final c = j['calm'];
    return DiaryEntry(
      feeling: Feeling.values.asNameMap()[j['feeling']],
      calm: {
        if (c is Map)
          for (final w in CalmWay.values)
            if (c[w.name] is int && (c[w.name] as int) > 0) w: c[w.name] as int,
      },
      best: CalmWay.values.asNameMap()[j['best']],
    );
  }
}

/// Days and weeks for the diary (a week starts on Monday, as in Taiwan's
/// calendars and kindergartens).
abstract final class Days {
  static String key(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parse(String k) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(k);
    if (m == null) return null;
    final d = DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    return key(d) == k ? d : null;
  }

  /// The day (midnight) of [d].
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The Monday of [d]'s week.
  static DateTime monday(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

  /// Monday to Sunday of [d]'s week (built from the calendar day, so a
  /// summer-time change does not move a day).
  static List<DateTime> week(DateTime d) {
    final m = monday(d);
    return [for (var i = 0; i < 7; i++) DateTime(m.year, m.month, m.day + i)];
  }

  static const weekdayZh = ['一', '二', '三', '四', '五', '六', '日'];
}

/// The sitting going on when the app was last seen: how much of it was
/// play time, and when. Opened again within ten minutes, the app goes on with
/// it (the time it was closed is not counted); later, a new sitting starts.
class Sitting {
  const Sitting(this.played, this.seen);

  final Duration played;
  final DateTime seen;

  Map<String, dynamic> toJson() => {'played': played.inSeconds, 'seen': seen.toIso8601String()};

  static Sitting? fromJson(dynamic j) {
    if (j is! Map) return null;
    final p = j['played'], seen = j['seen'] is String ? DateTime.tryParse(j['seen'] as String) : null;
    if (p is! int || p < 0 || seen == null) return null;
    return Sitting(Duration(seconds: p), seen);
  }
}

/// The parent gate's lock, kept in the file so restarting the app does not
/// clear it: three wrong answers in a row lock the gate for a minute, the
/// next three for five minutes, then fifteen; a right answer starts again.
class GateLock {
  const GateLock({this.misses = 0, this.locks = 0, this.since});

  /// Wrong answers since the last lock (or the last right answer).
  final int misses;

  /// Locks since the last right answer.
  final int locks;

  /// When the last lock began.
  final DateTime? since;

  static const maxMisses = 3;
  static const lengths = [Duration(minutes: 1), Duration(minutes: 5), Duration(minutes: 15)];

  /// How long the last lock lasts.
  Duration get length => lengths[(locks - 1).clamp(0, lengths.length - 1)];

  /// When the lock ends (null: not locked now). A clock moved back to before
  /// the lock began does not lock the gate: such a lock would never end.
  DateTime? until(DateTime now) {
    final s = since;
    if (s == null || locks == 0 || now.isBefore(s)) return null;
    final end = s.add(length);
    return now.isBefore(end) ? end : null;
  }

  /// A wrong answer at [now].
  GateLock wrong(DateTime now) => misses + 1 >= maxMisses ? GateLock(locks: locks + 1, since: now) : GateLock(misses: misses + 1, locks: locks, since: since);

  Map<String, dynamic> toJson() => {'misses': misses, 'locks': locks, if (since != null) 'since': since!.toIso8601String()};

  factory GateLock.fromJson(dynamic j) {
    if (j is! Map) return const GateLock();
    int count(Object? v) => v is int && v >= 0 ? v : 0;
    return GateLock(misses: count(j['misses']).clamp(0, maxMisses - 1), locks: count(j['locks']), since: j['since'] is String ? DateTime.tryParse(j['since'] as String) : null);
  }
}

/// Everything kept on the phone: the settings, the diary, the rest, which
/// stories were told, the sitting, the parent gate's lock. One small file
/// (store.dart).
class Game {
  const Game({this.settings = const Settings(), this.diary = const {}, this.restSince, this.told = const [], this.turn = 0, this.sitting, this.gate = const GateLock()});

  final Settings settings;

  /// Day key (Days.key) → that day.
  final Map<String, DiaryEntry> diary;

  /// When the play time ran out (null: playing).
  final DateTime? restSince;

  /// Stories already told, oldest first (the next one is one not told yet).
  final List<String> told;

  /// Counts the rounds of 怎麼辦, so the feelings take turns.
  final int turn;

  /// The sitting when the app was last seen (null: none going on).
  final Sitting? sitting;

  final GateLock gate;

  static const restLength = Duration(hours: 1);

  /// How many days the diary keeps.
  static const keepDays = 120;

  /// Resting for an hour after the time ran out. A clock moved back a
  /// little does not end the rest early; moved back more than an hour, it
  /// counts as rested (a lock that would never end).
  bool resting(DateTime now) {
    final since = restSince;
    if (since == null) return false;
    return now.difference(since).abs() < restLength;
  }

  DiaryEntry? entry(DateTime d) => diary[Days.key(d)];

  /// The feeling picked today, if any.
  Feeling? today(DateTime now) => entry(now)?.feeling;

  /// This week, Monday first: each day's entry (null if nothing was written).
  List<(DateTime, DiaryEntry?)> week(DateTime now) => [for (final d in Days.week(now)) (d, entry(d))];

  /// The feeling picked most often from [from] to [to] (both days included;
  /// a tie goes to the most recent).
  Feeling? mostFelt(DateTime from, DateTime to) {
    final counts = <Feeling, int>{};
    final last = <Feeling, String>{};
    for (final e in _between(from, to)) {
      final f = e.value.feeling;
      if (f == null) continue;
      counts[f] = (counts[f] ?? 0) + 1;
      if ((last[f] ?? '').compareTo(e.key) < 0) last[f] = e.key;
    }
    return _most(counts, last);
  }

  /// The calming way used most from [from] to [to].
  CalmWay? mostCalm(DateTime from, DateTime to) {
    final counts = <CalmWay, int>{};
    final last = <CalmWay, String>{};
    for (final e in _between(from, to)) {
      for (final c in e.value.calm.entries) {
        counts[c.key] = (counts[c.key] ?? 0) + c.value;
        if ((last[c.key] ?? '').compareTo(e.key) < 0) last[c.key] = e.key;
      }
    }
    return _most(counts, last);
  }

  Iterable<MapEntry<String, DiaryEntry>> _between(DateTime from, DateTime to) {
    final a = Days.key(from), b = Days.key(to);
    return diary.entries.where((e) => e.key.compareTo(a) >= 0 && e.key.compareTo(b) <= 0);
  }

  static T? _most<T>(Map<T, int> counts, Map<T, String> last) {
    T? best;
    for (final e in counts.entries) {
      if (best == null || e.value > counts[best]! || (e.value == counts[best]! && last[e.key]!.compareTo(last[best]!) > 0)) best = e.key;
    }
    return best;
  }

  Game copyWith({Settings? settings, Map<String, DiaryEntry>? diary, DateTime? restSince, bool clearRest = false, List<String>? told, int? turn, Sitting? sitting, bool clearSitting = false, GateLock? gate}) => Game(
        settings: settings ?? this.settings,
        diary: diary ?? this.diary,
        restSince: clearRest ? null : (restSince ?? this.restSince),
        told: told ?? this.told,
        turn: turn ?? this.turn,
        sitting: clearSitting ? null : (sitting ?? this.sitting),
        gate: gate ?? this.gate,
      );

  Game _write(DateTime d, DiaryEntry Function(DiaryEntry e) f) {
    final k = Days.key(d);
    final next = {...diary, k: f(diary[k] ?? const DiaryEntry())};
    // Only the last [keepDays] days are kept.
    final oldest = Days.key(Days.day(d).subtract(const Duration(days: keepDays)));
    next.removeWhere((key, _) => key.compareTo(oldest) < 0);
    return copyWith(diary: next);
  }

  /// Today's feeling in the diary (picking again changes it).
  Game feel(DateTime now, Feeling f) => _write(now, (e) => e.copyWith(feeling: f));

  /// A calming way was done today.
  Game calmed(DateTime now, CalmWay w) => _write(now, (e) => e.copyWith(calm: {...e.calm, w: (e.calm[w] ?? 0) + 1}));

  /// 「哪一個最有用？」
  Game best(DateTime now, CalmWay w) => _write(now, (e) => e.copyWith(best: w));

  /// The next story to tell: the first one at this level not told yet (all
  /// told: start again with the one told longest ago).
  Story? nextStory() {
    final list = settings.shownStories;
    if (list.isEmpty) return null;
    for (final s in list) {
      if (!told.contains(s.id)) return s;
    }
    return list.reduce((a, b) => told.indexOf(a.id) <= told.indexOf(b.id) ? a : b);
  }

  Game toldStory(String id) => copyWith(told: [...told.where((t) => t != id), id].skip(math.max(0, told.length + 1 - 60)).toList());

  Game nextTurn() => copyWith(turn: turn + 1);

  /// The play time ran out: the rest begins (the sitting is over).
  Game rest(DateTime now) => copyWith(restSince: now, clearSitting: true);

  Game playOn() => copyWith(clearRest: true, clearSitting: true);

  Map<String, dynamic> toJson() => {
        'version': 1,
        'settings': settings.toJson(),
        'diary': {for (final e in diary.entries) e.key: e.value.toJson()},
        if (restSince != null) 'restSince': restSince!.toIso8601String(),
        'told': told,
        'turn': turn,
        if (sitting != null) 'sitting': sitting!.toJson(),
        'gate': gate.toJson(),
      };

  factory Game.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const Game();
    final d = j['diary'], rest = j['restSince'], told = j['told'], turn = j['turn'];
    return Game(
      settings: Settings.fromJson(j['settings'] is Map ? (j['settings'] as Map).cast<String, dynamic>() : const {}),
      diary: {
        if (d is Map)
          for (final e in d.entries)
            if (e.key is String && Days.parse(e.key as String) != null && DiaryEntry.fromJson(e.value) != null) e.key as String: DiaryEntry.fromJson(e.value)!,
      },
      restSince: rest is String ? DateTime.tryParse(rest) : null,
      told: [
        if (told is List)
          for (final t in told)
            if (t is String && stories.any((s) => s.id == t)) t,
      ],
      turn: turn is int && turn >= 0 ? turn : 0,
      sitting: Sitting.fromJson(j['sitting']),
      gate: GateLock.fromJson(j['gate']),
    );
  }
}

/// A question with feeling cards: which ones are offered and which are right.
class Question {
  const Question(this.options, this.right);

  final List<Feeling> options;
  final Set<Feeling> right;

  bool isRight(Feeling f) => right.contains(f);
}

/// Feelings from [pool], shuffled, none similar to [avoid] or to each other,
/// at most [n].
List<Feeling> _apart(List<Feeling> pool, Iterable<Feeling> avoid, int n, math.Random r) {
  final out = <Feeling>[];
  final kept = [...avoid];
  for (final f in [...pool]..shuffle(r)) {
    if (out.length >= n) break;
    if (kept.contains(f) || kept.any(f.similar)) continue;
    out.add(f);
    kept.add(f);
  }
  return out;
}

/// 認表情: 棉棉 shows [target] (picked at random if null, never [last]); two
/// cards at 小小, four at 大; no two cards are similar feelings.
Question faceQuestion(Settings s, math.Random r, {Feeling? target, Feeling? last}) {
  final pool = s.feelings;
  final t = target ?? (pool.where((f) => f != last).toList()..shuffle(r)).firstOrNull ?? pool.first;
  final n = s.level == Level.small ? 2 : 4;
  final options = [t, ..._apart(pool, [t], n - 1, r)]..shuffle(r);
  return Question(options, {t});
}

/// 小故事: 「小雨現在是什麼心情？」 At 小小 one right card and one wrong;
/// at 大 every right one (up to three) and wrong ones to make four. A wrong
/// card is never similar to a right one or to another wrong one.
Question storyQuestion(Story story, Settings s, math.Random r) {
  final pool = s.feelings;
  final allRight = story.rightAt(s.level).where(pool.contains).toList();
  final small = s.level == Level.small;
  final shown = small ? [(allRight.toList()..shuffle(r)).first] : allRight;
  final n = small ? 2 : 4;
  final wrong = _apart([for (final f in pool) if (!allRight.contains(f)) f], allRight, n - shown.length, r);
  return Question([...shown, ...wrong]..shuffle(r), shown.toSet());
}
