import 'package:firebase_database/firebase_database.dart';
import '../models/task_model.dart';
import 'firebase_service.dart';

class TaskService {
  static final TaskService _instance = TaskService._internal();
  final _firebaseService = FirebaseService();

  factory TaskService() {
    return _instance;
  }

  TaskService._internal();

  Future<void> addTask(String userId, TaskModel task) async {
    final ref = _firebaseService.database.ref('users/$userId/tasks').push();
    await ref.set(task.toMap());
  }

  Future<List<TaskModel>> getTasks(String userId) async {
    final snapshot = await _firebaseService.database.ref('users/$userId/tasks').get();
    if (snapshot.exists) {
      final tasks = <TaskModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        tasks.add(TaskModel.fromMap(value, key, userId));
      });
      return tasks;
    }
    return [];
  }

  Future<void> updateTask(String userId, String taskId, TaskModel task) async {
    await _firebaseService.database
        .ref('users/$userId/tasks/$taskId')
        .update(task.toMap());
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _firebaseService.database.ref('users/$userId/tasks/$taskId').remove();
  }

  Stream<List<TaskModel>> watchTasks(String userId) {
    return _firebaseService.database
        .ref('users/$userId/tasks')
        .onValue
        .map((event) {
          if (event.snapshot.exists) {
            final tasks = <TaskModel>[];
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              tasks.add(TaskModel.fromMap(value, key, userId));
            });
            return tasks;
          }
          return [];
        });
  }
}
