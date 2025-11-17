import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/pomodoro_session.dart';
import '../../services/pomodoro_service.dart';
import '../../theme/app_theme.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with TickerProviderStateMixin {
  final PomodoroService _pomodoroService = PomodoroService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isPaused = false;
  String _currentType = 'work';
  String _currentTask = '';
  int _sessionsCompleted = 0;
  int _currentSessionInCycle = 1;
  
  PomodoroSettings _settings = PomodoroSettings();
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
    _loadStatistics();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadSettings() async {
    final settings = await _pomodoroService.getSettings();
    setState(() {
      _settings = settings;
      _updateTimerDuration();
    });
  }

  Future<void> _loadStatistics() async {
    final stats = await _pomodoroService.getStatistics();
    setState(() {
      _statistics = stats;
      _sessionsCompleted = stats['todaySessions'] ?? 0;
    });
  }

  void _updateTimerDuration() {
    switch (_currentType) {
      case 'work':
        _totalSeconds = _settings.workDuration * 60;
        break;
      case 'short_break':
        _totalSeconds = _settings.shortBreakDuration * 60;
        break;
      case 'long_break':
        _totalSeconds = _settings.longBreakDuration * 60;
        break;
    }
    _remainingSeconds = _isRunning ? _remainingSeconds : _totalSeconds;
    _updateProgressAnimation();
  }

  void _updateProgressAnimation() {
    _progressController.duration = Duration(seconds: _totalSeconds);
    if (!_isRunning) {
      _progressController.reset();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() async {
    if (_isRunning && !_isPaused) return;
    
    if (_isPaused) {
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });
      _pulseController.repeat(reverse: true);
      _progressController.forward();
    } else {
      final session = PomodoroSession(
        id: '',
        startTime: DateTime.now(),
        duration: _totalSeconds ~/ 60,
        type: _currentType,
        taskTitle: _currentTask.isEmpty ? null : _currentTask,
        createdAt: DateTime.now(),
      );
      
      await _pomodoroService.startSession(session);
      
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });
      
      _pulseController.repeat(reverse: true);
      _progressController.forward(from: _progressController.value);
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _progressController.stop();
    
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.reset();
    _progressController.reset();
    
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _completeSession() async {
    _timer?.cancel();
    _pulseController.stop();
    _progressController.stop();
    
    if (_settings.soundEnabled) {
      await _playCompletionSound();
    }
    
    setState(() {
      _isRunning = false;
      _isPaused = false;
      if (_currentType == 'work') {
        _sessionsCompleted++;
        _currentSessionInCycle++;
      }
    });
    
    _showCompletionDialog();
    _loadStatistics();
  }

  Future<void> _playCompletionSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/bell.mp3');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _showCompletionDialog() {
    String nextType;
    String title;
    String message;
    
    if (_currentType == 'work') {
      if (_currentSessionInCycle >= _settings.longBreakInterval) {
        nextType = 'long_break';
        title = 'Сессия завершена!';
        message = 'Отличная работа! Время для длинного перерыва.';
        _currentSessionInCycle = 1;
      } else {
        nextType = 'short_break';
        title = 'Сессия завершена!';
        message = 'Отличная работа! Время для короткого перерыва.';
      }
    } else {
      nextType = 'work';
      title = 'Перерыв завершен!';
      message = 'Отдохнули? Время для новой рабочей сессии!';
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _currentType == 'work' ? Icons.check_circle : Icons.local_cafe,
              size: 64,
              color: AppTheme.accentColor,
            ),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _switchToType(nextType);
            },
            child: Text(_currentType == 'work' ? 'Начать перерыв' : 'Начать работу'),
          ),
          if (_settings.autoStartBreaks || _settings.autoStartWork)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _switchToType(nextType);
                if ((_currentType == 'work' && _settings.autoStartBreaks) ||
                    (_currentType != 'work' && _settings.autoStartWork)) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _startTimer();
                  });
                }
              },
              child: const Text('Автозапуск'),
            ),
        ],
      ),
    );
  }

  void _switchToType(String type) {
    setState(() {
      _currentType = type;
      _updateTimerDuration();
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getTypeTitle() {
    switch (_currentType) {
      case 'work':
        return 'Рабочая сессия';
      case 'short_break':
        return 'Короткий перерыв';
      case 'long_break':
        return 'Длинный перерыв';
      default:
        return '';
    }
  }

  Color _getTypeColor() {
    switch (_currentType) {
      case 'work':
        return AppTheme.primaryColor;
      case 'short_break':
        return AppTheme.accentColor;
      case 'long_break':
        return AppTheme.secondaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Помодоро таймер'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCards(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTypeSelector(),
                const SizedBox(height: 40),
                _buildTimer(),
                const SizedBox(height: 40),
                _buildControls(),
                const SizedBox(height: 20),
                _buildTaskInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Сегодня',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${_statistics['todaySessions'] ?? 0}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'сессий',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Фокус',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${(_statistics['todayFocusTime'] ?? 0)} мин',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'сегодня',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Всего',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$_sessionsCompleted',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'завершено',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTypeButton('work', 'Работа', Icons.work),
        _buildTypeButton('short_break', 'Короткий', Icons.coffee),
        _buildTypeButton('long_break', 'Длинный', Icons.beach_access),
      ],
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon) {
    final isSelected = _currentType == type;
    return GestureDetector(
      onTap: _isRunning ? null : () => _switchToType(type),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _getTypeColor() : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getTypeColor(),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : _getTypeColor(),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _getTypeColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _progressController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isRunning ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getTypeColor().withValues(alpha: 0.1),
                    border: Border.all(
                      color: _getTypeColor(),
                      width: 8,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getTypeTitle(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _getTypeColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: _getTypeColor(),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isRunning && !_isPaused)
          ElevatedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Старт'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getTypeColor(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        if (_isRunning)
          ElevatedButton.icon(
            onPressed: _pauseTimer,
            icon: const Icon(Icons.pause),
            label: const Text('Пауза'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        if (_isPaused)
          ElevatedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Продолжить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getTypeColor(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        const SizedBox(width: 16),
        if (_isRunning || _isPaused)
          OutlinedButton.icon(
            onPressed: _resetTimer,
            icon: const Icon(Icons.refresh),
            label: const Text('Сброс'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: TextField(
        onChanged: (value) {
          _currentTask = value;
        },
        decoration: InputDecoration(
          labelText: 'Текущая задача',
          hintText: 'Что вы делаете сейчас?',
          prefixIcon: const Icon(Icons.task),
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки Помодоро'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Рабочая сессия'),
                trailing: Text('${_settings.workDuration} мин'),
                onTap: () => _showDurationDialog('workDuration'),
              ),
              ListTile(
                title: const Text('Короткий перерыв'),
                trailing: Text('${_settings.shortBreakDuration} мин'),
                onTap: () => _showDurationDialog('shortBreakDuration'),
              ),
              ListTile(
                title: const Text('Длинный перерыв'),
                trailing: Text('${_settings.longBreakDuration} мин'),
                onTap: () => _showDurationDialog('longBreakDuration'),
              ),
              SwitchListTile(
                title: const Text('Автозапуск перерывов'),
                value: _settings.autoStartBreaks,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(autoStartBreaks: value);
                  });
                  _pomodoroService.updateSettings(_settings);
                },
              ),
              SwitchListTile(
                title: const Text('Автозапуск работы'),
                value: _settings.autoStartWork,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(autoStartWork: value);
                  });
                  _pomodoroService.updateSettings(_settings);
                },
              ),
              SwitchListTile(
                title: const Text('Звуковые уведомления'),
                value: _settings.soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(soundEnabled: value);
                  });
                  _pomodoroService.updateSettings(_settings);
                },
              ),
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

  void _showDurationDialog(String setting) {
    int currentValue;
    String title;
    
    switch (setting) {
      case 'workDuration':
        currentValue = _settings.workDuration;
        title = 'Рабочая сессия';
        break;
      case 'shortBreakDuration':
        currentValue = _settings.shortBreakDuration;
        title = 'Короткий перерыв';
        break;
      case 'longBreakDuration':
        currentValue = _settings.longBreakDuration;
        title = 'Длинный перерыв';
        break;
      default:
        return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$currentValue минут'),
            Slider(
              value: currentValue.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              onChanged: (value) {
                currentValue = value.round();
                setState(() {});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              switch (setting) {
                case 'workDuration':
                  _settings = _settings.copyWith(workDuration: currentValue);
                  break;
                case 'shortBreakDuration':
                  _settings = _settings.copyWith(shortBreakDuration: currentValue);
                  break;
                case 'longBreakDuration':
                  _settings = _settings.copyWith(longBreakDuration: currentValue);
                  break;
              }
              _pomodoroService.updateSettings(_settings);
              _updateTimerDuration();
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сегодня: ${_statistics['todaySessions'] ?? 0} сессий'),
            Text('Фокус сегодня: ${_statistics['todayFocusTime'] ?? 0} минут'),
            Text('За неделю: ${_statistics['weekSessions'] ?? 0} сессий'),
            Text('Фокус за неделю: ${_statistics['weekFocusTime'] ?? 0} минут'),
            Text('Всего сессий: ${_statistics['totalSessions'] ?? 0}'),
            Text('Общий фокус: ${_statistics['totalFocusTime'] ?? 0} минут'),
            Text('Статус завершения: ${_statistics['completionRate'] ?? 0}%'),
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