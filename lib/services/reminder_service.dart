import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/reminder.dart';
import '../services/firebase_service.dart';

class ReminderService {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<List<Reminder>> getReminders() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/reminders').onValue.map((event) {
      final Map<dynamic, dynamic>? remindersMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (remindersMap == null) return [];

      return remindersMap.entries.map((entry) {
        return Reminder.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      }).toList();
    });
  }

  Stream<List<Reminder>> getActiveReminders() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/reminders').onValue.map((event) {
      final Map<dynamic, dynamic>? remindersMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (remindersMap == null) return [];

      return remindersMap.entries.map((entry) {
        final reminder = Reminder.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        final isActive = reminder.isActive && !reminder.isPast;
        return isActive ? reminder : null;
      }).where((reminder) => reminder != null).cast<Reminder>().toList();
    });
  }

  Stream<List<Reminder>> getRemindersForToday() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/reminders').onValue.map((event) {
      final Map<dynamic, dynamic>? remindersMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (remindersMap == null) return [];

      return remindersMap.entries.map((entry) {
        final reminder = Reminder.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        final isToday = reminder.isToday && reminder.isActive;
        return isToday ? reminder : null;
      }).where((reminder) => reminder != null).cast<Reminder>().toList();
    });
  }

  Future<String> addReminder(Reminder reminder) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final reminderRef = _database.child('users/$userId/reminders').push();
    await reminderRef.set(reminder.toMap());
    return reminderRef.key!;
  }

  Future<void> updateReminder(Reminder reminder) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/reminders/${reminder.id}').update(reminder.toMap());
  }

  Future<void> deleteReminder(String reminderId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/reminders/$reminderId').remove();
  }

  Future<void> toggleReminderStatus(String reminderId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/reminders/$reminderId/isActive').get();
    final currentStatus = snapshot.value as bool? ?? true;
    
    await _database.child('users/$userId/reminders/$reminderId').update({
      'isActive': !currentStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Reminder?> getReminder(String reminderId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/reminders/$reminderId').get();
    if (!snapshot.exists) return null;

    return Reminder.fromMap(Map<String, dynamic>.from(snapshot.value as Map), reminderId);
  }

  Future<List<Reminder>> getUpcomingReminders({int hours = 24}) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final now = DateTime.now();
    final endTime = now.add(Duration(hours: hours));

    final snapshot = await _database.child('users/$userId/reminders').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? remindersMap = snapshot.value as Map<dynamic, dynamic>?;
    if (remindersMap == null) return [];

    return remindersMap.entries.map((entry) {
      final reminder = Reminder.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      final isUpcoming = reminder.isActive && 
                        reminder.scheduledTime.isAfter(now.subtract(const Duration(seconds: 1))) && 
                        reminder.scheduledTime.isBefore(endTime);
      return isUpcoming ? reminder : null;
    }).where((reminder) => reminder != null).cast<Reminder>().toList();
  }

  Future<List<Reminder>> getRemindersByType(String type) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final snapshot = await _database.child('users/$userId/reminders').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? remindersMap = snapshot.value as Map<dynamic, dynamic>?;
    if (remindersMap == null) return [];

    return remindersMap.entries.map((entry) {
      final reminder = Reminder.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      final matchesType = reminder.type.toLowerCase() == type.toLowerCase() && reminder.isActive;
      return matchesType ? reminder : null;
    }).where((reminder) => reminder != null).cast<Reminder>().toList();
  }

  Future<List<Reminder>> getBreakReminders() async {
    return getRemindersByType('break');
  }

  Future<List<Reminder>> getDeadlineReminders() async {
    return getRemindersByType('deadline');
  }

  Future<void> createBreakReminder(String title, DateTime scheduledTime, {bool isRepeating = false}) async {
    final reminder = Reminder(
      id: '', // Будет сгенерирован в addReminder
      title: title,
      scheduledTime: scheduledTime,
      isRepeating: isRepeating,
      repeatPattern: isRepeating ? 'daily' : 'none',
      type: 'break',
      createdAt: DateTime.now(),
    );

    await addReminder(reminder);
  }

  Future<void> createDeadlineReminder(
    String title,
    DateTime deadlineTime,
    String relatedEntityId,
    String relatedEntityType, {
    int minutesBefore = 30,
  }) async {
    final reminderTime = deadlineTime.subtract(Duration(minutes: minutesBefore));
    
    final reminder = Reminder(
      id: '', // Будет сгенерирован в addReminder
      title: title,
      scheduledTime: reminderTime,
      type: 'deadline',
      minutesBefore: minutesBefore,
      relatedEntityId: relatedEntityId,
      relatedEntityType: relatedEntityType,
      createdAt: DateTime.now(),
    );

    await addReminder(reminder);
  }

  Future<void> createRepeatingReminder(
    String title,
    String repeatPattern,
    List<int> repeatDays,
    DateTime scheduledTime, {
    String? description,
    String type = 'custom',
  }) async {
    final reminder = Reminder(
      id: '', // Будет сгенерирован в addReminder
      title: title,
      description: description,
      scheduledTime: scheduledTime,
      isRepeating: true,
      repeatPattern: repeatPattern,
      repeatDays: repeatDays,
      type: type,
      createdAt: DateTime.now(),
    );

    await addReminder(reminder);
  }

  Future<void> updateRepeatingReminder(String reminderId, DateTime newScheduledTime) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/reminders/$reminderId').update({
      'scheduledTime': newScheduledTime.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return {};

    final snapshot = await _database.child('users/$userId/reminders').get();
    if (!snapshot.exists) return {};

    final Map<dynamic, dynamic>? remindersMap = snapshot.value as Map<dynamic, dynamic>?;
    if (remindersMap == null) return {};

    final reminders = remindersMap.entries.map((entry) {
      return Reminder.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
    }).toList();

    final active = reminders.where((r) => r.isActive).length;
    final today = reminders.where((r) => r.isToday && r.isActive).length;
    final past = reminders.where((r) => r.isPast).length;
    final repeating = reminders.where((r) => r.isRepeating).length;

    final types = <String, int>{};
    for (final reminder in reminders) {
      types[reminder.type] = (types[reminder.type] ?? 0) + 1;
    }

    return {
      'total': reminders.length,
      'active': active,
      'today': today,
      'past': past,
      'repeating': repeating,
      'types': types,
    };
  }
}