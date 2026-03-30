import 'package:flutter/material.dart';
import '../utils/theme.dart';

class HeatmapGrid extends StatelessWidget {
  final List<bool> data; // List of 8 boolean values for past days
  final Color color;
  final double squareSize;
  final double spacing;

  const HeatmapGrid({
    super.key,
    required this.data,
    required this.color,
    this.squareSize = 14,
    this.spacing = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final completed = entry.value;
        
        // Calculate opacity based on position (more recent = more opaque)
        final opacity = completed
            ? 1.0
            : (0.2 - (index * 0.02)).clamp(0.05, 0.2);

        return Container(
          width: squareSize,
          height: squareSize,
          margin: EdgeInsets.only(
            right: index < data.length - 1 ? spacing : 0,
          ),
          decoration: BoxDecoration(
            color: completed
                ? color
                : color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }
}

class WeekHeatmap extends StatelessWidget {
  final List<double> data; // 7 days of activity values (0.0 to 1.0)
  final List<Color> colors;
  final double barWidth;
  final double barHeight;
  final bool showLabels;
  final int? selectedIndex;

  const WeekHeatmap({
    super.key,
    required this.data,
    required this.colors,
    this.barWidth = 40,
    this.barHeight = 64,
    this.showLabels = true,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        final isSelected = selectedIndex == index;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: colors.first.withOpacity(0.3),
                          width: 2,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Stack colors if multiple
                    ...colors.asMap().entries.map((colorEntry) {
                      final colorIndex = colorEntry.key;
                      final color = colorEntry.value;
                      final heightPercent = value * (1 - colorIndex * 0.3);
                      
                      return Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: barHeight * heightPercent,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.4 - colorIndex * 0.1),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(8),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              if (showLabels) ...[
                const SizedBox(height: 4),
                Text(
                  days[index],
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? colors.first
                        : AppColors.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class CalendarDay extends StatelessWidget {
  final int? day;
  final bool isCompleted;
  final bool isToday;
  final bool isInMonth;
  final Color accentColor;
  final VoidCallback? onTap;

  const CalendarDay({
    super.key,
    this.day,
    this.isCompleted = false,
    this.isToday = false,
    this.isInMonth = true,
    this.accentColor = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null || !isInMonth) {
      return const SizedBox.shrink();
    }

    Widget dayWidget;

    if (isCompleted) {
      dayWidget = Container(
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (isToday) {
      dayWidget = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: accentColor.withOpacity(0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: accentColor.withOpacity(0.05),
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      dayWidget = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: AppTypography.labelLarge.copyWith(
              color: isInMonth
                  ? AppColors.onSurfaceVariant
                  : AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: dayWidget,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: dayWidget,
    );
  }
}
