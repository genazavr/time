import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/schedule.dart';
import '../services/firebase_service.dart';

class ScheduleService {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<List<Schedule>> getSchedules() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/schedules').onValue.map((event) {
      final Map<dynamic, dynamic>? schedulesMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (schedulesMap == null) return [];

      return schedulesMap.entries.map((entry) {
        return Schedule.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      }).toList();
    });
  }

  Future<String> addSchedule(Schedule schedule) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final scheduleRef = _database.child('users/$userId/schedules').push();
    await scheduleRef.set(schedule.toMap());
    return scheduleRef.key!;
  }

  Future<void> updateSchedule(Schedule schedule) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/schedules/${schedule.id}').update(schedule.toMap());
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/schedules/$scheduleId').remove();
  }

  Future<Schedule?> getSchedule(String scheduleId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/schedules/$scheduleId').get();
    if (!snapshot.exists) return null;

    return Schedule.fromMap(Map<String, dynamic>.from(snapshot.value as Map), scheduleId);
  }

  Future<List<Schedule>> getSchedulesForDay(DateTime day) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final startOfDay = DateTime(day.year, day.month, day.day);

    final snapshot = await _database.child('users/$userId/schedules').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? schedulesMap = snapshot.value as Map<dynamic, dynamic>?;
    if (schedulesMap == null) return [];

    return schedulesMap.entries.map((entry) {
      final schedule = Schedule.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      final scheduleDate = DateTime(schedule.startTime.year, schedule.startTime.month, schedule.startTime.day);
      final isSameDay = scheduleDate.isAtSameMomentAs(startOfDay);
      return isSameDay ? schedule : null;
    }).where((schedule) => schedule != null).cast<Schedule>().toList();
  }

  Future<List<Schedule>> getSchedulesForWeek(DateTime weekStart) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final weekEnd = weekStart.add(const Duration(days: 7));

    final snapshot = await _database.child('users/$userId/schedules').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? schedulesMap = snapshot.value as Map<dynamic, dynamic>?;
    if (schedulesMap == null) return [];

    return schedulesMap.entries.map((entry) {
      final schedule = Schedule.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      final isInWeek = schedule.startTime.isAfter(weekStart.subtract(const Duration(seconds: 1))) && 
                       schedule.startTime.isBefore(weekEnd);
      return isInWeek ? schedule : null;
    }).where((schedule) => schedule != null).cast<Schedule>().toList();
  }
}