# Примеры использования API BLISS

## Содержание
1. [Firebase Authentication](#firebase-authentication)
2. [Работа с задачами](#работа-с-задачами)
3. [Работа с заметками](#работа-с-заметками)
4. [Работа с расписанием](#работа-с-расписанием)
5. [Real-time синхронизация](#real-time-синхронизация)
6. [Обработка ошибок](#обработка-ошибок)

## Firebase Authentication

### Регистрация нового пользователя

```dart
import 'package:time/services/firebase_service.dart';
import 'package:time/models/user_model.dart';

Future<void> registerUser() async {
  final firebaseService = FirebaseService();
  
  try {
    // Регистрация в Firebase Auth
    final credential = await firebaseService.register(
      'john@example.com',
      'SecurePassword123',
    );
    
    // Сохранение данных пользователя в Realtime Database
    await firebaseService.saveUserData(
      credential.user!.uid,
      {
        'name': 'John Doe',
        'email': 'john@example.com',
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
    
    print('User registered successfully: ${credential.user!.uid}');
  } on FirebaseAuthException catch (e) {
    print('Registration error: ${e.message}');
  }
}
```

### Вход в систему

```dart
Future<void> loginUser() async {
  final firebaseService = FirebaseService();
  
  try {
    final credential = await firebaseService.login(
      'john@example.com',
      'SecurePassword123',
    );
    
    print('Logged in: ${credential.user!.email}');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      print('User not found');
    } else if (e.code == 'wrong-password') {
      print('Wrong password');
    } else {
      print('Login error: ${e.message}');
    }
  }
}
```

### Получение текущего пользователя

```dart
void getCurrentUserInfo() {
  final firebaseService = FirebaseService();
  
  final user = firebaseService.getCurrentUser();
  
  if (user != null) {
    print('User UID: ${user.uid}');
    print('User Email: ${user.email}');
    print('Email verified: ${user.emailVerified}');
  } else {
    print('No user logged in');
  }
}
```

### Получение данных пользователя из БД

```dart
Future<void> fetchUserData() async {
  final firebaseService = FirebaseService();
  
  final currentUser = firebaseService.getCurrentUser();
  if (currentUser == null) return;
  
  try {
    final userData = await firebaseService.getUserData(currentUser.uid);
    
    if (userData != null) {
      final user = UserModel.fromMap(userData, currentUser.uid);
      print('Name: ${user.name}');
      print('Email: ${user.email}');
      print('Created at: ${user.createdAt}');
    }
  } catch (e) {
    print('Error fetching user data: $e');
  }
}
```

### Выход из системы

```dart
Future<void> logoutUser() async {
  final firebaseService = FirebaseService();
  
  try {
    await firebaseService.logout();
    print('Logged out successfully');
  } catch (e) {
    print('Logout error: $e');
  }
}
```

## Работа с задачами

### Добавление задачи

```dart
import 'package:time/services/task_service.dart';
import 'package:time/models/task_model.dart';

Future<void> addNewTask(String userId) async {
  final taskService = TaskService();
  
  final task = TaskModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    userId: userId,
    title: 'Изучить Flutter',
    description: 'Пройти курс по Firebase интеграции',
    dueDate: DateTime.now().add(Duration(days: 5)),
    priority: TaskPriority.high,
    status: TaskStatus.pending,
    createdAt: DateTime.now(),
  );
  
  try {
    await taskService.addTask(userId, task);
    print('Task added successfully');
  } catch (e) {
    print('Error adding task: $e');
  }
}
```

### Получение всех задач

```dart
Future<void> fetchAllTasks(String userId) async {
  final taskService = TaskService();
  
  try {
    final tasks = await taskService.getTasks(userId);
    
    for (final task in tasks) {
      print('Task: ${task.title}');
      print('  - Status: ${task.status}');
      print('  - Priority: ${task.priority}');
      print('  - Due date: ${task.dueDate}');
    }
  } catch (e) {
    print('Error fetching tasks: $e');
  }
}
```

### Обновление статуса задачи

```dart
Future<void> completeTask(String userId, TaskModel task) async {
  final taskService = TaskService();
  
  final updatedTask = TaskModel(
    id: task.id,
    userId: task.userId,
    title: task.title,
    description: task.description,
    dueDate: task.dueDate,
    priority: task.priority,
    status: TaskStatus.completed,  // Изменили статус
    createdAt: task.createdAt,
  );
  
  try {
    await taskService.updateTask(userId, task.id, updatedTask);
    print('Task marked as completed');
  } catch (e) {
    print('Error updating task: $e');
  }
}
```

### Удаление задачи

```dart
Future<void> deleteTask(String userId, String taskId) async {
  final taskService = TaskService();
  
  try {
    await taskService.deleteTask(userId, taskId);
    print('Task deleted');
  } catch (e) {
    print('Error deleting task: $e');
  }
}
```

### Фильтрация задач по приоритету

```dart
Future<void> getHighPriorityTasks(String userId) async {
  final taskService = TaskService();
  
  try {
    final allTasks = await taskService.getTasks(userId);
    
    final highPriority = allTasks
        .where((task) => task.priority == TaskPriority.high)
        .toList();
    
    print('High priority tasks: ${highPriority.length}');
    for (final task in highPriority) {
      print('  - ${task.title}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

## Работа с заметками

### Добавление заметки

```dart
import 'package:time/services/note_service.dart';
import 'package:time/models/note_model.dart';

Future<void> addNote(String userId) async {
  final noteService = NoteService();
  
  final note = NoteModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    userId: userId,
    title: 'Идеи для проекта',
    content: '''
    1. Добавить оффлайн синхронизацию
    2. Реализовать Pomodoro таймер
    3. Добавить экспорт в PDF
    ''',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  try {
    await noteService.addNote(userId, note);
    print('Note added successfully');
  } catch (e) {
    print('Error adding note: $e');
  }
}
```

### Поиск по заметкам

```dart
Future<void> searchNotes(String userId, String query) async {
  final noteService = NoteService();
  
  try {
    final allNotes = await noteService.getNotes(userId);
    
    final results = allNotes
        .where((note) =>
            note.title.toLowerCase().contains(query.toLowerCase()) ||
            note.content.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    print('Found ${results.length} notes');
    for (final note in results) {
      print('  - ${note.title}');
    }
  } catch (e) {
    print('Error searching notes: $e');
  }
}
```

### Обновление заметки

```dart
Future<void> updateNote(String userId, NoteModel oldNote, String newContent) async {
  final noteService = NoteService();
  
  final updatedNote = NoteModel(
    id: oldNote.id,
    userId: oldNote.userId,
    title: oldNote.title,
    content: newContent,
    createdAt: oldNote.createdAt,
    updatedAt: DateTime.now(),
  );
  
  try {
    await noteService.updateNote(userId, oldNote.id, updatedNote);
    print('Note updated');
  } catch (e) {
    print('Error updating note: $e');
  }
}
```

## Работа с расписанием

### Добавление пары в расписание

```dart
import 'package:time/services/schedule_service.dart';
import 'package:time/models/schedule_model.dart';

Future<void> addLesson(String userId) async {
  final scheduleService = ScheduleService();
  
  final schedule = ScheduleModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    userId: userId,
    lessonName: 'Математика',
    dayOfWeek: DayOfWeek.monday,
    startTime: DateTime(2024, 1, 1, 9, 0),  // 9:00 AM
    endTime: DateTime(2024, 1, 1, 10, 30),  // 10:30 AM
    location: 'Аудитория 101',
    instructor: 'Проф. Иванов И.И.',
  );
  
  try {
    await scheduleService.addSchedule(userId, schedule);
    print('Lesson added to schedule');
  } catch (e) {
    print('Error adding lesson: $e');
  }
}
```

### Получение расписания на конкретный день

```dart
Future<void> getScheduleForDay(String userId, DayOfWeek day) async {
  final scheduleService = ScheduleService();
  
  try {
    final allSchedules = await scheduleService.getSchedules(userId);
    
    final daySchedules = allSchedules
        .where((schedule) => schedule.dayOfWeek == day)
        .toList();
    
    daySchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    print('Schedule for ${day.toString().split('.').last}:');
    for (final lesson in daySchedules) {
      print('  ${lesson.startTime.hour}:${lesson.startTime.minute} - ${lesson.lessonName}');
      print('    Location: ${lesson.location}');
      print('    Instructor: ${lesson.instructor}');
    }
  } catch (e) {
    print('Error fetching schedule: $e');
  }
}
```

## Real-time синхронизация

### Слушание изменений в задачах

```dart
void watchTasksRealtime(String userId) {
  final taskService = TaskService();
  
  taskService.watchTasks(userId).listen(
    (tasks) {
      print('Tasks updated! Count: ${tasks.length}');
      for (final task in tasks) {
        print('  - ${task.title} [${task.status}]');
      }
    },
    onError: (error) {
      print('Error watching tasks: $error');
    },
    onDone: () {
      print('Task stream closed');
    },
  );
}
```

### Слушание с фильтрацией

```dart
void watchCompletedTasks(String userId) {
  final taskService = TaskService();
  
  taskService.watchTasks(userId)
      .where((tasks) => tasks.isNotEmpty)
      .listen((tasks) {
        final completed = tasks
            .where((task) => task.status == TaskStatus.completed)
            .toList();
        
        print('Completed tasks: ${completed.length}');
      });
}
```

### Объединение нескольких потоков

```dart
import 'dart:async';

void watchAllUserData(String userId) {
  final taskService = TaskService();
  final noteService = NoteService();
  final scheduleService = ScheduleService();
  
  StreamZip<Object>([
    taskService.watchTasks(userId),
    noteService.watchNotes(userId),
    scheduleService.watchSchedules(userId),
  ]).listen((data) {
    final tasks = data[0] as List;
    final notes = data[1] as List;
    final schedules = data[2] as List;
    
    print('Tasks: ${tasks.length}, Notes: ${notes.length}, Schedules: ${schedules.length}');
  });
}
```

## Обработка ошибок

### Полная обработка ошибок

```dart
Future<void> robustTaskOperation(String userId) async {
  final taskService = TaskService();
  
  try {
    final tasks = await taskService.getTasks(userId).timeout(
      Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Request timed out'),
    );
    
    if (tasks.isEmpty) {
      print('No tasks found');
      return;
    }
    
    // Процесс
    print('Successfully fetched ${tasks.length} tasks');
  } on TimeoutException {
    print('Request timed out - please check your connection');
  } on FirebaseException catch (e) {
    print('Firebase error: ${e.code} - ${e.message}');
  } catch (e) {
    print('Unexpected error: $e');
  }
}
```

### Retry логика

```dart
Future<T> retryOperation<T>(
  Future<T> Function() operation,
  int maxRetries = 3,
) async {
  int attempt = 0;
  
  while (attempt < maxRetries) {
    try {
      return await operation();
    } catch (e) {
      attempt++;
      if (attempt == maxRetries) {
        rethrow;
      }
      print('Attempt $attempt failed, retrying...');
      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }
  
  throw Exception('Operation failed after $maxRetries attempts');
}

// Использование
Future<void> fetchWithRetry(String userId) async {
  final taskService = TaskService();
  
  try {
    final tasks = await retryOperation(
      () => taskService.getTasks(userId),
      maxRetries: 3,
    );
    print('Tasks: ${tasks.length}');
  } catch (e) {
    print('Failed to fetch tasks: $e');
  }
}
```

## Лучшие практики

### 1. Используйте try-catch для всех async операций

```dart
// ✅ Хорошо
try {
  await service.addTask(userId, task);
} catch (e) {
  print('Error: $e');
}

// ❌ Плохо
await service.addTask(userId, task);  // Может привести к краху
```

### 2. Кэшируйте сервисы

```dart
// ✅ Хорошо - Singleton используется повторно
final service1 = TaskService();
final service2 = TaskService();
// service1 === service2 (одна и та же инстанция)

// ❌ Плохо - создание новых инстанций
final s1 = TaskService();
final s2 = TaskService();  // Другая инстанция
```

### 3. Используйте Streams для real-time данных

```dart
// ✅ Хорошо - real-time обновления
taskService.watchTasks(userId).listen((tasks) {
  setState(() => _tasks = tasks);
});

// ❌ Плохо - только одноразовая загрузка
final tasks = await taskService.getTasks(userId);
```

### 4. Валидируйте данные перед сохранением

```dart
// ✅ Хорошо
bool isValidEmail(String email) {
  return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
}

if (!isValidEmail(email)) {
  throw ValidationException('Invalid email');
}

// ❌ Плохо
await service.register(email, password);  // Без проверки
```

---

Больше примеров см. в документации:
- `FIREBASE_SETUP.md` - конфигурация Firebase
- `PROJECT_STRUCTURE.md` - архитектура проекта
- `QUICKSTART.md` - быстрый старт
