import 'package:hive/hive.dart';

part 'completion.g.dart';

@HiveType(typeId: 3)
class Completion extends HiveObject {
  @HiveField(0)
  final String habitId;
  
  @HiveField(1)
  final DateTime date;
  
  @HiveField(2)
  final bool completed;
  
  @HiveField(3)
  final double? timeValue; // For time-tracked habits (in hours)
  
  @HiveField(4)
  final int? count; // For countable habits (e.g., glasses of water)

  Completion({
    required this.habitId,
    required this.date,
    this.completed = false,
    this.timeValue,
    this.count,
  });

  DateTime get dateKey => DateTime(date.year, date.month, date.day);

  Completion copyWith({
    bool? completed,
    double? timeValue,
    int? count,
  }) {
    return Completion(
      habitId: habitId,
      date: date,
      completed: completed ?? this.completed,
      timeValue: timeValue ?? this.timeValue,
      count: count ?? this.count,
    );
  }
}
