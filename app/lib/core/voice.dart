import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads out what 棉棉 says, the questions and the feelings' names, for children who
/// cannot read yet: Taiwanese Mandarin, then (if a parent turned it on) the
/// English words ("開心, happy"). It uses the phone's own speech; parents
/// can turn it off.
abstract interface class Voice {
  /// Says [zh] in Mandarin, then [en] (if any) in English.
  Future<void> say(String zh, {String? en});
  Future<void> stop();
}

class SystemVoice implements Voice {
  SystemVoice() {
    // Nothing is said while the app is out of sight.
    _life = AppLifecycleListener(onHide: stop);
  }

  late final AppLifecycleListener _life;
  FlutterTts? _tts;
  Future<FlutterTts>? _setUp;
  String? _language;

  /// Counts the lines asked for (and the stops): only the newest is said.
  var _turn = 0;

  /// The engine, set up once. Every line waits for the whole set-up, so a
  /// line asked for while the first one is still setting up is not cut off
  /// by the first one's late stop(): the newer line is the one said.
  Future<FlutterTts> _engine() => _setUp ??= () async {
        final tts = _tts = FlutterTts();
        await tts.awaitSpeakCompletion(true);
        await tts.setSpeechRate(0.45);
        await tts.setPitch(1.2);
        return tts;
      }();

  Future<bool> _in(FlutterTts tts, String language, int turn) async {
    if (_language != language) {
      _language = language;
      await tts.setLanguage(language);
    }
    // A newer line, or a screen that was left, while this one waited.
    return turn == _turn;
  }

  @override
  Future<void> say(String zh, {String? en}) async {
    final turn = ++_turn;
    try {
      final tts = await _engine();
      if (turn != _turn) return;
      await tts.stop();
      if (zh.isNotEmpty && await _in(tts, 'zh-TW', turn)) await tts.speak(zh);
      if (en == null || en.isEmpty || turn != _turn) return;
      if (await _in(tts, 'en-US', turn)) await tts.speak(en);
    } catch (_) {
      // No speech engine (tests, or a phone without one): the words on
      // screen and the pictures are enough.
    }
  }

  @override
  Future<void> stop() async {
    _turn++;
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  void dispose() => _life.dispose();
}

class SilentVoice implements Voice {
  const SilentVoice();

  @override
  Future<void> say(String zh, {String? en}) async {}

  @override
  Future<void> stop() async {}
}

/// Remembers what was said, and how often it was stopped (tests).
class RecordingVoice implements Voice {
  final said = <String>[];
  var stops = 0;

  @override
  Future<void> say(String zh, {String? en}) async => said.add(en == null ? zh : '$zh|$en');

  @override
  Future<void> stop() async => stops++;
}
