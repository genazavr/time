import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/calendar_event.dart';
import '../services/firebase_service.dart';

class CalendarService {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _eventsSubscription;

  Stream<List<CalendarEvent>> getEvents() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/calendar').onValue.map((event) {
      final Map<dynamic, dynamic>? eventsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (eventsMap == null) return [];

      return eventsMap.entries.map((entry) {
        return CalendarEvent.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      }).toList();
    });
  }

  Stream<List<CalendarEvent>> getEventsForDay(DateTime day) {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _database.child('users/$userId/calendar').onValue.map((event) {
      final Map<dynamic, dynamic>? eventsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (eventsMap == null) return [];

      return eventsMap.entries.map((entry) {
        final calendarEvent = CalendarEvent.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        final eventDate = calendarEvent.startDate;
        final isInDay = eventDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
                       eventDate.isBefore(endOfDay);
        return isInDay ? calendarEvent : null;
      }).where((event) => event != null).cast<CalendarEvent>().toList();
    });
  }

  Future<String> addEvent(CalendarEvent event) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final eventRef = _database.child('users/$userId/calendar').push();
    await eventRef.set(event.toMap());
    return eventRef.key!;
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/calendar/${event.id}').update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/calendar/$eventId').remove();
  }

  Future<CalendarEvent?> getEvent(String eventId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/calendar/$eventId').get();
    if (!snapshot.exists) return null;

    return CalendarEvent.fromMap(Map<String, dynamic>.from(snapshot.value as Map), eventId);
  }

  Future<List<CalendarEvent>> getEventsForMonth(DateTime month) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snapshot = await _database.child('users/$userId/calendar').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? eventsMap = snapshot.value as Map<dynamic, dynamic>?;
    if (eventsMap == null) return [];

    return eventsMap.entries.map((entry) {
      final event = CalendarEvent.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      final eventDate = event.startDate;
      final isInMonth = eventDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && 
                       eventDate.isBefore(endOfMonth.add(const Duration(seconds: 1)));
      return isInMonth ? event : null;
    }).where((event) => event != null).cast<CalendarEvent>().toList();
  }

  Future<List<CalendarEvent>> getUpcomingEvents({int days = 7}) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    final snapshot = await _database.child('users/$userId/calendar').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? eventsMap = snapshot.value as Map<dynamic, dynamic>?;
    if (eventsMap == null) return [];

    return eventsMap.entries.map((entry) {
      final event = CalendarEvent.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      final isUpcoming = event.startDate.isAfter(now.subtract(const Duration(seconds: 1))) && 
                       event.startDate.isBefore(endDate);
      return isUpcoming ? event : null;
    }).where((event) => event != null).cast<CalendarEvent>().toList();
  }

  void dispose() {
    _eventsSubscription?.cancel();
  }
}