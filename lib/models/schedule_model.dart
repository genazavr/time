enum DayOfWeek { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class ScheduleModel {
  final String id;
  final String userId;
  final String lessonName;
  final DayOfWeek dayOfWeek;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String instructor;

  ScheduleModel({
    required this.id,
    required this.userId,
    required this.lessonName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.instructor,
  });

  factory ScheduleModel.fromMap(Map<dynamic, dynamic> map, String id, String userId) {
    return ScheduleModel(
      id: id,
      userId: userId,
      lessonName: map['lessonName'] ?? '',
      dayOfWeek: DayOfWeek.values[map['dayOfWeek'] ?? 0],
      startTime: DateTime.parse(map['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(map['endTime'] ?? DateTime.now().toIso8601String()),
      location: map['location'] ?? '',
      instructor: map['instructor'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonName': lessonName,
      'dayOfWeek': dayOfWeek.index,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'instructor': instructor,
    };
  }
}
