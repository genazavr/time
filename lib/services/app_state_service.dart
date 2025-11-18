import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

import '../models/user_metrics.dart';

class AppStateService {
  static final AppStateService _instance = AppStateService._internal();

  factory AppStateService() => _instance;

  AppStateService._internal() {
    _metricsController = StreamController<UserMetrics>.broadcast();
    _userDataController = StreamController<Map<String, dynamic>>.broadcast();
  }

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  late final StreamController<UserMetrics> _metricsController;
  late final StreamController<Map<String, dynamic>> _userDataController;
  
  final List<StreamSubscription> _subscriptions = [];
  String? _currentUserId;

  UserMetrics _cachedMetrics = UserMetrics.empty;
  Map<String, dynamic> _cachedUserData = {};

  void initialize(String userId) {
    if (_currentUserId == userId && _subscriptions.isNotEmpty) {
      return;
    }

    cleanup();
    _currentUserId = userId;
    _setupMetricsStream(userId);
    _setupUserDataStream(userId);
  }

  void cleanup() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _currentUserId = null;
  }

  void dispose() {
    cleanup();
    _metricsController.close();
    _userDataController.close();
  }

  Stream<UserMetrics> watchMetrics() {
    _metricsController.add(_cachedMetrics);
    return _metricsController.stream;
  }

  Stream<Map<String, dynamic>> watchUserData() {
    _userDataController.add(_cachedUserData);
    return _userDataController.stream;
  }

  UserMetrics get metrics => _cachedMetrics;
  Map<String, dynamic> get userData => _cachedUserData;

  void _setupMetricsStream(String userId) {
    _listenToTasks(userId);
    _listenToEisenhower(userId);
    _listenToHomework(userId);
    _listenToPomodoro(userId);
    _listenToCalendar(userId);
    _listenToNotes(userId);
  }

  void _setupUserDataStream(String userId) {
    final sub = _database.ref('users/$userId').onValue.listen((event) {
      if (event.snapshot.value is Map) {
        final data = Map<String, dynamic>.from(
          (event.snapshot.value as Map).cast<String, dynamic>(),
        );
        _cachedUserData = data;
        _userDataController.add(_cachedUserData);
      }
    });
    _subscriptions.add(sub);
  }

  void _listenToTasks(String userId) {
    final sub = _database.ref('users/$userId/tasks').onValue.listen((_) {
      _emitMetrics();
    });
    _subscriptions.add(sub);
  }

  void _listenToEisenhower(String userId) {
    final sub = _database.ref('users/$userId/eisenhower').onValue.listen((_) {
      _emitMetrics();
    });
    _subscriptions.add(sub);
  }

  void _listenToHomework(String userId) {
    final sub = _database.ref('users/$userId/homework').onValue.listen((_) {
      _emitMetrics();
    });
    _subscriptions.add(sub);
  }

  void _listenToPomodoro(String userId) {
    final sub = _database.ref('users/$userId/pomodoro/sessions').onValue.listen((_) {
      _emitMetrics();
    });
    _subscriptions.add(sub);
  }

  void _listenToCalendar(String userId) {
    final sub = _database.ref('users/$userId/calendar').onValue.listen((_) {
      _emitMetrics();
    });
    _subscriptions.add(sub);
  }

  void _listenToNotes(String userId) {
    final sub = _database.ref('users/$userId/notes').onValue.listen((_) {
      _emitMetrics();
    });
    _subscriptions.add(sub);
  }

  Future<void> _emitMetrics() async {
    if (_currentUserId == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    try {
      final tasksSnap = await _database.ref('users/$_currentUserId/tasks').get();
      final eisenhowerSnap = await _database.ref('users/$_currentUserId/eisenhower').get();
      final homeworkSnap = await _database.ref('users/$_currentUserId/homework').get();
      final sessionsSnap = await _database.ref('users/$_currentUserId/pomodoro/sessions').get();
      final eventsSnap = await _database.ref('users/$_currentUserId/calendar').get();
      final notesSnap = await _database.ref('users/$_currentUserId/notes').get();

      int totalTasks = 0, completedTasks = 0, tasksDueToday = 0, activeTasks = 0;
      if (tasksSnap.exists && tasksSnap.value is Map) {
        final tasks = tasksSnap.value as Map;
        totalTasks = tasks.length;
        tasks.forEach((key, value) {
          if (value is Map && value['status'] == 'completed') {
            completedTasks++;
          }
          if (value is Map) {
            final dueDate = value['dueDate'];
            if (dueDate != null) {
              try {
                final due = DateTime.parse(dueDate.toString());
                if (DateTime(due.year, due.month, due.day).isAtSameMomentAs(today) &&
                    value['status'] != 'completed') {
                  tasksDueToday++;
                }
              } catch (_) {}
            }
          }
        });
      }

      int totalHomework = 0, completedHomework = 0, overdueHomework = 0;
      if (homeworkSnap.exists && homeworkSnap.value is Map) {
        final homework = homeworkSnap.value as Map;
        totalHomework = homework.length;
        homework.forEach((key, value) {
          if (value is Map) {
            if (value['isCompleted'] == true) {
              completedHomework++;
            }
            if (value['isOverdue'] == true) {
              overdueHomework++;
            }
          }
        });
      }

      int eventsToday = 0;
      if (eventsSnap.exists && eventsSnap.value is Map) {
        final events = eventsSnap.value as Map;
        events.forEach((key, value) {
          if (value is Map) {
            final startDate = value['startDate'];
            if (startDate != null && value['isCompleted'] != true) {
              try {
                final start = DateTime.parse(startDate.toString());
                if (DateTime(start.year, start.month, start.day).isAtSameMomentAs(today)) {
                  eventsToday++;
                }
              } catch (_) {}
            }
          }
        });
      }

      int pomodoroToday = 0, focusMinutesToday = 0, focusMinutesWeek = 0;
      int completedSessions = 0;
      if (sessionsSnap.exists && sessionsSnap.value is Map) {
        final sessions = sessionsSnap.value as Map;
        sessions.forEach((key, value) {
          if (value is Map) {
            final startTime = value['startTime'];
            if (startTime != null) {
              try {
                final start = DateTime.parse(startTime.toString());
                final sessionDay = DateTime(start.year, start.month, start.day);
                if (value['isCompleted'] == true) {
                  completedSessions++;
                  if (sessionDay.isAtSameMomentAs(today)) {
                    pomodoroToday++;
                  }
                  if (value['type'] == 'work' && 
                      sessionDay.isAfter(weekStart.subtract(const Duration(seconds: 1)))) {
                    focusMinutesWeek += (value['duration'] as int?) ?? 0;
                  }
                  if (value['type'] == 'work' && sessionDay.isAtSameMomentAs(today)) {
                    focusMinutesToday += (value['duration'] as int?) ?? 0;
                  }
                }
              } catch (_) {}
            }
          }
        });
      }

      if (eisenhowerSnap.exists && eisenhowerSnap.value is Map) {
        final eisenhower = eisenhowerSnap.value as Map;
        eisenhower.forEach((key, value) {
          if (value is Map && value['isCompleted'] != true) {
            activeTasks++;
          }
        });
      }

      int notesCount = 0;
      if (notesSnap.exists && notesSnap.value is Map) {
        notesCount = (notesSnap.value as Map).length;
      }

      final newMetrics = UserMetrics(
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        tasksDueToday: tasksDueToday,
        activeTasks: activeTasks,
        totalHomework: totalHomework,
        completedHomework: completedHomework,
        overdueHomework: overdueHomework,
        notesCount: notesCount,
        eventsToday: eventsToday,
        pomodoroSessionsToday: pomodoroToday,
        completedPomodoroSessions: completedSessions,
        focusMinutesToday: focusMinutesToday,
        focusMinutesWeek: focusMinutesWeek,
      );

      _cachedMetrics = newMetrics;
      _metricsController.add(_cachedMetrics);
    } catch (_) {
      // Silently handle errors during metrics emission
    }
  }
}
