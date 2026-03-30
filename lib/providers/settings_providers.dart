import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/habit.dart';
import '../models/completion.dart';
import '../models/task.dart';

// Theme Colors
enum AppThemeColor {
  purple,
  green,
  orange,
  blue,
  pink,
}

extension AppThemeColorExtension on AppThemeColor {
  Color get color {
    switch (this) {
      case AppThemeColor.purple:
        return const Color(0xFFBC9EFF);
      case AppThemeColor.green:
        return const Color(0xFF52FD98);
      case AppThemeColor.orange:
        return const Color(0xFFFFB37F);
      case AppThemeColor.blue:
        return const Color(0xFF4FC3F7);
      case AppThemeColor.pink:
        return const Color(0xFFFF80AB);
    }
  }

  String get name {
    switch (this) {
      case AppThemeColor.purple:
        return 'Purple';
      case AppThemeColor.green:
        return 'Green';
      case AppThemeColor.orange:
        return 'Orange';
      case AppThemeColor.blue:
        return 'Blue';
      case AppThemeColor.pink:
        return 'Pink';
    }
  }
}

// Settings box
const String settingsBoxName = 'settings_box';

// Keys for settings
const String themeColorKey = 'theme_color';
const String profileNameKey = 'profile_name';
const String profileAvatarPathKey = 'profile_avatar_path';

// Theme Provider
final themeColorProvider = StateNotifierProvider<ThemeColorNotifier, AppThemeColor>((ref) {
  return ThemeColorNotifier();
});

class ThemeColorNotifier extends StateNotifier<AppThemeColor> {
  ThemeColorNotifier() : super(AppThemeColor.purple) {
    _loadThemeColor();
  }

  Future<void> _loadThemeColor() async {
    final box = await Hive.openBox(settingsBoxName);
    final savedColor = box.get(themeColorKey);
    if (savedColor != null) {
      state = AppThemeColor.values.firstWhere(
        (e) => e.toString() == savedColor,
        orElse: () => AppThemeColor.purple,
      );
    }
  }

  Future<void> setThemeColor(AppThemeColor color) async {
    final box = await Hive.openBox(settingsBoxName);
    await box.put(themeColorKey, color.toString());
    state = color;
  }
}

// Profile Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});

class ProfileState {
  final String name;
  final String? avatarPath;

  const ProfileState({
    this.name = 'User',
    this.avatarPath,
  });

  ProfileState copyWith({
    String? name,
    String? avatarPath,
  }) {
    return ProfileState(
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final box = await Hive.openBox(settingsBoxName);
    final name = box.get(profileNameKey) as String?;
    final avatarPath = box.get(profileAvatarPathKey) as String?;

    state = ProfileState(
      name: name ?? 'User',
      avatarPath: avatarPath,
    );
  }

  Future<void> setName(String name) async {
    final box = await Hive.openBox(settingsBoxName);
    await box.put(profileNameKey, name);
    state = state.copyWith(name: name);
  }

  Future<void> setAvatarPath(String? path) async {
    final box = await Hive.openBox(settingsBoxName);
    if (path != null) {
      await box.put(profileAvatarPathKey, path);
    } else {
      await box.delete(profileAvatarPathKey);
    }
    state = state.copyWith(avatarPath: path);
  }
}

// Export/Import Provider
final backupProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupService {
  Future<String?> exportData() async {
    try {
      // Get all data
      final habitsBox = Hive.box<Habit>('habits');
      final completionsBox = Hive.box<Completion>('completions');
      final tasksBox = Hive.box<Task>('tasks');

      final data = {
        'habits': habitsBox.values.map((h) => _habitToJson(h)).toList(),
        'completions': completionsBox.values.map((c) => _completionToJson(c)).toList(),
        'tasks': tasksBox.values.map((t) => _taskToJson(t)).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      // Get Documents directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Documents');
        // Create Documents folder if it doesn't exist
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            directory = Directory('${directory.path}/Documents');
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        // Fallback to app documents
        directory = await getApplicationDocumentsDirectory();
      }

      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileName = 'Habylon_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '${directory.path}/$fileName';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonEncode(data));

      return filePath;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  Future<bool> importData() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return false;

      final filePath = result.files.first.path;
      if (filePath == null) return false;

      // Read and validate file
      final file = File(filePath);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validate structure
      if (!data.containsKey('habits') || !data.containsKey('completions')) {
        return false;
      }

      // Clear existing data
      final habitsBox = Hive.box<Habit>('habits');
      final completionsBox = Hive.box<Completion>('completions');
      final tasksBox = Hive.box<Task>('tasks');

      await habitsBox.clear();
      await completionsBox.clear();
      await tasksBox.clear();

      // Restore habits
      final habits = data['habits'] as List;
      for (final habitJson in habits) {
        final habit = _habitFromJson(habitJson as Map<String, dynamic>);
        await habitsBox.put(habit.id, habit);
      }

      // Restore completions
      final completions = data['completions'] as List;
      for (final completionJson in completions) {
        final completion = _completionFromJson(completionJson as Map<String, dynamic>);
        await completionsBox.add(completion);
      }

      // Restore tasks if present
      if (data.containsKey('tasks')) {
        final tasks = data['tasks'] as List;
        for (final taskJson in tasks) {
          final task = _taskFromJson(taskJson as Map<String, dynamic>);
          await tasksBox.add(task);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      return false;
    }
  }

  Map<String, dynamic> _habitToJson(Habit habit) {
    return {
      'id': habit.id,
      'name': habit.name,
      'color': habit.color,
      'icon': habit.icon,
      'type': habit.type.toString(),
      'streak': habit.streak,
      'category': habit.category,
      'targetDaysPerWeek': habit.targetDaysPerWeek,
      'frequency': habit.frequency.toString(),
      'targetTime': habit.targetTime,
      'createdAt': habit.createdAt.toIso8601String(),
    };
  }

  Habit _habitFromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      type: HabitType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => HabitType.check,
      ),
      streak: json['streak'] as int? ?? 0,
      category: json['category'] as String? ?? 'General',
      targetDaysPerWeek: json['targetDaysPerWeek'] as int?,
      frequency: Frequency.values.firstWhere(
        (e) => e.toString() == json['frequency'],
        orElse: () => Frequency.daily,
      ),
      targetTime: json['targetTime'] as double?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> _completionToJson(Completion completion) {
    return {
      'habitId': completion.habitId,
      'date': completion.date.toIso8601String(),
      'completed': completion.completed,
      'timeValue': completion.timeValue,
      'count': completion.count,
    };
  }

  Completion _completionFromJson(Map<String, dynamic> json) {
    return Completion(
      habitId: json['habitId'] as String,
      date: DateTime.parse(json['date'] as String),
      completed: json['completed'] as bool,
      timeValue: json['timeValue'] as double?,
      count: json['count'] as int?,
    );
  }

  Map<String, dynamic> _taskToJson(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'category': task.category,
      'date': task.date.toIso8601String(),
      'completed': task.completed,
      'priority': task.priority,
      'createdAt': task.createdAt.toIso8601String(),
    };
  }

  Task _taskFromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      completed: json['completed'] as bool,
      priority: json['priority'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// Delete all data provider
final deleteAllDataProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    try {
      final habitsBox = Hive.box<Habit>('habits');
      final completionsBox = Hive.box<Completion>('completions');
      final tasksBox = Hive.box<Task>('tasks');

      await habitsBox.clear();
      await completionsBox.clear();
      await tasksBox.clear();

      return true;
    } catch (e) {
      debugPrint('Delete all data error: $e');
      return false;
    }
  };
});
