import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/homework.dart';
import '../services/firebase_service.dart';

class HomeworkService {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<List<Homework>> getHomework() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/homework').onValue.map((event) {
      final Map<dynamic, dynamic>? homeworkMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (homeworkMap == null) return [];

      return homeworkMap.entries.map((entry) {
        return Homework.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      }).toList();
    });
  }

  Stream<List<Homework>> getPendingHomework() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/homework').onValue.map((event) {
      final Map<dynamic, dynamic>? homeworkMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (homeworkMap == null) return [];

      return homeworkMap.entries.map((entry) {
        final homework = Homework.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        return !homework.isCompleted ? homework : null;
      }).where((homework) => homework != null).cast<Homework>().toList();
    });
  }

  Stream<List<Homework>> getOverdueHomework() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/homework').onValue.map((event) {
      final Map<dynamic, dynamic>? homeworkMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (homeworkMap == null) return [];

      return homeworkMap.entries.map((entry) {
        final homework = Homework.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        final isOverdue = homework.isOverdue && !homework.isCompleted;
        return isOverdue ? homework : null;
      }).where((homework) => homework != null).cast<Homework>().toList();
    });
  }

  Stream<List<Homework>> getHomeworkForSubject(String subject) {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/homework').onValue.map((event) {
      final Map<dynamic, dynamic>? homeworkMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (homeworkMap == null) return [];

      return homeworkMap.entries.map((entry) {
        final homework = Homework.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        final matchesSubject = homework.subject.toLowerCase() == subject.toLowerCase();
        return matchesSubject ? homework : null;
      }).where((homework) => homework != null).cast<Homework>().toList();
    });
  }

  Future<String> addHomework(Homework homework) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final homeworkRef = _database.child('users/$userId/homework').push();
    await homeworkRef.set(homework.toMap());
    return homeworkRef.key!;
  }

  Future<void> updateHomework(Homework homework) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/homework/${homework.id}').update(homework.toMap());
  }

  Future<void> deleteHomework(String homeworkId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/homework/$homeworkId').remove();
  }

  Future<void> toggleHomeworkCompletion(String homeworkId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/homework/$homeworkId').get();
    if (!snapshot.exists) return;

    final homework = Homework.fromMap(Map<String, dynamic>.from(snapshot.value as Map), homeworkId);
    final newStatus = !homework.isCompleted;
    
    await _database.child('users/$userId/homework/$homeworkId').update({
      'isCompleted': newStatus,
      'completedAt': newStatus ? DateTime.now().toIso8601String() : (homework.completedAt?.toIso8601String() ?? ''),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Homework?> getHomeworkById(String homeworkId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/homework/$homeworkId').get();
    if (!snapshot.exists) return null;

    return Homework.fromMap(Map<String, dynamic>.from(snapshot.value as Map), homeworkId);
  }

  Future<List<Homework>> getHomeworkForWeek() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final snapshot = await _database.child('users/$userId/homework').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? homeworkMap = snapshot.value as Map<dynamic, dynamic>?;
    if (homeworkMap == null) return [];

    return homeworkMap.entries.map((entry) {
      final homework = Homework.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      final isInWeek = homework.dueDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) && 
                       homework.dueDate.isBefore(weekEnd.add(const Duration(seconds: 1))) &&
                       !homework.isCompleted;
      return isInWeek ? homework : null;
    }).where((homework) => homework != null).cast<Homework>().toList();
  }

  Future<Map<String, List<Homework>>> getHomeworkBySubject() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return {};

    final snapshot = await _database.child('users/$userId/homework').get();
    if (!snapshot.exists) return {};

    final Map<dynamic, dynamic>? homeworkMap = snapshot.value as Map<dynamic, dynamic>?;
    if (homeworkMap == null) return {};

    final homeworkList = homeworkMap.entries.map((entry) {
      return Homework.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
    }).where((homework) => !homework.isCompleted).toList();

    final Map<String, List<Homework>> bySubject = {};
    for (final homework in homeworkList) {
      if (!bySubject.containsKey(homework.subject)) {
        bySubject[homework.subject] = [];
      }
      bySubject[homework.subject]!.add(homework);
    }

    return bySubject;
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return {};

    final snapshot = await _database.child('users/$userId/homework').get();
    if (!snapshot.exists) return {};

    final Map<dynamic, dynamic>? homeworkMap = snapshot.value as Map<dynamic, dynamic>?;
    if (homeworkMap == null) return {};

    final homeworkList = homeworkMap.entries.map((entry) {
      return Homework.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
    }).toList();

    final total = homeworkList.length;
    final completed = homeworkList.where((h) => h.isCompleted).length;
    final overdue = homeworkList.where((h) => h.isOverdue && !h.isCompleted).length;
    final dueToday = homeworkList.where((h) => h.isDueToday && !h.isCompleted).length;
    final dueSoon = homeworkList.where((h) => h.isDueSoon && !h.isCompleted).length;

    final subjects = <String, int>{};
    for (final homework in homeworkList) {
      subjects[homework.subject] = (subjects[homework.subject] ?? 0) + 1;
    }

    return {
      'total': total,
      'completed': completed,
      'pending': total - completed,
      'overdue': overdue,
      'dueToday': dueToday,
      'dueSoon': dueSoon,
      'completionRate': total == 0 ? 0.0 : (completed / total * 100).roundToDouble(),
      'subjects': subjects,
      'totalEstimatedMinutes': homeworkList.fold<int>(0, (sum, hw) => sum + hw.estimatedMinutes),
    };
  }
}