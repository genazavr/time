import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/eisenhower_task.dart';
import '../../services/eisenhower_service.dart';
import '../../theme/app_theme.dart';

class EisenhowerScreen extends StatefulWidget {
  const EisenhowerScreen({super.key});

  @override
  State<EisenhowerScreen> createState() => _EisenhowerScreenState();
}

class _EisenhowerScreenState extends State<EisenhowerScreen> {
  final EisenhowerService _eisenhowerService = EisenhowerService();
  List<EisenhowerTask> _tasks = [];
  Map<String, dynamic> _statistics = {
    'pendingTasks': 0,
    'completedTasks': 0,
    'totalTasks': 0,
    'overdueTasks': 0,
    'completionRate': 0,
    'quadrantDistribution': {'1': 0, '2': 0, '3': 0, '4': 0},
  };
  bool _isLoading = true;
  StreamSubscription<List<EisenhowerTask>>? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadStatistics();
    
    // Убираем индикатор загрузки после небольшой задержки для лучшего UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _loadTasks() {
    _tasksSubscription?.cancel();
    _tasksSubscription = _eisenhowerService.getTasks().listen((tasks) {
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
        _loadStatistics();
      }
    });
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final stats = await _eisenhowerService.getStatistics();
    if (mounted) {
      setState(() {
        _statistics = stats;
      });
    }
  }

  List<EisenhowerTask> _getTasksForQuadrant(int quadrant) {
    return _tasks
        .where((task) => task.quadrant == quadrant && !task.isCompleted)
        .toList();
  }

  int get _activeTasksCount {
    return _tasks.where((task) => !task.isCompleted).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Матрица Эйзенхауэра'),
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _activeTasksCount == 0
              ? _buildEmptyState()
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
          SizedBox(height: 16),
          Text(
            'Загрузка задач...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.dashboard_outlined,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Матрица Эйзенхауэра',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Управляйте приоритетами эффективно\nраспределяя задачи по квадрантам',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildQuadrantPreview(),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showAddTaskDialog,
                icon: const Icon(Icons.add),
                label: const Text('Добавить первую задачу'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuadrantPreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: const Row(
              children: [
                SizedBox(width: 80),
                Expanded(
                  child: Center(
                    child: Text(
                      'СРОЧНО',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'НЕ СРОЧНО',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.all(8),
                child: const Column(
                  children: [
                    Text(
                      'ВАЖНО',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Кризисные',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.priority_high,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.schedule,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.all(8),
                child: const Column(
                  children: [
                    Text(
                      'НЕ ВАЖНО',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Помощь',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFED7AA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.people,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.coffee,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            _buildHeader(),
            _buildMatrix(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Управляйте приоритетами эффективно',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Активных задач: ${_statistics['pendingTasks'] ?? 0} | Завершено: ${_statistics['completedTasks'] ?? 0}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrix() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMatrixHeader(),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildQuadrant(1, 'Срочно\nВажно', AppTheme.errorColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuadrant(2, 'Не срочно\nВажно', AppTheme.accentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildQuadrant(3, 'Срочно\nНе важно', AppTheme.warningColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuadrant(4, 'Не срочно\nНе важно', Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixHeader() {
    return Row(
      children: [
        const SizedBox(width: 80),
        Expanded(
          child: Center(
            child: Text(
              'СРОЧНО',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'НЕ СРОЧНО',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuadrant(int quadrant, String title, Color color) {
    final tasks = _getTasksForQuadrant(quadrant);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: SizedBox(
        height: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getQuadrantDescription(quadrant),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 40,
                            color: color.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нет задач',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildTaskCard(tasks[index], color),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(EisenhowerTask task, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        onLongPress: () => _showTaskActions(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'complete':
                          _toggleTaskCompletion(task);
                          break;
                        case 'move':
                          _showMoveDialog(task);
                          break;
                        case 'edit':
                          _showEditTaskDialog(task);
                          break;
                        case 'delete':
                          _deleteTask(task);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20),
                            SizedBox(width: 8),
                            Text('Завершить'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'move',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 20),
                            SizedBox(width: 8),
                            Text('Переместить'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Редактировать'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Удалить', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (task.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: task.isOverdue ? Colors.red : color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.dueDate!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: task.isOverdue ? Colors.red : color,
                        fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (task.estimatedMinutes > 0) ...[
                    Icon(
                      Icons.timer,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.estimatedMinutes} мин',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
              if (task.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: task.tags.take(3).map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getQuadrantDescription(int quadrant) {
    switch (quadrant) {
      case 1:
        return 'Кризисные задачи';
      case 2:
        return 'Планирование';
      case 3:
        return 'Помощь другим';
      case 4:
        return 'Отдых и рутина';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate.isAtSameMomentAs(today)) {
      return 'Сегодня';
    } else if (taskDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Завтра';
    } else if (taskDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Вчера';
    } else {
      return '${date.day}.${date.month}';
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onSave: (task) async {
          try {
            await _eisenhowerService.addTask(task);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка при добавлении задачи: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditTaskDialog(EisenhowerTask task) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        existingTask: task,
        onSave: (updatedTask) async {
          try {
            await _eisenhowerService.updateTask(updatedTask);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка при обновлении задачи: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showTaskDetails(EisenhowerTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.description != null) ...[
                Text(task.description!),
                const SizedBox(height: 16),
              ],
              Text('Квадрант: ${task.quadrantName}'),
              if (task.dueDate != null) ...[
                const SizedBox(height: 8),
                Text('Срок: ${_formatDate(task.dueDate!)}'),
              ],
              if (task.estimatedMinutes > 0) ...[
                const SizedBox(height: 8),
                Text('Оценка времени: ${task.estimatedMinutes} минут'),
              ],
              if (task.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Теги: ${task.tags.join(', ')}'),
              ],
            ],
          ),
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

  void _showTaskActions(EisenhowerTask task) {
    _showTaskDetails(task);
  }

  void _toggleTaskCompletion(EisenhowerTask task) async {
    try {
      await _eisenhowerService.toggleTaskCompletion(task.id);
      _loadStatistics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при изменении статуса задачи: $e')),
      );
    }
  }

  void _showMoveDialog(EisenhowerTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переместить задачу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 3, 4].map((quadrant) {
            return ListTile(
              title: Text('Квадрант $quadrant: ${_getQuadrantDescription(quadrant)}'),
              onTap: () async {
                try {
                  await _eisenhowerService.moveTaskToQuadrant(task.id, quadrant);
                  Navigator.pop(context);
                  _loadStatistics();
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка при перемещении задачи: $e')),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _deleteTask(EisenhowerTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: const Text('Вы уверены, что хотите удалить эту задачу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _eisenhowerService.deleteTask(task.id);
                Navigator.pop(context);
                _loadStatistics();
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка при удалении задачи: $e')),
                );
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Всего задач: ${_statistics['totalTasks'] ?? 0}'),
            Text('Завершено: ${_statistics['completedTasks'] ?? 0}'),
            Text('Активных: ${_statistics['pendingTasks'] ?? 0}'),
            Text('Просрочено: ${_statistics['overdueTasks'] ?? 0}'),
            Text('Процент выполнения: ${_statistics['completionRate'] ?? 0}%'),
            const SizedBox(height: 16),
            const Text('Распределение по квадрантам:'),
            ...[
              for (int i = 1; i <= 4; i++)
                Text('  Квадрант $i: ${(_statistics['quadrantDistribution'] as Map<String, dynamic>? ?? {})[i.toString()] ?? 0} задач'),
            ],
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

class AddTaskDialog extends StatefulWidget {
  final EisenhowerTask? existingTask;
  final Function(EisenhowerTask) onSave;

  const AddTaskDialog({
    super.key,
    this.existingTask,
    required this.onSave,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedMinutesController;
  late TextEditingController _tagsController;
  late int _selectedQuadrant;
  DateTime? _dueDate;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTask?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingTask?.description ?? '');
    _estimatedMinutesController = TextEditingController(text: widget.existingTask?.estimatedMinutes.toString() ?? '30');
    _tagsController = TextEditingController(text: widget.existingTask?.tags.join(', ') ?? '');
    _selectedQuadrant = widget.existingTask?.quadrant ?? 1;
    _dueDate = widget.existingTask?.dueDate;
    _tags = widget.existingTask?.tags ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedMinutesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingTask == null ? 'Добавить задачу' : 'Редактировать задачу'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название задачи',
                  hintText: 'Введите название задачи',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Введите описание задачи',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _selectedQuadrant,
                decoration: const InputDecoration(labelText: 'Квадрант'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 - Срочно и важно')),
                  DropdownMenuItem(value: 2, child: Text('2 - Не срочно, но важно')),
                  DropdownMenuItem(value: 3, child: Text('3 - Срочно, но не важно')),
                  DropdownMenuItem(value: 4, child: Text('4 - Не срочно и не важно')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedQuadrant = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Срок выполнения'),
                subtitle: Text(_dueDate != null 
                    ? '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}'
                    : 'Не указан'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDueDate,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _estimatedMinutesController,
                decoration: const InputDecoration(
                  labelText: 'Оценка времени (минуты)',
                  hintText: 'Введите оценку времени',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Теги',
                  hintText: 'Введите теги через запятую',
                ),
                onChanged: (value) {
                  _tags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название задачи')),
      );
      return;
    }

    final task = EisenhowerTask(
      id: widget.existingTask?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      quadrant: _selectedQuadrant,
      dueDate: _dueDate,
      isCompleted: widget.existingTask?.isCompleted ?? false,
      estimatedMinutes: int.tryParse(_estimatedMinutesController.text) ?? 30,
      tags: _tags,
      createdAt: widget.existingTask?.createdAt ?? DateTime.now(),
    );

    widget.onSave(task);
    Navigator.pop(context);
  }
}