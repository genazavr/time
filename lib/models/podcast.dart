class Podcast {
  final String id;
  final String title;
  final String description;
  final String author;
  final String audioUrl;
  final String? imageUrl;
  final Duration duration;
  final String category;
  final List<String> tags;
  final DateTime publishedAt;
  final DateTime createdAt;
  final int playCount;
  final bool isFavorite;
  final double rating;

  Podcast({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.audioUrl,
    this.imageUrl,
    required this.duration,
    required this.category,
    this.tags = const [],
    required this.publishedAt,
    required this.createdAt,
    this.playCount = 0,
    this.isFavorite = false,
    this.rating = 0.0,
  });

  factory Podcast.fromMap(Map<String, dynamic> map, String id) {
    return Podcast(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      author: map['author'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      imageUrl: map['imageUrl'],
      duration: Duration(seconds: map['durationSeconds'] ?? 0),
      category: map['category'] ?? 'Образование',
      tags: List<String>.from(map['tags'] ?? []),
      publishedAt: DateTime.parse(map['publishedAt']),
      createdAt: DateTime.parse(map['createdAt']),
      playCount: map['playCount'] ?? 0,
      isFavorite: map['isFavorite'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'author': author,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'durationSeconds': duration.inSeconds,
      'category': category,
      'tags': tags,
      'publishedAt': publishedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'playCount': playCount,
      'isFavorite': isFavorite,
      'rating': rating,
    };
  }

  Podcast copyWith({
    String? id,
    String? title,
    String? description,
    String? author,
    String? audioUrl,
    String? imageUrl,
    Duration? duration,
    String? category,
    List<String>? tags,
    DateTime? publishedAt,
    DateTime? createdAt,
    int? playCount,
    bool? isFavorite,
    double? rating,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      playCount: playCount ?? this.playCount,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
    );
  }

  String get durationText {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class PodcastProgress {
  final String podcastId;
  final Duration position;
  final bool isCompleted;
  final DateTime lastPlayedAt;

  PodcastProgress({
    required this.podcastId,
    required this.position,
    this.isCompleted = false,
    required this.lastPlayedAt,
  });

  factory PodcastProgress.fromMap(Map<String, dynamic> map) {
    return PodcastProgress(
      podcastId: map['podcastId'] ?? '',
      position: Duration(seconds: map['positionSeconds'] ?? 0),
      isCompleted: map['isCompleted'] ?? false,
      lastPlayedAt: DateTime.parse(map['lastPlayedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'podcastId': podcastId,
      'positionSeconds': position.inSeconds,
      'isCompleted': isCompleted,
      'lastPlayedAt': lastPlayedAt.toIso8601String(),
    };
  }
}