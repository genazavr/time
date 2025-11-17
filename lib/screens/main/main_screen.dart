import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../models/user_metrics.dart';
import '../../services/app_state_service.dart';
import '../../services/firebase_service.dart';
import '../../services/local_avatar_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/achievement_utils.dart';
import '../calendar/calendar_screen.dart';
import '../pomodoro/pomodoro_screen.dart';
import '../eisenhower/eisenhower_screen.dart';
import '../homework/homework_screen.dart';
import '../notes/notes_screen.dart';
import '../schedule/schedule_screen.dart';
import '../podcasts/podcasts_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const PomodoroScreen(),
    const EisenhowerScreen(),
    const HomeworkScreen(),
    const ScheduleScreen(),
    const PodcastsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  _buildNavItem(Icons.dashboard_outlined, 'Главная', 0, 60),
                  _buildNavItem(Icons.timer_outlined, 'Помодоро', 1, 60),
                  _buildNavItem(Icons.grid_view_outlined, 'Эйзенхауэр', 2, 70),
                  _buildNavItem(Icons.assignment_outlined, 'ДЗ', 3, 50),
                  _buildNavItem(Icons.schedule, 'Расписание', 4, 70),
                  _buildNavItem(Icons.headphones_outlined, 'Подкасты', 5, 60),
                  _buildNavItem(Icons.person_outline, 'Профиль', 6, 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, double width) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : Colors.grey.shade500;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: SizedBox(
        width: width,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  key: ValueKey(isSelected),
                  icon,
                  color: color,
                  size: isSelected ? 22 : 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final LocalAvatarService _avatarService = LocalAvatarService();
  final AppStateService _appStateService = AppStateService();

  String? _userName;

  @override
  void initState() {
    super.initState();
    _avatarService.loadAvatar();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = _firebaseService.getCurrentUser();
    if (user == null) return;
    final data = _appStateService.userData;
    if (!mounted) return;
    setState(() {
      _userName = (data['name'] as String?)?.trim();
      if (_userName != null && _userName!.isEmpty) {
        _userName = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.getCurrentUser();
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLISS'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          ValueListenableBuilder<String?>(
            valueListenable: _avatarService.avatarNotifier,
            builder: (context, path, _) {
              final image = _resolveAvatar(path);
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  backgroundImage: image,
                  child: image == null
                      ? const Icon(Icons.person_outline, color: Colors.white)
                      : null,
                ),
              );
            },
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
            child: AnimationLimiter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => ScaleAnimation(
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    _buildWelcomeCard(context, user, metrics, achievements.length),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildTodayOverview(context, metrics),
                    const SizedBox(height: 24),
                    _buildProgressSection(context, metrics),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ImageProvider? _resolveAvatar(String? path) {
    if (path == null || path.isEmpty || kIsWeb) {
      return null;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    return FileImage(file);
  }

  String _greetingName(User? user) {
    if (_userName != null && _userName!.isNotEmpty) {
      return _userName!;
    }
    final displayName = user?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final email = user?.email;
    if (email == null || email.isEmpty) {
      return 'Пользователь';
    }
    return email.split('@').first;
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    User? user,
    UserMetrics metrics,
    int achievementsCount,
  ) {
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
                  final image = _resolveAvatar(path);
                  return CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    backgroundImage: image,
                    child: image == null
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Привет, ${_greetingName(user)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Сфокусируйся на важном сегодня',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
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
              _buildHighlight(
                context,
                title: 'Задачи',
                value: metrics.totalTasks > 0
                    ? '${metrics.completedTasks}/${metrics.totalTasks}'
                    : '0',
                icon: Icons.task_alt,
              ),
              _buildHighlight(
                context,
                title: 'Фокус',
                value: '${metrics.focusMinutesToday} мин',
                icon: Icons.timer_outlined,
              ),
              _buildHighlight(
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

  Widget _buildHighlight(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.timer_outlined,
        title: 'Помодоро',
        color: AppTheme.primaryColor,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PomodoroScreen()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.calendar_today_outlined,
        title: 'Календарь',
        color: AppTheme.accentColor,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CalendarScreen()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.note_outlined,
        title: 'Заметки',
        color: AppTheme.secondaryColor,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotesScreen()),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const spacing = 16.0;
            double buttonWidth;
            if (width >= 840) {
              buttonWidth = (width - spacing * 2) / 3;
            } else if (width >= 360) {
              buttonWidth = (width - spacing) / 2;
            } else {
              buttonWidth = width;
            }
            buttonWidth = buttonWidth.clamp(0.0, 320.0);
            return Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: spacing,
                runSpacing: spacing,
                children: actions.map((action) {
                  final currentWidth = width < 360 ? width : buttonWidth;
                  return SizedBox(
                    width: currentWidth,
                    child: _buildActionCard(context, action),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickAction action) {
    return Card(
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayOverview(BuildContext context, UserMetrics metrics) {
    final pendingHomework = metrics.totalHomework > metrics.completedHomework
        ? metrics.totalHomework - metrics.completedHomework
        : 0;

    final items = [
      _OverviewItem('Задачи на сегодня', metrics.tasksDueToday, AppTheme.primaryColor),
      _OverviewItem('Домашние задания', pendingHomework, AppTheme.warningColor),
      _OverviewItem('События', metrics.eventsToday, AppTheme.accentColor),
      _OverviewItem('Помодоро сессии', metrics.pomodoroSessionsToday, AppTheme.secondaryColor),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Обзор дня',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _buildOverviewItem(context, items[i]),
                  if (i != items.length - 1) const Divider(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewItem(BuildContext context, _OverviewItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.value.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: item.color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, UserMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Прогресс на этой неделе',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProgressBar(
                  context,
                  label: 'Завершено задач',
                  progress: metrics.tasksCompletionRatio,
                  color: AppTheme.accentColor,
                  detail: metrics.totalTasks > 0
                      ? '${metrics.completedTasks}/${metrics.totalTasks}'
                      : 'Нет задач',
                ),
                const SizedBox(height: 16),
                _buildProgressBar(
                  context,
                  label: 'Фокус время',
                  progress: metrics.focusDayProgress,
                  color: AppTheme.primaryColor,
                  detail: '${metrics.focusMinutesToday} мин из 150',
                ),
                const SizedBox(height: 16),
                _buildProgressBar(
                  context,
                  label: 'Цели по ДЗ',
                  progress: metrics.homeworkCompletionRatio,
                  color: AppTheme.warningColor,
                  detail: metrics.totalHomework > 0
                      ? '${metrics.completedHomework}/${metrics.totalHomework}'
                      : 'Нет ДЗ',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context, {
    required String label,
    required double progress,
    required Color color,
    String? detail,
  }) {
    final progressValue = progress.clamp(0.0, 1.0);
    final percent = (progressValue * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                ],
              ),
            ),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressValue,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}

class _OverviewItem {
  final String label;
  final int value;
  final Color color;

  const _OverviewItem(this.label, this.value, this.color);
}

