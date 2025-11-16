# 🎯 Руководство по начальной конфигурации BLISS

## 1️⃣ Шаг 1: Подготовка окружения

### Требования
- ✅ Flutter SDK последняя версия
- ✅ Dart SDK (входит в Flutter)
- ✅ Git
- ✅ Аккаунт Firebase
- ✅ IDE (VS Code, Android Studio или Xcode)

### Проверка установки
```bash
flutter --version
dart --version
```

## 2️⃣ Шаг 2: Клонирование проекта

```bash
git clone <your-repo-url>
cd project
git checkout feat/firebase-auth-realtime-registration-katenka-74591
```

## 3️⃣ Шаг 3: Установка зависимостей

```bash
# Обновить Flutter
flutter upgrade

# Получить зависимости
flutter pub get
```

## 4️⃣ Шаг 4: Конфигурация Firebase (критично!)

### 4.1 Активировать FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 4.2 Конфигурировать Firebase для проекта
```bash
flutterfire configure --project=katenka-74591
```

**Что будет спрошено:**
- Платформы: выберите все необходимые (iOS, Android, Web, etc.)
- Google Cloud Project: выберите `katenka-74591`

**Результат:**
- ✅ Автоматически обновится `lib/firebase_options.dart`
- ✅ Создадутся конфиги для каждой платформы
- ✅ Будут добавлены необходимые классы для Kotlin/Swift

### 4.3 Firebase Console: Включить Authentication
1. Откройте https://console.firebase.google.com/project/katenka-74591
2. Перейдите в **Authentication**
3. Нажмите **Get started**
4. Выберите **Email/Password**
5. Включите Email/Password и нажмите **Enable**

### 4.4 Firebase Console: Конфигурировать Realtime Database
1. Перейдите в **Realtime Database**
2. Нажмите **Create Database**
3. Выберите location (например, `europe-west1`)
4. Выберите **Start in test mode** для разработки
5. Нажмите **Enable**

### 4.5 Установить Security Rules
1. В Realtime Database перейдите в **Rules** tab
2. Скопируйте содержимое файла `database.rules.json`
3. Вставьте в Rules editor
4. Нажмите **Publish**

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

## 5️⃣ Шаг 5: Проверка конфигурации

### Проверить firebase_options.dart
```dart
// Должны быть заполнены:
- apiKey
- appId
- messagingSenderId
- projectId
- databaseURL
- authDomain
```

### Тестовая сборка
```bash
# Для Android
flutter build apk --debug

# Для iOS
flutter build ios --debug

# Для Web
flutter build web
```

## 6️⃣ Шаг 6: Запуск приложения

```bash
# Общий запуск (автоматически выбирает платформу)
flutter run

# Для конкретной платформы
flutter run -d android      # Android эмулятор
flutter run -d ios         # iOS симулятор
flutter run -d chrome      # Web в Chrome
flutter run -d windows     # Windows
flutter run -d linux       # Linux
flutter run -d macos       # macOS
```

## 7️⃣ Шаг 7: Первое использование

### Регистрация тестового пользователя
1. Запустите приложение
2. Нажмите **"Нет аккаунта? Создать"**
3. Заполните:
   - Имя: `Test User`
   - Email: `test@example.com`
   - Пароль: `Password123`
4. Нажмите **Зарегистрироваться**

### Проверка Firebase
1. Откройте Firebase Console
2. Перейдите в **Authentication**
   - Должен появиться пользователь `test@example.com`
3. Перейдите в **Realtime Database**
   - Должна появиться папка `users` с данными пользователя

## 🔍 Troubleshooting

### ❌ "flutterfire_cli not found"
```bash
# Добавьте в PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Или переустановите
dart pub global activate flutterfire_cli --overwrite
```

### ❌ "firebase_options.dart not found"
```bash
# Пересоздайте конфиг
rm lib/firebase_options.dart
flutterfire configure --project=katenka-74591
```

### ❌ "Pod install failed" (iOS)
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter run -d ios
```

### ❌ "Build cache issues"
```bash
flutter clean
flutter pub get
flutter run
```

### ❌ "Authentication error"
- ✅ Убедитесь что Email/Password включен в Firebase
- ✅ Проверьте database.rules.json опубликованы
- ✅ Убедитесь что проект ID верный

### ❌ "Database connection refused"
- ✅ Проверьте что Realtime Database создана
- ✅ Проверьте что databaseURL в firebase_options.dart
- ✅ Убедитесь что Rules позволяют доступ

## 📊 Проверка статуса

### Список установленных зависимостей
```bash
flutter pub get
```

### Анализ проекта
```bash
flutter analyze
```

### Форматирование кода
```bash
flutter format lib/
```

## 🧪 Тестирование конфигурации

### Простой тест конфигурации
```dart
// Добавьте в main.dart для проверки
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final firebaseService = FirebaseService();
    await firebaseService.initialize();
    print('✅ Firebase инициализирован успешно');
  } catch (e) {
    print('❌ Ошибка Firebase: $e');
  }
  
  runApp(const MyApp());
}
```

## 📱 Платформоспецифические инструкции

### iOS
```bash
cd ios
# Проверить версию CocoaPods
pod --version

# Обновить pods
pod install --repo-update
cd ..

# Запустить на симуляторе
flutter run -d ios
```

### Android
```bash
# Проверить SDK
flutter doctor

# Запустить на эмуляторе
flutter run -d android
```

### Web
```bash
# Требуется Chrome/Chromium
flutter run -d chrome

# Или Firefox
flutter run -d firefox
```

## 💾 Сохранение прогресса

### Создать новый коммит
```bash
git add .
git commit -m "Configure Firebase for BLISS app"
git push origin feat/firebase-auth-realtime-registration-katenka-74591
```

## ✅ Чек-лист завершения

- [ ] Flutter SDK установлен
- [ ] Зависимости получены (`flutter pub get`)
- [ ] FlutterFire CLI активирован
- [ ] Проект Firebase конфигурирован
- [ ] Email/Password Authentication включен
- [ ] Realtime Database создана
- [ ] Security Rules опубликованы
- [ ] Приложение собирается без ошибок
- [ ] Тестовый пользователь создан
- [ ] Данные видны в Firebase Console

## 🎓 Следующие шаги

1. Прочитайте **[README_FIREBASE.md](README_FIREBASE.md)** - обзор функциональности
2. Изучите **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - архитектура
3. Посмотрите **[EXAMPLES.md](EXAMPLES.md)** - примеры кода
4. Начните разрабатывать новые функции

## 📞 Поддержка

- **Firebase Console:** https://console.firebase.google.com/project/katenka-74591
- **Flutter Docs:** https://flutter.dev/docs
- **Firebase Docs:** https://firebase.google.com/docs

---

**После выполнения всех шагов приложение готово к разработке!** 🚀

Если возникнут проблемы:
1. Проверьте Troubleshooting раздел выше
2. Запустите `flutter doctor` для диагностики
3. Проверьте Firebase Console логи
4. Просмотрите документацию Firebase
