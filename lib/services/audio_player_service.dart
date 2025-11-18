import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/podcast.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  
  factory AudioPlayerService() => _instance;
  
  AudioPlayerService._internal() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isPlayingController.add(_isPlaying);
    });
    
    _player.positionStream.listen((position) {
      _currentPosition = position;
      _positionController.add(_currentPosition);
    });
    
    _player.durationStream.listen((duration) {
      _totalDuration = duration;
      _durationController.add(_totalDuration);
    });
    
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _isPlayingController.add(_isPlaying);
        _playNext();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  Podcast? _currentPodcast;
  List<Podcast> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  
  final StreamController<bool> _isPlayingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController = StreamController<Duration?>.broadcast();
  final StreamController<Podcast?> _currentPodcastController = StreamController<Podcast?>.broadcast();

  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<Podcast?> get currentPodcastStream => _currentPodcastController.stream;

  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration? get totalDuration => _totalDuration;
  Podcast? get currentPodcast => _currentPodcast;
  List<Podcast> get playlist => _playlist;

  Future<void> playPodcast(Podcast podcast, {List<Podcast>? playlist}) async {
    try {
      if (playlist != null) {
        _playlist = playlist;
        _currentIndex = playlist.indexWhere((p) => p.id == podcast.id);
        if (_currentIndex == -1) {
          _playlist = [podcast];
          _currentIndex = 0;
        }
      } else {
        _playlist = [podcast];
        _currentIndex = 0;
      }

      String audioUrl = podcast.localAudioPath ?? podcast.audioUrl;
      if (audioUrl.isEmpty) return;

      if (_currentPodcast?.id != podcast.id) {
        await _player.setUrl(audioUrl);
        _currentPodcast = podcast;
        _currentPodcastController.add(_currentPodcast);
      }

      await _player.play();
      _isPlaying = true;
      _isPlayingController.add(_isPlaying);
    } catch (e) {
      debugPrint('Error playing podcast: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    _isPlayingController.add(_isPlaying);
  }

  Future<void> resume() async {
    await _player.play();
    _isPlaying = true;
    _isPlayingController.add(_isPlaying);
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _isPlayingController.add(_isPlaying);
    _currentPodcast = null;
    _currentPodcastController.add(_currentPodcast);
    _currentPosition = Duration.zero;
    _positionController.add(_currentPosition);
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await playPodcast(_playlist[_currentIndex], playlist: _playlist);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await playPodcast(_playlist[_currentIndex], playlist: _playlist);
  }

  void _playNext() {
    if (_playlist.length > 1) {
      playNext();
    }
  }

  Future<void> setPlaylist(List<Podcast> playlist, {int startIndex = 0}) async {
    _playlist = playlist;
    _currentIndex = startIndex.clamp(0, playlist.length - 1);
    
    if (playlist.isNotEmpty) {
      await playPodcast(playlist[_currentIndex], playlist: _playlist);
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  void dispose() {
    _player.dispose();
    _isPlayingController.close();
    _positionController.close();
    _durationController.close();
    _currentPodcastController.close();
  }
}