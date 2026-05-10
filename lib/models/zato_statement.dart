import 'package:uuid/uuid.dart';

class ZatoStatement {
  final String id;
  final String negativeStatement;
  final String positiveStatement;
  final bool isStarred;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ZatoStatement({
    required this.id,
    required this.negativeStatement,
    required this.positiveStatement,
    this.isStarred = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory ZatoStatement.create({
    required String negativeStatement,
    required String positiveStatement,
    bool isStarred = false,
  }) {
    return ZatoStatement(
      id: const Uuid().v4(),
      negativeStatement: negativeStatement,
      positiveStatement: positiveStatement,
      isStarred: isStarred,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'negativeStatement': negativeStatement,
      'positiveStatement': positiveStatement,
      'isStarred': isStarred,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ZatoStatement.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return ZatoStatement(
      id: map['id'] ?? '',
      negativeStatement: map['negativeStatement'] ?? '',
      positiveStatement: map['positiveStatement'] ?? '',
      isStarred: map['isStarred'] ?? false,
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  ZatoStatement copyWith({
    String? id,
    String? negativeStatement,
    String? positiveStatement,
    bool? isStarred,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ZatoStatement(
      id: id ?? this.id,
      negativeStatement: negativeStatement ?? this.negativeStatement,
      positiveStatement: positiveStatement ?? this.positiveStatement,
      isStarred: isStarred ?? this.isStarred,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static List<String> get templates => [
    'Я не справлюсь с этим',
    'Все считают меня неудачником',
    'Я слишком медленный/медленная',
    'У меня никогда ничего не получится',
    'Я боюсь, что облажаюсь',
    'Это слишком сложно для меня',
    'Я не заслуживаю успеха',
    'Люди меня осуждают',
    'Я опять всё испортил/испортила',
    'У меня нет таланта',
  ];

  static List<String> get hints => [
    'Да, это сложно, ЗАТО я научусь',
    'Это неприятно, ЗАТО это временно',
    'Да, это страшно, ЗАТО я расту',
    'Это не получилось, ЗАТO я стал/стала лучше',
    'Да, мне страшно, ЗАТО это возможность',
    'Это тяжело, ЗАТО я становлюсь сильнее',
    'Да, не идеально, ЗАТО я стараюсь',
    'Это сложно, ЗАТO у меня есть шанс',
  ];
}
