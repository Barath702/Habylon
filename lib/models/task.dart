import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@HiveType(typeId: 4)
class Task extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String category; // Personal, Work, Health
  
  @HiveField(3)
  DateTime date;
  
  @HiveField(4)
  bool completed;
  
  @HiveField(5)
  DateTime createdAt;
  
  @HiveField(6)
  int? priority; // 1 = high, 2 = medium, 3 = low

  Task({
    String? id,
    required this.title,
    required this.category,
    required this.date,
    this.completed = false,
    DateTime? createdAt,
    this.priority,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  DateTime get dateKey => DateTime(date.year, date.month, date.day);

  Task copyWith({
    String? title,
    String? category,
    DateTime? date,
    bool? completed,
    int? priority,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      priority: priority ?? this.priority,
    );
  }
}
