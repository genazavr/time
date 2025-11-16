class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String color;
  final bool isAllDay;
  final String? location;
  final List<String> attendees;
  final String type; // 'lesson', 'homework', 'exam', 'personal', 'reminder'
  final int priority; // 0-3 (низкий, средний, высокий, критический)
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.color = '#3B82F6',
    this.isAllDay = false,
    this.location,
    this.attendees = const [],
    this.type = 'personal',
    this.priority = 1,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map, String id) {
    return CalendarEvent(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      color: map['color'] ?? '#3B82F6',
      isAllDay: map['isAllDay'] ?? false,
      location: map['location'],
      attendees: List<String>.from(map['attendees'] ?? []),
      type: map['type'] ?? 'personal',
      priority: map['priority'] ?? 1,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'color': color,
      'isAllDay': isAllDay,
      'location': location,
      'attendees': attendees,
      'type': type,
      'priority': priority,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? color,
    bool? isAllDay,
    String? location,
    List<String>? attendees,
    String? type,
    int? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      attendees: attendees ?? this.attendees,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}