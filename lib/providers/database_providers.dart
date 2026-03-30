import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../models/completion.dart';
import '../models/task.dart';

// Box names
const String habitsBoxName = 'habits';
const String completionsBoxName = 'completions';
const String tasksBoxName = 'tasks';

// Raw box providers - boxes are already opened in main.dart
final habitsBoxProvider = Provider<Box<Habit>>((ref) {
  return Hive.box<Habit>(habitsBoxName);
});

final completionsBoxProvider = Provider<Box<Completion>>((ref) {
  return Hive.box<Completion>(completionsBoxName);
});

final tasksBoxProvider = Provider<Box<Task>>((ref) {
  return Hive.box<Task>(tasksBoxName);
});

// Habit provider - emits immediately with current values
final habitsProvider = StreamProvider<List<Habit>>((ref) async* {
  final box = ref.watch(habitsBoxProvider);
  
  // Emit current values immediately
  yield box.values.toList();
  
  // Listen for changes
  await for (final _ in box.watch()) {
    yield box.values.toList();
  }
});

// Single habit provider
final habitProvider = Provider.family<Habit?, String>((ref, id) {
  final habitsAsync = ref.watch(habitsProvider);
  return habitsAsync.when(
    data: (habits) {
      try {
        return habits.firstWhere((h) => h.id == id);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// All completions provider - emits immediately
final allCompletionsProvider = StreamProvider<List<Completion>>((ref) async* {
  final box = ref.watch(completionsBoxProvider);

  // Emit current values immediately
  yield box.values.toList();

  // Listen for changes
  await for (final _ in box.watch()) {
    yield box.values.toList();
  }
});

// Consistency percentage provider - calculates (completed / total possible) * 100
// Tracks from habit creation date, starts at 100% for new habits
// Formula: consistency = (completed_days / total_days_since_creation) * 100
final consistencyProvider = Provider.family<int, List<Habit>>((ref, habits) {
  final completionsAsync = ref.watch(allCompletionsProvider);

  return completionsAsync.when(
    data: (completions) {
      if (habits.isEmpty) return 100; // Start at 100% when no habits

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int totalPossibleDays = 0;
      int completedDays = 0;

      // Group completions by date and habit
      final completionsByDate = <DateTime, Set<String>>{};
      for (final completion in completions) {
        if (completion.completed) {
          final dateKey = DateTime(completion.date.year, completion.date.month, completion.date.day);
          completionsByDate.putIfAbsent(dateKey, () => <String>{});
          completionsByDate[dateKey]!.add(completion.habitId);
        }
      }

      // Calculate for each habit from its creation date
      for (final habit in habits) {
        final createdAt = DateTime(
          habit.createdAt.year,
          habit.createdAt.month,
          habit.createdAt.day,
        );

        // Calculate days from creation to today (inclusive)
        final daysSinceCreation = today.difference(createdAt).inDays + 1;
        totalPossibleDays += daysSinceCreation;

        // Count completed days for this habit
        for (int i = 0; i < daysSinceCreation; i++) {
          final checkDate = today.subtract(Duration(days: i));
          if (completionsByDate[checkDate]?.contains(habit.id) ?? false) {
            completedDays++;
          }
        }
      }

      if (totalPossibleDays == 0) return 100; // Start at 100% for new habits

      // Calculate consistency percentage
      final percentage = ((completedDays / totalPossibleDays) * 100).round();
      return percentage.clamp(0, 100);
    },
    loading: () => 100, // Start at 100% while loading
    error: (_, __) => 100, // Start at 100% on error
  );
});

// Weekly habit consistency provider - calculates based on target days per week
// For weekly habits: consistency = (completedDaysThisWeek / targetDaysPerWeek) * 100
// If week not finished and target met: 100%
// If week finished and target not met: (completed / target) * 100
final weeklyHabitConsistencyProvider = Provider.family<int, Habit>((ref, habit) {
  final completionsAsync = ref.watch(completionsProvider(habit.id));

  return completionsAsync.when(
    data: (completions) {
      if (habit.frequency != Frequency.weekly || habit.targetDaysPerWeek == null) {
        return 100; // Default for non-weekly habits
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Calculate week boundaries (Monday to Sunday)
      final daysSinceMonday = (today.weekday - 1) % 7;
      final weekStart = today.subtract(Duration(days: daysSinceMonday));
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Count completed days in current week
      final completedDaysInWeek = completions.where((c) {
        if (!c.completed) return false;
        final completionDate = DateTime(c.date.year, c.date.month, c.date.day);
        return completionDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
               completionDate.isBefore(weekEnd.add(const Duration(days: 1)));
      }).length;

      final targetDays = habit.targetDaysPerWeek!;
      final isWeekFinished = today.weekday == 7; // Sunday

      // If completed target days or more: 100%
      if (completedDaysInWeek >= targetDays) {
        return 100;
      }

      // If week not finished: show current progress but cap at 100 when target met
      if (!isWeekFinished) {
        // Show current progress, will be 100% once target is met
        return ((completedDaysInWeek / targetDays) * 100).round().clamp(0, 99);
      }

      // Week finished and target not met: calculate actual percentage
      return ((completedDaysInWeek / targetDays) * 100).round().clamp(0, 100);
    },
    loading: () => 100,
    error: (_, __) => 100,
  );
});

// Perfect days provider - counts days where all habits were completed
// Also calculates current perfect streak
final perfectDaysProvider = Provider.family<Map<String, int>, List<Habit>>((ref, habits) {
  final completionsAsync = ref.watch(allCompletionsProvider);

  return completionsAsync.when(
    data: (completions) {
      if (habits.isEmpty) {
        return {'total': 0, 'streak': 0};
      }

      final habitCount = habits.length;

      // Group completions by date
      final completionsByDate = <DateTime, Set<String>>{};
      for (final completion in completions) {
        if (completion.completed) {
          final dateKey = DateTime(completion.date.year, completion.date.month, completion.date.day);
          completionsByDate.putIfAbsent(dateKey, () => <String>{});
          completionsByDate[dateKey]!.add(completion.habitId);
        }
      }

      // Count perfect days
      int perfectDaysCount = 0;
      final perfectDates = <DateTime>[];

      completionsByDate.forEach((date, completedHabits) {
        if (completedHabits.length >= habitCount) {
          perfectDaysCount++;
          perfectDates.add(date);
        }
      });

      // Calculate current perfect streak
      perfectDates.sort((a, b) => b.compareTo(a)); // Sort descending (newest first)

      int currentStreak = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if today is perfect
      bool todayIsPerfect = completionsByDate[today]?.length == habitCount;

      // Check if yesterday was perfect
      final yesterday = today.subtract(const Duration(days: 1));
      bool yesterdayIsPerfect = completionsByDate[yesterday]?.length == habitCount;

      // Start streak calculation from today or yesterday
      bool hasStreak = todayIsPerfect || yesterdayIsPerfect;

      if (hasStreak) {
        for (int i = 0; i < 365; i++) {
          final expectedDate = today.subtract(Duration(days: i));
          if (completionsByDate[expectedDate]?.length == habitCount) {
            currentStreak++;
          } else {
            break;
          }
        }
      }

      return {'total': perfectDaysCount, 'streak': currentStreak};
    },
    loading: () => {'total': 0, 'streak': 0},
    error: (_, __) => {'total': 0, 'streak': 0},
  );
});

// Per-habit completion percentage provider
// completion = (completed days / total tracked days) * 100
final habitCompletionPercentageProvider = Provider.family<int, Habit>((ref, habit) {
  final completionsAsync = ref.watch(completionsProvider(habit.id));

  return completionsAsync.when(
    data: (completions) {
      final completedDays = completions.where((c) => c.completed).length;
      final totalTrackedDays = completions.length;

      if (totalTrackedDays == 0) return 0;
      return ((completedDays / totalTrackedDays) * 100).round();
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Per-habit total days provider
// Counts days from habit creation date until today
final habitTotalDaysProvider = Provider.family<int, Habit>((ref, habit) {
  final now = DateTime.now();
  final createdAt = DateTime(
    habit.createdAt.year,
    habit.createdAt.month,
    habit.createdAt.day,
  );
  final today = DateTime(now.year, now.month, now.day);

  return today.difference(createdAt).inDays + 1; // +1 to include today
});

// Per-habit current streak provider
// Calculates consecutive days of completion ending today or yesterday
final habitStreakProvider = Provider.family<int, Habit>((ref, habit) {
  final completionsAsync = ref.watch(completionsProvider(habit.id));

  return completionsAsync.when(
    data: (completions) {
      if (completions.isEmpty) return 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Group completions by date
      final completedDates = <DateTime>{};
      for (final completion in completions) {
        if (completion.completed) {
          final date = DateTime(
            completion.date.year,
            completion.date.month,
            completion.date.day,
          );
          completedDates.add(date);
        }
      }

      // Check if today is completed
      bool todayCompleted = completedDates.contains(today);

      // Calculate streak
      int streak = 0;
      DateTime checkDate = today;

      // If today is not completed, start from yesterday
      if (!todayCompleted) {
        checkDate = today.subtract(const Duration(days: 1));
      }

      // Count consecutive completed days going backwards
      for (int i = 0; i < 365; i++) {
        final dateToCheck = today.subtract(Duration(days: i));
        if (completedDates.contains(dateToCheck)) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Per-habit best streak provider - finds longest continuous streak in history
final habitBestStreakProvider = Provider.family<int, Habit>((ref, habit) {
  final completionsAsync = ref.watch(completionsProvider(habit.id));

  return completionsAsync.when(
    data: (completions) {
      if (completions.isEmpty) return 0;

      // Group completions by date
      final completedDates = <DateTime>{};
      for (final completion in completions) {
        if (completion.completed) {
          final date = DateTime(
            completion.date.year,
            completion.date.month,
            completion.date.day,
          );
          completedDates.add(date);
        }
      }

      if (completedDates.isEmpty) return 0;

      // Sort dates
      final sortedDates = completedDates.toList()..sort();

      // Find longest streak
      int maxStreak = 1;
      int currentStreak = 1;

      for (int i = 1; i < sortedDates.length; i++) {
        final prevDate = sortedDates[i - 1];
        final currDate = sortedDates[i];
        final difference = currDate.difference(prevDate).inDays;

        if (difference == 1) {
          currentStreak++;
          maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
        } else {
          currentStreak = 1;
        }
      }

      return maxStreak;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Per-habit total completions provider
final habitTotalCompletionsProvider = Provider.family<int, Habit>((ref, habit) {
  final completionsAsync = ref.watch(completionsProvider(habit.id));

  return completionsAsync.when(
    data: (completions) {
      return completions.where((c) => c.completed).length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Per-habit 30-day trend data provider - returns list of completion values (0.0 to 1.0) for last 30 days
final habitTrendDataProvider = Provider.family<List<double>, Habit>((ref, habit) {
  final completionsAsync = ref.watch(completionsProvider(habit.id));

  return completionsAsync.when(
    data: (completions) {
      final now = DateTime.now();
      final trendData = <double>[];

      // Group completions by date
      final completedDates = <DateTime>{};
      for (final completion in completions) {
        if (completion.completed) {
          final date = DateTime(
            completion.date.year,
            completion.date.month,
            completion.date.day,
          );
          completedDates.add(date);
        }
      }

      // Generate 30 days of data (oldest to newest for chart)
      for (int i = 29; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final isCompleted = completedDates.contains(date);
        trendData.add(isCompleted ? 1.0 : 0.0);
      }

      return trendData;
    },
    loading: () => List.filled(30, 0.0),
    error: (_, __) => List.filled(30, 0.0),
  );
});

// Per-habit best days analysis - completion % for each weekday
final habitBestDaysProvider = Provider.family<Map<int, double>, Habit>((ref, habit) {
  final completionsAsync = ref.watch(completionsProvider(habit.id));
  final totalDaysAsync = ref.watch(habitTotalDaysProvider(habit));

  return completionsAsync.when(
    data: (completions) {
      // Weekday stats: 1=Monday, 7=Sunday
      final weekdayCompletions = <int, int>{}; // completed count per weekday
      final weekdayTotal = <int, int>{}; // total occurrences per weekday

      // Initialize all weekdays
      for (int i = 1; i <= 7; i++) {
        weekdayCompletions[i] = 0;
        weekdayTotal[i] = 0;
      }

      // Count completions by weekday
      for (final completion in completions) {
        final weekday = completion.date.weekday; // 1=Monday, 7=Sunday
        weekdayTotal[weekday] = (weekdayTotal[weekday] ?? 0) + 1;
        if (completion.completed) {
          weekdayCompletions[weekday] = (weekdayCompletions[weekday] ?? 0) + 1;
        }
      }

      // Calculate percentages
      final result = <int, double>{};
      for (int i = 1; i <= 7; i++) {
        final total = weekdayTotal[i] ?? 0;
        final completed = weekdayCompletions[i] ?? 0;
        result[i] = total > 0 ? completed / total : 0.0;
      }

      return result;
    },
    loading: () => {for (int i = 1; i <= 7; i++) i: 0.0},
    error: (_, __) => {for (int i = 1; i <= 7; i++) i: 0.0},
  );
});

// Per-habit monthly history - completion % for last 5 months
final habitMonthlyHistoryProvider = Provider.family<List<Map<String, dynamic>>, Habit>((ref, habit) {
  final completionsAsync = ref.watch(completionsProvider(habit.id));

  return completionsAsync.when(
    data: (completions) {
      final now = DateTime.now();
      final monthlyData = <Map<String, dynamic>>[];

      // Group completions by month
      final completionsByMonth = <String, List<Completion>>{};
      for (final completion in completions) {
        final key = '${completion.date.year}-${completion.date.month.toString().padLeft(2, '0')}';
        completionsByMonth.putIfAbsent(key, () => []);
        completionsByMonth[key]!.add(completion);
      }

      // Get last 5 months
      for (int i = 4; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthKey = '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
        final monthCompletions = completionsByMonth[monthKey] ?? [];

        // Calculate completion rate for this month
        final totalDays = monthCompletions.length;
        final completedDays = monthCompletions.where((c) => c.completed).length;
        final percentage = totalDays > 0 ? (completedDays / totalDays) : 0.0;

        monthlyData.add({
          'month': monthDate,
          'percentage': percentage,
          'completed': completedDays,
          'total': totalDays,
        });
      }

      return monthlyData;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Per-habit streak history - all streak sequences sorted by most recent
final habitStreakHistoryProvider = Provider.family<List<Map<String, dynamic>>, Habit>((ref, habit) {
  final completionsAsync = ref.watch(completionsProvider(habit.id));

  return completionsAsync.when(
    data: (completions) {
      if (completions.isEmpty) return [];

      // Group completions by date
      final completedDates = <DateTime>{};
      for (final completion in completions) {
        if (completion.completed) {
          final date = DateTime(
            completion.date.year,
            completion.date.month,
            completion.date.day,
          );
          completedDates.add(date);
        }
      }

      if (completedDates.isEmpty) return [];

      // Sort dates descending (newest first)
      final sortedDates = completedDates.toList()..sort((a, b) => b.compareTo(a));

      // Find all streaks
      final streaks = <Map<String, dynamic>>[];
      DateTime? streakEnd;
      DateTime? streakStart;
      int currentStreakLength = 0;

      for (int i = 0; i < sortedDates.length; i++) {
        final date = sortedDates[i];

        if (streakEnd == null) {
          // Start first streak
          streakEnd = date;
          streakStart = date;
          currentStreakLength = 1;
        } else {
          final prevDate = sortedDates[i - 1];
          final difference = prevDate.difference(date).inDays;

          if (difference == 1) {
            // Continue current streak
            streakStart = date;
            currentStreakLength++;
          } else {
            // End current streak and start new one
            streaks.add({
              'start': streakStart!,
              'end': streakEnd,
              'length': currentStreakLength,
            });
            streakEnd = date;
            streakStart = date;
            currentStreakLength = 1;
          }
        }
      }

      // Add final streak
      if (streakEnd != null && streakStart != null) {
        streaks.add({
          'start': streakStart,
          'end': streakEnd,
          'length': currentStreakLength,
        });
      }

      return streaks;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Insight messages provider for a habit
final habitInsightsProvider = Provider.family<Map<String, String>, Habit>((ref, habit) {
  final currentStreak = ref.watch(habitStreakProvider(habit));
  final bestStreak = ref.watch(habitBestStreakProvider(habit));
  final bestDays = ref.watch(habitBestDaysProvider(habit));
  final completionsAsync = ref.watch(completionsProvider(habit.id));
  final totalDays = ref.watch(habitTotalDaysProvider(habit));

  return completionsAsync.when(
    data: (completions) {
      final insights = <String, String>{};

      // Streak insight
      final daysToBeat = bestStreak - currentStreak;
      if (daysToBeat > 0) {
        insights['streak'] = '$currentStreak day streak. $daysToBeat more days to beat your best';
      } else if (currentStreak > 0) {
        insights['streak'] = '$currentStreak day streak. You\'re at your best!';
      } else {
        insights['streak'] = 'Start your streak today!';
      }

      // Best day insight
      int bestWeekday = 1;
      double bestPercentage = 0;
      bestDays.forEach((weekday, percentage) {
        if (percentage > bestPercentage) {
          bestPercentage = percentage;
          bestWeekday = weekday;
        }
      });

      final weekdayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      if (bestPercentage > 0) {
        insights['bestDay'] = 'You perform best on ${weekdayNames[bestWeekday]} (${(bestPercentage * 100).toInt()}%)';
      } else {
        insights['bestDay'] = 'Track more to see your best day';
      }

      // Progress insight
      final completedCount = completions.where((c) => c.completed).length;
      final completionRate = totalDays > 0 ? (completedCount / totalDays) : 0;
      insights['progress'] = 'Completion rate: ${(completionRate * 100).toInt()}%';

      return insights;
    },
    loading: () => {
      'streak': 'Loading...',
      'bestDay': 'Loading...',
      'progress': 'Loading...',
    },
    error: (_, __) => {
      'streak': 'No data yet',
      'bestDay': 'No data yet',
      'progress': 'No data yet',
    },
  );
});
final completionsProvider = StreamProvider.family<List<Completion>, String>((ref, habitId) async* {
  final box = ref.watch(completionsBoxProvider);
  
  // Emit current values immediately
  yield box.values.where((c) => c.habitId == habitId).toList();
  
  // Listen for changes
  await for (final _ in box.watch()) {
    yield box.values.where((c) => c.habitId == habitId).toList();
  }
});

// Today's completion for a habit
final todayCompletionProvider = Provider.family<Completion?, String>((ref, habitId) {
  final completionsAsync = ref.watch(completionsProvider(habitId));
  final today = DateTime.now();
  
  return completionsAsync.when(
    data: (completions) {
      try {
        return completions.firstWhere(
          (c) => c.date.year == today.year && 
                 c.date.month == today.month && 
                 c.date.day == today.day,
        );
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// All tasks provider - emits immediately
final tasksProvider = StreamProvider<List<Task>>((ref) async* {
  final box = ref.watch(tasksBoxProvider);
  
  // Emit current values immediately
  yield box.values.toList();
  
  // Listen for changes
  await for (final _ in box.watch()) {
    yield box.values.toList();
  }
});

// Tasks by date provider
final tasksByDateProvider = Provider.family<List<Task>, DateTime>((ref, date) {
  final tasksAsync = ref.watch(tasksProvider);
  
  return tasksAsync.when(
    data: (tasks) {
      return tasks.where((t) => 
        t.date.year == date.year && 
        t.date.month == date.month && 
        t.date.day == date.day
      ).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Habit repository for CRUD operations
class HabitRepository {
  final Box<Habit> _box;
  
  HabitRepository(this._box);
  
  Future<void> addHabit(Habit habit) async {
    // Validate data before saving
    final validatedHabit = _validateHabit(habit);
    await _box.put(validatedHabit.id, validatedHabit);
  }
  
  Future<void> updateHabit(Habit habit) async {
    // Validate data before saving
    final validatedHabit = _validateHabit(habit);
    await _box.put(validatedHabit.id, validatedHabit);
  }
  
  Future<void> deleteHabit(String id) async {
    await _box.delete(id);
  }
  
  List<Habit> getAllHabits() {
    final habits = _box.values.toList();
    // Validate and fix any habits with null/missing data
    return habits.map((h) => _validateHabit(h)).toList();
  }
  
  /// Validates habit data and assigns defaults if missing
  /// This ensures color and icon are never null/empty
  Habit _validateHabit(Habit habit) {
    var validatedColor = habit.color;
    var validatedIcon = habit.icon;
    bool needsUpdate = false;
    
    // Validate color - must not be null or empty
    if (validatedColor == null || validatedColor.isEmpty) {
      validatedColor = 'primary';
      needsUpdate = true;
      debugPrint('Habit ${habit.id} (${habit.name}): color was null/empty, set to primary');
    }
    
    // Validate icon - must not be null or empty
    if (validatedIcon == null || validatedIcon.isEmpty) {
      validatedIcon = 'water_drop';
      needsUpdate = true;
      debugPrint('Habit ${habit.id} (${habit.name}): icon was null/empty, set to water_drop');
    }
    
    // If data was fixed, update in storage
    if (needsUpdate) {
      final fixedHabit = habit.copyWith(
        color: validatedColor,
        icon: validatedIcon,
      );
      _box.put(habit.id, fixedHabit);
      return fixedHabit;
    }
    
    return habit;
  }
}

// Completion repository
class CompletionRepository {
  final Box<Completion> _box;
  
  CompletionRepository(this._box);
  
  Future<void> addCompletion(Completion completion) async {
    final key = '${completion.habitId}_${completion.dateKey.millisecondsSinceEpoch}';
    await _box.put(key, completion);
  }
  
  Future<void> updateCompletion(Completion completion) async {
    final key = '${completion.habitId}_${completion.dateKey.millisecondsSinceEpoch}';
    await _box.put(key, completion);
  }
  
  Future<void> deleteCompletion(String habitId, DateTime date) async {
    final key = '${habitId}_${DateTime(date.year, date.month, date.day).millisecondsSinceEpoch}';
    await _box.delete(key);
  }
  
  List<Completion> getCompletionsForHabit(String habitId) {
    return _box.values.where((c) => c.habitId == habitId).toList();
  }
  
  Completion? getCompletionForDate(String habitId, DateTime date) {
    final key = '${habitId}_${DateTime(date.year, date.month, date.day).millisecondsSinceEpoch}';
    return _box.get(key);
  }
}

// Task repository
class TaskRepository {
  final Box<Task> _box;
  
  TaskRepository(this._box);
  
  Future<void> addTask(Task task) async {
    await _box.put(task.id, task);
  }
  
  Future<void> updateTask(Task task) async {
    await _box.put(task.id, task);
  }
  
  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }
  
  List<Task> getAllTasks() {
    return _box.values.toList();
  }
  
  List<Task> getTasksForDate(DateTime date) {
    return _box.values.where((t) => 
      t.date.year == date.year && 
      t.date.month == date.month && 
      t.date.day == date.day
    ).toList();
  }
}

// Repository providers
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final box = ref.watch(habitsBoxProvider);
  return HabitRepository(box);
});

final completionRepositoryProvider = Provider<CompletionRepository>((ref) {
  final box = ref.watch(completionsBoxProvider);
  return CompletionRepository(box);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final box = ref.watch(tasksBoxProvider);
  return TaskRepository(box);
});
