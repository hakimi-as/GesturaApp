import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../providers/theme_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewCard(context),
                    const SizedBox(height: 24),
                    _buildThemeOptions(context),
                    const SizedBox(height: 24),
                    _buildInfoCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Icon(
                Icons.arrow_back,
                color: context.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text('🎨', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildPreviewCard(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Theme',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDark ? 'Dark Mode' : 'Light Mode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Mini Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildMiniPreview(context, true),
                const SizedBox(width: 12),
                _buildMiniPreview(context, false),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildMiniPreview(BuildContext context, bool isDark) {
    final isActive = context.isDarkMode == isDark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⚙️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Choose Theme',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Container(
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  _buildThemeOption(
                    context,
                    icon: Icons.light_mode,
                    title: 'Light',
                    subtitle: 'Bright and clear',
                    isSelected: themeProvider.themeMode == AppThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(AppThemeMode.light),
                  ),
                  Divider(height: 1, indent: 70, color: context.borderColor),
                  _buildThemeOption(
                    context,
                    icon: Icons.dark_mode,
                    title: 'Dark',
                    subtitle: 'Easy on the eyes',
                    isSelected: themeProvider.themeMode == AppThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(AppThemeMode.dark),
                  ),
                  Divider(height: 1, indent: 70, color: context.borderColor),
                  _buildThemeOption(
                    context,
                    icon: Icons.settings_brightness,
                    title: 'System',
                    subtitle: 'Match device settings',
                    isSelected: themeProvider.themeMode == AppThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(AppThemeMode.system),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlpha(30)
                    : context.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : context.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected ? AppColors.primary : context.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.borderColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Dark mode can help reduce eye strain, especially in low-light conditions.',
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}