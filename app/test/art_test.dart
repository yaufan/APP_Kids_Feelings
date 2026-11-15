import 'dart:io';

import 'package:feelings_house/core/calm.dart';
import 'package:feelings_house/core/stories.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every picture the program asks for exists (docs/art.md), and none uses
/// what flutter_svg cannot draw.
void main() {
  bool has(String path) => File('assets/art/$path.svg').existsSync();

  test('every picture the screens ask for is drawn', () {
    final wanted = [
      for (final n in ['house', 'house_lit', 'sun', 'moon', 'ground', 'puff']) 'house/$n',
      for (final n in ['balloon', 'teddy', 'pillow', 'cup', 'numcloud', 'heart']) 'calm/$n',
      for (final w in CalmWay.values) 'calm/way_${w.art}',
      for (final d in ['faces', 'story', 'calm', 'help', 'diary']) 'icons/door_$d',
      'icons/cloud_small',
      for (final p in StoryPlace.values) 'stories/bg_${p.name}',
      for (final s in stories)
        for (final p in s.props) 'stories/${p.art}',
    ];
    expect([for (final p in wanted) if (!has(p)) p], isEmpty, reason: 'draw these in design/art/');
  });

  test('every story puts its things and clouds inside the picture', () {
    for (final s in stories) {
      for (final p in s.props) {
        expect(p.x - p.w / 2, greaterThanOrEqualTo(-0.02), reason: '${s.id}/${p.art}');
        expect(p.x + p.w / 2, lessThanOrEqualTo(1.02), reason: '${s.id}/${p.art}');
        expect(p.y, inInclusiveRange(0.2, 1.0), reason: '${s.id}/${p.art}');
      }
      final (x, y, w) = s.xiaoyu;
      expect(x, inInclusiveRange(0.1, 0.9), reason: s.id);
      expect(y, inInclusiveRange(0.2, 1.0), reason: s.id);
      expect(w, inInclusiveRange(0.15, 0.45), reason: s.id);
      for (final c in s.cast) {
        expect(c.x, inInclusiveRange(0.05, 0.97), reason: s.id);
      }
    }
  });

  test('no picture uses what flutter_svg cannot draw, and none is too big', () {
    final bad = <String>[];
    var n = 0;
    for (final f in Directory('assets/art').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.svg')) continue;
      n++;
      final text = f.readAsStringSync();
      if (f.lengthSync() > 70 * 1024) bad.add('${f.path} too big');
      for (final no in ['<filter', '<mask', '<clipPath', '<style', 'style=', '<text', '<image', '<pattern', 'mix-blend']) {
        if (text.contains(no)) bad.add('${f.path} uses $no');
      }
      if (!text.trimRight().endsWith('</svg>')) bad.add('${f.path} is cut off');
    }
    expect(n, greaterThan(40));
    expect(bad, isEmpty);
  });

  test('every sound the app plays is there', () {
    final names = [
      'tap', 'pop', 'chime', 'right', 'try', 'whoosh', 'ding', 'breath_in', 'breath_out', 'float', 'hug', 'heartbeat', 'thump', 'pour', 'gulp',
      'steps', 'sparkle', 'clap', 'page', 'night', for (var i = 1; i <= 4; i++) 'count_$i',
      for (final h in HelpWay.values) h.sound,
      for (final f in ['happy', 'sad', 'angry', 'scared', 'surprised', 'shy', 'nervous', 'disappointed', 'proud', 'tired', 'bored', 'jealous', 'calm', 'wronged']) 'feel_$f',
      for (final m in ['home', 'story', 'calm', 'rest']) 'music_$m',
    ];
    expect([for (final s in names) if (!File('assets/sounds/$s.wav').existsSync()) s], isEmpty);
  });
}
