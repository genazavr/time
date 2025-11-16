import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/eisenhower_task.dart';
import '../services/firebase_service.dart';

class EisenhowerService {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<List<EisenhowerTask>> getTasks() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/eisenhower').onValue.map((event) {
      final Map<dynamic, dynamic>? tasksMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (tasksMap == null) return [];

      return tasksMap.entries.map((entry) {
        return EisenhowerTask.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      }).toList();
    });
  }

  Stream<List<EisenhowerTask>> getTasksByQuadrant(int quadrant) {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);

    return _database.child('users/$userId/eisenhower').onValue.map((event) {
      final Map<dynamic, dynamic>? tasksMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (tasksMap == null) return [];

      return tasksMap.entries.map((entry) {
        final task = EisenhowerTask.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        return task.quadrant == quadrant ? task : null;
      }).where((task) => task != null).cast<EisenhowerTask>().toList();
    });
  }

  Future<String> addTask(EisenhowerTask task) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final taskRef = _database.child('users/$userId/eisenhower').push();
    await taskRef.set(task.toMap());
    return taskRef.key!;
  }

  Future<void> updateTask(EisenhowerTask task) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/eisenhower/${task.id}').update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/eisenhower/$taskId').remove();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/eisenhower/$taskId/isCompleted').get();
    final currentStatus = snapshot.value as bool? ?? false;
    
    await _database.child('users/$userId/eisenhower/$taskId').update({
      'isCompleted': !currentStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> moveTaskToQuadrant(String taskId, int newQuadrant) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _database.child('users/$userId/eisenhower/$taskId').update({
      'quadrant': newQuadrant,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<EisenhowerTask?> getTask(String taskId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _database.child('users/$userId/eisenhower/$taskId').get();
    if (!snapshot.exists) return null;

    return EisenhowerTask.fromMap(Map<String, dynamic>.from(snapshot.value as Map), taskId);
  }

  Future<List<EisenhowerTask>> getOverdueTasks() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final now = DateTime.now();

    final snapshot = await _database.child('users/$userId/eisenhower').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? tasksMap = snapshot.value as Map<dynamic, dynamic>?;
    if (tasksMap == null) return [];

    return tasksMap.entries.map((entry) {
      final task = EisenhowerTask.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      final isOverdue = task.dueDate != null && 
                       task.dueDate!.isBefore(now) && 
                       !task.isCompleted;
      return isOverdue ? task : null;
    }).where((task) => task != null).cast<EisenhowerTask>().toList();
  }

  Future<List<EisenhowerTask>> getTasksForToday() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final snapshot = await _database.child('users/$userId/eisenhower').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic>? tasksMap = snapshot.value as Map<dynamic, dynamic>?;
    if (tasksMap == null) return [];

    return tasksMap.entries.map((entry) {
      final task = EisenhowerTask.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      if (task.dueDate == null) return null;
      final dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final isToday = dueDate.isAtSameMomentAs(today) || 
                    (task.dueDate!.isBefore(tomorrow) && !task.isCompleted);
      return isToday ? task : null;
    }).where((task) => task != null).cast<EisenhowerTask>().toList();
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return {};

    final snapshot = await _database.child('users/$userId/eisenhower').get();
    if (!snapshot.exists) return {};

    final Map<dynamic, dynamic>? tasksMap = snapshot.value as Map<dynamic, dynamic>?;
    if (tasksMap == null) return {};

    final tasks = tasksMap.entries.map((entry) {
      return EisenhowerTask.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
    }).toList();

    final quadrantCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0};
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final overdueTasks = tasks.where((t) => 
        t.dueDate != null && 
        t.dueDate!.isBefore(DateTime.now()) && 
        !t.isCompleted).length;

    for (final task in tasks) {
      if (!task.isCompleted) {
        quadrantCounts[task.quadrant] = (quadrantCounts[task.quadrant] ?? 0) + 1;
      }
    }

    return {
      'totalTasks': tasks.length,
      'completedTasks': completedTasks,
      'pendingTasks': tasks.length - completedTasks,
      'overdueTasks': overdueTasks,
      'completionRate': tasks.isEmpty ? 0.0 : (completedTasks / tasks.length * 100).roundToDouble(),
      'quadrantDistribution': quadrantCounts,
      'totalEstimatedMinutes': tasks.fold<int>(0, (sum, task) => sum + task.estimatedMinutes),
    };
  }
}