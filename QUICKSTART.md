# Быстрый старт BLISS

## Предварительные требования

- Flutter SDK (последняя версия)
- Dart SDK (включён в Flutter)
- Firebase CLI (опционально)

## Установка и настройка

### 1. Клонируйте репозиторий
```bash
git clone <repository>
cd project
```

### 2. Установите зависимости Flutter
```bash
flutter pub get
```

### 3. Установите и конфигурируйте Firebase
```bash
# Установите FlutterFire CLI
dart pub global activate flutterfire_cli

# Конфигурируйте Firebase для вашего проекта
flutterfire configure --project=katenka-74591
```

### 4. Запустите приложение
```bash
flutter run
```

## После конфигурации FlutterFire

После запуска `flutterfire configure`, будут автоматически:
1. Загружены Firebase credentials
2. Обновлён `firebase_options.dart`
3. Сконфигурированы платформы (iOS, Android, Web)

## Первый запуск

1. Нажмите на "Нет аккаунта? Создать"
2. Введите ваши данные:
   - Имя
   - Email
   - Пароль (минимум 6 символов)
3. Нажмите "Зарегистрироваться"
4. Вы будете перенаправлены на главный экран

## Структура проекта

Основные файлы для изучения:
- `lib/main.dart` - Entry point приложения
- `lib/services/firebase_service.dart` - Firebase интеграция
- `lib/screens/auth/` - Экраны аутентификации
- `lib/models/` - Модели данных

## Использование сервисов

### Регистрация пользователя
```dart
final firebaseService = FirebaseService();
final userCredential = await firebaseService.register(
  'user@example.com',
  'password123',
);
```

### Добавление задачи
```dart
final taskService = TaskService();
final task = TaskModel(
  id: 'task_id',
  userId: userId,
  title: 'Моя задача',
  description: 'Описание',
  dueDate: DateTime.now().add(Duration(days: 1)),
  priority: TaskPriority.high,
  status: TaskStatus.pending,
  createdAt: DateTime.now(),
);
await taskService.addTask(userId, task);
```

### Слушание изменений
```dart
final taskService = TaskService();
taskService.watchTasks(userId).listen((tasks) {
  setState(() {
    _tasks = tasks;
  });
});
```

## Desarrollo Tips

### Работа с Firebase Emulator (опционально)
```bash
firebase emulators:start
```

### Отладка
- Используйте `flutter run -v` для подробного вывода
- Проверяйте Firebase Console для ошибок аутентификации
- Используйте `flutter devtools` для отладки состояния

### Hot Reload
- Используйте `r` в терминале для hot reload
- Состояние аутентификации сохраняется при reload

## Troubleshooting

### "Firebase initialization failed"
```bash
# Пересоздайте `firebase_options.dart`
rm lib/firebase_options.dart
flutterfire configure --project=katenka-74591
```

### "Pod install failed" (iOS)
```bash
cd ios
pod install --repo-update
cd ..
```

### "Build failed" (Android)
```bash
flutter clean
flutter pub get
flutter run
```

## Что дальше?

После успешного запуска:
1. Прочитайте `PROJECT_STRUCTURE.md` для понимания архитектуры
2. Изучите `FIREBASE_SETUP.md` для Firebase конфигурации
3. Начните добавлять новые функции согласно `lib/models/`

## Поддержка

- Проверьте Firebase Console: https://console.firebase.google.com/
- Документация Flutter: https://flutter.dev/docs
- Документация Firebase: https://firebase.google.com/docs
