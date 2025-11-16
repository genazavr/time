class EisenhowerTask {
  final String id;
  final String title;
  final String? description;
  final int quadrant; // 1-4 (Срочно/Важно, Не срочно/Важно, Срочно/Не важно, Не срочно/Не важно)
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final int estimatedMinutes; // Оценка времени в минутах

  EisenhowerTask({
    required this.id,
    required this.title,
    this.description,
    required this.quadrant,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.tags = const [],
    this.estimatedMinutes = 30,
  });

  factory EisenhowerTask.fromMap(Map<String, dynamic> map, String id) {
    return EisenhowerTask(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      quadrant: map['quadrant'] ?? 1,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      tags: List<String>.from(map['tags'] ?? []),
      estimatedMinutes: map['estimatedMinutes'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'quadrant': quadrant,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tags': tags,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  EisenhowerTask copyWith({
    String? id,
    String? title,
    String? description,
    int? quadrant,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? estimatedMinutes,
  }) {
    return EisenhowerTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      quadrant: quadrant ?? this.quadrant,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  String get quadrantName {
    switch (quadrant) {
      case 1:
        return 'Срочно и важно';
      case 2:
        return 'Не срочно, но важно';
      case 3:
        return 'Срочно, но не важно';
      case 4:
        return 'Не срочно и не важно';
      default:
        return 'Без категории';
    }
  }

  String get quadrantDescription {
    switch (quadrant) {
      case 1:
        return 'Кризисные задачи, дедлайны';
      case 2:
        return 'Планирование, развитие';
      case 3:
        return 'Помощь другим, некоторые письма';
      case 4:
        return 'Отдых, рутинные дела';
      default:
        return '';
    }
  }

  String get quadrantColor {
    switch (quadrant) {
      case 1:
        return '#EF4444'; // Красный
      case 2:
        return '#10B981'; // Зеленый
      case 3:
        return '#F59E0B'; // Оранжевый
      case 4:
        return '#6B7280'; // Серый
      default:
        return '#3B82F6'; // Синий
    }
  }
}