import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bliss_reminders',
          'BLISS Напоминания',
          channelDescription: 'Напоминания из приложения BLISS',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bliss_immediate',
          'BLISS Срочные',
          channelDescription: 'Срочные уведомления из приложения BLISS',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Specific notification types for BLISS
  Future<void> schedulePomodoroStart({
    required int sessionId,
    required DateTime startTime,
  }) async {
    await scheduleNotification(
      id: 1000 + sessionId,
      title: 'Помодоро сессия начинается!',
      body: 'Время сфокусироваться. Удачи!',
      scheduledTime: startTime,
      payload: 'pomodoro_start_$sessionId',
    );
  }

  Future<void> schedulePomodoroEnd({
    required int sessionId,
    required DateTime endTime,
  }) async {
    await scheduleNotification(
      id: 2000 + sessionId,
      title: 'Помодоро сессия завершена!',
      body: 'Отличная работа! Время для перерыва.',
      scheduledTime: endTime,
      payload: 'pomodoro_end_$sessionId',
    );
  }

  Future<void> scheduleHomeworkReminder({
    required int homeworkId,
    required String title,
    required DateTime dueTime,
  }) async {
    // Напоминание за 2 часа
    final reminderTime = dueTime.subtract(const Duration(hours: 2));
    
    await scheduleNotification(
      id: 3000 + homeworkId,
      title: 'Напоминание о домашнем задании',
      body: 'Не забудьте сдать: $title',
      scheduledTime: reminderTime,
      payload: 'homework_reminder_$homeworkId',
    );
  }

  Future<void> scheduleBreakReminder({
    required int reminderId,
    required String title,
    required DateTime scheduledTime,
  }) async {
    await scheduleNotification(
      id: 4000 + reminderId,
      title: 'Время сделать перерыв!',
      body: title,
      scheduledTime: scheduledTime,
      payload: 'break_reminder_$reminderId',
    );
  }

  Future<void> scheduleDailyMotivation({
    required int id,
    required DateTime scheduledTime,
  }) async {
    final motivations = [
      'Отличный день для продуктивности!',
      'Каждая задача приближает к цели.',
      'Маленькие шаги ведут к большим результатам.',
      'Ты справишься со всем!',
      'Фокус и дисциплина - ключ к успеху.',
    ];
    
    final motivation = motivations[DateTime.now().day % motivations.length];
    
    await scheduleNotification(
      id: 5000 + id,
      title: 'Ежедневная мотивация',
      body: motivation,
      scheduledTime: scheduledTime,
      payload: 'daily_motivation_$id',
    );
  }
}