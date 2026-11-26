// Records a demo video of 心情小屋 being played: a scripted child (a white
// dot where the finger is) with a caption under the phone screen; the music
// and sounds the app asked for are written down and mixed in afterwards by
// tools/demo_audio.py.
//
//   flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true
//   python3 ../tools/demo_audio.py
//
// Needs ffmpeg; writes build/demo/demo.mp4, chapters.txt and sounds.txt.
// Skipped in normal test runs.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feelings_house/app/app.dart';
import 'package:feelings_house/app/cloud.dart';
import 'package:feelings_house/app/widgets.dart';
import 'package:feelings_house/core/feelings.dart';
import 'package:feelings_house/features/calm/calm_views.dart';
import 'package:feelings_house/core/game.dart';
import 'package:feelings_house/core/providers.dart';
import 'package:feelings_house/core/sounds.dart';
import 'package:feelings_house/core/store.dart';
import 'package:feelings_house/core/voice.dart';
import 'package:feelings_house/features/parent/parent_gate.dart';

import '../helpers.dart' show loadFonts;

const _phone = Size(390, 844);
const _captionHeight = 84.0;
const _fps = 10;
const _demo = bool.fromEnvironment('DEMO');

/// The music and the sounds asked for, with the frame they were asked at.
class _Recording implements Sounds {
  _Recording(this.frame);

  final int Function() frame;
  final lines = <String>[];
  final _holders = MusicHolders();
  Music? _playing;

  @override
  set music(bool on) {}

  @override
  set effects(bool on) {}

  @override
  void play(String sfx) => lines.add('${frame()} sfx $sfx');

  @override
  void hold(Object owner, Music? music) {
    _holders.hold(owner, music);
    _changed();
  }

  @override
  void release(Object owner) {
    _holders.release(owner);
    _changed();
  }

  void _changed() {
    final now = _holders.current;
    if (now == _playing) return;
    _playing = now;
    lines.add('${frame()} music ${now?.file ?? '-'}');
  }
}

