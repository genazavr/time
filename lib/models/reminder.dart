class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime scheduledTime;
  final bool isRepeating;
  final String repeatPattern; // 'daily', 'weekly', 'monthly', 'none'
  final List<int> repeatDays; // Для еженедельных: 1-7 (Пн-Вс)
  final bool isActive;
  final String type; // 'break', 'deadline', 'custom'
  final int? minutesBefore; // Минут до события для напоминаний о дедлайнах
  final String? relatedEntityId; // ID связанной задачи/события
  final String? relatedEntityType; // Тип связанной сущности
  final DateTime createdAt;
  final DateTime? updatedAt;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledTime,
    this.isRepeating = false,
    this.repeatPattern = 'none',
    this.repeatDays = const [],
    this.isActive = true,
    this.type = 'custom',
    this.minutesBefore,
    this.relatedEntityId,
    this.relatedEntityType,
    required this.createdAt,
    this.updatedAt,
  });

  factory Reminder.fromMap(Map<String, dynamic> map, String id) {
    return Reminder(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      isRepeating: map['isRepeating'] ?? false,
      repeatPattern: map['repeatPattern'] ?? 'none',
      repeatDays: List<int>.from(map['repeatDays'] ?? []),
      isActive: map['isActive'] ?? true,
      type: map['type'] ?? 'custom',
      minutesBefore: map['minutesBefore'],
      relatedEntityId: map['relatedEntityId'],
      relatedEntityType: map['relatedEntityType'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isRepeating': isRepeating,
      'repeatPattern': repeatPattern,
      'repeatDays': repeatDays,
      'isActive': isActive,
      'type': type,
      'minutesBefore': minutesBefore,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledTime,
    bool? isRepeating,
    String? repeatPattern,
    List<int>? repeatDays,
    bool? isActive,
    String? type,
    int? minutesBefore,
    String? relatedEntityId,
    String? relatedEntityType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatPattern: repeatPattern ?? this.repeatPattern,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get repeatPatternText {
    switch (repeatPattern) {
      case 'daily':
        return 'Ежедневно';
      case 'weekly':
        return 'Еженедельно';
      case 'monthly':
        return 'Ежемесячно';
      default:
        return 'Без повтора';
    }
  }

  String get typeText {
    switch (type) {
      case 'break':
        return 'Перерыв';
      case 'deadline':
        return 'Дедлайн';
      default:
        return 'Напоминание';
    }
  }

  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
    return reminderDay.isAtSameMomentAs(today);
  }

  bool get isPast {
    return DateTime.now().isAfter(scheduledTime);
  }
}