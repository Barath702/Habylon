import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../providers/database_providers.dart';
import '../utils/theme.dart';
import '../widgets/glass_widgets.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int selectedHabitIndex = 0;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (habits) {
          if (habits.isEmpty) {
            return _buildEmptyState();
          }

          // Ensure selected index is valid
          if (selectedHabitIndex >= habits.length) {
            selectedHabitIndex = 0;
          }

          final selectedHabit = habits[selectedHabitIndex];

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
                    // Habit Selector
                    _buildHabitSelector(habits),

                    const SizedBox(height: AppSpacing.xl),

                    // Key Stats
                    _buildKeyStats(selectedHabit),

                    const SizedBox(height: AppSpacing.xl),

                    // Trend Section
                    _buildTrendSection(selectedHabit),

                    const SizedBox(height: AppSpacing.xl),

                    // Best Days
                    _buildBestDays(selectedHabit),

                    const SizedBox(height: AppSpacing.xl),

                    // Insights
                    _buildInsights(selectedHabit),

                    const SizedBox(height: AppSpacing.xl),

                    // Monthly History
                    _buildMonthlyHistory(selectedHabit),

                    const SizedBox(height: AppSpacing.xl),

                    // Streak History
                    _buildStreakHistory(selectedHabit),

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No habits yet',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Start tracking your habits to see analytics',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  'Create a Habit',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
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
        color: AppColors.surface.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights,
                    color: themeColor,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Analytics',
                    style: AppTypography.headlineSmall,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitSelector(List<Habit> habits) {
    final emoji = _getEmojiForHabit(habits[selectedHabitIndex]);
    final themeColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    selectedHabitIndex = (selectedHabitIndex - 1 + habits.length) % habits.length;
                  });
                },
                child: Icon(
                  Icons.chevron_left,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        habits[selectedHabitIndex].name,
                        style: AppTypography.headlineSmall.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Dots indicator
                  Row(
                    children: List.generate(habits.length, (index) {
                      return Container(
                        width: index == selectedHabitIndex ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index == selectedHabitIndex
                              ? themeColor
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    selectedHabitIndex = (selectedHabitIndex + 1) % habits.length;
                  });
                },
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${selectedHabitIndex + 1} of ${habits.length} habits',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _getEmojiForHabit(Habit habit) {
    final iconMap = {
      'pool': '🏊',
      'water': '💧',
      'fitness_center': '💪',
      'gym': '🏋️',
      'local_florist': '🌸',
      'plant': '🌱',
      'music_note': '🎵',
      'music': '🎧',
      'book': '📚',
      'meditation': '🧘',
      'run': '🏃',
      'walk': '🚶',
      'bike': '🚴',
      'sleep': '😴',
      'food': '🍎',
    };
    return iconMap[habit.icon.toLowerCase()] ?? '✨';
  }

  Widget _buildKeyStats(Habit habit) {
    final currentStreak = ref.watch(habitStreakProvider(habit));
    final bestStreak = ref.watch(habitBestStreakProvider(habit));
    final totalCompletions = ref.watch(habitTotalCompletionsProvider(habit));
    final themeColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            value: currentStreak.toString(),
            label: 'Current Streak',
            color: themeColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events,
            value: bestStreak.toString(),
            label: 'Best Streak',
            color: themeColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            value: totalCompletions.toString(),
            label: 'Completions',
            color: themeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              fontSize: 20,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(Habit habit) {
    final trendData = ref.watch(habitTrendDataProvider(habit));
    final themeColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: themeColor, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Trend',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(
                  color: themeColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                '30 days'.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: themeColor,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Real trend chart
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: CustomPaint(
                  size: const Size(double.infinity, 150),
                  painter: RealTrendChartPainter(trendData, themeColor),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getDateLabel(29),
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 9,
                      color: AppColors.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
                  Text(
                    _getDateLabel(15),
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 9,
                      color: AppColors.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
                  Text(
                    'Today',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 9,
                      color: AppColors.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDateLabel(int daysAgo) {
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    return DateFormat('d MMM').format(date);
  }

  Widget _buildBestDays(Habit habit) {
    final bestDays = ref.watch(habitBestDaysProvider(habit));
    final themeColor = Theme.of(context).colorScheme.primary;

    // Find best day
    int bestWeekday = 1;
    double bestPercentage = 0;
    bestDays.forEach((weekday, percentage) {
      if (percentage > bestPercentage) {
        bestPercentage = percentage;
        bestWeekday = weekday;
      }
    });

    final weekdayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekdayFullNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_view_week, color: themeColor, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Best Days',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            if (bestPercentage > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: themeColor, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      weekdayFullNames[bestWeekday],
                      style: AppTypography.labelSmall.copyWith(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final weekday = index + 1; // 1=Monday
              final value = bestDays[weekday] ?? 0.0;
              return Column(
                children: [
                  Text(
                    '${(value * 100).toInt()}%',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 32,
                    height: 80 * value,
                    decoration: BoxDecoration(
                      color: value > 0.7
                          ? themeColor.withOpacity(0.8)
                          : value > 0.4
                              ? themeColor.withOpacity(0.4)
                              : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    weekdayNames[index],
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInsights(Habit habit) {
    final insights = ref.watch(habitInsightsProvider(habit));
    final themeColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb, color: themeColor, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Insights',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInsightRow(Icons.local_fire_department, insights['streak'] ?? '', themeColor),
              const SizedBox(height: AppSpacing.md),
              _buildInsightRow(Icons.star, insights['bestDay'] ?? '', themeColor),
              const SizedBox(height: AppSpacing.md),
              _buildInsightRow(Icons.trending_up, insights['progress'] ?? '', themeColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(IconData icon, String text, Color themeColor) {
    return Row(
      children: [
        Icon(icon, color: themeColor, size: 18),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyHistory(Habit habit) {
    final monthlyData = ref.watch(habitMonthlyHistoryProvider(habit));
    final themeColor = Theme.of(context).colorScheme.primary;

    if (monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month, color: themeColor, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Monthly History',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: monthlyData.map((data) {
              final month = data['month'] as DateTime;
              final percentage = data['percentage'] as double;
              return Column(
                children: [
                  Text(
                    DateFormat('MMM').format(month),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 40,
                    height: 60 * percentage,
                    decoration: BoxDecoration(
                      color: percentage > 0.7
                          ? themeColor.withOpacity(0.8)
                          : percentage > 0.4
                              ? themeColor.withOpacity(0.4)
                              : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakHistory(Habit habit) {
    final streakHistory = ref.watch(habitStreakHistoryProvider(habit));
    final themeColor = Theme.of(context).colorScheme.primary;

    if (streakHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: themeColor, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Streak History',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: streakHistory.take(5).map((streak) {
              final start = streak['start'] as DateTime;
              final end = streak['end'] as DateTime;
              final length = streak['length'] as int;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, color: themeColor, size: 18),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$length day streak',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 8,
                      width: 80 * (length / 30).clamp(0.2, 1.0),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Real trend chart painter using actual data
class RealTrendChartPainter extends CustomPainter {
  final List<double> trendData;
  final Color themeColor;

  RealTrendChartPainter(this.trendData, this.themeColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (trendData.isEmpty) return;

    final paint = Paint()
      ..color = themeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = themeColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Calculate points from trend data
    final points = <Offset>[];
    final stepX = size.width / (trendData.length - 1);

    for (int i = 0; i < trendData.length; i++) {
      final x = i * stepX;
      final y = size.height - (trendData[i] * size.height * 0.8) - (size.height * 0.1);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Draw fill
    fillPath.moveTo(0, size.height);
    for (var point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    // Draw end point with glow if last value is completed
    if (trendData.isNotEmpty && trendData.last > 0) {
      final endPoint = points.last;
      final glowPaint = Paint()
        ..color = themeColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(endPoint, 4, glowPaint);
      canvas.drawCircle(endPoint, 3, Paint()..color = themeColor);
    }
  }

  @override
  bool shouldRepaint(covariant RealTrendChartPainter oldDelegate) {
    return oldDelegate.trendData != trendData || oldDelegate.themeColor != themeColor;
  }
}
