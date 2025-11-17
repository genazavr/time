import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../models/calendar_event.dart';
import '../models/homework.dart';
import '../models/pomodoro_session.dart';
import '../models/task_model.dart';
import '../models/user_metrics.dart';
import 'firebase_service.dart';

class UserMetricsService {
  static final UserMetricsService _instance = UserMetricsService._internal();

  factory UserMetricsService() => _instance;

  UserMetricsService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  StreamController<UserMetrics>? _controller;
  final List<StreamSubscription<DatabaseEvent>> _subscriptions = [];

  List<TaskModel> _tasks = [];
  List<Homework> _homework = [];
  List<PomodoroSession> _sessions = [];
  List<CalendarEvent> _events = [];
  int _notesCount = 0;
  String? _activeUserId;

  Stream<UserMetrics> watchMetrics() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) {
      return Stream.value(UserMetrics.empty);
    }

    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<UserMetrics>.broadcast();
    }

    if (_activeUserId != userId) {
      _reset();
      _activeUserId = userId;
      _setupSubscriptions(userId);
    } else if (_subscriptions.isEmpty) {
      _setupSubscriptions(userId);
    }

    return _controller!.stream;
  }

  void dispose() {
    _reset();
    _controller?.close();
    _controller = null;
  }

  void _reset() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _tasks = [];
    _homework = [];
    _sessions = [];
    _events = [];
    _notesCount = 0;
    if (_controller != null && !_controller!.isClosed) {
      _controller!.add(UserMetrics.empty);
    }
  }

  void _setupSubscriptions(String userId) {
    _listen('users/$userId/tasks', (value) {
      _tasks = _parseCollection(value, (data, id) =>
          TaskModel.fromMap(Map<String, dynamic>.from(data), id, userId));
    });

    _listen('users/$userId/homework', (value) {
      _homework = _parseCollection(
        value,
        (data, id) => Homework.fromMap(Map<String, dynamic>.from(data), id),
      );
    });

    _listen('users/$userId/pomodoro/sessions', (value) {
      _sessions = _parseCollection(
        value,
        (data, id) =>
            PomodoroSession.fromMap(Map<String, dynamic>.from(data), id),
      );
    });

    _listen('users/$userId/calendar', (value) {
      _events = _parseCollection(
        value,
        (data, id) =>
            CalendarEvent.fromMap(Map<String, dynamic>.from(data), id),
      );
    });

    _listen('users/$userId/notes', (value) {
      if (value == null) {
        _notesCount = 0;
      } else if (value is Map<dynamic, dynamic>) {
        _notesCount = value.length;
      } else if (value is List) {
        _notesCount = value.where((e) => e != null).length;
      } else {
        _notesCount = 0;
      }
    });
  }

  void _listen(String path, void Function(dynamic value) onData) {
    final sub = _database.ref(path).onValue.listen((event) {
      onData(event.snapshot.value);
      _emit();
    });
    _subscriptions.add(sub);
  }

  void _emit() {
    if (_controller == null || _controller!.isClosed) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final completedTasks =
        _tasks.where((task) => task.status == TaskStatus.completed).length;
    final tasksDueToday = _tasks.where((task) {
      final dueDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      return task.status != TaskStatus.completed && dueDate.isAtSameMomentAs(today);
    }).length;

    final completedHomework =
        _homework.where((homework) => homework.isCompleted).length;
    final overdueHomework =
        _homework.where((homework) => homework.isOverdue).length;

    final eventsToday = _events.where((event) {
      final eventDay = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      return eventDay.isAtSameMomentAs(today) && !event.isCompleted;
    }).length;

    final pomodoroToday = _sessions.where((session) {
      final sessionDay = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      return sessionDay.isAtSameMomentAs(today) && session.isCompleted;
    }).length;

    final focusMinutesToday = _sessions.where((session) {
      final sessionDay = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      return sessionDay.isAtSameMomentAs(today) &&
          session.type == 'work' &&
          session.isCompleted;
    }).fold<int>(0, (sum, session) => sum + session.duration);

    final focusMinutesWeek = _sessions.where((session) {
      final sessionDay = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      return sessionDay.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
          session.type == 'work' &&
          session.isCompleted;
    }).fold<int>(0, (sum, session) => sum + session.duration);

    final metrics = UserMetrics(
      totalTasks: _tasks.length,
      completedTasks: completedTasks,
      tasksDueToday: tasksDueToday,
      totalHomework: _homework.length,
      completedHomework: completedHomework,
      overdueHomework: overdueHomework,
      notesCount: _notesCount,
      eventsToday: eventsToday,
      pomodoroSessionsToday: pomodoroToday,
      completedPomodoroSessions:
          _sessions.where((session) => session.isCompleted).length,
      focusMinutesToday: focusMinutesToday,
      focusMinutesWeek: focusMinutesWeek,
    );

    _controller!.add(metrics);
  }

  List<T> _parseCollection<T>(
    dynamic raw,
    T Function(Map<dynamic, dynamic> data, String id) builder,
  ) {
    if (raw == null) return [];
    if (raw is Map<dynamic, dynamic>) {
      final result = <T>[];
      raw.forEach((key, value) {
        if (value is Map) {
          result.add(builder(Map<dynamic, dynamic>.from(value), key.toString()));
        }
      });
      return result;
    }
    if (raw is List) {
      final result = <T>[];
      for (var i = 0; i < raw.length; i++) {
        final value = raw[i];
        if (value is Map) {
          result.add(builder(Map<dynamic, dynamic>.from(value), i.toString()));
        }
      }
      return result;
    }
    return [];
  }
}
