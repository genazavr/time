import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/pomodoro_session.dart';
import '../services/firebase_service.dart';

class PomodoroService {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<List<PomodoroSession>> getSessions() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/pomodoro/sessions').onValue.map((event) {
      final Map<dynamic, dynamic>? sessionsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (sessionsMap == null) return [];

      return sessionsMap.entries.map((entry) {
        return PomodoroSession.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      }).toList();
    });
  }

  Stream<List<PomodoroSession>> getSessionsForToday() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _database.child('users/$userId/pomodoro/sessions').onValue.map((event) {
      final Map<dynamic, dynamic>? sessionsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (sessionsMap == null) return [];

      return sessionsMap.entries.map((entry) {
        final session = PomodoroSession.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        final isToday = session.startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
                        session.startTime.isBefore(endOfDay);
        return isToday ? session : null;
      }).where((session) => session != null).cast<PomodoroSession>().toList();
    });
  }

  Future<String> startSession(PomodoroSession session) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final sessionRef = _database.child('users/$userId/pomodoro/sessions').push();
    await sessionRef.set(session.toMap());
    return sessionRef.key!;
  }

  Future<void> completeSession(String sessionId, DateTime endTime) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/pomodoro/sessions/$sessionId').update({
      'endTime': endTime.toIso8601String(),
      'isCompleted': true,
    });
  }

  Future<void> incrementInterruptions(String sessionId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/pomodoro/sessions/$sessionId/interruptions').get();
    final currentInterruptions = snapshot.value as int? ?? 0;
    
    await _database.child('users/$userId/pomodoro/sessions/$sessionId').update({
      'interruptions': currentInterruptions + 1,
    });
  }

  Future<void> deleteSession(String sessionId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/pomodoro/sessions/$sessionId').remove();
  }

  // Статистика
  Future<Map<String, dynamic>> getStatistics() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return {};

    final snapshot = await _database.child('users/$userId/pomodoro/sessions').get();
    if (!snapshot.exists) return {};

    final Map<dynamic, dynamic>? sessionsMap = snapshot.value as Map<dynamic, dynamic>?;
    if (sessionsMap == null) return {};

    final sessions = sessionsMap.entries.map((entry) {
      return PomodoroSession.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
    }).toList();

    final today = DateTime.now();
    final todaySessions = sessions.where((session) {
      final sessionDate = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      return sessionDate.isAtSameMomentAs(todayDate);
    }).toList();

    final thisWeek = sessions.where((session) {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final sessionDate = session.startTime;
      return sessionDate.isAfter(weekStart.subtract(const Duration(seconds: 1)));
    }).toList();

    final workSessions = sessions.where((s) => s.type == 'work' && s.isCompleted).toList();
    final totalFocusTime = workSessions.fold<int>(0, (sum, session) => sum + session.duration);

    return {
      'todaySessions': todaySessions.length,
      'todayFocusTime': todaySessions
          .where((s) => s.type == 'work' && s.isCompleted)
          .fold<int>(0, (sum, session) => sum + session.duration),
      'weekSessions': thisWeek.length,
      'weekFocusTime': thisWeek
          .where((s) => s.type == 'work' && s.isCompleted)
          .fold<int>(0, (sum, session) => sum + session.duration),
      'totalSessions': sessions.length,
      'totalFocusTime': totalFocusTime,
      'completionRate': sessions.isEmpty ? 0.0 : 
          (sessions.where((s) => s.isCompleted).length / sessions.length * 100).roundToDouble(),
    };
  }

  // Настройки Pomodoro
  Future<PomodoroSettings> getSettings() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return PomodoroSettings();

    final snapshot = await _database.child('users/$userId/pomodoro/settings').get();
    if (!snapshot.exists) return PomodoroSettings();

    return PomodoroSettings.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
  }

  Future<void> updateSettings(PomodoroSettings settings) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/pomodoro/settings').set(settings.toMap());
  }
}