void main() {
  testWidgets('demo video', skip: !_demo, (tester) async {
    await tester.runAsync(loadFonts);
    tester.view.physicalSize = Size(_phone.width * 3, (_phone.height + _captionHeight) * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var frameCount = 0;
    var now = DateTime(2026, 11, 13, 10);
    final track = _Recording(() => frameCount);
    final finger = ValueNotifier<Offset?>(null);
    final caption = ValueNotifier<String>('');
    final key = GlobalKey();
    final store = MemoryStore();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          SizedBox.fromSize(
            size: _phone,
            child: MediaQuery(
              data: const MediaQueryData(size: _phone, devicePixelRatio: 3, padding: EdgeInsets.only(top: 24)),
              child: Stack(children: [
                ProviderScope(
                  overrides: [
                    storeProvider.overrideWithValue(store),
                    savedGameProvider.overrideWithValue(const Game()),
                    soundsProvider.overrideWithValue(track),
                    voiceProvider.overrideWithValue(const SilentVoice()),
                    randomProvider.overrideWithValue(math.Random(4)),
                    clockProvider.overrideWithValue(() => now),
                  ],
                  child: const FeelingsApp(),
                ),
                IgnorePointer(child: ValueListenableBuilder(valueListenable: finger, builder: (_, at, _) => _Finger(at))),
              ]),
            ),
          ),
          SizedBox(
            width: _phone.width,
            height: _captionHeight,
            child: ColoredBox(
              color: const Color(0xFF9C86D8),
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: caption,
                  builder: (_, text, _) => Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Huninn', color: Colors.white, fontSize: 17, height: 1.35)),
                ),
              ),
            ),
          ),
        ]),
      ),
    ));

    final rec = (await tester.runAsync(() => _Recorder.start(key)))!;
    final marks = <String>[];
    void mark(String name) => marks.add('$name $frameCount');
    Future<void> frames(int n) async {
      for (var i = 0; i < n; i++) {
        frameCount++;
        await tester.runAsync(() async {
          await rec.capture();
          await Future<void>.delayed(const Duration(milliseconds: 15));
        });
        await tester.pump(const Duration(milliseconds: 1000 ~/ _fps));
      }
    }

    Future<void> seconds(double s) => frames((s * _fps).round());
    Future<void> touch(Offset at) async {
      finger.value = at;
      await frames(2);
      await tester.tapAt(at);
      await frames(2);
      finger.value = null;
    }

    Offset at(String l) => tester.getCenter(find.bySemanticsLabel(l).last);
    Future<void> label(String l) async {
      final f = find.bySemanticsLabel(l);
      if (f.evaluate().isEmpty || !tester.getRect(f.last).overlaps(Offset.zero & _phone)) {
        await tester.scrollUntilVisible(f, 120, scrollable: find.byType(Scrollable).first);
        await frames(3);
      }
      await touch(at(l));
    }
    Future<void> tapKey(String id) => touch(tester.getCenter(find.byKey(ValueKey(id)).last));
    ProviderContainer container() => ProviderScope.containerOf(tester.element(find.byType(FeelingsApp)));
    void change(Game Function(Game) f) => container().read(gameProvider.notifier).change(f);

    Feeling stage() => tester.widget<Cloud>(find.descendant(of: find.byKey(const ValueKey('stage')), matching: find.byType(Cloud))).feeling!;
    List<Feeling> cards() => tester.widgetList<FeelingCard>(find.byType(FeelingCard)).map((c) => c.feeling).toList();
    Future<void> holdFor(Finder f, double s) async {
      final c = tester.getCenter(f.last);
      finger.value = c;
      final g = await tester.startGesture(c);
      await seconds(s);
      await g.up();
      finger.value = null;
    }

    // The house.
    mark('home');
    caption.value = '心情小屋：和一朵會變心情的雲「棉棉」\n認識心情、說出心情、讓自己冷靜下來';
    await seconds(4);
    caption.value = '點棉棉，牠會說自己現在的心情';
    await label('棉棉');
    await seconds(2.5);

    // 認表情 (小小).
    mark('faces');
    caption.value = '認表情：棉棉現在是什麼心情？\n小小（2～3 歲）兩個選項';
    await label('認表情');
    await seconds(3);
    var target = stage();
    final wrong = cards().firstWhere((f) => f != target);
    caption.value = '選錯了不扣分：棉棉說「我不是${wrong.zh}喔」\n眉毛跳一下提示';
    await label(wrong.zh);
    await seconds(3.5);
    caption.value = '選對了：棉棉點點頭，然後慢慢變回開心\n回饋就是臉變了，沒有星星和分數';
    await label(target.zh);
    await seconds(5.5);
    change((g) => g.copyWith(settings: g.settings.copyWith(level: Level.big)));
    caption.value = '大（4～5 歲）：十四種心情、四個選項\n相近的心情不會同時出現';
    await label('下一個');
    await seconds(3);
    target = stage();
    await label(target.zh);
    await seconds(3);
    await label('回小屋');
    await seconds(1.5);

    // 小故事 and 怎麼辦.
    mark('story');
    caption.value = '小故事：家裡和幼兒園常發生的事\n小雨現在是什麼心情？';
    await label('小故事');
    await seconds(4);
    caption.value = '好幾個答案都對：選一個，小雨的臉就變了\n另外對的標「也可以」';
    await label(cards().firstWhere((f) => f == Feeling.sad).zh);
    await seconds(5);
    mark('help');
    caption.value = '怎麼辦？三個都是好方法\n（分享和輪流，留給真的朋友一起練）';
    await label('怎麼辦？');
    await seconds(3);
    await label('抱抱小雨');
    await seconds(4);
    mark('talk');
    caption.value = '家長一起說：給大人的問題卡\n問問孩子、可以一起說、小提醒（可以跳過）';
    await label('家長一起說');
    await seconds(4.5);
    await label('下一個問題');
    await seconds(2.5);
    await label('回小屋');
    await seconds(1.5);

    // 冷靜小屋.
    mark('calm');
    caption.value = '冷靜小屋：六個讓自己冷靜的方法\n不限時間，家長模式也可以一鍵打開';
    await label('冷靜小屋');
    await seconds(3.5);
    await label('吹氣球');
    await seconds(1.5);
    for (var i = 0; i < 3; i++) {
      caption.value = '吹氣球深呼吸（第 ${i + 1} 次）\n按住吸氣四秒，氣球變大；放開慢慢吐氣';
      await holdFor(find.byKey(const ValueKey('hold')), 4.3);
      await seconds(4.4);
    }
    caption.value = '做完三次，氣球飄走了\n棉棉從緊張變成安心，給你一個抱抱';
    await seconds(4);
    mark('pillow');
    await label('再做一個');
    await seconds(1);
    caption.value = '搥枕頭：用力點枕頭，噗！噗！\n棉棉的紅色一下一下退掉（家長打開的話，也可以搖手機）';
    await label('搥枕頭');
    await seconds(1.5);
    for (var i = 0; i < 8; i++) {
      await tapKey('pillow');
      await seconds(.35);
    }
    await seconds(3);
    mark('adult');
    await label('再做一個');
    await seconds(1);
    caption.value = '找大人：大人雲走過來牽起棉棉\n然後 APP 說「現在換你去找大人」';
    await label('找大人');
    await seconds(1.2);
    await label('請大人來');
    await seconds(6.5);
    await label('回小屋');
    await seconds(1.5);

    // 心情日記.
    mark('diary');
    caption.value = '心情日記：今天，你的心情是？\n下面看得到這個星期每一天';
    change((g) => g.feel(DateTime(2026, 11, 10), Feeling.sad).feel(DateTime(2026, 11, 11), Feeling.angry).feel(DateTime(2026, 11, 12), Feeling.calm));
    await label('心情日記');
    await seconds(3);
    await tapKey('diary-happy');
    await seconds(3.5);
    caption.value = '「說給爸爸媽媽聽」：APP 念一句給大人聽\n然後是給大人的問題卡';
    await label('說給爸爸媽媽聽');
    await seconds(5);
    await label('回小屋');
    await seconds(2.5);

    // Rest.
    mark('rest');
    now = now.add(const Duration(minutes: 15, seconds: 1));
    caption.value = '家長設定的時間到了（預設 15 分鐘）\n「換你去做了！去跟爸爸媽媽說說你今天的心情」';
    await seconds(6);

    // Parent mode.
    mark('parent');
    caption.value = '家長答對題目，才能再玩或進家長模式';
    const digits = {'零': 0, '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9};
    Future<void> gate() async {
      final parts = (find.textContaining('加').evaluate().first.widget as Text).data!.split(' ');
      for (final d in '${digits[parts[0]]! + digits[parts[2]]!}'.split('')) {
        await touch(tester.getCenter(find.byKey(ValueKey('gate-key-$d'))));
        await frames(3);
      }
    }

    await label('家長');
    await seconds(1.2);
    await gate();
    await seconds(1.5);
    await label('家長');
    await seconds(1);
    await gate();
    await seconds(1);
    caption.value = '家長模式：一鍵打開冷靜小屋、年齡、玩多久\n這個星期的心情日記、最常用的冷靜方法';
    await seconds(3.5);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await seconds(3.5);
    caption.value = '';
    mark('end');
    await seconds(0.5);
    expect(ParentPass.take(), isFalse);
    expect(find.byType(BalloonView), findsNothing);
    await tester.runAsync(() async {
      await rec.finish();
      File('build/demo/chapters.txt').writeAsStringSync('${marks.join('\n')}\n');
      File('build/demo/sounds.txt').writeAsStringSync('fps $_fps\nframes $frameCount\n${track.lines.join('\n')}\n');
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }, timeout: const Timeout(Duration(minutes: 40)));
}

