import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/completion.dart';
import '../providers/database_providers.dart';
import '../utils/theme.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/bottom_nav.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (habits) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverToBoxAdapter(child: _buildMonthSelector()),
              ),
              if (habits.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildHabitCalendarCard(habits[index]),
                      childCount: habits.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Calendar', style: AppTypography.headlineSmall),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthFormat = DateFormat('MMMM yyyy');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1));
          },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceBright, shape: BoxShape.circle),
            child: Icon(Icons.chevron_left, color: AppColors.onSurfaceVariant),
          ),
        ),
        Text(
          monthFormat.format(selectedMonth),
          style: AppTypography.headlineSmall.copyWith(fontSize: 18),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1));
          },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceBright, shape: BoxShape.circle),
            child: Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitCalendarCard(Habit habit) {
    final color = _getColorFromString(habit.color);
    final completionsAsync = ref.watch(completionsProvider(habit.id));
    final completionPercentage = ref.watch(habitCompletionPercentageProvider(habit));
    final totalDays = ref.watch(habitTotalDaysProvider(habit));
    final streak = ref.watch(habitStreakProvider(habit));

    return completionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (completions) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(
                color: color.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Name + Streak Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.2), width: 1),
                            ),
                            child: Icon(_getIconFromString(habit.icon), color: color, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(habit.name, style: AppTypography.headlineSmall.copyWith(fontSize: 16)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, color: color, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$streak Day Streak',
                              style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox('Completion', '$completionPercentage%', AppColors.secondary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildStatBox('Total Days', '$totalDays', AppColors.tertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Calendar Grid
                  _buildHabitCalendarGrid(completions, color),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall.copyWith(letterSpacing: 0.1)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(color: valueColor, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCalendarGrid(List<Completion> completions, Color color) {
    final daysInMonth = _getDaysInMonth(selectedMonth);
    final firstWeekday = _getFirstWeekdayOfMonth(selectedMonth);
    final completedDates = <DateTime>{};
    for (final completion in completions) {
      if (completion.completed) {
        completedDates.add(DateTime(completion.date.year, completion.date.month, completion.date.day));
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
              .map((d) => Expanded(
                    child: Text(d, textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.2,
          children: _buildCalendarDays(daysInMonth, firstWeekday, color, completedDates),
        ),
      ],
    );
  }

  List<Widget> _buildCalendarDays(int daysInMonth, int firstWeekday, Color color, Set<DateTime> completedDates) {
    final days = <Widget>[];
    final now = DateTime.now();
    for (int i = 0; i < firstWeekday; i++) days.add(const SizedBox.shrink());
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedMonth.year, selectedMonth.month, day);
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      final isCompleted = completedDates.contains(date);
      days.add(
        GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); },
          child: Container(
            decoration: BoxDecoration(
              color: isCompleted ? color.withOpacity(0.8) : (isToday ? AppColors.surfaceContainerHigh : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text('$day',
                  style: AppTypography.labelSmall.copyWith(
                      color: isCompleted ? Colors.black : (isToday ? color : AppColors.onSurface),
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
        ),
      );
    }
    return days;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: AppSpacing.md),
          Text('No habits yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          Text('Add habits to see your calendar', style: AppTypography.labelMedium),
        ],
      ),
    );
  }

  int _getDaysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;
  int _getFirstWeekdayOfMonth(DateTime date) => DateTime(date.year, date.month, 1).weekday - 1;

  Color _getColorFromString(String color) {
    switch (color.toLowerCase()) {
      case 'primary': case 'purple': return AppColors.primary;
      case 'secondary': case 'green': return AppColors.secondary;
      case 'tertiary': case 'orange': return AppColors.tertiary;
      case 'lightblue': case 'light_blue': return const Color(0xFF4FC3F7);
      case 'error': case 'red': return AppColors.error;
      case 'errorcontainer': case 'error_container': return AppColors.errorContainer;
      default: return AppColors.primary;
    }
  }

  IconData _getIconFromString(String icon) {
    switch (icon) {
      case 'water_drop': case 'water': case 'pool': return Icons.water_drop;
      case 'fitness_center': case 'gym': return Icons.fitness_center;
      case 'book': return Icons.book;
      case 'self_improvement': case 'meditation': return Icons.self_improvement;
      case 'directions_run': case 'run': return Icons.directions_run;
      case 'bedtime': case 'sleep': return Icons.bedtime;
      case 'restaurant': case 'food': return Icons.restaurant;
      case 'music_note': case 'music': return Icons.music_note;
      case 'local_florist': case 'plant': return Icons.local_florist;
      default: return Icons.check_circle;
    }
  }
}
