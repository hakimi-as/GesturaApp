import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../services/haptic_service.dart';
import '../../screens/learn/learning_paths_screen.dart';
import '../common/glass_ui.dart';

/// Entry card for Learning Paths - displays on Learn Screen
class LearningPathsEntryCard extends StatelessWidget {
  const LearningPathsEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LearningPathsScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Teal gradient overlay on glass
          gradient: const LinearGradient(
            colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: kGlassRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Glass icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: kGlassRadius,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.route_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Text content — bold white title, muted subtitle
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learning Paths',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Structured courses for all levels',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: kGlassRadius,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Teal gradient progress bar (decorative, showing "always available")
            GlassProgressBar(value: 1.0, height: 3),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }
}
