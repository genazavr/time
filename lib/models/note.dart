class Note {
  final String id;
  final String title;
  final String? content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.title,
    this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory Note.fromMap(Map<dynamic, dynamic> map, String id) {
    DateTime? parsedDate(dynamic value) {
      if (value == null) return null;
      try {
        if (value is String && value.isNotEmpty) {
          return DateTime.parse(value);
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
      return null;
    }

    return Note(
      id: id,
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString(),
      createdAt: parsedDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parsedDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}