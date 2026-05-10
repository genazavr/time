import 'package:uuid/uuid.dart';

class ControlSphere {
  final String id;
  final String situation;
  final String emotions;
  final String controlAction;
  final List<String> controlCheckboxes;
  final String tag;
  final bool isControllable;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ControlSphere({
    required this.id,
    required this.situation,
    required this.emotions,
    required this.controlAction,
    this.controlCheckboxes = const [],
    required this.tag,
    this.isControllable = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ControlSphere.create({
    required String situation,
    required String emotions,
    required String controlAction,
    List<String> controlCheckboxes = const [],
    required String tag,
    bool isControllable = true,
  }) {
    return ControlSphere(
      id: const Uuid().v4(),
      situation: situation,
      emotions: emotions,
      controlAction: controlAction,
      controlCheckboxes: controlCheckboxes,
      tag: tag,
      isControllable: isControllable,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'situation': situation,
      'emotions': emotions,
      'controlAction': controlAction,
      'controlCheckboxes': controlCheckboxes,
      'tag': tag,
      'isControllable': isControllable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ControlSphere.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return ControlSphere(
      id: map['id'] ?? '',
      situation: map['situation'] ?? '',
      emotions: map['emotions'] ?? '',
      controlAction: map['controlAction'] ?? '',
      controlCheckboxes: (map['controlCheckboxes'] is List)
          ? List<String>.from(map['controlCheckboxes'])
          : [],
      tag: map['tag'] ?? 'Другое',
      isControllable: map['isControllable'] ?? true,
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  ControlSphere copyWith({
    String? id,
    String? situation,
    String? emotions,
    String? controlAction,
    List<String>? controlCheckboxes,
    String? tag,
    bool? isControllable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ControlSphere(
      id: id ?? this.id,
      situation: situation ?? this.situation,
      emotions: emotions ?? this.emotions,
      controlAction: controlAction ?? this.controlAction,
      controlCheckboxes: controlCheckboxes ?? this.controlCheckboxes,
      tag: tag ?? this.tag,
      isControllable: isControllable ?? this.isControllable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static List<String> get availableTags => [
    'Работа',
    'Учёба',
    'Личная жизнь',
    'Здоровье',
    'Финансы',
    'Отношения',
    'Другое',
  ];
}
