import '../models/schedule_model.dart';
import 'firebase_service.dart';

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  final _firebaseService = FirebaseService();

  factory ScheduleService() {
    return _instance;
  }

  ScheduleService._internal();

  Future<void> addSchedule(String userId, ScheduleModel schedule) async {
    final ref = _firebaseService.database.ref('users/$userId/schedules').push();
    await ref.set(schedule.toMap());
  }

  Future<List<ScheduleModel>> getSchedules(String userId) async {
    final snapshot = await _firebaseService.database.ref('users/$userId/schedules').get();
    if (snapshot.exists) {
      final schedules = <ScheduleModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        schedules.add(ScheduleModel.fromMap(value, key, userId));
      });
      return schedules;
    }
    return [];
  }

  Future<void> updateSchedule(String userId, String scheduleId, ScheduleModel schedule) async {
    await _firebaseService.database
        .ref('users/$userId/schedules/$scheduleId')
        .update(schedule.toMap());
  }

  Future<void> deleteSchedule(String userId, String scheduleId) async {
    await _firebaseService.database.ref('users/$userId/schedules/$scheduleId').remove();
  }

  Stream<List<ScheduleModel>> watchSchedules(String userId) {
    return _firebaseService.database
        .ref('users/$userId/schedules')
        .onValue
        .map((event) {
          if (event.snapshot.exists) {
            final schedules = <ScheduleModel>[];
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              schedules.add(ScheduleModel.fromMap(value, key, userId));
            });
            return schedules;
          }
          return [];
        });
  }
}
