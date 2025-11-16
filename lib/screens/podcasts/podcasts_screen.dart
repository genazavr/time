import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
              backgroundColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
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
            'Нет подкастов',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите + чтобы добавить подкаст',
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  image: podcast.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(podcast.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: podcast.imageUrl == null
                    ? Icon(
                        Icons.headphones,
                        size: 32,
                        color: AppTheme.primaryColor,
                      )
                    : null,
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
                            color: AppTheme.secondaryColor.withOpacity(0.1),
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
              if (podcast.imageUrl != null) ...[
                Image.network(podcast.imageUrl!),
                const SizedBox(height: 16),
              ],
              Text('Автор: ${podcast.author}'),
              const SizedBox(height: 8),
              Text('Категория: ${podcast.category}'),
              const SizedBox(height: 8),
              Text('Длительность: ${podcast.durationText}'),
              const SizedBox(height: 8),
              Text('Прослушиваний: ${podcast.playCount}'),
              const SizedBox(height: 8),
              Text('Рейтинг: ${podcast.rating.toStringAsFixed(1)}'),
              const SizedBox(height: 16),
              Text(podcast.description),
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
        title: const Text('Избранные подкасты'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: favorites.isEmpty
              ? const Center(child: Text('Нет избранных подкастов'))
              : ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final podcast = favorites[index];
                    return ListTile(
                      title: Text(podcast.title),
                      subtitle: Text(podcast.author),
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
        title: const Text('Удалить подкаст?'),
        content: const Text('Вы уверены, что хотите удалить этот подкаст?'),
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
  late TextEditingController _audioUrlController;
  late TextEditingController _imageUrlController;
  late String _selectedCategory;
  late int _durationMinutes;
  late int _durationSeconds;

  @override
  void initState() {
    super.initState();
    final podcast = widget.existingPodcast;
    _titleController = TextEditingController(text: podcast?.title ?? '');
    _descriptionController = TextEditingController(text: podcast?.description ?? '');
    _authorController = TextEditingController(text: podcast?.author ?? '');
    _audioUrlController = TextEditingController(text: podcast?.audioUrl ?? '');
    _imageUrlController = TextEditingController(text: podcast?.imageUrl ?? '');
    _selectedCategory = podcast?.category ?? (widget.categories.isNotEmpty ? widget.categories.first : 'Образование');
    _durationMinutes = podcast?.duration.inMinutes ?? 30;
    _durationSeconds = podcast?.duration.inSeconds % 60 ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _audioUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingPodcast == null ? 'Добавить подкаст' : 'Редактировать подкаст'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Введите название подкаста',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Автор',
                  hintText: 'Введите имя автора',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Введите описание подкаста',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: widget.categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _audioUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL аудио',
                  hintText: 'Введите URL аудиофайла',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL изображения',
                  hintText: 'Введите URL изображения (необязательно)',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Минуты',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _durationMinutes = int.tryParse(value) ?? 0;
                      },
                      controller: TextEditingController(text: _durationMinutes.toString()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Секунды',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _durationSeconds = int.tryParse(value) ?? 0;
                      },
                      controller: TextEditingController(text: _durationSeconds.toString()),
                    ),
                  ),
                ],
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

  void _savePodcast() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название подкаста')),
      );
      return;
    }

    if (_authorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя автора')),
      );
      return;
    }

    if (_audioUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите URL аудиофайла')),
      );
      return;
    }

    final duration = Duration(minutes: _durationMinutes, seconds: _durationSeconds);

    final podcast = Podcast(
      id: widget.existingPodcast?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      author: _authorController.text.trim().isEmpty ? '' : _authorController.text.trim(),
      audioUrl: _audioUrlController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty 
          ? null 
          : _imageUrlController.text.trim(),
      duration: duration,
      category: _selectedCategory,
      publishedAt: widget.existingPodcast?.publishedAt ?? DateTime.now(),
      createdAt: widget.existingPodcast?.createdAt ?? DateTime.now(),
      playCount: widget.existingPodcast?.playCount ?? 0,
      isFavorite: widget.existingPodcast?.isFavorite ?? false,
      rating: widget.existingPodcast?.rating ?? 0.0,
    );

    widget.onSave(podcast);
    Navigator.pop(context);
  }
}