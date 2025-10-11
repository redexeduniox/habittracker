import 'package:everbloom/models/user.dart';

enum HabitStatus { completed, skipped, missed, pending }

class Habit {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime scheduledTime;
  final int durationMinutes;
  final int currentStreak;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, HabitStatus> calendar;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.scheduledTime,
    required this.durationMinutes,
    this.currentStreak = 0,
    required this.createdAt,
    required this.updatedAt,
    this.calendar = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'scheduledTime': scheduledTime.toIso8601String(),
    'durationMinutes': durationMinutes,
    'currentStreak': currentStreak,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'calendar': calendar.map((key, value) => MapEntry(key, value.name)),
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    userId: json['userId'],
    title: json['title'],
    description: json['description'],
    scheduledTime: DateTime.parse(json['scheduledTime']),
    durationMinutes: json['durationMinutes'],
    currentStreak: json['currentStreak'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    calendar: (json['calendar'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, HabitStatus.values.firstWhere((e) => e.name == value))
    ) ?? {},
  );

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? scheduledTime,
    int? durationMinutes,
    int? currentStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, HabitStatus>? calendar,
  }) => Habit(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    description: description ?? this.description,
    scheduledTime: scheduledTime ?? this.scheduledTime,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    currentStreak: currentStreak ?? this.currentStreak,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    calendar: calendar ?? this.calendar,
  );
}