class _Finger extends StatelessWidget {
  const _Finger(this.at);

  final Offset? at;

  @override
  Widget build(BuildContext context) {
    final p = at;
    if (p == null) return const SizedBox.expand();
    return Stack(children: [
      Positioned(
        left: p.dx - 22,
        top: p.dy - 22,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: const Color(0xFF4A3B32).withValues(alpha: 0.5), width: 3),
          ),
        ),
      ),
    ]);
  }
}

/// Streams frames of [key]'s boundary into ffmpeg.
class _Recorder {
  _Recorder(this._key, this._ffmpeg);

  final GlobalKey _key;
  final Process _ffmpeg;

  static Future<_Recorder> start(GlobalKey key) async {
    Directory('build/demo').createSync(recursive: true);
    final size = Size(_phone.width * 2, (_phone.height + _captionHeight) * 2);
    final ffmpeg = await Process.start('ffmpeg', [
      '-y', '-loglevel', 'error',
      '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '${size.width.toInt()}x${size.height.toInt()}', '-r', '$_fps', '-i', '-',
      '-vf', 'fps=30', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '24', '-movflags', '+faststart', 'build/demo/demo_silent.mp4',
    ]);
    ffmpeg.stderr.listen(stderr.add);
    return _Recorder(key, ffmpeg);
  }

  Future<void> capture() async {
    final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    _ffmpeg.stdin.add(bytes!.buffer.asUint8List());
    await _ffmpeg.stdin.flush();
  }

  Future<void> finish() async {
    await _ffmpeg.stdin.flush();
    await _ffmpeg.stdin.close();
    final code = await _ffmpeg.exitCode;
    if (code != 0) throw StateError('ffmpeg failed ($code)');
  }
}
