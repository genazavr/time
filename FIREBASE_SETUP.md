# Firebase Setup для BLISS

## Конфигурация Firebase для проекта

Этот проект уже настроен на использование Firebase Authentication и Realtime Database.

### Project ID: `katenka-74591`
### Sender ID: `439851419572`

## Шаги для финализации конфигурации

### 1. Установите FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2. Конфигурируйте Firebase для вашего проекта
```bash
flutterfire configure --project=katenka-74591
```

Этот команда автоматически:
- Загрузит необходимые конфиги для Android, iOS и Web
- Обновит `firebase_options.dart` с корректными учётными данными
- Сконфигурирует все необходимые файлы

### 3. Firebase Rules для Realtime Database

Установите следующие правила безопасности в Firebase Console:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid",
        ".validate": "newData.hasChildren(['name', 'email', 'createdAt'])"
      }
    }
  }
}
```

### 4. Включите Email/Password Authentication

В Firebase Console:
1. Перейдите в Authentication > Sign-in method
2. Включите Email/Password provider

## Структура проекта

```
lib/
├── main.dart                    # Entry point с Firebase инициализацией
├── firebase_options.dart        # Конфигурация Firebase (обновляется flutterfire)
├── services/
│   └── firebase_service.dart   # Сервис для работы с Firebase
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart   # Экран входа
│   │   └── registration_screen.dart  # Экран регистрации
│   └── home/
│       └── home_screen.dart    # Главный экран приложения
```

## Features

- ✅ Firebase Authentication (Email/Password)
- ✅ Firebase Realtime Database интеграция
- ✅ Экран регистрации с валидацией
- ✅ Экран входа
- ✅ Главный экран с информацией пользователя
- ✅ Сохранение пользовательских данных в БД
- ✅ Функция выхода

## Готовые возможности для расширения

Проект готов к добавлению следующих функций:
- Календарь
- Задачи и заметки
- Расписание уроков
- Таймер Pomodoro
- Матрица Эйзенхауэра
- Напоминания
- Подкасты

Все эти функции будут использовать Firebase Realtime Database для синхронизации данных.

## Запуск приложения

```bash
flutter pub get
flutter run
```

## Troubleshooting

### "Firebase initialization failed"
- Убедитесь, что вы запустили `flutterfire configure`
- Проверьте `firebase_options.dart` на корректность данных

### "Authentication failed"
- Проверьте Firebase Console settings
- Убедитесь, что Email/Password provider включён

### "Database connection error"
- Проверьте Firebase Rules для Realtime Database
- Убедитесь, что Database URL правилен в `firebase_options.dart`
