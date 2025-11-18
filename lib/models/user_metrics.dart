import 'dart:math';

class UserMetrics {
  final int totalTasks;
  final int completedTasks;
  final int tasksDueToday;
  final int activeTasks;
  final int totalHomework;
  final int completedHomework;
  final int overdueHomework;
  final int notesCount;
  final int eventsToday;
  final int pomodoroSessionsToday;
  final int completedPomodoroSessions;
  final int focusMinutesToday;
  final int focusMinutesWeek;

  const UserMetrics({
    required this.totalTasks,
    required this.completedTasks,
    required this.tasksDueToday,
    required this.activeTasks,
    required this.totalHomework,
    required this.completedHomework,
    required this.overdueHomework,
    required this.notesCount,
    required this.eventsToday,
    required this.pomodoroSessionsToday,
    required this.completedPomodoroSessions,
    required this.focusMinutesToday,
    required this.focusMinutesWeek,
  });

  double get tasksCompletionRatio =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  double get homeworkCompletionRatio =>
      totalHomework == 0 ? 0 : completedHomework / totalHomework;

  double get focusDayProgress =>
      _clampProgress(focusMinutesToday, 150);

  double get focusWeekProgress =>
      _clampProgress(focusMinutesWeek, 150 * 5);

  static const empty = UserMetrics(
    totalTasks: 0,
    completedTasks: 0,
    tasksDueToday: 0,
    activeTasks: 0,
    totalHomework: 0,
    completedHomework: 0,
    overdueHomework: 0,
    notesCount: 0,
    eventsToday: 0,
    pomodoroSessionsToday: 0,
    completedPomodoroSessions: 0,
    focusMinutesToday: 0,
    focusMinutesWeek: 0,
  );

  double _clampProgress(int value, int goal) {
    if (goal <= 0) return 0;
    if (value <= 0) return 0;
    return min(1, value / goal);
  }
}
