import 'feelings.dart';

/// The six ways to calm down in 冷靜小屋 (docs/design.md). Each is a little
/// activity with a clear end ([goal]); 棉棉 starts in [from] and ends 安心.
enum CalmWay {
  balloon('吹氣球', 'balloon', Feeling.nervous, '按住，慢慢吸氣，氣球變大；放開，慢慢吐氣。', 3),
  count('數到四', 'count', Feeling.scared, '一顆一顆點雲朵，我們一起數到四。', 4),
  hug('抱抱布偶', 'hug', Feeling.sad, '把小熊拿給棉棉，抱一抱。', 1),
  pillow('搥枕頭', 'pillow', Feeling.angry, '用力點枕頭，噗！噗！', 8),
  water('喝口水', 'water', Feeling.nervous, '把水杯拿到棉棉嘴邊，喝一口水。', 3),
  adult('找大人', 'adult', Feeling.scared, '點一下，請大人來。', 1);

  const CalmWay(this.zh, this.art, this.from, this.howTo, this.goal);

  final String zh;

  /// Its picture: assets/art/calm/way_<art>.svg.
  final String art;

  /// How 棉棉 feels when it starts.
  final Feeling from;

  /// What to do (read out).
  final String howTo;

  /// How many times the thing is done before it is over (three breaths,
  /// four clouds, eight thumps…): every way ends by itself.
  final int goal;

  /// 小小 has three of them (docs/design.md).
  static const small = [balloon, hug, adult];

  /// The free version has two.
  static const free = [balloon, adult];

  /// What to try when you feel [f] yourself (怎麼辦: 「你很生氣，可以怎麼做？」).
  static List<CalmWay> forFeeling(Feeling f) => switch (f) {
        Feeling.angry || Feeling.jealous => const [pillow, balloon, adult],
        Feeling.sad || Feeling.disappointed || Feeling.wronged => const [hug, water, adult],
        Feeling.scared => const [hug, count, adult],
        _ => const [balloon, count, water],
      };
}
