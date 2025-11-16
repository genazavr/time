class PomodoroSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // в минутах
  final String type; // 'work', 'short_break', 'long_break'
  final String? taskTitle;
  final bool isCompleted;
  final int interruptions;
  final DateTime createdAt;

  PomodoroSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.type,
    this.taskTitle,
    this.isCompleted = false,
    this.interruptions = 0,
    required this.createdAt,
  });

  factory PomodoroSession.fromMap(Map<String, dynamic> map, String id) {
    return PomodoroSession(
      id: id,
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      duration: map['duration'] ?? 25,
      type: map['type'] ?? 'work',
      taskTitle: map['taskTitle'],
      isCompleted: map['isCompleted'] ?? false,
      interruptions: map['interruptions'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'type': type,
      'taskTitle': taskTitle,
      'isCompleted': isCompleted,
      'interruptions': interruptions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PomodoroSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    String? type,
    String? taskTitle,
    bool? isCompleted,
    int? interruptions,
    DateTime? createdAt,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      taskTitle: taskTitle ?? this.taskTitle,
      isCompleted: isCompleted ?? this.isCompleted,
      interruptions: interruptions ?? this.interruptions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PomodoroSettings {
  final int workDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final int longBreakInterval;
  final bool autoStartBreaks;
  final bool autoStartWork;
  final bool soundEnabled;
  final String soundType;

  PomodoroSettings({
    this.workDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.longBreakInterval = 4,
    this.autoStartBreaks = false,
    this.autoStartWork = false,
    this.soundEnabled = true,
    this.soundType = 'bell',
  });

  PomodoroSettings copyWith({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? longBreakInterval,
    bool? autoStartBreaks,
    bool? autoStartWork,
    bool? soundEnabled,
    String? soundType,
  }) {
    return PomodoroSettings(
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartWork: autoStartWork ?? this.autoStartWork,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundType: soundType ?? this.soundType,
    );
  }

  factory PomodoroSettings.fromMap(Map<String, dynamic> map) {
    return PomodoroSettings(
      workDuration: map['workDuration'] ?? 25,
      shortBreakDuration: map['shortBreakDuration'] ?? 5,
      longBreakDuration: map['longBreakDuration'] ?? 15,
      longBreakInterval: map['longBreakInterval'] ?? 4,
      autoStartBreaks: map['autoStartBreaks'] ?? false,
      autoStartWork: map['autoStartWork'] ?? false,
      soundEnabled: map['soundEnabled'] ?? true,
      soundType: map['soundType'] ?? 'bell',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workDuration': workDuration,
      'shortBreakDuration': shortBreakDuration,
      'longBreakDuration': longBreakDuration,
      'longBreakInterval': longBreakInterval,
      'autoStartBreaks': autoStartBreaks,
      'autoStartWork': autoStartWork,
      'soundEnabled': soundEnabled,
      'soundType': soundType,
    };
  }
}