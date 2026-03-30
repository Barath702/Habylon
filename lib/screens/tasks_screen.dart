import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/database_providers.dart';
import '../utils/theme.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/bottom_nav.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool isTimelineView = true;
  bool showCompleted = true;

  // Generate 14-day timeline: past 7 days + today + next 6 days
  List<DateTime> get _timelineDates {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(14, (index) {
      return today.subtract(Duration(days: 7 - index));
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (tasks) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              SliverToBoxAdapter(child: _buildTabSwitcher()),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    isTimelineView 
                      ? _buildTimelineView(tasks)
                      : _buildAllTasksView(tasks),
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

  Widget _buildAppBar() {
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
          Text('Tasks', style: AppTypography.headlineSmall),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Row(
        children: [
          _buildTab('Timeline', isTimelineView, () => setState(() => isTimelineView = true), themeColor),
          const SizedBox(width: AppSpacing.xl),
          _buildTab('All Tasks', !isTimelineView, () => setState(() => isTimelineView = false), themeColor),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap, Color themeColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? themeColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: isActive ? themeColor : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // TIMELINE VIEW: Shows 14-day vertical timeline with glowing line
  Widget _buildTimelineView(List<Task> allTasks) {
    final dateFormat = DateFormat('MMM d');
    final dayFormat = DateFormat('EEEE');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final themeColor = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        // Vertical timeline line
        Positioned(
          left: 15,
          top: 20,
          bottom: 50,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),

        // Timeline items
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _timelineDates.map((date) {
              final isToday = date.year == today.year && 
                              date.month == today.month && 
                              date.day == today.day;
              
              // Get tasks for this specific date
              final dayTasks = allTasks.where((t) {
                final taskDate = DateTime(t.date.year, t.date.month, t.date.day);
                return taskDate.year == date.year && 
                       taskDate.month == date.month && 
                       taskDate.day == date.day;
              }).toList();

              final completedCount = dayTasks.where((t) => t.completed).length;
              final allCompleted = completedCount == dayTasks.length && dayTasks.isNotEmpty;
              final hasTasks = dayTasks.isNotEmpty;

              return _buildTimelineDateItem(
                date: date,
                isToday: isToday,
                dateFormat: dateFormat,
                dayFormat: dayFormat,
                tasks: dayTasks,
                completedCount: completedCount,
                allCompleted: allCompleted,
                hasTasks: hasTasks,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDateItem({
    required DateTime date,
    required bool isToday,
    required DateFormat dateFormat,
    required DateFormat dayFormat,
    required List<Task> tasks,
    required int completedCount,
    required bool allCompleted,
    required bool hasTasks,
  }) {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Timeline node (circle)
          Positioned(
            left: -41,
            top: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isToday ? themeColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isToday 
                      ? themeColor 
                      : hasTasks 
                          ? themeColor.withOpacity(0.5)
                          : AppColors.outlineVariant,
                  width: isToday ? 3 : 2,
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header row
              Row(
                children: [
                  Text(
                    dateFormat.format(date),
                    style: AppTypography.headlineSmall.copyWith(
                      fontSize: 16,
                      color: isToday ? themeColor : AppColors.onSurface,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    dayFormat.format(date).substring(0, 3),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TODAY',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Task count indicator
                  if (hasTasks)
                    Text(
                      '$completedCount/${tasks.length}',
                      style: AppTypography.labelMedium.copyWith(
                        color: allCompleted ? themeColor : AppColors.onSurfaceVariant,
                      ),
                    ),
                  if (hasTasks)
                    const SizedBox(width: AppSpacing.sm),
                  if (hasTasks)
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Tasks for this date
              if (tasks.isNotEmpty) ...[
                ...tasks.map((task) => _buildTaskItem(task)),
                
                // Completed section toggle
                if (completedCount > 0 && completedCount < tasks.length)
                  _buildCompletedToggle(completedCount),

                // All done card
                if (allCompleted)
                  _buildAllDoneCard(completedCount),
              ],

              // Add task button for today and future dates
              if (isToday || date.isAfter(DateTime.now()))
                _buildAddTaskButton(date),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final categoryColor = _getCategoryColor(task.category);
    final themeColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () => _toggleTaskCompletion(task),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleTaskCompletion(task),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  task.completed
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: task.completed
                      ? themeColor
                      : AppColors.outlineVariant,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                task.title,
                style: AppTypography.bodyMedium.copyWith(
                  decoration: task.completed ? TextDecoration.lineThrough : null,
                  color: task.completed 
                      ? AppColors.onSurfaceVariant 
                      : AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedToggle(int completedCount) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => showCompleted = !showCompleted);
      },
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              showCompleted ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Completed $completedCount',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllDoneCard(int completedCount) {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: themeColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: themeColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'All done! ',
            style: AppTypography.labelMedium.copyWith(
              color: themeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$completedCount task${completedCount > 1 ? 's' : ''} completed',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTaskButton(DateTime date) {
    final isToday = _isToday(date);
    final themeColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () => _showAddTaskDialog(initialDate: date),
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isToday ? AppColors.surfaceContainerLow : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isToday 
                ? AppColors.outlineVariant.withOpacity(0.3) 
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: themeColor, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Add task',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ALL TASKS VIEW: Shows all tasks regardless of date
  Widget _buildAllTasksView(List<Task> allTasks) {
    final incompleteTasks = allTasks.where((t) => !t.completed).toList();
    final completedTasks = allTasks.where((t) => t.completed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // My Tasks section header
        Row(
          children: [
            Text(
              'My Tasks',
              style: AppTypography.headlineSmall.copyWith(fontSize: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
              ),
              child: Icon(Icons.add, color: AppColors.onSurfaceVariant, size: 16),
            ),
            if (allTasks.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${allTasks.length}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Incomplete tasks
        ...incompleteTasks.map((task) => _buildAllTasksItem(task)),

        // Empty state
        if (incompleteTasks.isEmpty && completedTasks.isEmpty)
          _buildEmptyState(),

        // Completed section
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () => setState(() => showCompleted = !showCompleted),
            child: Row(
              children: [
                Icon(
                  showCompleted ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Completed ${completedTasks.length}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (showCompleted) ...[
            const SizedBox(height: AppSpacing.md),
            ...completedTasks.map((task) => _buildAllTasksItem(task)),
          ],
        ],

        // Add new task button
        const SizedBox(height: AppSpacing.lg),
        GestureDetector(
          onTap: () => _showAddTaskDialog(),
          child: Row(
            children: [
              Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'New Task',
                style: AppTypography.labelLarge.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllTasksItem(Task task) {
    final categoryColor = _getCategoryColor(task.category);
    final dateText = _getRelativeDateText(task.date);
    final themeColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () => _toggleTaskCompletion(task),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleTaskCompletion(task),
              child: Icon(
                task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.completed ? themeColor : AppColors.outlineVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTypography.bodyMedium.copyWith(
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      color: task.completed ? AppColors.onSurfaceVariant : AppColors.onSurface,
                    ),
                  ),
                  if (task.category.isNotEmpty)
                    Text(
                      task.category,
                      style: AppTypography.labelSmall.copyWith(
                        color: categoryColor,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              dateText,
              style: AppTypography.labelSmall.copyWith(
                color: dateText.contains('Today') || dateText.contains('Tomorrow')
                    ? themeColor
                    : dateText.contains('Yesterday') || _isPastDate(task.date)
                        ? AppColors.tertiary
                        : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _getRelativeDateText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    final difference = taskDate.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == -1) return 'Yesterday';
    if (difference == 1) return 'Tomorrow';
    if (difference > 1 && difference < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMM d').format(date);
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    return taskDate.isBefore(today);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Icon(Icons.task_alt, size: 48, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: AppSpacing.md),
          Text('No tasks yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          Text('Tap + to add your first task', style: AppTypography.labelMedium),
        ],
      ),
    );
  }

  void _toggleTaskCompletion(Task task) async {
    HapticFeedback.mediumImpact();
    final repo = ref.read(taskRepositoryProvider);
    await repo.updateTask(task.copyWith(completed: !task.completed));
  }

  void _showAddTaskDialog({DateTime? initialDate}) {
    // Validate input before showing dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddTaskSheet(
        initialDate: initialDate ?? DateTime.now(),
        onAdd: (title, category, date) async {
          // Input validation
          final trimmedTitle = title.trim();
          if (trimmedTitle.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task name cannot be empty')),
            );
            return;
          }
          if (trimmedTitle.length > 100) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task name too long (max 100 characters)')),
            );
            return;
          }
          
          try {
            final repo = ref.read(taskRepositoryProvider);
            await repo.addTask(Task(
              title: trimmedTitle,
              category: category,
              date: date,
              completed: false,
            ));
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add task: $e')),
              );
            }
          }
        },
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'personal': return AppColors.tertiary;
      case 'work': return AppColors.primary;
      case 'health': return AppColors.secondary;
      default: return AppColors.primary;
    }
  }
}

class _AddTaskSheet extends StatefulWidget {
  final Function(String title, String category, DateTime date) onAdd;
  final DateTime initialDate;

  const _AddTaskSheet({required this.onAdd, required this.initialDate});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _controller = TextEditingController();
  String selectedCategory = 'Personal';
  late DateTime selectedDate;
  final categories = ['Personal', 'Work', 'Health'];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Task', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            
            // Task title input
            TextField(
              controller: _controller,
              autofocus: true,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
                filled: true,
                fillColor: AppColors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Category selection
            Text('Category', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                final color = _getCategoryColor(cat);
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.2) : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected ? color : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Date picker
            Text('Date', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: AppColors.secondary,
                          surface: AppColors.surfaceContainer,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.secondary, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                      style: AppTypography.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Add button
            SizedBox(
              width: double.infinity,
              child: NeonButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    widget.onAdd(_controller.text, selectedCategory, selectedDate);
                  }
                },
                child: Text(
                  'Add Task',
                  style: AppTypography.labelLarge.copyWith(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'personal': return AppColors.tertiary;
      case 'work': return AppColors.primary;
      case 'health': return AppColors.secondary;
      default: return AppColors.primary;
    }
  }
}
