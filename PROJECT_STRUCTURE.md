# Структура проекта BLISS

## Архитектура приложения

Приложение использует **Firebase Authentication** и **Firebase Realtime Database** для управления пользователями и данными.

### Слои приложения:

```
lib/
├── main.dart                         # Entry point, инициализация Firebase
├── firebase_options.dart              # Firebase конфигурация
├── theme/
│   └── app_theme.dart                # UI тема и стили
├── services/                          # Бизнес логика
│   ├── firebase_service.dart          # Firebase Authentication & DB
│   ├── task_service.dart              # Управление задачами
│   ├── note_service.dart              # Управление заметками
│   └── schedule_service.dart          # Управление расписанием
├── models/                            # Модели данных
│   ├── user_model.dart
│   ├── task_model.dart
│   ├── note_model.dart
│   └── schedule_model.dart
├── screens/                           # UI слой
│   ├── auth/
│   │   ├── login_screen.dart          # Экран входа
│   │   └── registration_screen.dart   # Экран регистрации
│   └── home/
│       └── home_screen.dart           # Главный экран
└── widgets/                           # Переиспользуемые виджеты (будущее)
```

## Структура данных в Firebase

```
katenka-74591 (проект)
└── users
    └── {uid}                          # ID пользователя (Firebase Auth)
        ├── name: string              # Имя пользователя
        ├── email: string             # Email
        ├── createdAt: timestamp      # Дата создания
        ├── tasks/                    # Задачи пользователя
        │   └── {taskId}
        │       ├── title
        │       ├── description
        │       ├── dueDate
        │       ├── priority
        │       ├── status
        │       └── createdAt
        ├── notes/                    # Заметки пользователя
        │   └── {noteId}
        │       ├── title
        │       ├── content
        │       ├── createdAt
        │       └── updatedAt
        └── schedules/                # Расписание уроков
            └── {scheduleId}
                ├── lessonName
                ├── dayOfWeek
                ├── startTime
                ├── endTime
                ├── location
                └── instructor
```

## Сервисы

### FirebaseService
Основной сервис для работы с Firebase:
- `register(email, password)` - регистрация
- `login(email, password)` - вход
- `logout()` - выход
- `getCurrentUser()` - получить текущего пользователя
- `saveUserData(userId, data)` - сохранить данные пользователя
- `getUserData(userId)` - получить данные пользователя

### TaskService
Управление задачами (Singleton):
- `addTask(userId, task)` - добавить задачу
- `getTasks(userId)` - получить все задачи
- `updateTask(userId, taskId, task)` - обновить задачу
- `deleteTask(userId, taskId)` - удалить задачу
- `watchTasks(userId)` - слушать изменения задач (Stream)

### NoteService
Управление заметками (Singleton):
- `addNote(userId, note)` - добавить заметку
- `getNotes(userId)` - получить все заметки
- `updateNote(userId, noteId, note)` - обновить заметку
- `deleteNote(userId, noteId)` - удалить заметку
- `watchNotes(userId)` - слушать изменения заметок (Stream)

### ScheduleService
Управление расписанием (Singleton):
- `addSchedule(userId, schedule)` - добавить расписание
- `getSchedules(userId)` - получить все расписания
- `updateSchedule(userId, scheduleId, schedule)` - обновить расписание
- `deleteSchedule(userId, scheduleId)` - удалить расписание
- `watchSchedules(userId)` - слушать изменения расписаний (Stream)

## Экраны

### AuthWrapper
Главный навигатор приложения:
- Проверяет статус аутентификации
- Показывает либо экран входа/регистрации, либо главный экран

### LoginScreen
Экран входа с:
- Email текстовое поле
- Password текстовое поле с видимостью
- Кнопка "Войти"
- Ссылка на регистрацию
- Обработка ошибок

### RegistrationScreen
Экран регистрации с:
- Имя пользователя
- Email
- Пароль (минимум 6 символов)
- Подтверждение пароля
- Валидация всех полей
- Сохранение данных в Realtime Database

### HomeScreen
Главный экран приложения с:
- Информацией о пользователе
- Списком доступных функций
- Кнопкой выхода

## Модели данных

### UserModel
```dart
UserModel(
  uid: String,
  name: String,
  email: String,
  createdAt: DateTime,
)
```

### TaskModel
```dart
TaskModel(
  id: String,
  userId: String,
  title: String,
  description: String,
  dueDate: DateTime,
  priority: TaskPriority (low, medium, high, urgent),
  status: TaskStatus (pending, inProgress, completed),
  createdAt: DateTime,
)
```

### NoteModel
```dart
NoteModel(
  id: String,
  userId: String,
  title: String,
  content: String,
  createdAt: DateTime,
  updatedAt: DateTime,
)
```

### ScheduleModel
```dart
ScheduleModel(
  id: String,
  userId: String,
  lessonName: String,
  dayOfWeek: DayOfWeek,
  startTime: DateTime,
  endTime: DateTime,
  location: String,
  instructor: String,
)
```

## Будущие функции

1. **Календарь** - интеграция с device calendar
2. **Поиск** - поиск по задачам и заметкам
3. **Напоминания** - push-уведомления и планировщик
4. **Поддержка темы** - тёмная/светлая тема
5. **Синхронизация** - offline-first синхронизация
6. **Analytics** - отслеживание активности
7. **Экспорт** - экспорт данных в PDF/CSV
8. **Поделиться** - поделиться задачами с другими

## Руководство для разработчиков

### Добавление новой функции

1. Создать модель в `lib/models/`
2. Создать сервис в `lib/services/`
3. Создать экран в `lib/screens/`
4. Добавить навигацию в `AuthWrapper` или соответствующий экран

### Правила кода

- Используй Singleton pattern для сервисов
- Все async операции обрабатывай с try-catch
- Используй Stream для realtime данных
- Следуй Material Design 3 guideline
- Пиши лаконичный и чистый код
- Документируй сложную логику

### Интеграция Firebase Rules

Убедись, что Firebase Rules настроены для безопасности:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid",
        "tasks": {
          "$taskId": {
            ".validate": "newData.hasChildren(['title', 'dueDate'])"
          }
        },
        "notes": {
          "$noteId": {
            ".validate": "newData.hasChildren(['title', 'content'])"
          }
        }
      }
    }
  }
}
```

## Зависимости

```yaml
firebase_core: ^3.0.0
firebase_auth: ^5.0.0
firebase_database: ^11.0.0
flutter_lints: ^5.0.0
cupertino_icons: ^1.0.8
```

## Заметки

- Приложение использует **только Firebase Realtime Database**
- Не используются Firestore, Firebase Storage или другие сервисы
- Все данные пользователя хранятся под его UID
- Каждый пользователь может видеть только свои данные
