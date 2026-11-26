import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// The music (design/sounds/make_sounds.py): slow lullaby-like tunes, one for
/// the house, a slower one for 冷靜小屋, a light one for the stories, and the
/// quiet one for resting.
enum Music {
  home('music_home'),
  story('music_story'),
  calm('music_calm'),
  rest('music_rest');

  const Music(this.file);

  final String file;
}

/// Short sounds are named by their file in assets/sounds/ (tap, pop, hug,
/// thump, `feel_<feeling>`…; design/sounds/README.md lists them).
abstract interface class Sounds {
  set music(bool on);
  set effects(bool on);

  void play(String sfx);

  /// [owner] (a screen) wants [music]; the one asked for last plays.
  void hold(Object owner, Music? music);

  void release(Object owner);
}

class MusicHolders {
  final _holders = <Object, Music?>{};

  void hold(Object owner, Music? music) {
    _holders.remove(owner);
    _holders[owner] = music;
  }

  void release(Object owner) => _holders.remove(owner);

  Music? get current => _holders.isEmpty ? null : _holders.values.last;
}

class SilentSounds implements Sounds {
  const SilentSounds();

  @override
  set music(bool on) {}

  @override
  set effects(bool on) {}

  @override
  void play(String sfx) {}

  @override
  void hold(Object owner, Music? music) {}

  @override
  void release(Object owner) {}
}

/// Remembers the sounds played (tests).
class RecordingSounds implements Sounds {
  final played = <String>[];
  final _holders = MusicHolders();

  Music? get music => _holders.current;

  @override
  set music(bool on) {}

  @override
  set effects(bool on) {}

  @override
  void play(String sfx) => played.add(sfx);

  @override
  void hold(Object owner, Music? music) => _holders.hold(owner, music);

  @override
  void release(Object owner) => _holders.release(owner);
}

/// How every player plays: on the phone's media stream (the volume the
/// child's parent turns up for videos), not the ringer, so it is not silent in
/// vibrate or silent mode; asking for no audio focus, so sounds never stop
/// each other or the voice. On iOS a mixable ambient session.
final soundContext = AudioContext(
  android: const AudioContextAndroid(
    usageType: AndroidUsageType.media,
    contentType: AndroidContentType.music,
    audioFocus: AndroidAudioFocus.none,
  ),
  iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
);

/// Plays through audioplayers: a pool per sound, one looping player for the
/// music; quiet while the app is in the background.
class SystemSounds implements Sounds {
  SystemSounds() {
    _lifecycle = AppLifecycleListener(onHide: () => _setAway(true), onShow: () => _setAway(false));
  }

  static const _sfxVolume = 0.85, _musicVolume = 0.35;

  late final AppLifecycleListener _lifecycle;
  final _pools = <String, Future<AudioPool>>{};
  final _holders = MusicHolders();
  Future<void>? _setUp;
  AudioPlayer? _loop;

  /// The music wanted, and the music the loop is really playing.
  Music? _playing, _sounding;

  /// Switches of the music, one after the other: a stop asked for while a
  /// start is still loading waits for it, so the music never starts after
  /// it was stopped (the app hidden, a screen left).
  Future<void> _switching = Future.value();
  var _music = true, _effects = true, _away = false;

  @override
  set music(bool on) {
    _music = on;
    _update();
  }

  @override
  set effects(bool on) => _effects = on;

  void _setAway(bool away) {
    _away = away;
    _update();
  }

  Future<void> _ready() => _setUp ??= AudioPlayer.global.setAudioContext(soundContext);

  @override
  void play(String sfx) {
    if (!_effects || _away || sfx.isEmpty) return;
    unawaited(_play(sfx));
  }

  Future<void> _play(String sfx) async {
    try {
      await _ready();
      final pool = await (_pools[sfx] ??= AudioPool.create(source: AssetSource('sounds/$sfx.wav'), maxPlayers: 4, audioContext: soundContext));
      await pool.start(volume: _sfxVolume);
    } catch (_) {
      _pools.remove(sfx);
    }
  }

  @override
  void hold(Object owner, Music? music) {
    _holders.hold(owner, music);
    _update();
  }

  @override
  void release(Object owner) {
    _holders.release(owner);
    _update();
  }

  void _update() {
    final wanted = !_music || _away ? null : _holders.current;
    if (wanted == _playing) return;
    _playing = wanted;
    _switching = _switching.then((_) => _apply());
  }

  /// Makes the loop play what is wanted now (a later wish queues another).
  Future<void> _apply() async {
    final music = _playing;
    if (music == _sounding) return;
    try {
      await _ready();
      var loop = _loop;
      if (loop == null) {
        loop = _loop = AudioPlayer();
        await loop.setAudioContext(soundContext);
        await loop.setReleaseMode(ReleaseMode.loop);
      }
      await loop.stop();
      _sounding = null;
      if (music == null) return;
      await loop.setVolume(_musicVolume);
      await loop.play(AssetSource('sounds/${music.file}.wav'));
      _sounding = music;
    } catch (_) {
      _sounding = null;
    }
  }

  void dispose() {
    _lifecycle.dispose();
    unawaited(_loop?.dispose());
  }
}
