import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../services/app_state_service.dart';
import '../../services/firebase_service.dart';
import '../../services/local_avatar_service.dart';
import '../../theme/app_theme.dart';
import '../calendar/calendar_screen.dart';
import '../pomodoro/pomodoro_screen.dart';
import '../eisenhower/eisenhower_screen.dart';
import '../homework/homework_screen.dart';
import '../notes/notes_screen.dart';
import '../schedule/schedule_screen.dart';
import '../podcasts/podcasts_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final LocalAvatarService _avatarService = LocalAvatarService();
  final AppStateService _appStateService = AppStateService();

  String? _userName;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _avatarService.loadAvatar();
    _loadUserName();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  String _greetingName() {
    if (_userName != null && _userName!.isNotEmpty) return _userName!;
    final u = _firebaseService.getCurrentUser();
    if (u?.displayName != null && u!.displayName!.trim().isNotEmpty) {
      return u.displayName!.trim();
    }
    if (u?.email != null && u!.email!.isNotEmpty) {
      return u.email!.split('@').first;
    }
    return 'Пользователь';
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброе утро';
    if (h < 17) return 'Добрый день';
    if (h < 22) return 'Добрый вечер';
    return 'Доброй ночи';
  }

  ImageProvider? _resolveAvatar(String? path) {
    if (path == null || path.isEmpty || kIsWeb) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ВЕСЬ экран — это один скролл
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              Colors.white,
              AppTheme.secondaryColor.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildWelcomeSection(),
                  const SizedBox(height: 60),
                  _buildNavigationGrid(),
                  const SizedBox(height: 60),
                  _buildBottomCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'BLISS',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _avatarService.avatarNotifier,
          builder: (context, path, _) {
            final img = _resolveAvatar(path);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: img,
                child: img == null
                    ? Icon(Icons.person_outline,
                    color: AppTheme.primaryColor, size: 28)
                    : null,
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _greetingName(),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 4,
          width: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationGrid() {
    final buttons = [
      _NavigationButton(
        icon: Icons.timer_outlined,
        label: 'Помодоро',
        color: AppTheme.primaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const PomodoroScreen()),
        ),
      ),
      _NavigationButton(
        icon: Icons.grid_view_outlined,
        label: 'Эйзенхауэр',
        color: AppTheme.accentColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const EisenhowerScreen()),
        ),
      ),
      _NavigationButton(
        icon: Icons.assignment_outlined,
        label: 'Домашка',
        color: AppTheme.secondaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const HomeworkScreen()),
        ),
      ),
      _NavigationButton(
        icon: Icons.schedule,
        label: 'Расписание',
        color: AppTheme.warningColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const ScheduleScreen()),
        ),
      ),
      _NavigationButton(
        icon: Icons.note_outlined,
        label: 'Заметки',
        color: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const NotesScreen()),
        ),
      ),
      _NavigationButton(
        icon: Icons.calendar_today_outlined,
        label: 'Календарь',
        color: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const CalendarScreen()),
        ),
      ),
      _NavigationButton(
        icon: Icons.headphones_outlined,
        label: 'Подкасты',
        color: Colors.red,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const PodcastsScreen()),
        ),
      ),
      _NavigationButton(
        icon: Icons.analytics_outlined,
        label: 'Прогресс',
        color: Colors.teal,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Статистика скоро будет доступна')),
        ),
      ),
    ];

    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: buttons.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(child: buttons[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.secondaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Совет дня',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Начни день с техники Помодоро — 25 минут сфокусированной работы помогут достичь большего.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatefulWidget {
  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<_NavigationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: widget.color.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
