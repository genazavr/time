import 'package:flutter/material.dart';
import '../models/podcast.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  Podcast? _currentPodcast;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _audioService.isPlayingStream.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });
    
    _audioService.positionStream.listen((position) {
      if (mounted && !_isDragging) {
        setState(() => _currentPosition = position);
      }
    });
    
    _audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _totalDuration = duration);
      }
    });
    
    _audioService.currentPodcastStream.listen((podcast) {
      if (mounted) {
        setState(() => _currentPodcast = podcast);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPodcast == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Icon(
                  _getIconData(_currentPodcast!.iconName ?? 'headphones'),
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentPodcast!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPodcast!.author,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _audioService.stop();
                },
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_totalDuration != null)
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: _totalDuration!.inMilliseconds.toDouble(),
                    value: _isDragging 
                        ? _currentPosition.inMilliseconds.toDouble() 
                        : _currentPosition.inMilliseconds.clamp(0.0, _totalDuration!.inMilliseconds.toDouble()).toDouble(),
                    onChanged: (value) {
                      setState(() {
                        _isDragging = true;
                        _currentPosition = Duration(milliseconds: value.round());
                      });
                    },
                    onChangeEnd: (value) {
                      setState(() {
                        _isDragging = false;
                      });
                      _audioService.seekTo(Duration(milliseconds: value.round()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _audioService.formatDuration(_currentPosition),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _audioService.formatDuration(_totalDuration!),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _audioService.playPrevious,
                icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isPlaying ? _audioService.pause : _audioService.resume,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
              ),
              IconButton(
                onPressed: _audioService.playNext,
                icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'music_note': return Icons.music_note;
      case 'album': return Icons.album;
      case 'library_music': return Icons.library_music;
      case 'audiotrack': return Icons.audiotrack;
      case 'mic': return Icons.mic;
      case 'radio': return Icons.radio;
      case 'podcast': return Icons.podcasts;
      case 'speaker': return Icons.speaker;
      case 'equalizer': return Icons.equalizer;
      case 'queue_music': return Icons.queue_music;
      default: return Icons.headphones;
    }
  }
}