import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/aurora_scaffold.dart';
import '../../widgets/common/glass_ui.dart';
import '../auth/register_screen.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  String? _selectedLanguage;
  String? _selectedGoal;
  String? _selectedExperience;

  final List<Map<String, dynamic>> _languages = [
    {'code': 'ASL', 'name': 'American Sign Language', 'icon': Icons.flag_rounded},
    {'code': 'BSL', 'name': 'British Sign Language', 'icon': Icons.flag_rounded},
    {'code': 'MSL', 'name': 'Malaysian Sign Language', 'icon': Icons.flag_rounded},
    {'code': 'ISL', 'name': 'International Sign', 'icon': Icons.public_rounded},
  ];

  bool get _canContinue =>
      _selectedLanguage != null && _selectedGoal != null && _selectedExperience != null;

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferredSignLanguage', _selectedLanguage!);
    await prefs.setString('learningGoal', _selectedGoal!);
    await prefs.setString('experienceLevel', _selectedExperience!);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final goals = [
      {'id': 'casual', 'name': l10n.casualLearning, 'icon': Icons.self_improvement_rounded, 'desc': '5-10 min/day'},
      {'id': 'regular', 'name': l10n.regularPractice, 'icon': Icons.menu_book_rounded, 'desc': '15-20 min/day'},
      {'id': 'intensive', 'name': l10n.intensiveStudy, 'icon': Icons.rocket_launch_rounded, 'desc': '30+ min/day'},
    ];

    final experiences = [
      {'id': 'beginner', 'name': l10n.completeBeginner, 'icon': Icons.eco_rounded},
      {'id': 'some', 'name': l10n.knowSomeSigns, 'icon': Icons.spa_rounded},
      {'id': 'intermediate', 'name': l10n.intermediate, 'icon': Icons.park_rounded},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraScaffold(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconColor: AppColors.primary,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const TealGradientIcon(icon: Icons.tune_rounded, size: 36),
                    const SizedBox(width: 10),
                    Text(
                      l10n.preferencesTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sign Language Selection
                      _buildSectionTitle(Icons.language_rounded, l10n.chooseSignLanguage),
                      const SizedBox(height: 12),
                      _buildLanguageSelector(),
                      const SizedBox(height: 28),

                      // Learning Goal Selection
                      _buildSectionTitle(Icons.track_changes_rounded, l10n.dailyLearningGoal),
                      const SizedBox(height: 12),
                      _buildGoalSelector(goals),
                      const SizedBox(height: 28),

                      // Experience Level
                      _buildSectionTitle(Icons.bar_chart_rounded, l10n.experienceLevel),
                      const SizedBox(height: 12),
                      _buildExperienceSelector(experiences),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: GlassPrimaryButton(
                  label: _canContinue ? l10n.continueLabel : l10n.selectAllOptions,
                  onPressed: _canContinue ? _savePreferences : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      children: _languages.map((lang) {
        final isSelected = _selectedLanguage == lang['code'];
        return GestureDetector(
          onTap: () => setState(() => _selectedLanguage = lang['code'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: kGlassRadius,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.10),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    lang['icon'] as IconData,
                    color: isSelected ? AppColors.primary : context.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang['code'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? AppColors.primary : context.textPrimary,
                        ),
                      ),
                      Text(
                        lang['name'] as String,
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildGoalSelector(List<Map<String, dynamic>> goals) {
    return Row(
      children: goals.map((goal) {
        final isSelected = _selectedGoal == goal['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGoal = goal['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: goal != goals.last ? 10 : 0,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: kGlassRadius,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.10),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      goal['icon'] as IconData,
                      color: isSelected ? AppColors.primary : context.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goal['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isSelected ? AppColors.primary : context.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal['desc'] as String,
                    style: TextStyle(
                      color: context.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildExperienceSelector(List<Map<String, dynamic>> experiences) {
    return Column(
      children: experiences.map((exp) {
        final isSelected = _selectedExperience == exp['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedExperience = exp['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: kGlassRadius,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.10),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    exp['icon'] as IconData,
                    color: isSelected ? AppColors.primary : context.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    exp['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected ? AppColors.primary : context.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 300.ms);
  }
}
