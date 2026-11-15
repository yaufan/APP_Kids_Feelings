/// The feelings (docs/design.md 「棉棉：會變心情的雲」): four basic ones for
/// 小小 (2～3 歲) and fourteen for 大 (4～5 歲).
enum Feeling {
  happy('開心', 'happy', basic: true, pleasant: true),
  sad('難過', 'sad', basic: true),
  angry('生氣', 'angry', basic: true),
  scared('害怕', 'scared', basic: true),
  surprised('驚訝', 'surprised', pleasant: true),
  shy('害羞', 'shy'),
  nervous('緊張', 'nervous'),
  disappointed('失望', 'disappointed'),
  proud('得意', 'proud', pleasant: true),
  tired('累累的', 'tired'),
  bored('無聊', 'bored'),
  jealous('嫉妒', 'jealous'),
  calm('安心', 'calm', pleasant: true),
  wronged('委屈', 'hurt inside');

  const Feeling(this.zh, this.en, {this.basic = false, this.pleasant = false});

  final String zh;
  final String en;

  /// One of the four 小小 learns.
  final bool basic;

  /// A good feeling (the friend is cheered, not comforted).
  final bool pleasant;

  /// Its little sound (design/sounds: 開心 two notes up, 難過 two down…).
  String get sound => 'feel_$name';

  static const basics = [happy, sad, angry, scared];

  /// Feelings close enough that a child could fairly pick either: never
  /// offered side by side as a right one and a wrong one, or as two wrong
  /// ones (docs/design.md: 相近的心情不會同時出現，例如難過和委屈).
  static const similarPairs = {
    (sad, wronged),
    (sad, disappointed),
    (disappointed, wronged),
    (disappointed, bored),
    (scared, nervous),
    (shy, nervous),
    (happy, proud),
    (happy, calm),
    (angry, jealous),
    (tired, bored),
  };

  bool similar(Feeling other) => other != this && (similarPairs.contains((this, other)) || similarPairs.contains((other, this)));
}

/// How old the child is (parent mode).
enum Level {
  small('小小', '2～3 歲'),
  big('大', '4～5 歲');

  const Level(this.zh, this.ages);

  final String zh;
  final String ages;

  /// The feelings this level learns.
  List<Feeling> get feelings => this == small ? Feeling.basics : Feeling.values;
}
