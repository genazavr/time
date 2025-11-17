import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/note.dart';
import '../../services/note_service.dart';
import '../../theme/app_theme.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();
  List<Note> _notes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    _noteService.getNotes().listen((notes) {
      setState(() {
        _notes = notes;
      });
    });
  }

  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    return _notes.where((note) =>
        note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (note.content?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty) _buildSearchBar(),
          Expanded(
            child: _filteredNotes.isEmpty
                ? _buildEmptyState()
                : _buildNotesGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Поиск заметок...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
            },
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Заметки не найдены' : 'Нет заметок',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Нажмите + чтобы создать первую заметку',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimationLimiter(
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: _filteredNotes.length,
          itemBuilder: (context, index) {
            final note = _filteredNotes[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: _buildNoteCard(note),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.warningColor,
      Colors.purple,
      Colors.teal,
    ];
    final color = colors[note.title.hashCode % colors.length];

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showNoteDetails(note),
        onLongPress: () => _showNoteActions(note),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditNoteDialog(note);
                          break;
                        case 'delete':
                          _deleteNote(note);
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
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.content ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(note.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);
    
    if (noteDate.isAtSameMomentAs(today)) {
      return 'Сегодня';
    } else if (noteDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Вчера';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  void _toggleSearch() {
    setState(() {
      _searchQuery = _searchQuery.isEmpty ? '' : '';
    });
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        onSave: (note) async {
          await _noteService.addNote(note);
        },
      ),
    );
  }

  void _showEditNoteDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        existingNote: note,
        onSave: (updatedNote) async {
          await _noteService.updateNote(updatedNote);
        },
      ),
    );
  }

  void _showNoteDetails(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.title),
        content: SingleChildScrollView(
          child: Text(note.content ?? ''),
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

  void _showNoteActions(Note note) {
    _showNoteDetails(note);
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: const Text('Вы уверены, что хотите удалить эту заметку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await _noteService.deleteNote(note.id);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddNoteDialog extends StatefulWidget {
  final Note? existingNote;
  final Function(Note) onSave;

  const AddNoteDialog({
    super.key,
    this.existingNote,
    required this.onSave,
  });

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingNote == null ? 'Добавить заметку' : 'Редактировать заметку'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Заголовок',
                hintText: 'Введите заголовок заметки',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Содержание',
                hintText: 'Введите содержание заметки',
              ),
              maxLines: 8,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveNote,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _saveNote() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите заголовок заметки')),
      );
      return;
    }

    final note = Note(
      id: widget.existingNote?.id ?? '',
      title: _titleController.text.trim(),
      content: _contentController.text.trim().isEmpty 
          ? null 
          : _contentController.text.trim(),
      createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
    );

    widget.onSave(note);
    Navigator.pop(context);
  }
}