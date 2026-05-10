import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gamification.dart';

class GamificationService {
  static const String _statsKey = 'user_stats';
  static const String _settingsKey = 'user_settings';

  // Point values
  static const int pointsPomodoro = 50;
  static const int pointsTaskComplete = 20;
  static const int pointsZato = 30;
  static const int pointsSphere = 25;
  static const int pointsStreak = 10;

  Future<UserStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_statsKey);
    if (saved == null) {
      return UserStats(
        achievements: Achievement.allAchievements
            .map((a) => a.copyWith())
            .toList(),
      );
    }
    try {
      final map = jsonDecode(saved);
      return UserStats(
        totalPoints: map['totalPoints'] ?? 0,
        level: map['level'] ?? 1,
        pomodoroSessions: map['pomodoroSessions'] ?? 0,
        tasksCompleted: map['tasksCompleted'] ?? 0,
        zatoTransformations: map['zatoTransformations'] ?? 0,
        controlSpheres: map['controlSpheres'] ?? 0,
        currentStreak: map['currentStreak'] ?? 0,
        longestStreak: map['longestStreak'] ?? 0,
        lastActiveDate: map['lastActiveDate'] != null
            ? DateTime.parse(map['lastActiveDate'])
            : null,
        achievements: _parseAchievements(map['achievements']),
        weeklyPomodoro: Map<String, int>.from(map['weeklyPomodoro'] ?? {}),
        dailyPoints: Map<String, int>.from(map['dailyPoints'] ?? {}),
      );
    } catch (e) {
      return UserStats(
        achievements: Achievement.allAchievements
            .map((a) => a.copyWith())
            .toList(),
      );
    }
  }

  List<Achievement> _parseAchievements(List? data) {
    if (data == null)
      return Achievement.allAchievements.map((a) => a.copyWith()).toList();
    return data
        .map(
          (a) => Achievement(
            id: a['id'],
            title: a['title'],
            description: a['description'],
            icon: a['icon'],
            requiredValue: a['requiredValue'],
            type: AchievementType.values[a['type'] ?? 0],
            isUnlocked: a['isUnlocked'] ?? false,
            unlockedAt: a['unlockedAt'] != null
                ? DateTime.parse(a['unlockedAt'])
                : null,
          ),
        )
        .toList();
  }

  Future<void> saveStats(UserStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'totalPoints': stats.totalPoints,
      'level': stats.level,
      'pomodoroSessions': stats.pomodoroSessions,
      'tasksCompleted': stats.tasksCompleted,
      'zatoTransformations': stats.zatoTransformations,
      'controlSpheres': stats.controlSpheres,
      'currentStreak': stats.currentStreak,
      'longestStreak': stats.longestStreak,
      'lastActiveDate': stats.lastActiveDate?.toIso8601String(),
      'achievements': stats.achievements
          .map(
            (a) => {
              'id': a.id,
              'title': a.title,
              'description': a.description,
              'icon': a.icon,
              'requiredValue': a.requiredValue,
              'type': a.type.index,
              'isUnlocked': a.isUnlocked,
              'unlockedAt': a.unlockedAt?.toIso8601String(),
            },
          )
          .toList(),
      'weeklyPomodoro': stats.weeklyPomodoro,
      'dailyPoints': stats.dailyPoints,
    };
    await prefs.setString(_statsKey, jsonEncode(map));
  }

  Future<UserStats> addPomodoro(int minutes) async {
    final stats = await getStats();
    final today = _dateKey();
    final dayOfWeek = DateTime.now().weekday.toString();

    final newWeeklyPomodoro = Map<String, int>.from(stats.weeklyPomodoro);
    newWeeklyPomodoro[dayOfWeek] =
        (newWeeklyPomodoro[dayOfWeek] ?? 0) + minutes;

    final newDailyPoints = Map<String, int>.from(stats.dailyPoints);
    newDailyPoints[today] = (newDailyPoints[today] ?? 0) + pointsPomodoro;

    final newStats = stats.copyWith(
      totalPoints: stats.totalPoints + pointsPomodoro,
      level: UserStats.calculateLevel(stats.totalPoints + pointsPomodoro),
      pomodoroSessions: stats.pomodoroSessions + 1,
      weeklyPomodoro: newWeeklyPomodoro,
      dailyPoints: newDailyPoints,
    );

    final updatedStats = await _checkAchievements(newStats);
    await saveStats(updatedStats);
    return updatedStats;
  }

  Future<UserStats> completeTask() async {
    final stats = await getStats();
    final today = _dateKey();

    final newDailyPoints = Map<String, int>.from(stats.dailyPoints);
    newDailyPoints[today] = (newDailyPoints[today] ?? 0) + pointsTaskComplete;

    final newStats = stats.copyWith(
      totalPoints: stats.totalPoints + pointsTaskComplete,
      level: UserStats.calculateLevel(stats.totalPoints + pointsTaskComplete),
      tasksCompleted: stats.tasksCompleted + 1,
      dailyPoints: newDailyPoints,
    );

    final updatedStats = await _checkAchievements(newStats);
    await saveStats(updatedStats);
    return updatedStats;
  }

  Future<UserStats> addZato() async {
    final stats = await getStats();
    final today = _dateKey();

    final newDailyPoints = Map<String, int>.from(stats.dailyPoints);
    newDailyPoints[today] = (newDailyPoints[today] ?? 0) + pointsZato;

    final newStats = stats.copyWith(
      totalPoints: stats.totalPoints + pointsZato,
      level: UserStats.calculateLevel(stats.totalPoints + pointsZato),
      zatoTransformations: stats.zatoTransformations + 1,
      dailyPoints: newDailyPoints,
    );

    final updatedStats = await _checkAchievements(newStats);
    await saveStats(updatedStats);
    return updatedStats;
  }

  Future<UserStats> addZatoStar() async {
    return addZato();
  }

  Future<UserStats> addControlSphere() async {
    final stats = await getStats();
    final today = _dateKey();

    final newDailyPoints = Map<String, int>.from(stats.dailyPoints);
    newDailyPoints[today] = (newDailyPoints[today] ?? 0) + pointsSphere;

    final newStats = stats.copyWith(
      totalPoints: stats.totalPoints + pointsSphere,
      level: UserStats.calculateLevel(stats.totalPoints + pointsSphere),
      controlSpheres: stats.controlSpheres + 1,
      dailyPoints: newDailyPoints,
    );

    final updatedStats = await _checkAchievements(newStats);
    await saveStats(updatedStats);
    return updatedStats;
  }

  Future<UserStats> updateStreak() async {
    final stats = await getStats();
    final today = DateTime.now();
    final lastActive = stats.lastActiveDate;

    int newStreak = stats.currentStreak;
    int newLongest = stats.longestStreak;

    if (lastActive == null) {
      newStreak = 1;
    } else {
      final diff = today.difference(lastActive).inDays;
      if (diff == 0) {
        // Same day, no change
      } else if (diff == 1) {
        // Yesterday, increment streak
        newStreak = stats.currentStreak + 1;
        final todayKey = _dateKey();
        final newDailyPoints = Map<String, int>.from(stats.dailyPoints);
        newDailyPoints[todayKey] =
            (newDailyPoints[todayKey] ?? 0) + pointsStreak;

        final newStats = stats.copyWith(
          currentStreak: newStreak,
          longestStreak: newStreak > newLongest ? newStreak : newLongest,
          lastActiveDate: today,
          dailyPoints: newDailyPoints,
          totalPoints: stats.totalPoints + pointsStreak,
        );
        await saveStats(newStats);
        return _checkAchievements(newStats);
      } else {
        // Streak broken
        newStreak = 1;
      }
    }

    final todayKey = _dateKey();
    final newDailyPoints = Map<String, int>.from(stats.dailyPoints);
    newDailyPoints[todayKey] = (newDailyPoints[todayKey] ?? 0) + pointsStreak;

    final newStats = stats.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > newLongest ? newStreak : newLongest,
      lastActiveDate: today,
      dailyPoints: newDailyPoints,
      totalPoints: stats.totalPoints + pointsStreak,
    );

    await saveStats(newStats);
    return _checkAchievements(newStats);
  }

  Future<UserStats> _checkAchievements(UserStats stats) async {
    final achievements = List<Achievement>.from(stats.achievements);
    bool changed = false;

    for (int i = 0; i < achievements.length; i++) {
      if (achievements[i].isUnlocked) continue;

      bool shouldUnlock = false;
      switch (achievements[i].type) {
        case AchievementType.pomodoro:
          shouldUnlock =
              stats.pomodoroSessions >= achievements[i].requiredValue;
          break;
        case AchievementType.zato:
          shouldUnlock =
              stats.zatoTransformations >= achievements[i].requiredValue;
          break;
        case AchievementType.zatoStar:
          final starredZatos = stats.achievements
              .where((a) => a.type == AchievementType.zatoStar && a.isUnlocked)
              .length;
          shouldUnlock = starredZatos >= achievements[i].requiredValue;
          break;
        case AchievementType.sphere:
          shouldUnlock = stats.controlSpheres >= achievements[i].requiredValue;
          break;
        case AchievementType.streak:
          shouldUnlock =
              stats.currentStreak >= achievements[i].requiredValue ||
              stats.longestStreak >= achievements[i].requiredValue;
          break;
        case AchievementType.task:
          shouldUnlock = stats.tasksCompleted >= achievements[i].requiredValue;
          break;
        case AchievementType.level:
          shouldUnlock = stats.level >= achievements[i].requiredValue;
          break;
      }

      if (shouldUnlock) {
        achievements[i] = achievements[i].copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        changed = true;
      }
    }

    if (changed) {
      return stats.copyWith(achievements: achievements);
    }
    return stats;
  }

  String _dateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<Map<String, dynamic>> getWeeklyStats() async {
    final stats = await getStats();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    Map<String, int> weekData = {};
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final key = day.weekday.toString();
      weekData[day.weekday.toString()] = stats.weeklyPomodoro[key] ?? 0;
    }

    return weekData;
  }
}

class UserSettings {
  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final bool darkMode;
  final bool notificationsEnabled;
  final int reminderHour;
  final int reminderMinute;

  UserSettings({
    this.pomodoroMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  UserSettings copyWith({
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    bool? darkMode,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return UserSettings(
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  Map<String, dynamic> toMap() => {
    'pomodoroMinutes': pomodoroMinutes,
    'shortBreakMinutes': shortBreakMinutes,
    'longBreakMinutes': longBreakMinutes,
    'darkMode': darkMode,
    'notificationsEnabled': notificationsEnabled,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
  };

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      pomodoroMinutes: map['pomodoroMinutes'] ?? 25,
      shortBreakMinutes: map['shortBreakMinutes'] ?? 5,
      longBreakMinutes: map['longBreakMinutes'] ?? 15,
      darkMode: map['darkMode'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      reminderHour: map['reminderHour'] ?? 9,
      reminderMinute: map['reminderMinute'] ?? 0,
    );
  }
}

class SettingsService {
  static const String _key = 'user_settings';

  Future<UserSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) return UserSettings();
    try {
      return UserSettings.fromMap(jsonDecode(saved));
    } catch (e) {
      return UserSettings();
    }
  }

  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toMap()));
  }
}
