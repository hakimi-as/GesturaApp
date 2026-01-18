import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
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

  final List<Map<String, String>> _languages = [
    {'code': 'ASL', 'name': 'American Sign Language', 'emoji': '🇺🇸'},
    {'code': 'BSL', 'name': 'British Sign Language', 'emoji': '🇬🇧'},
    {'code': 'MSL', 'name': 'Malaysian Sign Language', 'emoji': '🇲🇾'},
    {'code': 'ISL', 'name': 'International Sign', 'emoji': '🌍'},
  ];

  final List<Map<String, String>> _goals = [
    {'id': 'casual', 'name': 'Casual Learning', 'emoji': '🎯', 'desc': '5-10 min/day'},
    {'id': 'regular', 'name': 'Regular Practice', 'emoji': '📚', 'desc': '15-20 min/day'},
    {'id': 'intensive', 'name': 'Intensive Study', 'emoji': '🚀', 'desc': '30+ min/day'},
  ];

  final List<Map<String, String>> _experiences = [
    {'id': 'beginner', 'name': 'Complete Beginner', 'emoji': '🌱'},
    {'id': 'some', 'name': 'Know Some Signs', 'emoji': '🌿'},
    {'id': 'intermediate', 'name': 'Intermediate', 'emoji': '🌳'},
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
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
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
                  const Text('⚙️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
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
                    _buildSectionTitle('🌐', 'Choose Your Sign Language'),
                    const SizedBox(height: 12),
                    _buildLanguageSelector(),
                    const SizedBox(height: 28),

                    // Learning Goal Selection
                    _buildSectionTitle('🎯', 'Daily Learning Goal'),
                    const SizedBox(height: 12),
                    _buildGoalSelector(),
                    const SizedBox(height: 28),

                    // Experience Level
                    _buildSectionTitle('📊', 'Your Experience Level'),
                    const SizedBox(height: 12),
                    _buildExperienceSelector(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue ? _savePreferences : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canContinue ? AppColors.primary : context.bgElevated,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: context.bgElevated,
                    disabledForegroundColor: context.textMuted,
                  ),
                  child: Text(
                    _canContinue ? 'Continue' : 'Select All Options',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
          onTap: () => setState(() => _selectedLanguage = lang['code']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withAlpha(20) : context.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : context.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(lang['emoji']!, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang['code']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? AppColors.primary : context.textPrimary,
                        ),
                      ),
                      Text(
                        lang['name']!,
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildGoalSelector() {
    return Row(
      children: _goals.map((goal) {
        final isSelected = _selectedGoal == goal['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGoal = goal['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: goal != _goals.last ? 10 : 0,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withAlpha(20) : context.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(goal['emoji']!, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    goal['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSelected ? AppColors.primary : context.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal['desc']!,
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

  Widget _buildExperienceSelector() {
    return Column(
      children: _experiences.map((exp) {
        final isSelected = _selectedExperience == exp['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedExperience = exp['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withAlpha(20) : context.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : context.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(exp['emoji']!, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    exp['name']!,
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
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