import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../services/app_state_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
  final _appStateService = AppStateService();
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>>? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      _userDataSubscription = _appStateService.watchUserData().listen((userData) {
        if (mounted) {
          setState(() {
            _userData = userData;
            _isLoading = false;
          });
        }
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    await _userDataSubscription?.cancel();
    await _firebaseService.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLISS'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Добро пожаловать!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                                                       _userData['name'] ?? 'Пользователь',
                                                       style: Theme.of(context)
                                                           .textTheme
                                                           .bodyLarge
                                                           ?.copyWith(fontWeight: FontWeight.w500),
                                                     ),
                                                     const SizedBox(height: 4),
                                                     Text(
                                                       _userData['email'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Функции',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      context,
                      Icons.calendar_today,
                      'Календарь',
                      'Управляйте своими событиями',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context,
                      Icons.task_alt,
                      'Задачи',
                      'Планируйте и отслеживайте задачи',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context,
                      Icons.notes,
                      'Заметки',
                      'Записывайте важные мысли',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context,
                      Icons.schedule,
                      'Расписание',
                      'Создавайте расписание уроков',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context,
                      Icons.timer,
                      'Pomodoro',
                      'Техника Помодоро для продуктивности',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context,
                      Icons.grid_on,
                      'Матрица Эйзенхауэра',
                      'Приоритизируйте ваши задачи',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
