import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/user_metrics.dart';
import '../../models/user_notification.dart';
import '../../services/app_state_service.dart';
import '../../services/firebase_service.dart';
import '../../services/local_avatar_service.dart';
import '../../services/notification_center_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/achievement_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final LocalAvatarService _avatarService = LocalAvatarService();
  final ImagePicker _imagePicker = ImagePicker();
  final NotificationCenterService _notificationCenter = NotificationCenterService();
  final NotificationService _notificationService = NotificationService();
  final AppStateService _appStateService = AppStateService();

  late final Stream<List<UserNotification>> _notificationsStream;
  StreamSubscription<List<UserNotification>>? _notificationsSubscription;
  StreamSubscription<Map<String, dynamic>>? _userDataSubscription;
  Map<String, dynamic> _userData = {};
  bool _isAvatarLoading = false;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _avatarService.loadAvatar();
    _notificationsStream = _notificationCenter.watchNotifications().asBroadcastStream();
    _notificationsSubscription = _notificationsStream.listen((notifications) {
      final unread = notifications.where((notification) => notification.isUnread).length;
      if (mounted) {
        setState(() => _unreadNotifications = unread);
      }
    });
    _userDataSubscription = _appStateService.watchUserData().listen((userData) {
      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _userDataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final hasAccess = await _ensureImageAccess();
    if (!mounted) return;
    if (!hasAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Нет доступа к фотографиям'),
          action: SnackBarAction(
            label: 'Настройки',
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (image == null) return;

    if (!mounted) return;
    setState(() => _isAvatarLoading = true);
    try {
      await _avatarService.setAvatar(image.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аватар обновлён')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAvatarLoading = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    await _avatarService.setAvatar(null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Аватар удалён')),
    );
  }

  Future<bool> _ensureImageAccess() async {
    if (kIsWeb) return true;

    Future<bool> requestPermission(Permission permission) async {
      final status = await permission.status;
      if (status.isGranted || status.isLimited) return true;
      final result = await permission.request();
      return result.isGranted || result.isLimited;
    }

    if (Platform.isIOS) {
      return requestPermission(Permission.photos);
    }

    if (Platform.isAndroid) {
      if (await requestPermission(Permission.photos)) {
        return true;
      }
      return requestPermission(Permission.storage);
    }

    return true;
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
          'Все данные сохранятся в вашем профиле и будут доступны после повторного входа.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    try {
      await _notificationsSubscription?.cancel();
      _notificationsSubscription = null;
      await _firebaseService.logout();
      await _avatarService.reset();
      await _notificationService.cancelAllNotifications();
      await _notificationCenter.stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы вышли из аккаунта')),
      );
    } catch (error, stackTrace) {
      debugPrint('Logout error: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось выйти. Попробуйте ещё раз.')),
      );
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar();
              },
            ),
            if (_avatarService.currentPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Удалить фото'),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _avatarImage(String? path) {
    if (path == null || path.isEmpty || kIsWeb) {
      return null;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    return FileImage(file);
  }

  String _displayName(User? user) {
    final name = (_userData['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final displayName = user?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final email = user?.email;
    if (email == null || email.isEmpty) return 'Пользователь';
    return email.split('@').first;
  }

  String _displayEmail(User? user) {
    return user?.email ?? 'Не указан';
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Выйти',
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: StreamBuilder<UserMetrics>(
        stream: _appStateService.watchMetrics(),
        initialData: UserMetrics.empty,
        builder: (context, snapshot) {
          final metrics = snapshot.data ?? UserMetrics.empty;
          final achievements = buildUserAchievements(metrics);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user, metrics, achievements.length),
                const SizedBox(height: 24),
                _buildAccountSection(user),
                const SizedBox(height: 24),
                _buildStatsSection(metrics),
                const SizedBox(height: 24),
                _buildAchievementsSection(achievements),
                const SizedBox(height: 24),
                _buildMenuSection(metrics),
                const SizedBox(height: 24),
                _buildAboutSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User? user, UserMetrics metrics, int achievementsCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: _avatarService.avatarNotifier,
                builder: (context, path, _) {
                  final image = _avatarImage(path);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: _showAvatarOptions,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.white,
                          backgroundImage: image,
                          child: image == null
                              ? Icon(
                                  Icons.person,
                                  size: 48,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                      ),
                      if (_isAvatarLoading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.15),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showAvatarOptions,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(user),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _displayEmail(user),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Участник с ${_formatDate(_userData['createdAt'])}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHeaderStat(
                context,
                title: 'Задачи',
                value: metrics.totalTasks > 0
                    ? '${metrics.completedTasks}/${metrics.totalTasks}'
                    : '0',
                icon: Icons.task_alt,
              ),
              _buildHeaderStat(
                context,
                title: 'Фокус',
                value: '${metrics.focusMinutesWeek} мин/нед',
                icon: Icons.bolt_outlined,
              ),
              _buildHeaderStat(
                context,
                title: 'Достижения',
                value: achievementsCount.toString(),
                icon: Icons.emoji_events_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Аккаунт',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Имя'),
                subtitle: Text(_displayName(user)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.alternate_email_outlined),
                title: const Text('Email'),
                subtitle: Text(_displayEmail(user)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Дата регистрации'),
                subtitle: Text(_formatDate(_userData['createdAt'])),
              ),
              if (user?.uid != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('UID'),
                  subtitle: Text(user!.uid),
                ),
              ],
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: FilledButton.icon(
                  onPressed: _confirmSignOut,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Выйти из аккаунта'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildStatsSection(UserMetrics metrics) {
    final stats = [
      _ProfileStat(
        icon: Icons.task_alt,
        color: AppTheme.accentColor,
        title: 'Задачи',
        value: metrics.completedTasks.toString(),
        subtitle: metrics.totalTasks > 0 ? 'из ${metrics.totalTasks}' : 'Нет задач',
      ),
      _ProfileStat(
        icon: Icons.timer_outlined,
        color: AppTheme.primaryColor,
        title: 'Помодоро',
        value: metrics.completedPomodoroSessions.toString(),
        subtitle: '${metrics.focusMinutesWeek} мин за неделю',
      ),
      _ProfileStat(
        icon: Icons.school_outlined,
        color: AppTheme.warningColor,
        title: 'Домашние задания',
        value: metrics.completedHomework.toString(),
        subtitle: metrics.totalHomework > 0 ? 'из ${metrics.totalHomework}' : 'Нет ДЗ',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ваша активность',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 880
                ? 3
                : width >= 560
                    ? 2
                    : 1;
            final itemWidth = crossAxisCount == 1
                ? width
                : (width - 16 * (crossAxisCount - 1)) / crossAxisCount;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: stats
                  .map(
                    (stat) => SizedBox(
                      width: itemWidth,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: stat.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  stat.icon,
                                  color: stat.color,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                stat.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stat.value,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: stat.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stat.subtitle,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(List<UserAchievement> achievements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Достижения',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: achievements.isEmpty
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.emoji_events_outlined,
                          color: AppTheme.secondaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Достижения появятся, как только вы начнёте активно пользоваться BLISS.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: achievements
                        .map((achievement) => _buildAchievementChip(context, achievement))
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementChip(BuildContext context, UserAchievement achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: achievement.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: achievement.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(achievement.icon, color: achievement.color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: achievement.color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                achievement.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(UserMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Меню',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('Статистика'),
                subtitle: const Text('Обновляется в реальном времени'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showStatisticsDialog(metrics),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Уведомления'),
                subtitle: Text(
                  _unreadNotifications > 0
                      ? 'Непрочитанных: $_unreadNotifications'
                      : 'Все уведомления просмотрены',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_unreadNotifications > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: _showNotificationsDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Резервное копирование'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showBackupDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Помощь и поддержка'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showHelpDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'О приложении',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        ),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BLISS',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Версия 1.0.0',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Balance • Learning • Inspiring • Serenity • Success',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'BLISS помогает вам планировать учебу, управлять временем и достигать целей без стресса.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic dateData) {
    if (dateData == null) return 'неизвестно';
    try {
      final date = DateTime.parse(dateData.toString());
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day.$month.${date.year}';
    } catch (_) {
      return 'неизвестно';
    }
  }


  void _showStatisticsDialog(UserMetrics metrics) {
    final pendingHomework = (metrics.totalHomework - metrics.completedHomework).clamp(0, metrics.totalHomework);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Всего задач: ${metrics.totalTasks}'),
            Text('• Завершено задач: ${metrics.completedTasks}'),
            Text('• Помодоро сессий: ${metrics.completedPomodoroSessions}'),
            Text('• Фокус сегодня: ${metrics.focusMinutesToday} мин'),
            Text('• Домашние задания: ${metrics.completedHomework}/${metrics.totalHomework}'),
            Text('• Оставшиеся ДЗ: $pendingHomework'),
            Text('• События сегодня: ${metrics.eventsToday}'),
            Text('• Заметок: ${metrics.notesCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, controller) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Уведомления',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        if (_unreadNotifications > 0)
                          TextButton(
                            onPressed: () => _notificationCenter.markAllAsRead(),
                            child: const Text('Отметить всё'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<List<UserNotification>>(
                        stream: _notificationsStream,
                        builder: (context, snapshot) {
                          final notifications = snapshot.data ?? const <UserNotification>[];
                          if (notifications.isEmpty) {
                            return _buildEmptyNotificationsState();
                          }
                          return ListView.separated(
                            controller: controller,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              return _buildNotificationTile(notification);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyNotificationsState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 36,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Вы в курсе всех событий',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Как только появится что-то важное,\nмы отправим уведомление.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(UserNotification notification) {
    final theme = Theme.of(context);
    final color = _notificationColor(notification.type);
    final icon = _notificationIcon(notification.type);
    final isUnread = notification.isUnread;

    return InkWell(
      onTap: isUnread ? () => _notificationCenter.markAsRead(notification.id) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isUnread
              ? color.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnread ? color.withValues(alpha: 0.25) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatNotificationTime(notification.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.message.isNotEmpty
                        ? notification.message
                        : 'Нет дополнительных сведений',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: isUnread
                        ? TextButton.icon(
                            onPressed: () => _notificationCenter.markAsRead(notification.id),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.done_all, size: 18),
                            label: const Text('Отметить прочитанным'),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.done_all, size: 18, color: AppTheme.accentColor),
                              const SizedBox(width: 6),
                              Text(
                                'Прочитано',
                                style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _notificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.task:
        return AppTheme.primaryColor;
      case NotificationType.homework:
        return AppTheme.warningColor;
      case NotificationType.schedule:
        return AppTheme.secondaryColor;
      case NotificationType.pomodoro:
        return AppTheme.accentColor;
      case NotificationType.system:
        return Colors.blueGrey;
    }
  }

  IconData _notificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.task:
        return Icons.check_circle_outline;
      case NotificationType.homework:
        return Icons.school_outlined;
      case NotificationType.schedule:
        return Icons.calendar_month_outlined;
      case NotificationType.pomodoro:
        return Icons.timer_outlined;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  String _formatNotificationTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';

    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day.$month.${time.year}';
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Резервное копирование'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Последнее копирование:'),
            SizedBox(height: 8),
            Text('Сегодня, 14:30'),
            SizedBox(height: 16),
            Text('Автоматическое копирование:'),
            SizedBox(height: 8),
            Text('Каждый день в 22:00'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Резервная копия создана')),
              );
            },
            child: const Text('Создать копию'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Помощь и поддержка'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Частые вопросы:'),
            SizedBox(height: 8),
            Text('• Как добавить задачу?'),
            Text('• Как настроить Помодоро?'),
            Text('• Как экспортировать данные?'),
            SizedBox(height: 16),
            Text('Контакты поддержки:'),
            SizedBox(height: 8),
            Text('Email: support@bliss.app'),
            Text('Telegram: @bliss_support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  const _ProfileStat({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });
}
