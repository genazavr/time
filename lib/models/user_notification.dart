enum NotificationType { task, homework, schedule, pomodoro, system }

class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.deliveredAt,
    this.action,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? action;

  bool get isUnread => !isRead;

  int get localId => id.hashCode & 0x7fffffff;

  UserNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    DateTime? deliveredAt,
    String? action,
  }) {
    return UserNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      action: action ?? this.action,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
      if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      if (action != null && action!.isNotEmpty) 'action': action,
    };
  }

  factory UserNotification.fromMap(Map<String, dynamic> map, String id) {
    final typeName = (map['type'] as String?)?.toLowerCase();
    final notificationType = NotificationType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => NotificationType.system,
    );

    final title = _stringOrFallback(map['title'], fallback: 'Уведомление');
    final message = _stringOrFallback(map['message']);
    final action = _optionalString(map['action']);

    return UserNotification(
      id: id,
      title: title,
      message: message,
      type: notificationType,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
      readAt: _parseDate(map['readAt']),
      deliveredAt: _parseDate(map['deliveredAt']),
      action: action,
    );
  }

  static String _stringOrFallback(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  static String? _optionalString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      if (value > 9999999999) {
        return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000).toLocal();
    }

    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }

    return null;
  }
}
