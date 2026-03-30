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
import '../widgets/bottom_nav.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final Habit? habit;

  const AddEditHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  late HabitType _habitType;
  late Frequency _frequency;
  int _daysPerWeek = 3;

  final List<String> _icons = [
    'water_drop',
    'fitness_center',
    'book',
    'self_improvement',
    'directions_run',
    'bedtime',
    'restaurant',
    'music_note',
  ];

  final List<Map<String, dynamic>> _colors = [
    {'name': 'primary', 'color': AppColors.primary},
    {'name': 'secondary', 'color': AppColors.secondary},
    {'name': 'tertiary', 'color': AppColors.tertiary},
    {'name': 'lightBlue', 'color': const Color(0xFF4FC3F7)},
    {'name': 'error', 'color': AppColors.error},
    {'name': 'errorContainer', 'color': AppColors.errorContainer},
  ];

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _nameController = TextEditingController(text: habit?.name ?? '');
    _selectedIcon = habit?.icon ?? 'water_drop';
    _selectedColor = habit?.color ?? 'primary';
    _habitType = HabitType.check;
    _frequency = habit?.frequency ?? Frequency.daily;
    _daysPerWeek = habit?.targetDaysPerWeek ?? 3;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;
    final selectedColorValue = _getColorFromString(_selectedColor);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverToBoxAdapter(
            child: _buildAppBar(isEditing),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Icon Selector
                _buildIconSelector(selectedColorValue),

                const SizedBox(height: AppSpacing.xxl),

                // Habit Name Input
                _buildNameInput(),

                const SizedBox(height: AppSpacing.xxl),

                // Color Picker
                _buildColorPicker(),

                const SizedBox(height: AppSpacing.xxl),

                // Goal Frequency
                _buildFrequencySection(),

                const SizedBox(height: AppSpacing.xxl),

                // Days per week
                if (_frequency == Frequency.weekly)
                  _buildDaysPerWeekSelector(selectedColorValue),

                if (_frequency == Frequency.weekly)
                  const SizedBox(height: AppSpacing.xxl),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButton(isEditing, selectedColorValue),
    );
  }

  Widget _buildAppBar(bool isEditing) {
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
              GestureDetector(
                onTap: () => context.pop(),
                child: Icon(
                  Icons.close,
                  color: AppColors.onSurfaceVariant,
                  size: 28,
                ),
              ),
              Text(
                isEditing ? 'Edit Habit' : 'New Habit',
                style: AppTypography.headlineSmall,
              ),
              GestureDetector(
                onTap: _saveHabit,
                child: Text(
                  'Save',
                  style: AppTypography.labelLarge.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSelector(Color selectedColor) {
    return Column(
      children: [
        // Selected Icon Display - Single squircle with glow
        GestureDetector(
          onTap: () => _showIconPicker(),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withOpacity(0.5),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: selectedColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _getIconFromString(_selectedIcon),
              color: selectedColor,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tap to change icon',
          style: AppTypography.labelMedium.copyWith(
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: Text(
            'Habit Name *',
            style: AppTypography.labelMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _nameController,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: 'What habit do you want to build?',
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: Text(
            'Choose Color',
            style: AppTypography.labelMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _colors.map((colorData) {
              final isSelected = _selectedColor == colorData['name'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedColor = colorData['name']);
                },
                child: Container(
                  width: isSelected ? 48 : 40,
                  height: isSelected ? 48 : 40,
                  margin: const EdgeInsets.only(right: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorData['color'],
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: AppColors.onSurface,
                            width: 3,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (colorData['color'] as Color).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 24,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySection() {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completion Target',
                  style: AppTypography.headlineSmall.copyWith(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Set a goal for this habit',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _frequency = Frequency.daily);
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: _frequency == Frequency.daily
                        ? themeColor.withOpacity(0.1)
                        : AppColors.glassCardBackground,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(
                      color: _frequency == Frequency.daily
                          ? themeColor.withOpacity(0.5)
                          : AppColors.glassCardBorder,
                      width: _frequency == Frequency.daily ? 2 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _frequency == Frequency.daily
                            ? themeColor
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Daily',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _frequency = Frequency.weekly);
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: _frequency == Frequency.weekly
                        ? themeColor.withOpacity(0.1)
                        : AppColors.glassCardBackground,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(
                      color: _frequency == Frequency.weekly
                          ? themeColor.withOpacity(0.5)
                          : AppColors.glassCardBorder,
                      width: _frequency == Frequency.weekly ? 2 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.event_repeat,
                            color: _frequency == Frequency.weekly
                                ? themeColor
                                : AppColors.onSurfaceVariant,
                          ),
                          if (_frequency == Frequency.weekly)
                            Icon(
                              Icons.check_circle,
                              color: themeColor,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Weekly',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildDaysPerWeekSelector(Color color) {
    final themeColor = Theme.of(context).colorScheme.primary;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Days per week',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Recommended: 3 days',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: themeColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_daysPerWeek > 1) {
                      HapticFeedback.lightImpact();
                      setState(() => _daysPerWeek--);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: themeColor,
                      size: 18,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$_daysPerWeek',
                    style: AppTypography.headlineSmall.copyWith(
                      color: themeColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_daysPerWeek < 7) {
                      HapticFeedback.lightImpact();
                      setState(() => _daysPerWeek++);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: themeColor,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isEditing, Color color) {
    final isNameEmpty = _nameController.text.isEmpty;
    final themeColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background,
            AppColors.background.withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: NeonButton(
        onPressed: isNameEmpty ? null : _saveHabit,
        width: double.infinity,
        height: 64,
        backgroundColor: isNameEmpty ? Colors.grey.shade700 : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isEditing ? 'Update Habit' : 'Create Habit',
              style: AppTypography.labelLarge.copyWith(
                color: isNameEmpty ? Colors.grey.shade400 : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward,
              color: isNameEmpty ? Colors.grey.shade400 : Colors.black,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker() {
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
            Text(
              'Select Icon',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: _icons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIcon = icon);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      _getIconFromString(icon),
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      size: 28,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  IconData _getIconFromString(String icon) {
    switch (icon) {
      case 'music_note':
      case 'music':
        return Icons.music_note;
      case 'fitness_center':
      case 'gym':
        return Icons.fitness_center;
      case 'water_drop':
      case 'water':
        return Icons.water_drop;
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
      default:
        return Icons.check_circle;
    }
  }

  Color _getColorFromString(String color) {
    switch (color.toLowerCase()) {
      case 'primary':
        return AppColors.primary;
      case 'secondary':
        return AppColors.secondary;
      case 'tertiary':
        return AppColors.tertiary;
      case 'lightblue':
      case 'light_blue':
        return const Color(0xFF4FC3F7);
      case 'error':
        return AppColors.error;
      case 'errorcontainer':
      case 'error_container':
        return AppColors.errorContainer;
      default:
        return AppColors.primary;
    }
  }

  void _saveHabit() async {
    if (_nameController.text.isEmpty) return;

    HapticFeedback.mediumImpact();

    final repo = ref.read(habitRepositoryProvider);
    
    if (widget.habit != null) {
      // Update existing habit
      final updatedHabit = widget.habit!.copyWith(
        name: _nameController.text,
        icon: _selectedIcon,
        color: _selectedColor,
        type: _habitType,
        frequency: _frequency,
        targetDaysPerWeek: _daysPerWeek,
      );
      await repo.updateHabit(updatedHabit);
    } else {
      // Create new habit
      final newHabit = Habit(
        name: _nameController.text,
        icon: _selectedIcon,
        color: _selectedColor,
        type: _habitType,
        frequency: _frequency,
        targetDaysPerWeek: _daysPerWeek,
      );
      await repo.addHabit(newHabit);
    }

    if (mounted) {
      context.pop();
    }
  }
}
