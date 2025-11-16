import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/podcast.dart';
import '../services/firebase_service.dart';

class PodcastService {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<List<Podcast>> getPodcasts() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/podcasts').onValue.map((event) {
      final Map<dynamic, dynamic>? podcastsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (podcastsMap == null) return [];

      return podcastsMap.entries.map((entry) {
        return Podcast.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      }).toList();
    });
  }

  Stream<List<Podcast>> getFavoritePodcasts() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/podcasts').onValue.map((event) {
      final Map<dynamic, dynamic>? podcastsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (podcastsMap == null) return [];

      return podcastsMap.entries.map((entry) {
        final podcast = Podcast.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        return podcast.isFavorite ? podcast : null;
      }).where((podcast) => podcast != null).cast<Podcast>().toList();
    });
  }

  Stream<List<Podcast>> getPodcastsByCategory(String category) {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/podcasts').onValue.map((event) {
      final Map<dynamic, dynamic>? podcastsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (podcastsMap == null) return [];

      return podcastsMap.entries.map((entry) {
        final podcast = Podcast.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        final matchesCategory = podcast.category.toLowerCase() == category.toLowerCase();
        return matchesCategory ? podcast : null;
      }).where((podcast) => podcast != null).cast<Podcast>().toList();
    });
  }

  Future<String> addPodcast(Podcast podcast) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final podcastRef = _database.child('users/$userId/podcasts').push();
    await podcastRef.set(podcast.toMap());
    return podcastRef.key!;
  }

  Future<void> updatePodcast(Podcast podcast) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/podcasts/${podcast.id}').update(podcast.toMap());
  }

  Future<void> deletePodcast(String podcastId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/podcasts/$podcastId').remove();
  }

  Future<void> toggleFavorite(String podcastId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/podcasts/$podcastId/isFavorite').get();
    final currentStatus = snapshot.value as bool? ?? false;
    
    await _database.child('users/$userId/podcasts/$podcastId').update({
      'isFavorite': !currentStatus,
    });
  }

  Future<void> incrementPlayCount(String podcastId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/podcasts/$podcastId/playCount').get();
    final currentCount = snapshot.value as int? ?? 0;
    
    await _database.child('users/$userId/podcasts/$podcastId').update({
      'playCount': currentCount + 1,
    });
  }

  Future<void> updateRating(String podcastId, double rating) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/podcasts/$podcastId').update({
      'rating': rating,
    });
  }

  Future<Podcast?> getPodcast(String podcastId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/podcasts/$podcastId').get();
    if (!snapshot.exists) return null;

    return Podcast.fromMap(Map<String, dynamic>.from(snapshot.value as Map), podcastId);
  }

  // Управление прогрессом прослушивания
  Future<void> saveProgress(String podcastId, Duration position) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final progress = PodcastProgress(
      podcastId: podcastId,
      position: position,
      lastPlayedAt: DateTime.now(),
    );

    await _database.child('users/$userId/podcastProgress/$podcastId').set(progress.toMap());
  }

  Future<PodcastProgress?> getProgress(String podcastId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/podcastProgress/$podcastId').get();
    if (!snapshot.exists) return null;

    return PodcastProgress.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
  }

  Future<List<PodcastProgress>> getAllProgress() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final snapshot = await _database.child('users/$userId/podcastProgress').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? progressMap = snapshot.value as Map<dynamic, dynamic>?;
    if (progressMap == null) return [];

    return progressMap.entries.map((entry) {
      return PodcastProgress.fromMap(Map<String, dynamic>.from(entry.value));
    }).toList();
  }

  Future<List<String>> getCategories() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final snapshot = await _database.child('users/$userId/podcasts').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? podcastsMap = snapshot.value as Map<dynamic, dynamic>?;
    if (podcastsMap == null) return [];

    final categories = <String>{};
    for (final entry in podcastsMap.entries) {
      final podcast = Podcast.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      categories.add(podcast.category);
    }

    return categories.toList();
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return {};

    final snapshot = await _database.child('users/$userId/podcasts').get();
    if (!snapshot.exists) return {};

    final Map<dynamic, dynamic>? podcastsMap = snapshot.value as Map<dynamic, dynamic>?;
    if (podcastsMap == null) return {};

    final podcasts = podcastsMap.entries.map((entry) {
      return Podcast.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
    }).toList();

    final favorites = podcasts.where((p) => p.isFavorite).length;
    final totalPlays = podcasts.fold<int>(0, (sum, p) => sum + p.playCount);
    final averageRating = podcasts.isEmpty ? 0.0 : 
        podcasts.fold<double>(0, (sum, p) => sum + p.rating) / podcasts.length;

    final categories = <String, int>{};
    for (final podcast in podcasts) {
      categories[podcast.category] = (categories[podcast.category] ?? 0) + 1;
    }

    return {
      'totalPodcasts': podcasts.length,
      'favorites': favorites,
      'totalPlays': totalPlays,
      'averageRating': averageRating.roundToDouble(),
      'categories': categories,
      'totalDuration': podcasts.fold<int>(0, (sum, p) => sum + p.duration.inMinutes),
    };
  }
}