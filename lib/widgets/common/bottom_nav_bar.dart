import 'package:flutter/material.dart';
import '../../config/theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgCard,  // ← Theme-aware
        border: Border(
          top: BorderSide(color: context.borderColor, width: 1),  // ← Theme-aware
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,  // ← Pass context
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.translate_outlined,
                activeIcon: Icons.translate,
                label: 'Translate',
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                label: 'Learn',
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,  // ← Add context parameter
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : context.textMuted,  // ← Theme-aware
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : context.textMuted,  // ← Theme-aware
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}