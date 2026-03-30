import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String color; // Store as hex string: 'primary', 'secondary', 'tertiary', etc.
  
  @HiveField(3)
  String icon; // Material icon name
  
  @HiveField(4)
  HabitType type;
  
  @HiveField(5)
  int streak;
  
  @HiveField(6)
  DateTime createdAt;
  
  @HiveField(7)
  String category; // Personal, Work, Health, Fitness, etc.
  
  @HiveField(8)
  int? targetDaysPerWeek; // For weekly habits
  
  @HiveField(9)
  Frequency frequency;
  
  @HiveField(10)
  double? targetTime; // For time-tracked habits (in hours)
  
  Habit({
    String? id,
    required this.name,
    required this.color,
    required this.icon,
    this.type = HabitType.check,
    this.streak = 0,
    DateTime? createdAt,
    this.category = 'General',
    this.targetDaysPerWeek,
    this.frequency = Frequency.daily,
    this.targetTime,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Habit copyWith({
    String? name,
    String? color,
    String? icon,
    HabitType? type,
    int? streak,
    DateTime? createdAt,
    String? category,
    int? targetDaysPerWeek,
    Frequency? frequency,
    double? targetTime,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      targetDaysPerWeek: targetDaysPerWeek ?? this.targetDaysPerWeek,
      frequency: frequency ?? this.frequency,
      targetTime: targetTime ?? this.targetTime,
    );
  }
}

@HiveType(typeId: 1)
enum HabitType {
  @HiveField(0)
  check,
  @HiveField(1)
  time,
}

@HiveType(typeId: 2)
enum Frequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
}
