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
import '../widgets/heatmap_widgets.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
              // App Bar
              SliverToBoxAdapter(
                child: _buildAppBar(),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero Section (without date)
                    _buildHeroSection(),

                    const SizedBox(height: AppSpacing.xl),

                    // Habit Cards
                    ...habits.map((habit) => _buildHabitCard(habit)),

                    if (habits.isEmpty)
                      _buildEmptyState(),

                    const SizedBox(height: AppSpacing.xl),

                    // Weekly Summary Bento
                    _buildWeeklySummary(habits),

                    const SizedBox(height: 100), // Bottom padding
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM').format(now);
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
          // Date on the left
          Text(
            dateStr,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          // Right side icons
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/analytics'),
                child: const Icon(
                  Icons.insights_outlined,
                  color: Color(0xFFFFD700),
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuel your ',
          style: AppTypography.headlineLarge,
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'pulse',
                style: AppTypography.headlineLarge.copyWith(
                  color: themeColor,
                ),
              ),
              TextSpan(
                text: '.',
                style: AppTypography.headlineLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final color = _getColorFromString(habit.color);
    final completionsAsync = ref.watch(completionsProvider(habit.id));
    
    return completionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (completions) {
        // Generate mock heatmap data for last 8 days
        final heatmapData = List.generate(8, (index) {
          return completions.any((c) {
            final checkDate = DateTime.now().subtract(Duration(days: 7 - index));
            return c.date.year == checkDate.year &&
                   c.date.month == checkDate.month &&
                   c.date.day == checkDate.day &&
                   c.completed;
          });
        });

        final isCompletedToday = completions.any((c) {
          final today = DateTime.now();
          return c.date.year == today.year &&
                 c.date.month == today.month &&
                 c.date.day == today.day &&
                 c.completed;
        });

        return GestureDetector(
          onTap: () => _toggleHabitCompletion(habit),
          onLongPress: () => _showHabitOptions(habit),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(
                color: isCompletedToday 
                    ? color.withOpacity(0.3) 
                    : AppColors.outlineVariant.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.lg),
              backgroundColor: Colors.transparent,
              borderColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Icon container
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: color.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              _getIconFromString(habit.icon),
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: AppTypography.headlineSmall.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${habit.streak} Day Streak',
                                style: AppTypography.labelMedium.copyWith(
                                  color: color.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Check button
                      GestureDetector(
                        onTap: () => _toggleHabitCompletion(habit),
                        child: AnimatedScale(
                          scale: isCompletedToday ? 1.0 : 0.95,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isCompletedToday ? color : AppColors.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: isCompletedToday
                                  ? null
                                  : Border.all(
                                      color: color.withOpacity(0.3),
                                      width: 1,
                                    ),
                            ),
                            child: Icon(
                              Icons.check,
                              color: isCompletedToday
                                  ? Colors.black
                                  : color.withOpacity(0.4),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Heatmap and controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HeatmapGrid(
                        data: heatmapData,
                        color: color,
                      ),
                      Row(
                        children: [
                          _buildControlButton(Icons.remove, color),
                          const SizedBox(width: AppSpacing.sm),
                          _buildControlButton(Icons.add, color, isBold: true),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton(IconData icon, Color color, {bool isBold = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isBold ? AppColors.onSurface : AppColors.onSurfaceVariant,
        size: 16,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Icon(
            Icons.spa_outlined,
            size: 48,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No habits yet',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap + to create your first habit',
            style: AppTypography.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary(List<Habit> habits) {
    final consistency = ref.watch(consistencyProvider(habits));
    final perfectDays = ref.watch(perfectDaysProvider(habits));
    final themeColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.bolt,
                  color: themeColor,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$consistency%',
                  style: AppTypography.headlineMedium,
                ),
                Text(
                  'Consistency',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.celebration,
                  color: themeColor,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  perfectDays['streak']! > 0 ? 'Perfect' : 'Keep Going',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  '${perfectDays['streak']} Day Streak',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorFromString(String color) {
    switch (color.toLowerCase()) {
      case 'primary':
      case 'purple':
        return AppColors.primary;
      case 'secondary':
      case 'green':
        return AppColors.secondary;
      case 'tertiary':
      case 'orange':
        return AppColors.tertiary;
      case 'lightblue':
      case 'light_blue':
        return const Color(0xFF4FC3F7);
      case 'error':
      case 'red':
        return AppColors.error;
      case 'errorcontainer':
      case 'error_container':
        return AppColors.errorContainer;
      default:
        return AppColors.primary;
    }
  }

  IconData _getIconFromString(String icon) {
    switch (icon) {
      case 'water_drop':
      case 'water':
      case 'pool':
        return Icons.water_drop;
      case 'fitness_center':
      case 'gym':
        return Icons.fitness_center;
      case 'book':
        return Icons.book;
      case 'self_improvement':
      case 'meditation':
        return Icons.self_improvement;
      case 'directions_run':
      case 'run':
        return Icons.directions_run;
      case 'bedtime':
      case 'sleep':
        return Icons.bedtime;
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'music_note':
      case 'music':
        return Icons.music_note;
      case 'local_florist':
      case 'plant':
        return Icons.local_florist;
      default:
        return Icons.check_circle;
    }
  }

  void _toggleHabitCompletion(Habit habit) async {
    HapticFeedback.mediumImpact();
    
    final repo = ref.read(completionRepositoryProvider);
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    
    final existing = repo.getCompletionForDate(habit.id, today);
    
    if (existing != null) {
      await repo.updateCompletion(existing.copyWith(completed: !existing.completed));
    } else {
      await repo.addCompletion(Completion(
        habitId: habit.id,
        date: today,
        completed: true,
      ));
    }
    
    // Update streak
    final habitRepo = ref.read(habitRepositoryProvider);
    final updatedHabit = habit.copyWith(
      streak: existing?.completed == true ? habit.streak - 1 : habit.streak + 1,
    );
    await habitRepo.updateHabit(updatedHabit);
  }

  void _showHabitOptions(Habit habit) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              habit.name,
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
              title: Text('Edit Habit', style: AppTypography.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                context.push('/add-habit', extra: habit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: Text('Delete Habit', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(habit);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: Text(
          'Delete Habit?',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.error),
        ),
        content: Text(
          'This will permanently delete "${habit.name}" and all its completion history. This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final habitRepo = ref.read(habitRepositoryProvider);
              final completionRepo = ref.read(completionRepositoryProvider);
              
              // Delete all completions for this habit
              final completions = completionRepo.getCompletionsForHabit(habit.id);
              for (final completion in completions) {
                await completionRepo.deleteCompletion(habit.id, completion.date);
              }
              
              // Delete the habit
              await habitRepo.deleteHabit(habit.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Habit deleted', style: AppTypography.bodyMedium),
                    backgroundColor: AppColors.surfaceContainer,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'Delete',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
