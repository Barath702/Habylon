import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/database_providers.dart';
import '../providers/settings_providers.dart';
import '../utils/theme.dart';
import '../widgets/glass_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final themeColor = ref.watch(themeColorProvider);
    final habitsAsync = ref.watch(habitsProvider);

    // Calculate current streak from habits
    final currentStreak = habitsAsync.when(
      data: (habits) {
        if (habits.isEmpty) return 0;
        return habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
      },
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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
                // Profile Section
                _buildProfileSection(profile, currentStreak),

                const SizedBox(height: AppSpacing.xl),

                // App Settings
                _buildAppSettings(themeColor),

                const SizedBox(height: AppSpacing.xl),

                // Data Management
                _buildDataManagementSection(),

                const SizedBox(height: AppSpacing.xl),

                // About
                _buildAboutSection(),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
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
          Text(
            'Settings',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildProfileSection(ProfileState profile, int currentStreak) {
    return GestureDetector(
      onTap: _showEditProfileDialog,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: profile.avatarPath != null && File(profile.avatarPath!).existsSync()
                  ? Image.file(
                      File(profile.avatarPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(profile.name),
                    )
                  : _buildDefaultAvatar(profile.name),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: AppTypography.headlineSmall.copyWith(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                currentStreak > 0 ? '$currentStreak Day Streak' : 'Start your streak today',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.edit,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: AppTypography.headlineMedium.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAppSettings(AppThemeColor themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Settings'.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.palette,
                title: 'Theme',
                subtitle: themeColor.name,
                onTap: _showThemePicker,
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.widgets,
                title: 'Home Screen Widgets',
                subtitle: 'Track habits from your home screen',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection() {
    final backupService = ref.read(backupProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data'.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.download,
                title: 'Export Data',
                subtitle: 'Save backup as JSON file',
                onTap: () => _exportData(backupService),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.upload,
                title: 'Import Data',
                subtitle: 'Restore from backup file',
                onTap: () => _importData(backupService),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.delete_forever,
                title: 'Delete All Data',
                subtitle: 'Remove all habits and data',
                isDestructive: true,
                onTap: _showDeleteConfirmation,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About'.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.info,
                title: 'About Habylon',
                subtitle: 'View on GitHub',
                onTap: () async {
                  final uri = Uri.parse('https://github.com/Barath702/Habylon');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'Version 1.0.0',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.error.withOpacity(0.1)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.error : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDestructive ? AppColors.error : AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  void _showThemePicker() {
    final currentTheme = ref.read(themeColorProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
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
              'Choose Theme',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: AppThemeColor.values.map((color) {
                final isSelected = color == currentTheme;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(themeColorProvider.notifier).setThemeColor(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: AppColors.onSurface,
                          )
                        : null,
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

  void _showEditProfileDialog() {
    final profile = ref.read(profileProvider);
    final nameController = TextEditingController(text: profile.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: Text(
          'Edit Profile',
          style: AppTypography.headlineSmall,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar selection
            GestureDetector(
              onTap: _showAvatarPicker,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: profile.avatarPath != null && File(profile.avatarPath!).existsSync()
                    ? ClipOval(
                        child: Image.file(
                          File(profile.avatarPath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.camera_alt,
                        color: AppColors.onSurfaceVariant,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tap to change avatar',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Name field
            TextField(
              controller: nameController,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: AppTypography.labelMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
            ),
          ],
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
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(profileProvider.notifier).setName(name);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Save',
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

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
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
              'Choose Avatar',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            ListTile(
              leading: Icon(Icons.camera, color: Theme.of(context).colorScheme.primary),
              title: Text('Take Photo', style: AppTypography.bodyMedium),
              onTap: () async {
                Navigator.pop(context);
                final image = await _imagePicker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  ref.read(profileProvider.notifier).setAvatarPath(image.path);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
              title: Text('Choose from Gallery', style: AppTypography.bodyMedium),
              onTap: () async {
                Navigator.pop(context);
                final image = await _imagePicker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  ref.read(profileProvider.notifier).setAvatarPath(image.path);
                }
              },
            ),
            if (ref.read(profileProvider).avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: Text('Remove Avatar', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(profileProvider.notifier).setAvatarPath(null);
                },
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BackupService backupService) async {
    final path = await backupService.exportData();
    if (path != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to: $path', style: AppTypography.bodyMedium),
            backgroundColor: AppColors.surfaceContainer,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed', style: AppTypography.bodyMedium),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _importData(BackupService backupService) async {
    final success = await backupService.importData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Data imported successfully' : 'Import failed',
            style: AppTypography.bodyMedium,
          ),
          backgroundColor: success ? AppColors.surfaceContainer : AppColors.error,
        ),
      );
      if (success) {
        // Refresh the app state
        ref.invalidate(habitsProvider);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: Text(
          'Delete All Data?',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.error),
        ),
        content: Text(
          'This will permanently delete all your habits, completions, and tasks. This action cannot be undone.',
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
              final deleteFn = ref.read(deleteAllDataProvider);
              final success = await deleteFn();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'All data deleted' : 'Delete failed',
                      style: AppTypography.bodyMedium,
                    ),
                    backgroundColor: success ? AppColors.surfaceContainer : AppColors.error,
                  ),
                );
                if (success) {
                  ref.invalidate(habitsProvider);
                }
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
