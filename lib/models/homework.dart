class Homework {
  final String id;
  final String title;
  final String? description;
  final String subject;
  final DateTime dueDate;
  final DateTime? assignedDate;
  final bool isCompleted;
  final DateTime completedAt;
  final int priority; // 0-3 (низкий, средний, высокий, критический)
  final List<String> attachments;
  final List<String> tags;
  final int estimatedMinutes;
  final String? teacherName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Homework({
    required this.id,
    required this.title,
    this.description,
    required this.subject,
    required this.dueDate,
    this.assignedDate,
    this.isCompleted = false,
    this.completedAt = DateTime.now(),
    this.priority = 1,
    this.attachments = const [],
    this.tags = const [],
    this.estimatedMinutes = 30,
    this.teacherName,
    required this.createdAt,
    this.updatedAt,
  });

  factory Homework.fromMap(Map<String, dynamic> map, String id) {
    return Homework(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      subject: map['subject'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      assignedDate: map['assignedDate'] != null ? DateTime.parse(map['assignedDate']) : null,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: DateTime.parse(map['completedAt'] ?? DateTime.now().toIso8601String()),
      priority: map['priority'] ?? 1,
      attachments: List<String>.from(map['attachments'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      estimatedMinutes: map['estimatedMinutes'] ?? 30,
      teacherName: map['teacherName'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'assignedDate': assignedDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt.toIso8601String(),
      'priority': priority,
      'attachments': attachments,
      'tags': tags,
      'estimatedMinutes': estimatedMinutes,
      'teacherName': teacherName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Homework copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    DateTime? dueDate,
    DateTime? assignedDate,
    bool? isCompleted,
    DateTime? completedAt,
    int? priority,
    List<String>? attachments,
    List<String>? tags,
    int? estimatedMinutes,
    String? teacherName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Homework(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      assignedDate: assignedDate ?? this.assignedDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      tags: tags ?? this.tags,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get priorityName {
    switch (priority) {
      case 0:
        return 'Низкий';
      case 1:
        return 'Средний';
      case 2:
        return 'Высокий';
      case 3:
        return 'Критический';
      default:
        return 'Средний';
    }
  }

  String get priorityColor {
    switch (priority) {
      case 0:
        return '#10B981'; // Зеленый
      case 1:
        return '#3B82F6'; // Синий
      case 2:
        return '#F59E0B'; // Оранжевый
      case 3:
        return '#EF4444'; // Красный
      default:
        return '#3B82F6'; // Синий
    }
  }

  bool get isOverdue {
    return !isCompleted && DateTime.now().isAfter(dueDate);
  }

  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDay.isAtSameMomentAs(today);
  }

  bool get isDueSoon {
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    return daysUntilDue <= 3 && daysUntilDue >= 0;
  }
}