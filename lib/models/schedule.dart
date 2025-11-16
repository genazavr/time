class Schedule {
  final String id;
  final String subject;
  final String? lessonTitle;
  final String? teacherName;
  final String? classroom;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Schedule({
    required this.id,
    required this.subject,
    this.lessonTitle,
    this.teacherName,
    this.classroom,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.updatedAt,
  });

  factory Schedule.fromMap(Map<String, dynamic> map, String id) {
    return Schedule(
      id: id,
      subject: map['subject'] ?? '',
      lessonTitle: map['lessonTitle'],
      teacherName: map['teacherName'],
      classroom: map['classroom'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'lessonTitle': lessonTitle,
      'teacherName': teacherName,
      'classroom': classroom,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Schedule copyWith({
    String? id,
    String? subject,
    String? lessonTitle,
    String? teacherName,
    String? classroom,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      teacherName: teacherName ?? this.teacherName,
      classroom: classroom ?? this.classroom,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get timeRange {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - '
           '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  Duration get duration {
    return endTime.difference(startTime);
  }
}