import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Manages in-app audio playback for guides.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;

  PlayerState get state => _player.state;
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  Future<void> play(String url) async {
    if (_currentUrl == url && _player.state == PlayerState.playing) return;
    if (_currentUrl != null && _currentUrl != url) await _player.stop();
    if (_currentUrl != url) {
      await _player.setSource(UrlSource(url));
      _currentUrl = url;
    }
    await _player.resume();
  }

  Future<void> pause() => _player.pause();
  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
  }

  Future<void> seek(Duration position) => _player.seek(position);

  bool isPlayingUrl(String url) =>
      _currentUrl == url && _player.state == PlayerState.playing;

  void dispose() => _player.dispose();
}
