import 'package:flutter/material.dart';

import '../models/user_metrics.dart';
import '../theme/app_theme.dart';

class UserAchievement {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const UserAchievement({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

List<UserAchievement> buildUserAchievements(UserMetrics metrics) {
  final achievements = <UserAchievement>[];
  final added = <String>{};

  void add(String key, UserAchievement achievement) {
    if (added.add(key)) {
      achievements.add(achievement);
    }
  }

  if (metrics.completedTasks > 0) {
    add(
      'first_task',
      UserAchievement(
        icon: Icons.playlist_add_check_outlined,
        color: AppTheme.accentColor,
        title: 'Первый шаг сделан',
        subtitle: 'Вы завершили ${metrics.completedTasks} задач',
      ),
    );
  }

  if (metrics.completedTasks >= 10) {
    add(
      'task_master',
      UserAchievement(
        icon: Icons.task_alt,
        color: AppTheme.primaryColor,
        title: 'Мастер продуктивности',
        subtitle: '10 и более задач закрыты',
      ),
    );
  }

  if (metrics.focusMinutesWeek >= 150) {
    add(
      'focus_week',
      UserAchievement(
        icon: Icons.timer_outlined,
        color: AppTheme.secondaryColor,
        title: 'Фокус недели',
        subtitle: '${metrics.focusMinutesWeek} минут концентрации',
      ),
    );
  }

  if (metrics.completedHomework > 0 && metrics.overdueHomework == 0) {
    add(
      'homework_zero',
      UserAchievement(
        icon: Icons.school_outlined,
        color: AppTheme.warningColor,
        title: 'Чистый дневник',
        subtitle: 'Все домашние задания под контролем',
      ),
    );
  }

  if (metrics.eventsToday > 0) {
    add(
      'planner',
      UserAchievement(
        icon: Icons.calendar_today_outlined,
        color: AppTheme.accentColor,
        title: 'Организованный день',
        subtitle: 'Событий сегодня: ${metrics.eventsToday}',
      ),
    );
  }

  if (metrics.notesCount >= 5) {
    add(
      'note_keeper',
      UserAchievement(
        icon: Icons.note_alt_outlined,
        color: AppTheme.secondaryColor,
        title: 'Хранитель идей',
        subtitle: 'Создано ${metrics.notesCount} заметок',
      ),
    );
  }

  if (metrics.completedPomodoroSessions >= 4) {
    add(
      'pomodoro_runner',
      UserAchievement(
        icon: Icons.local_fire_department_outlined,
        color: AppTheme.primaryColor,
        title: 'Сила фокуса',
        subtitle: '${metrics.completedPomodoroSessions} помодоро завершено',
      ),
    );
  }

  return achievements;
}
