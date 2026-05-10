import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/control_sphere.dart';
import '../../services/emotions_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

class ControlSphereScreen extends StatefulWidget {
  const ControlSphereScreen({super.key});

  @override
  State<ControlSphereScreen> createState() => _ControlSphereScreenState();
}

class _ControlSphereScreenState extends State<ControlSphereScreen> {
  final EmotionsService _service = EmotionsService();
  final GamificationService _gamificationService = GamificationService();
  List<ControlSphere> _spheres = [];
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    _loadSpheres();
  }

  Future<void> _loadSpheres() async {
    final spheres = await _service.getControlSpheres();
    setState(() {
      _spheres = spheres;
    });
  }

  List<ControlSphere> get _filteredSpheres {
    if (_selectedTag == null) return _spheres;
    return _spheres.where((s) => s.tag == _selectedTag).toList();
  }

  Future<void> _showAddDialog({ControlSphere? sphere}) async {
    final situationController = TextEditingController(
      text: sphere?.situation ?? '',
    );
    final emotionsController = TextEditingController(
      text: sphere?.emotions ?? '',
    );
    final actionController = TextEditingController(
      text: sphere?.controlAction ?? '',
    );
    String selectedTag = sphere?.tag ?? 'Другое';
    bool isControllable = sphere?.isControllable ?? true;
    List<String> checkboxes = List.from(sphere?.controlCheckboxes ?? []);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sphere == null ? 'Новая ситуация' : 'Редактировать',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ситуация',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: situationController,
                        maxLines: 2,
                        decoration: _inputDecoration('Опишите ситуацию...'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Что вызывает переживания?',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emotionsController,
                        maxLines: 3,
                        decoration: _inputDecoration('Что вы чувствуете?'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Категория',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ControlSphere.availableTags.map((tag) {
                          final isSelected = tag == selectedTag;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.secondaryColor,
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? null
                                  : Border.all(color: Colors.grey.shade300),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    setModalState(() => selectedTag = tag),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.nunito(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Это в моем контроле?',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => isControllable = true),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isControllable
                                      ? AppTheme.accentColor.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isControllable
                                        ? AppTheme.accentColor
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: isControllable
                                          ? AppTheme.accentColor
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Да',
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => isControllable = false),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: !isControllable
                                      ? Colors.red.shade50
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !isControllable
                                        ? Colors.red.shade300
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      color: !isControllable
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Нет',
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (isControllable) ...[
                        Text(
                          'Что я могу контролировать?',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: actionController,
                          maxLines: 2,
                          decoration: _inputDecoration(
                            'Конкретные действия...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              [
                                'Принять ситуацию',
                                'Изменить реакцию',
                                'Попросить помощи',
                                'Сделать паузу',
                                'Найти решение',
                                'Обратиться к специалисту',
                              ].map((item) {
                                final isChecked = checkboxes.contains(item);
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: isChecked
                                        ? LinearGradient(
                                            colors: [
                                              AppTheme.accentColor,
                                              AppTheme.accentColor.withValues(
                                                alpha: 0.7,
                                              ),
                                            ],
                                          )
                                        : null,
                                    color: isChecked
                                        ? null
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isChecked
                                        ? null
                                        : Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        setModalState(() {
                                          if (isChecked) {
                                            checkboxes.remove(item);
                                          } else {
                                            checkboxes.add(item);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isChecked
                                                  ? Icons.check_circle
                                                  : Icons.circle_outlined,
                                              size: 16,
                                              color: isChecked
                                                  ? Colors.white
                                                  : Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              item,
                                              style: GoogleFonts.nunito(
                                                fontSize: 12,
                                                color: isChecked
                                                    ? Colors.white
                                                    : Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                      if (!isControllable) ...[
                        Text(
                          'Как принять неконтролируемое?',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: actionController,
                          maxLines: 2,
                          decoration: _inputDecoration(
                            'Техники: дыхание, медитация, отпустить...',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (situationController.text.isEmpty) return;

                      final newSphere = sphere != null
                          ? sphere.copyWith(
                              situation: situationController.text,
                              emotions: emotionsController.text,
                              controlAction: actionController.text,
                              controlCheckboxes: checkboxes,
                              tag: selectedTag,
                              isControllable: isControllable,
                            )
                          : ControlSphere.create(
                              situation: situationController.text,
                              emotions: emotionsController.text,
                              controlAction: actionController.text,
                              controlCheckboxes: checkboxes,
                              tag: selectedTag,
                              isControllable: isControllable,
                            );

                      if (sphere != null) {
                        await _service.updateControlSphere(newSphere);
                      } else {
                        await _service.addControlSphere(newSphere);
                        await _gamificationService.addControlSphere();
                      }

                      await _loadSpheres();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      sphere == null ? 'Добавить' : 'Сохранить',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildTagFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip('Все', null),
          ...ControlSphere.availableTags.map((tag) => _filterChip(tag, tag)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final isSelected = _selectedTag == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _selectedTag = value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              const Color(0xFFE8EAF6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTagFilter(),
              const SizedBox(height: 16),
              Expanded(
                child: _filteredSpheres.isEmpty
                    ? _buildEmptyState()
                    : _buildSpheresList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final stats = _service.getControlSphereStats(_spheres);
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
              Icons.pie_chart_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сферы контроля',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${stats['total'] ?? 0} записей • ${stats['controllable'] ?? 0} под контролем',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
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
            Icons.psychology_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет записей',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте ситуацию для анализа',
            style: GoogleFonts.nunito(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSpheresList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredSpheres.length,
        itemBuilder: (context, index) {
          final sphere = _filteredSpheres[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 20,
              child: FadeInAnimation(child: _buildSphereCard(sphere)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSphereCard(ControlSphere sphere) {
    final isControllable = sphere.isControllable;
    final color = isControllable ? AppTheme.accentColor : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isControllable ? Icons.check_circle : Icons.cancel,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sphere.tag,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => _showAddDialog(sphere: sphere),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red.shade300,
                  ),
                  onPressed: () async {
                    await _service.deleteControlSphere(sphere.id);
                    await _loadSpheres();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ситуация',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(sphere.situation, style: GoogleFonts.nunito(fontSize: 14)),
                const SizedBox(height: 12),
                Text(
                  'Переживания',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(sphere.emotions, style: GoogleFonts.nunito(fontSize: 14)),
                const SizedBox(height: 12),
                Text(
                  isControllable ? 'Контроль' : 'Принятие',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sphere.controlAction.isEmpty ? '—' : sphere.controlAction,
                  style: GoogleFonts.nunito(fontSize: 14),
                ),
                if (sphere.controlCheckboxes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sphere.controlCheckboxes
                        .map(
                          (cb) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: AppTheme.accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cb,
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
