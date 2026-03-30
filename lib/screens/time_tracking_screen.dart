import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/habit.dart';
import '../providers/database_providers.dart';
import '../utils/theme.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/heatmap_widgets.dart';
import '../widgets/bottom_nav.dart';
import 'package:intl/intl.dart';

class TimeTrackingScreen extends ConsumerStatefulWidget {
  const TimeTrackingScreen({super.key});

  @override
  ConsumerState<TimeTrackingScreen> createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends ConsumerState<TimeTrackingScreen> {
  String selectedCategory = 'Art';
  final List<String> categories = ['Art', 'Work', 'Health'];

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (habits) {
          // Filter time-based habits
          final timeHabits = habits.where((h) => h.type == HabitType.time).toList();

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
                    // Date Header
                    _buildDateHeader(now),

                    const SizedBox(height: AppSpacing.xl),

                    // Weekly Indicators
                    _buildWeeklyIndicators(),

                    const SizedBox(height: AppSpacing.xl),

                    // Category Chips
                    _buildCategoryChips(),

                    const SizedBox(height: AppSpacing.xl),

                    // Time Tracker Cards
                    ...timeHabits.map((habit) => _buildTimeTrackerCard(habit)),

                    if (timeHabits.isEmpty)
                      _buildEmptyState(),

                    const SizedBox(height: AppSpacing.xl),

                    // Activity Density Chart
                    _buildActivityDensityChart(),

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) => _onNavTap(index, context),
        onFabTap: () => context.push('/add-habit'),
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
                    Icons.menu,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Today',
                    style: AppTypography.headlineSmall,
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: AppColors.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Icon(
                    Icons.visibility_off_outlined,
                    color: AppColors.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Icon(
                    Icons.settings_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime now) {
    final monthFormat = DateFormat('MMMM');
    final dayFormat = DateFormat('d');
    final weekdayFormat = DateFormat('EEE');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthFormat.format(now),
              style: AppTypography.labelMedium.copyWith(
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${dayFormat.format(now)}th, ',
                    style: AppTypography.headlineLarge,
                  ),
                  TextSpan(
                    text: weekdayFormat.format(now),
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '3/8 TASKS',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: 96,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.375,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyIndicators() {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final today = DateTime.now().weekday - 1; // 0 = Monday

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        final isToday = index == today;
        final isPast = index < today;

        return Column(
          children: [
            Container(
              width: isToday ? 48 : 40,
              height: isToday ? 48 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isToday
                      ? AppColors.primary
                      : isPast
                          ? AppColors.secondary
                          : AppColors.outlineVariant,
                  width: isToday ? 2 : 1,
                ),
                color: isToday
                    ? AppColors.primary.withOpacity(0.1)
                    : isPast
                        ? AppColors.secondary.withOpacity(0.05)
                        : null,
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ]
                    : isPast
                        ? [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.15),
                              blurRadius: 15,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
              ),
              child: Center(
                child: Text(
                  day,
                  style: AppTypography.labelSmall.copyWith(
                    color: isToday
                        ? AppColors.primary
                        : isPast
                            ? AppColors.secondary
                            : AppColors.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: isToday ? 10 : 9,
                  ),
                ),
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: CategoryChip(
              label: category,
              isSelected: isSelected,
              accentColor: AppColors.primary,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => selectedCategory = category);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeTrackerCard(Habit habit) {
    final color = _getColorFromString(habit.color);

    return GlowContainer(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          habit.name,
                          style: AppTypography.headlineSmall.copyWith(
                            color: color,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.streak} DAY STREAK',
                          style: AppTypography.labelSmall,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.targetTime?.toStringAsFixed(1) ?? "0.0"}H TOTAL',
                          style: AppTypography.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildActionButton(Icons.refresh, color),
                    const SizedBox(width: AppSpacing.sm),
                    _buildActionButton(Icons.add, color, filled: true),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Time Grid
            _buildTimeGrid(color),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildActionButton(IconData icon, Color color, {bool filled = false}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: filled ? color : AppColors.surfaceContainerHighest,
        shape: BoxShape.circle,
        boxShadow: filled
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: filled ? AppColors.onPrimary : color,
        size: 20,
      ),
    );
  }

  Widget _buildTimeGrid(Color color) {
    final days = ['Mon', 'Tue', 'Wed'];
    final weeks = ['Wk 01', 'Wk 02', 'Wk 03', 'Today'];

    return Column(
      children: [
        // Header row
        Row(
          children: [
            const SizedBox(width: 50),
            ...weeks.map((week) => Expanded(
              child: Text(
                week,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: week == 'Today' ? color : AppColors.onSurfaceVariant,
                  fontWeight: week == 'Today' ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            )),
          ],
        ),
        
        const SizedBox(height: AppSpacing.sm),

        // Data rows
        ...days.map((day) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    day,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                ...['1.25', '2.00', '0.50', '1.50'].map((value) => Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: value == '1.50' ? color : AppColors.onSurface,
                      fontWeight: value == '1.50' ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                )),
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: AppSpacing.sm),

        // Total row
        Container(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: color.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  'TOTAL',
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...['4.0h', '3.5h', '3.7h', '4.5h'].map((value) => Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: value == '4.5h' ? color : AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Icon(
            Icons.timer_outlined,
            size: 48,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No time trackers yet',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Create a time-tracked habit to see it here',
            style: AppTypography.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDensityChart() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Density',
            style: AppTypography.labelLarge.copyWith(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          WeekHeatmap(
            data: [0.6, 0.4, 0.8, 0.1, 0.95, 0.3, 0.0],
            colors: [AppColors.primary, AppColors.secondary],
            barHeight: 64,
            selectedIndex: 4,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
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
      default:
        return AppColors.primary;
    }
  }

  void _onNavTap(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/tasks');
        break;
      case 2:
        context.go('/calendar');
        break;
      case 3:
        break;
    }
  }
}
