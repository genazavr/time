import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _service = SettingsService();
  UserSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.getSettings();
    setState(() => _settings = settings);
  }

  Future<void> _updateSettings(UserSettings newSettings) async {
    await _service.saveSettings(newSettings);
    setState(() => _settings = newSettings);
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null)
      return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('🍅 Помодоро', [
                        _buildSliderTile(
                          'Длительность работы',
                          _settings!.pomodoroMinutes,
                          5,
                          60,
                          (v) => _updateSettings(
                            _settings!.copyWith(pomodoroMinutes: v.toInt()),
                          ),
                        ),
                        _buildSliderTile(
                          'Короткий перерыв',
                          _settings!.shortBreakMinutes,
                          1,
                          15,
                          (v) => _updateSettings(
                            _settings!.copyWith(shortBreakMinutes: v.toInt()),
                          ),
                        ),
                        _buildSliderTile(
                          'Длинный перерыв',
                          _settings!.longBreakMinutes,
                          10,
                          30,
                          (v) => _updateSettings(
                            _settings!.copyWith(longBreakMinutes: v.toInt()),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildSection('🔔 Напоминания', [
                        _buildSwitchTile(
                          'Уведомления',
                          'Получать напоминания',
                          _settings!.notificationsEnabled,
                          (v) => _updateSettings(
                            _settings!.copyWith(notificationsEnabled: v),
                          ),
                        ),
                        if (_settings!.notificationsEnabled)
                          _buildTimeTile(
                            'Время напоминания',
                            _settings!.reminderHour,
                            _settings!.reminderMinute,
                          ),
                      ]),
                      const SizedBox(height: 20),
                      _buildSection('🎨 Внешний вид', [
                        _buildSwitchTile(
                          'Тёмная тема',
                          'Использовать тёмную тему',
                          _settings!.darkMode,
                          (v) =>
                              _updateSettings(_settings!.copyWith(darkMode: v)),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildSection('ℹ️ О приложении', [
                        _buildInfoTile('Версия', '1.0.0'),
                        _buildInfoTile('Разработчик', 'BLISS Team'),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Настройки',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSliderTile(
    String title,
    int value,
    int min,
    int max,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.nunito(fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$value мин',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            activeColor: AppTheme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Switch(
        value: value,
        activeColor: AppTheme.primaryColor,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTimeTile(String title, int hour, int minute) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
      ),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );
        if (time != null) {
          _updateSettings(
            _settings!.copyWith(
              reminderHour: time.hour,
              reminderMinute: time.minute,
            ),
          );
        }
      },
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.nunito(color: Colors.grey.shade600),
      ),
    );
  }
}
