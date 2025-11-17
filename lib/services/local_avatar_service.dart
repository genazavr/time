import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAvatarService {
  static final LocalAvatarService _instance = LocalAvatarService._internal();

  factory LocalAvatarService() => _instance;

  LocalAvatarService._internal();

  static const _avatarKey = 'profile_avatar_path';

  final ValueNotifier<String?> _avatarNotifier = ValueNotifier<String?>(null);
  bool _initialized = false;

  ValueListenable<String?> get avatarNotifier => _avatarNotifier;

  String? get currentPath => _avatarNotifier.value;

  Future<void> loadAvatar() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _avatarNotifier.value = prefs.getString(_avatarKey);
    _initialized = true;
  }

  Future<void> setAvatar(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_avatarKey);
      _avatarNotifier.value = null;
      return;
    }
    await prefs.setString(_avatarKey, path);
    _avatarNotifier.value = path;
  }

  Future<void> reset() async {
    await setAvatar(null);
    _initialized = true;
  }
}
