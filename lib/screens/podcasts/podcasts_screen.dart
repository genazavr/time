import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/podcast.dart';
import '../../services/podcast_service.dart';
import '../../theme/app_theme.dart';

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  final PodcastService _podcastService = PodcastService();
  List<Podcast> _podcasts = [];
  List<String> _categories = [];
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
    _loadCategories();
  }

  void _loadPodcasts() {
    _podcastService.getPodcasts().listen((podcasts) {
      setState(() {
        _podcasts = podcasts;
      });
    });
  }

  Future<void> _loadCategories() async {
    final categories = await _podcastService.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  List<Podcast> get _filteredPodcasts {
    if (_selectedCategory == 'all') return _podcasts;
    return _podcasts.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подкасты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => _showFavoritePodcasts(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _filteredPodcasts.isEmpty
                ? _buildEmptyState()
                : _buildPodcastsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPodcastDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          final category = index == 0 ? 'all' : _categories[index - 1];
          final isSelected = _selectedCategory == category;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(index == 0 ? 'Все' : category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          );
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
            Icons.headphones_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет треков',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите + чтобы добавить трек',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPodcasts.length,
      itemBuilder: (context, index) {
        final podcast = _filteredPodcasts[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildPodcastCard(podcast),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPodcastCard(Podcast podcast) {
    IconData podcastIcon = _getIconData(podcast.iconName ?? 'headphones');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showPodcastDetails(podcast),
        onLongPress: () => _showPodcastActions(podcast),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: Icon(
                  podcastIcon,
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            podcast.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            podcast.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: podcast.isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(podcast),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      podcast.author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            podcast.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          podcast.durationText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.play_arrow,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${podcast.playCount}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPodcastDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPodcastDialog(
        categories: _categories,
        onSave: (podcast) async {
          await _podcastService.addPodcast(podcast);
        },
      ),
    );
  }

  void _showPodcastDetails(Podcast podcast) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(podcast.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIconData(podcast.iconName ?? 'headphones'), size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text('Автор: ${podcast.author}'),
              const SizedBox(height: 8),
              Text('Категория: ${podcast.category}'),
              const SizedBox(height: 8),
              Text('Длительность: ${podcast.durationText}'),
              const SizedBox(height: 8),
              Text('Прослушиваний: ${podcast.playCount}'),
              const SizedBox(height: 8),
              if (podcast.localAudioPath != null) ...[
                Text('Файл: ${podcast.localAudioPath!.split('/').last}'),
                const SizedBox(height: 8),
              ],
              if (podcast.description.isNotEmpty) ...[
                const Divider(),
                Text(podcast.description),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _playPodcast(podcast);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Слушать'),
          ),
        ],
      ),
    );
  }

  void _showPodcastActions(Podcast podcast) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(podcast.isFavorite ? Icons.favorite : Icons.favorite_border),
              title: Text(podcast.isFavorite ? 'Удалить из избранного' : 'Добавить в избранное'),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(podcast);
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Слушать'),
              onTap: () {
                Navigator.pop(context);
                _playPodcast(podcast);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(context);
                _showEditPodcastDialog(podcast);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deletePodcast(podcast);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPodcastDialog(Podcast podcast) {
    showDialog(
      context: context,
      builder: (context) => AddPodcastDialog(
        categories: _categories,
        existingPodcast: podcast,
        onSave: (updatedPodcast) async {
          await _podcastService.updatePodcast(updatedPodcast);
        },
      ),
    );
  }

  void _showFavoritePodcasts() async {
    final favorites = await _podcastService.getFavoritePodcasts().first;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Избранные треки'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: favorites.isEmpty
              ? const Center(child: Text('Нет избранных треков'))
              : ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final podcast = favorites[index];
                    return ListTile(
                      leading: Icon(_getIconData(podcast.iconName ?? 'headphones')),
                      title: Text(podcast.title),
                      subtitle: Text(podcast.author),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () {
                          _toggleFavorite(podcast);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _playPodcast(podcast);
                      },
                    );
                  },
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

  void _toggleFavorite(Podcast podcast) async {
    await _podcastService.toggleFavorite(podcast.id);
  }

  void _playPodcast(Podcast podcast) async {
    await _podcastService.incrementPlayCount(podcast.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Воспроизведение: ${podcast.title}')),
    );
  }

  void _deletePodcast(Podcast podcast) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить трек?'),
        content: const Text('Вы уверены, что хотите удалить этот трек?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await _podcastService.deletePodcast(podcast.id);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'music_note': return Icons.music_note;
      case 'album': return Icons.album;
      case 'library_music': return Icons.library_music;
      case 'audiotrack': return Icons.audiotrack;
      case 'mic': return Icons.mic;
      case 'radio': return Icons.radio;
      case 'podcast': return Icons.podcasts;
      case 'speaker': return Icons.speaker;
      case 'equalizer': return Icons.equalizer;
      case 'queue_music': return Icons.queue_music;
      default: return Icons.headphones;
    }
  }
}

class AddPodcastDialog extends StatefulWidget {
  final List<String> categories;
  final Podcast? existingPodcast;
  final Function(Podcast) onSave;

  const AddPodcastDialog({
    super.key,
    required this.categories,
    this.existingPodcast,
    required this.onSave,
  });

  @override
  State<AddPodcastDialog> createState() => _AddPodcastDialogState();
}

class _AddPodcastDialogState extends State<AddPodcastDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _authorController;
  late String _selectedCategory;
  late String _selectedIcon;
  late bool _isFavorite;
  String? _localAudioPath;
  String? _audioFileName;
  Duration? _audioDuration;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    final podcast = widget.existingPodcast;
    _titleController = TextEditingController(text: podcast?.title ?? '');
    _descriptionController = TextEditingController(text: podcast?.description ?? '');
    _authorController = TextEditingController(text: podcast?.author ?? '');
    _selectedCategory = podcast?.category ?? (widget.categories.isNotEmpty ? widget.categories.first : 'Музыка');
    _selectedIcon = podcast?.iconName ?? 'headphones';
    _isFavorite = podcast?.isFavorite ?? false;
    _localAudioPath = podcast?.localAudioPath;
    _audioDuration = podcast?.duration;
    if (_localAudioPath != null) {
      _audioFileName = _localAudioPath!.split('/').last;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        setState(() {
          _localAudioPath = path;
          _audioFileName = result.files.single.name;
        });

        await _audioPlayer.setFilePath(path);
        final duration = _audioPlayer.duration;
        if (duration != null) {
          setState(() {
            _audioDuration = duration;
          });
        }

        if (_titleController.text.isEmpty) {
          setState(() {
            _titleController.text = result.files.single.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе файла: $e')),
        );
      }
    }
  }

  void _showIconPicker() {
    final icons = {
      'headphones': Icons.headphones,
      'music_note': Icons.music_note,
      'album': Icons.album,
      'library_music': Icons.library_music,
      'audiotrack': Icons.audiotrack,
      'mic': Icons.mic,
      'radio': Icons.radio,
      'podcast': Icons.podcasts,
      'speaker': Icons.speaker,
      'equalizer': Icons.equalizer,
      'queue_music': Icons.queue_music,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите иконку'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final entry = icons.entries.elementAt(index);
              final isSelected = _selectedIcon == entry.key;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = entry.key;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primaryColor.withValues(alpha: 0.2) 
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected 
                        ? Border.all(color: AppTheme.primaryColor, width: 2) 
                        : null,
                  ),
                  child: Icon(
                    entry.value,
                    size: 32,
                    color: isSelected ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
              );
            },
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

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(_selectedIcon);
    
    return AlertDialog(
      title: Text(widget.existingPodcast == null ? 'Добавить трек' : 'Редактировать трек'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _pickAudioFile,
                icon: const Icon(Icons.audio_file),
                label: Text(_audioFileName ?? 'Выбрать аудио файл'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              if (_audioFileName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Файл: $_audioFileName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_audioDuration != null)
                  Text(
                    'Длительность: ${_audioDuration!.inMinutes}:${(_audioDuration!.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название трека',
                  hintText: 'Введите название',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Исполнитель',
                  hintText: 'Введите имя исполнителя',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Введите описание',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  prefixIcon: Icon(Icons.category),
                ),
                items: widget.categories.isNotEmpty
                    ? widget.categories.map((category) {
                        return DropdownMenuItem(value: category, child: Text(category));
                      }).toList()
                    : [
                        const DropdownMenuItem(value: 'Музыка', child: Text('Музыка')),
                        const DropdownMenuItem(value: 'Подкасты', child: Text('Подкасты')),
                        const DropdownMenuItem(value: 'Образование', child: Text('Образование')),
                      ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _showIconPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, color: AppTheme.primaryColor, size: 32),
                      const SizedBox(width: 16),
                      Text(
                        'Выбрать иконку',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isFavorite,
                onChanged: (value) {
                  setState(() {
                    _isFavorite = value;
                  });
                },
                title: const Text('Избранный трек'),
                secondary: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey,
                ),
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
          onPressed: _savePodcast,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'music_note': return Icons.music_note;
      case 'album': return Icons.album;
      case 'library_music': return Icons.library_music;
      case 'audiotrack': return Icons.audiotrack;
      case 'mic': return Icons.mic;
      case 'radio': return Icons.radio;
      case 'podcast': return Icons.podcasts;
      case 'speaker': return Icons.speaker;
      case 'equalizer': return Icons.equalizer;
      case 'queue_music': return Icons.queue_music;
      default: return Icons.headphones;
    }
  }

  void _savePodcast() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название трека')),
      );
      return;
    }

    if (_authorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя исполнителя')),
      );
      return;
    }

    if (_localAudioPath == null && widget.existingPodcast == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите аудио файл')),
      );
      return;
    }

    final podcast = Podcast(
      id: widget.existingPodcast?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? '' 
          : _descriptionController.text.trim(),
      author: _authorController.text.trim(),
      audioUrl: _localAudioPath ?? widget.existingPodcast?.audioUrl ?? '',
      localAudioPath: _localAudioPath ?? widget.existingPodcast?.localAudioPath,
      iconName: _selectedIcon,
      duration: _audioDuration ?? widget.existingPodcast?.duration ?? const Duration(seconds: 0),
      category: _selectedCategory,
      publishedAt: widget.existingPodcast?.publishedAt ?? DateTime.now(),
      createdAt: widget.existingPodcast?.createdAt ?? DateTime.now(),
      playCount: widget.existingPodcast?.playCount ?? 0,
      isFavorite: _isFavorite,
      rating: widget.existingPodcast?.rating ?? 0.0,
    );

    widget.onSave(podcast);
    Navigator.pop(context);
  }
}
