import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/zato_statement.dart';
import '../../services/emotions_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

class ZatoScreen extends StatefulWidget {
  const ZatoScreen({super.key});

  @override
  State<ZatoScreen> createState() => _ZatoScreenState();
}

class _ZatoScreenState extends State<ZatoScreen> {
  final EmotionsService _service = EmotionsService();
  final GamificationService _gamificationService = GamificationService();
  List<ZatoStatement> _statements = [];

  @override
  void initState() {
    super.initState();
    _loadStatements();
  }

  Future<void> _loadStatements() async {
    final statements = await _service.getZatoStatements();
    setState(() {
      _statements = statements;
    });
  }

  Future<void> _showAddDialog({ZatoStatement? statement}) async {
    final negativeController = TextEditingController(
      text: statement?.negativeStatement ?? '',
    );
    final positiveController = TextEditingController(
      text: statement?.positiveStatement ?? '',
    );
    String? selectedTemplate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                      statement == null
                          ? 'Новая трансформация'
                          : 'Редактировать',
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
                      if (statement == null) ...[
                        Text(
                          'Шаблоны негативных мыслей',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: ZatoStatement.templates.length,
                            itemBuilder: (context, index) {
                              final template = ZatoStatement.templates[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade100,
                                        Colors.red.shade50,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        setModalState(() {
                                          negativeController.text = template;
                                          selectedTemplate = template;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          template.length > 22
                                              ? '${template.substring(0, 22)}...'
                                              : template,
                                          style: GoogleFonts.nunito(
                                            fontSize: 11,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        'Негативное утверждение',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: negativeController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Я не справлюсь...',
                          hintStyle: GoogleFonts.nunito(
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.red.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Подсказки для трансформации',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ZatoStatement.hints.map((hint) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accentColor.withValues(alpha: 0.15),
                                  AppTheme.accentColor.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.accentColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  setModalState(() {
                                    positiveController.text = hint;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    hint.length > 28
                                        ? '${hint.substring(0, 28)}...'
                                        : hint,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: AppTheme.accentColor,
                                      fontWeight: FontWeight.w500,
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
                        'Утверждение «ЗАТО»',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: positiveController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Да, это сложно, ЗАТО я научусь...',
                          hintStyle: GoogleFonts.nunito(
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: AppTheme.accentColor.withValues(
                            alpha: 0.1,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
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
                      if (negativeController.text.isEmpty ||
                          positiveController.text.isEmpty)
                        return;

                      final newStatement = statement != null
                          ? statement.copyWith(
                              negativeStatement: negativeController.text,
                              positiveStatement: positiveController.text,
                            )
                          : ZatoStatement.create(
                              negativeStatement: negativeController.text,
                              positiveStatement: positiveController.text,
                            );

                      if (statement != null) {
                        await _service.updateZatoStatement(newStatement);
                      } else {
                        await _service.addZatoStatement(newStatement);
                        await _gamificationService.addZato();
                      }

                      await _loadStatements();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      statement == null ? 'Добавить' : 'Сохранить',
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

  @override
  Widget build(BuildContext context) {
    final starredCount = _service.getStarredCount(_statements);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.accentColor.withValues(alpha: 0.1),
              const Color(0xFFE8F5E9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(starredCount),
              const SizedBox(height: 16),
              Expanded(
                child: _statements.isEmpty
                    ? _buildEmptyState()
                    : _buildStatementsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.accentColor, AppTheme.secondaryColor],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.4),
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

  Widget _buildHeader(int starredCount) {
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
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
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
                  'Техника ЗАТО',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_statements.length} трансформаций • $starredCount сработали',
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
          Icon(Icons.transform_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Нет трансформаций',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Превратите негатив в позитив',
            style: GoogleFonts.nunito(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementsList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statements.length,
        itemBuilder: (context, index) {
          final statement = _statements[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 20,
              child: FadeInAnimation(child: _buildStatementCard(statement)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatementCard(ZatoStatement statement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.close, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statement.negativeStatement,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    statement.isStarred ? Icons.star : Icons.star_border,
                    color: statement.isStarred ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () async {
                    await _service.toggleZatoStarred(statement.id);
                    await _loadStatements();
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statement.positiveStatement,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () => _showAddDialog(statement: statement),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade300,
                    size: 20,
                  ),
                  onPressed: () async {
                    await _service.deleteZatoStatement(statement.id);
                    await _loadStatements();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
