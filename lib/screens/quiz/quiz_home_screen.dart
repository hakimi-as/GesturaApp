import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';
import 'quiz_screen.dart';

class QuizHomeScreen extends StatelessWidget {
  const QuizHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quiz'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(context),
            const SizedBox(height: 24),

            // Quiz Types
            Text(
              'Choose Quiz Type',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),

            _buildQuizTypeCard(
              context,
              icon: '👁️',
              title: 'Sign to Text',
              description: 'See a sign and guess what it means',
              color: AppColors.primary,
              quizType: 'sign_to_text',
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

            const SizedBox(height: 12),

            _buildQuizTypeCard(
              context,
              icon: '✋',
              title: 'Text to Sign',
              description: 'Read text and pick the correct sign',
              color: AppColors.secondary,
              quizType: 'text_to_sign',
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

            const SizedBox(height: 12),

            _buildQuizTypeCard(
              context,
              icon: '⏱️',
              title: 'Timed Challenge',
              description: 'Answer as many as you can in 60 seconds',
              color: AppColors.warning,
              quizType: 'timed',
            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

            const SizedBox(height: 12),

            _buildQuizTypeCard(
              context,
              icon: '✍️',
              title: 'Spelling Quiz',
              description: 'Spell words using finger spelling signs',
              color: AppColors.accent,
              quizType: 'spelling',
            ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),

            const SizedBox(height: 24),

            // Recent Scores Section
            Text(
              'Recent Scores',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 16),

            _buildRecentScores(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Your Knowledge',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Take a quiz and earn XP!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current XP: ${user?.totalXP ?? 0}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('🎯', style: TextStyle(fontSize: 32)),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
      },
    );
  }

  Widget _buildQuizTypeCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
    required Color color,
    required String quizType,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(quizType: quizType),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScores(BuildContext context) {
    // Placeholder - will be populated from Firebase later
    final scores = [
      {'type': 'Sign to Text', 'score': 90, 'date': 'Today'},
      {'type': 'Timed Challenge', 'score': 75, 'date': 'Yesterday'},
      {'type': 'Spelling Quiz', 'score': 100, 'date': '2 days ago'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: scores.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('📝', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        'No quizzes taken yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            : scores.asMap().entries.map((entry) {
                final index = entry.key;
                final score = entry.value;
                final isLast = index == scores.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _getScoreColor(score['score'] as int)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${score['score']}%',
                                style: TextStyle(
                                  color: _getScoreColor(score['score'] as int),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  score['type'] as String,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  score['date'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: context.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _getScoreIcon(score['score'] as int),
                            color: _getScoreColor(score['score'] as int),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: context.borderColor,
                        indent: 72,
                      ),
                  ],
                );
              }).toList(),
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getScoreIcon(int score) {
    if (score >= 90) return Icons.emoji_events;
    if (score >= 70) return Icons.thumb_up;
    return Icons.refresh;
  }
}