import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onFabTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.grid_view_rounded, 0, themeColor),
              _buildNavItem(Icons.checklist_rounded, 1, themeColor),
              _buildFab(themeColor),
              _buildNavItem(Icons.calendar_month_rounded, 2, themeColor),
              _buildNavItem(Icons.settings_rounded, 3, themeColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, Color themeColor) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        width: 60,
        decoration: BoxDecoration(
          // 🔥 Keep circle but invisible
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isSelected ? themeColor : AppColors.onSurfaceVariant,
            size: isSelected ? 26 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFab(Color themeColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onFabTap?.call();
      },
      child: SizedBox(
        height: 56,
        width: 56,
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              color: Colors.black,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
