import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../../models/schedule.dart';
import '../../services/schedule_service.dart';
import '../../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  List<Schedule> _schedules = [];
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() {
    _scheduleService.getSchedules().listen((schedules) {
      setState(() {
        _schedules = schedules;
      });
    });
  }

  List<Schedule> get _schedulesForDay {
    return _schedules.where((schedule) {
      final scheduleDate = DateTime(schedule.startTime.year, schedule.startTime.month, schedule.startTime.day);
      final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      return scheduleDate.isAtSameMomentAs(selectedDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _schedulesForDay.isEmpty
                ? _buildEmptyState()
                : _buildScheduleList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDay = _selectedDay.subtract(const Duration(days: 1));
              });
            },
          ),
          Expanded(
            child: Text(
              DateFormat('EEEE, d MMMM y', 'ru_RU').format(_selectedDay),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDay = _selectedDay.add(const Duration(days: 1));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет занятий на этот день',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите + чтобы добавить расписание',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    final sortedSchedules = List.from(_schedulesForDay)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSchedules.length,
      itemBuilder: (context, index) {
        final schedule = sortedSchedules[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildScheduleCard(schedule),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showScheduleDetails(schedule),
        onLongPress: () => _showScheduleActions(schedule),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: _getSubjectColor(schedule.subject),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.subject,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getSubjectColor(schedule.subject),
                      ),
                    ),
                    if (schedule.lessonTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        schedule.lessonTitle!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                    if (schedule.teacherName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        schedule.teacherName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormat('HH:mm').format(schedule.startTime)} - ${DateFormat('HH:mm').format(schedule.endTime)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (schedule.classroom != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.room,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.classroom!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditScheduleDialog(schedule);
                      break;
                    case 'delete':
                      _deleteSchedule(schedule);
                      break;
                  }
                },
                itemBuilder: (context) => [
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _selectedDay = date;
      });
    }
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AddScheduleDialog(
        selectedDay: _selectedDay,
        onSave: (schedule) async {
          await _scheduleService.addSchedule(schedule);
        },
      ),
    );
  }

  void _showEditScheduleDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AddScheduleDialog(
        selectedDay: _selectedDay,
        existingSchedule: schedule,
        onSave: (updatedSchedule) async {
          await _scheduleService.updateSchedule(updatedSchedule);
        },
      ),
    );
  }

  void _showScheduleDetails(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.subject),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (schedule.lessonTitle != null) ...[
              Text(schedule.lessonTitle!),
              const SizedBox(height: 16),
            ],
            Text('Преподаватель: ${schedule.teacherName ?? 'Не указан'}'),
            const SizedBox(height: 8),
            Text('Время: ${DateFormat('HH:mm').format(schedule.startTime)} - ${DateFormat('HH:mm').format(schedule.endTime)}'),
            const SizedBox(height: 8),
            Text('Аудитория: ${schedule.classroom ?? 'Не указана'}'),
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

  void _showScheduleActions(Schedule schedule) {
    _showScheduleDetails(schedule);
  }

  void _deleteSchedule(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить занятие?'),
        content: const Text('Вы уверены, что хотите удалить это занятие из расписания?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await _scheduleService.deleteSchedule(schedule.id);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddScheduleDialog extends StatefulWidget {
  final DateTime selectedDay;
  final Schedule? existingSchedule;
  final Function(Schedule) onSave;

  const AddScheduleDialog({
    super.key,
    required this.selectedDay,
    this.existingSchedule,
    required this.onSave,
  });

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  late TextEditingController _subjectController;
  late TextEditingController _lessonTitleController;
  late TextEditingController _teacherController;
  late TextEditingController _classroomController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final schedule = widget.existingSchedule;
    _subjectController = TextEditingController(text: schedule?.subject ?? '');
    _lessonTitleController = TextEditingController(text: schedule?.lessonTitle ?? '');
    _teacherController = TextEditingController(text: schedule?.teacherName ?? '');
    _classroomController = TextEditingController(text: schedule?.classroom ?? '');
    _startTime = schedule != null 
        ? TimeOfDay.fromDateTime(schedule.startTime)
        : const TimeOfDay(hour: 9, minute: 0);
    _endTime = schedule != null 
        ? TimeOfDay.fromDateTime(schedule.endTime)
        : const TimeOfDay(hour: 10, minute: 30);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _lessonTitleController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingSchedule == null ? 'Добавить занятие' : 'Редактировать занятие'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Предмет',
                  hintText: 'Введите название предмета',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lessonTitleController,
                decoration: const InputDecoration(
                  labelText: 'Тема урока',
                  hintText: 'Введите тему урока',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _teacherController,
                decoration: const InputDecoration(
                  labelText: 'Преподаватель',
                  hintText: 'Введите имя преподавателя',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _classroomController,
                decoration: const InputDecoration(
                  labelText: 'Аудитория',
                  hintText: 'Введите номер аудитории',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Начало'),
                subtitle: Text(_startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: _selectStartTime,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Окончание'),
                subtitle: Text(_endTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: _selectEndTime,
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
          onPressed: _saveSchedule,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  void _saveSchedule() {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название предмета')),
      );
      return;
    }

    final startDateTime = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Время окончания должно быть позже времени начала')),
      );
      return;
    }

    final schedule = Schedule(
      id: widget.existingSchedule?.id ?? '',
      subject: _subjectController.text.trim(),
      lessonTitle: _lessonTitleController.text.trim().isEmpty 
          ? null 
          : _lessonTitleController.text.trim(),
      teacherName: _teacherController.text.trim().isEmpty 
          ? null 
          : _teacherController.text.trim(),
      classroom: _classroomController.text.trim().isEmpty 
          ? null 
          : _classroomController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      createdAt: widget.existingSchedule?.createdAt ?? DateTime.now(),
    );

    widget.onSave(schedule);
    Navigator.pop(context);
  }
}