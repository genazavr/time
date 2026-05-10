import 'package:uuid/uuid.dart';

class UserStats {
  final int totalPoints;
  final int level;
  final int pomodoroSessions;
  final int tasksCompleted;
  final int zatoTransformations;
  final int controlSpheres;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final List<Achievement> achievements;
  final Map<String, int> weeklyPomodoro; // day -> minutes
  final Map<String, int> dailyPoints; // date -> points

  UserStats({
    this.totalPoints = 0,
    this.level = 1,
    this.pomodoroSessions = 0,
    this.tasksCompleted = 0,
    this.zatoTransformations = 0,
    this.controlSpheres = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.achievements = const [],
    this.weeklyPomodoro = const {},
    this.dailyPoints = const {},
  });

  int get pointsToNextLevel => level * 1000 - (totalPoints % (level * 1000));
  double get levelProgress => (totalPoints % (level * 1000)) / (level * 1000);

  static int calculateLevel(int points) {
    if (points < 1000) return 1;
    if (points < 3000) return 2;
    if (points < 6000) return 3;
    if (points < 10000) return 4;
    if (points < 15000) return 5;
    return 6 + ((points - 15000) ~/ 10000);
  }

  static String getLevelTitle(int level) {
    switch (level) {
      case 1:
        return 'Новичок';
      case 2:
        return 'Ученик';
      case 3:
        return 'Практик';
      case 4:
        return 'Мастер';
      case 5:
        return 'Эксперт';
      case 6:
        return 'Гуру';
      default:
        return 'Легенда';
    }
  }

  UserStats copyWith({
    int? totalPoints,
    int? level,
    int? pomodoroSessions,
    int? tasksCompleted,
    int? zatoTransformations,
    int? controlSpheres,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    List<Achievement>? achievements,
    Map<String, int>? weeklyPomodoro,
    Map<String, int>? dailyPoints,
  }) {
    return UserStats(
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      pomodoroSessions: pomodoroSessions ?? this.pomodoroSessions,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      zatoTransformations: zatoTransformations ?? this.zatoTransformations,
      controlSpheres: controlSpheres ?? this.controlSpheres,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      achievements: achievements ?? this.achievements,
      weeklyPomodoro: weeklyPomodoro ?? this.weeklyPomodoro,
      dailyPoints: dailyPoints ?? this.dailyPoints,
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredValue;
  final AchievementType type;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
    required this.type,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      requiredValue: requiredValue,
      type: type,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  static List<Achievement> get allAchievements => [
    Achievement(
      id: 'pomo_1',
      title: 'Первый сеанс',
      description: 'Заверши 1 Помодоро',
      icon: '🍅',
      requiredValue: 1,
      type: AchievementType.pomodoro,
    ),
    Achievement(
      id: 'pomo_10',
      title: 'Набираем темп',
      description: 'Заверши 10 Помодоро',
      icon: '🔥',
      requiredValue: 10,
      type: AchievementType.pomodoro,
    ),
    Achievement(
      id: 'pomo_50',
      title: 'Мастер фокуса',
      description: 'Заверши 50 Помодоро',
      icon: '⚡',
      requiredValue: 50,
      type: AchievementType.pomodoro,
    ),
    Achievement(
      id: 'pomo_100',
      title: 'Легенда продуктивности',
      description: 'Заверши 100 Помодоро',
      icon: '👑',
      requiredValue: 100,
      type: AchievementType.pomodoro,
    ),
    Achievement(
      id: 'zato_1',
      title: 'Первая трансформация',
      description: 'Используй технику ЗАТО 1 раз',
      icon: '💡',
      requiredValue: 1,
      type: AchievementType.zato,
    ),
    Achievement(
      id: 'zato_10',
      title: 'Мыслитель',
      description: 'Трансформируй 10 негативных мыслей',
      icon: '🧠',
      requiredValue: 10,
      type: AchievementType.zato,
    ),
    Achievement(
      id: 'zato_30',
      title: '30 дней ЗАТО',
      description: 'Трансформируй 30 мыслей',
      icon: '🌟',
      requiredValue: 30,
      type: AchievementType.zato,
    ),
    Achievement(
      id: 'zato_star',
      title: 'Эксперт',
      description: 'Отметь 10 техник как сработавшие',
      icon: '⭐',
      requiredValue: 10,
      type: AchievementType.zatoStar,
    ),
    Achievement(
      id: 'sphere_1',
      title: 'Аналитик',
      description: 'Добавь 1 сферу контроля',
      icon: '🎯',
      requiredValue: 1,
      type: AchievementType.sphere,
    ),
    Achievement(
      id: 'sphere_10',
      title: 'Мастер осознанности',
      description: 'Проанализируй 10 ситуаций',
      icon: '🧘',
      requiredValue: 10,
      type: AchievementType.sphere,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Тройка',
      description: '3 дня подряд',
      icon: '🔥',
      requiredValue: 3,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Неделя силы',
      description: '7 дней подряд',
      icon: '💪',
      requiredValue: 7,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Месяц мастера',
      description: '30 дней подряд',
      icon: '🏆',
      requiredValue: 30,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'task_10',
      title: 'Начинающий',
      description: 'Выполни 10 задач',
      icon: '✅',
      requiredValue: 10,
      type: AchievementType.task,
    ),
    Achievement(
      id: 'task_50',
      title: 'Профессионал',
      description: 'Выполни 50 задач',
      icon: '🎖️',
      requiredValue: 50,
      type: AchievementType.task,
    ),
    Achievement(
      id: 'level_5',
      title: 'Пятый уровень',
      description: 'Достигни 5 уровня',
      icon: '🎯',
      requiredValue: 5,
      type: AchievementType.level,
    ),
  ];
}

enum AchievementType { pomodoro, zato, zatoStar, sphere, streak, task, level }
