import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../../models/homework.dart';
import '../../services/homework_service.dart';
import '../../theme/app_theme.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> with TickerProviderStateMixin {
  final HomeworkService _homeworkService = HomeworkService();
  List<Homework> _homework = [];
  List<Homework> _filteredHomework = [];
  String _selectedFilter = 'all';
  String _selectedSubject = 'all';
  List<String> _subjects = [];
  late TabController _tabController;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHomework();
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadHomework() {
    _homeworkService.getHomework().listen((homework) {
      setState(() {
        _homework = homework;
        _subjects = _extractSubjects(homework);
        _applyFilters();
      });
    });
  }

  Future<void> _loadStatistics() async {
    final stats = await _homeworkService.getStatistics();
    setState(() {
      _statistics = stats;
    });
  }

  List<String> _extractSubjects(List<Homework> homework) {
    final subjects = homework.map((h) => h.subject).toSet().toList();
    subjects.sort();
    return subjects;
  }

  void _applyFilters() {
    List<Homework> filtered = List.from(_homework);

    // Применяем фильтр по статусу
    switch (_selectedFilter) {
      case 'pending':
        filtered = filtered.where((h) => !h.isCompleted).toList();
        break;
      case 'completed':
        filtered = filtered.where((h) => h.isCompleted).toList();
        break;
      case 'overdue':
        filtered = filtered.where((h) => h.isOverdue && !h.isCompleted).toList();
        break;
      case 'today':
        filtered = filtered.where((h) => h.isDueToday && !h.isCompleted).toList();
        break;
      case 'soon':
        filtered = filtered.where((h) => h.isDueSoon && !h.isCompleted).toList();
        break;
    }

    // Применяем фильтр по предмету
    if (_selectedSubject != 'all') {
      filtered = filtered.where((h) => h.subject == _selectedSubject).toList();
    }

    setState(() {
      _filteredHomework = filtered;
    });
  }

  List<Homework> _getHomeworkForTab(int index) {
    switch (index) {
      case 0: // Активные
        return _homework.where((h) => !h.isCompleted).toList();
      case 1: // Сегодня
        return _homework.where((h) => h.isDueToday).toList();
      case 2: // Завершенные
        return _homework.where((h) => h.isCompleted).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Домашние задания'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Активные'),
            Tab(text: 'Сегодня'),
            Tab(text: 'Завершено'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatisticsDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
              _applyFilters();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Все')),
              const PopupMenuItem(value: 'pending', child: Text('Невыполненные')),
              const PopupMenuItem(value: 'completed', child: Text('Выполненные')),
              const PopupMenuItem(value: 'overdue', child: Text('Просроченные')),
              const PopupMenuItem(value: 'today', child: Text('На сегодня')),
              const PopupMenuItem(value: 'soon', child: Text('Скоро')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSubjectFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeworkList(_getHomeworkForTab(0)),
                _buildHomeworkList(_getHomeworkForTab(1)),
                _buildHomeworkList(_getHomeworkForTab(2)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHomeworkDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _subjects.length + 1,
        itemBuilder: (context, index) {
          final subject = index == 0 ? 'all' : _subjects[index - 1];
          final isSelected = _selectedSubject == subject;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(index == 0 ? 'Все предметы' : subject),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedSubject = subject;
                });
                _applyFilters();
              },
              backgroundColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeworkList(List<Homework> homework) {
    if (homework.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет домашних заданий',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: homework.length,
      itemBuilder: (context, index) {
        final item = homework[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildHomeworkCard(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeworkCard(Homework homework) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showHomeworkDetails(homework),
        onLongPress: () => _showHomeworkActions(homework),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      homework.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: homework.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Checkbox(
                    value: homework.isCompleted,
                    onChanged: (value) => _toggleHomeworkCompletion(homework),
                  ),
                ],
              ),
              if (homework.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  homework.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSubjectColor(homework.subject).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      homework.subject,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getSubjectColor(homework.subject),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(int.parse(homework.priorityColor.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      homework.priorityName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Color(int.parse(homework.priorityColor.replaceFirst('#', '0xFF'))),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: homework.isOverdue ? Colors.red : 
                           homework.isDueToday ? AppTheme.warningColor : 
                           Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd.MM').format(homework.dueDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: homework.isOverdue ? Colors.red : 
                             homework.isDueToday ? AppTheme.warningColor : 
                             Colors.grey.shade600,
                      fontWeight: homework.isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (homework.estimatedMinutes > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '~${homework.estimatedMinutes} минут',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (homework.teacherName != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        homework.teacherName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.warningColor,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    final index = subject.hashCode % colors.length;
    return colors[index];
  }

  void _showAddHomeworkDialog() {
    showDialog(
      context: context,
      builder: (context) => AddHomeworkDialog(
        subjects: _subjects,
        onSave: (homework) async {
          await _homeworkService.addHomework(homework);
          _loadStatistics();
        },
      ),
    );
  }

  void _showHomeworkDetails(Homework homework) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(homework.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (homework.description != null) ...[
                Text(homework.description!),
                const SizedBox(height: 16),
              ],
              Text('Предмет: ${homework.subject}'),
              const SizedBox(height: 8),
              Text('Приоритет: ${homework.priorityName}'),
              const SizedBox(height: 8),
              Text('Срок: ${DateFormat('dd.MM.yyyy HH:mm').format(homework.dueDate)}'),
              if (homework.estimatedMinutes > 0) ...[
                const SizedBox(height: 8),
                Text('Оценка времени: ${homework.estimatedMinutes} минут'),
              ],
              if (homework.teacherName != null) ...[
                const SizedBox(height: 8),
                Text('Учитель: ${homework.teacherName}'),
              ],
              if (homework.isCompleted && homework.completedAt != null) ...[
                const SizedBox(height: 8),
                Text('Выполнено: ${DateFormat('dd.MM.yyyy HH:mm').format(homework.completedAt!)}'),
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

  void _showHomeworkActions(Homework homework) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(homework.isCompleted ? Icons.undo : Icons.check_circle),
              title: Text(homework.isCompleted ? 'Отметить как невыполненное' : 'Отметить как выполненное'),
              onTap: () {
                Navigator.pop(context);
                _toggleHomeworkCompletion(homework);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(context);
                _showEditHomeworkDialog(homework);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteHomework(homework);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHomeworkDialog(Homework homework) {
    showDialog(
      context: context,
      builder: (context) => AddHomeworkDialog(
        subjects: _subjects,
        existingHomework: homework,
        onSave: (updatedHomework) async {
          await _homeworkService.updateHomework(updatedHomework);
          _loadStatistics();
        },
      ),
    );
  }

  void _toggleHomeworkCompletion(Homework homework) async {
    await _homeworkService.toggleHomeworkCompletion(homework.id);
    _loadStatistics();
  }

  void _deleteHomework(Homework homework) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить домашнее задание?'),
        content: const Text('Вы уверены, что хотите удалить это домашнее задание?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await _homeworkService.deleteHomework(homework.id);
              Navigator.pop(context);
              _loadStatistics();
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
            Text('Всего заданий: ${_statistics['total'] ?? 0}'),
            Text('Выполнено: ${_statistics['completed'] ?? 0}'),
            Text('Ожидает: ${_statistics['pending'] ?? 0}'),
            Text('Просрочено: ${_statistics['overdue'] ?? 0}'),
            Text('На сегодня: ${_statistics['dueToday'] ?? 0}'),
            Text('Скоро: ${_statistics['dueSoon'] ?? 0}'),
            Text('Процент выполнения: ${_statistics['completionRate'] ?? 0}%'),
            const SizedBox(height: 16),
            const Text('По предметам:'),
            ...[
              for (final entry in (_statistics['subjects'] as Map<String, dynamic>? ?? {}).entries)
                Text('  ${entry.key}: ${entry.value}'),
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

class AddHomeworkDialog extends StatefulWidget {
  final List<String> subjects;
  final Homework? existingHomework;
  final Function(Homework) onSave;

  const AddHomeworkDialog({
    super.key,
    required this.subjects,
    this.existingHomework,
    required this.onSave,
  });

  @override
  State<AddHomeworkDialog> createState() => _AddHomeworkDialogState();
}

class _AddHomeworkDialogState extends State<AddHomeworkDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _teacherController;
  late TextEditingController _estimatedMinutesController;
  late String _selectedSubject;
  late int _selectedPriority;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;

  @override
  void initState() {
    super.initState();
    final homework = widget.existingHomework;
    _titleController = TextEditingController(text: homework?.title ?? '');
    _descriptionController = TextEditingController(text: homework?.description ?? '');
    _teacherController = TextEditingController(text: homework?.teacherName ?? '');
    _estimatedMinutesController = TextEditingController(text: homework?.estimatedMinutes.toString() ?? '30');
    _selectedSubject = homework?.subject ?? (widget.subjects.isNotEmpty ? widget.subjects.first : '');
    _selectedPriority = homework?.priority ?? 1;
    _dueDate = homework?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _dueTime = TimeOfDay.fromDateTime(homework?.dueDate ?? DateTime.now().add(const Duration(days: 1)));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _teacherController.dispose();
    _estimatedMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingHomework == null ? 'Добавить домашнее задание' : 'Редактировать домашнее задание'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название задания',
                  hintText: 'Введите название задания',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Введите описание задания',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSubject.isEmpty ? null : _selectedSubject,
                decoration: const InputDecoration(labelText: 'Предмет'),
                items: widget.subjects.map((subject) {
                  return DropdownMenuItem(value: subject, child: Text(subject));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Приоритет'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Низкий')),
                  DropdownMenuItem(value: 1, child: Text('Средний')),
                  DropdownMenuItem(value: 2, child: Text('Высокий')),
                  DropdownMenuItem(value: 3, child: Text('Критический')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Срок выполнения'),
                subtitle: Text('${DateFormat('dd.MM.yyyy').format(_dueDate)} ${_dueTime.format(context)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _teacherController,
                decoration: const InputDecoration(
                  labelText: 'Учитель',
                  hintText: 'Имя учителя',
                ),
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
          onPressed: _saveHomework,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _dueTime,
      );
      if (time != null) {
        setState(() {
          _dueDate = date;
          _dueTime = time;
        });
      }
    }
  }

  void _saveHomework() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название задания')),
      );
      return;
    }

    if (_selectedSubject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите предмет')),
      );
      return;
    }

    final dueDateTime = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    final homework = Homework(
      id: widget.existingHomework?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      subject: _selectedSubject,
      dueDate: dueDateTime,
      priority: _selectedPriority,
      teacherName: _teacherController.text.trim().isEmpty 
          ? null 
          : _teacherController.text.trim(),
      estimatedMinutes: int.tryParse(_estimatedMinutesController.text) ?? 30,
      createdAt: widget.existingHomework?.createdAt ?? DateTime.now(),
    );

    widget.onSave(homework);
    Navigator.pop(context);
  }
}