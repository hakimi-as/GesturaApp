import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/badge_model.dart';
import '../../models/challenge_model.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/badges/badge_unlock_dialog.dart';
import '../../widgets/challenges/challenge_complete_dialog.dart';

class QuizResultScreen extends StatefulWidget {
  final String quizType;

  const QuizResultScreen({
    super.key,
    required this.quizType,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _xpAdded = false;
  List<BadgeModel> _newBadges = [];
  List<ChallengeModel> _completedChallenges = [];

  @override
  void initState() {
    super.initState();
    _addXPAndCheckBadges();
  }

  Future<void> _addXPAndCheckBadges() async {
    if (_xpAdded) return;

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);
    final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    final firestoreService = FirestoreService();

    final xpEarned = quizProvider.calculateXPEarned();
    final isPerfect = quizProvider.totalQuestions > 0 && 
        quizProvider.correctAnswers == quizProvider.totalQuestions;
    
    // 1. Award XP
    if (xpEarned > 0) {
      await authProvider.addXP(xpEarned);
    }

    // 2. Save Activity (this also updates quizzesCompleted and perfectQuizzes)
    if (authProvider.userId != null) {
      await firestoreService.completeQuiz(
        userId: authProvider.userId!,
        quizType: widget.quizType,
        score: quizProvider.score,
        totalQuestions: quizProvider.totalQuestions,
        correctAnswers: quizProvider.correctAnswers,
        xpEarned: xpEarned,
      );

      // 3. Refresh user data to get updated quiz stats
      await authProvider.refreshUser();

      // 4. Check for new badges
      if (authProvider.currentUser != null) {
        final newBadges = await badgeProvider.checkForNewBadges(
          userId: authProvider.userId!,
          user: authProvider.currentUser!,
          quizzesCompleted: authProvider.currentUser!.quizzesCompleted,
          perfectQuizzes: isPerfect ? authProvider.currentUser!.perfectQuizzes : null,
        );

        // 5. Check for completed challenges
        final completedChallenges = await challengeProvider.updateProgress(
          userId: authProvider.userId!,
          user: authProvider.currentUser!,
          quizzesCompleted: 1,
          xpEarned: xpEarned,
          perfectQuiz: isPerfect,
        );
        
        if ((newBadges.isNotEmpty || completedChallenges.isNotEmpty) && mounted) {
          setState(() {
            _newBadges = newBadges;
            _completedChallenges = completedChallenges;
          });
          
          // Show dialogs after a short delay to let the result screen render
          Future.delayed(const Duration(milliseconds: 1500), () async {
            if (mounted && _newBadges.isNotEmpty) {
              await BadgeUnlockDialog.showMultiple(context, _newBadges);
            }
            if (mounted && _completedChallenges.isNotEmpty) {
              await ChallengeCompleteDialog.showMultiple(context, _completedChallenges);
            }
          });
        }
      }
    }

    setState(() => _xpAdded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          final correctAnswers = quizProvider.correctAnswers;
          final totalQuestions = quizProvider.totalQuestions;
          final score = quizProvider.score;
          final xpEarned = quizProvider.calculateXPEarned();
          final percentage = totalQuestions > 0
              ? (correctAnswers / totalQuestions * 100).toInt()
              : 0;
          final isPassed = percentage >= 70;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Result Icon
                  _buildResultIcon(isPassed, percentage),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _getResultTitle(percentage),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 8),

                  Text(
                    _getResultSubtitle(percentage),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 32),

                  // Score Card
                  _buildScoreCard(context, correctAnswers, totalQuestions, percentage),
                  const SizedBox(height: 16),

                  // XP Earned Card
                  _buildXPCard(context, xpEarned, score),
                  const SizedBox(height: 16),

                  // Stats Row
                  _buildStatsRow(context, quizProvider),
                  const SizedBox(height: 32),

                  // Achievements (if any)
                  if (percentage == 100) _buildPerfectScoreBadge(context),

                  const SizedBox(height: 24),

                  // Buttons
                  _buildButtons(context),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultIcon(bool isPassed, int percentage) {
    String emoji;
    Color color;

    if (percentage == 100) {
      emoji = '🏆';
      color = const Color(0xFFFFD700);
    } else if (percentage >= 90) {
      emoji = '🌟';
      color = AppColors.success;
    } else if (percentage >= 70) {
      emoji = '👏';
      color = AppColors.success;
    } else if (percentage >= 50) {
      emoji = '💪';
      color = AppColors.warning;
    } else {
      emoji = '📚';
      color = AppColors.secondary;
    }

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(70),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 70),
        ),
      ),
    )
        .animate()
        .scale(
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .then()
        .shimmer(duration: 1000.ms);
  }

  String _getResultTitle(int percentage) {
    if (percentage == 100) return 'Perfect Score!';
    if (percentage >= 90) return 'Excellent!';
    if (percentage >= 70) return 'Great Job!';
    if (percentage >= 50) return 'Good Effort!';
    return 'Keep Practicing!';
  }

  String _getResultSubtitle(int percentage) {
    if (percentage == 100) return 'You got every question right! Amazing!';
    if (percentage >= 90) return 'Almost perfect! Outstanding performance!';
    if (percentage >= 70) return 'You passed the quiz! Well done!';
    if (percentage >= 50) return 'You\'re making progress. Keep going!';
    return 'Practice makes perfect. Try again!';
  }

  Widget _buildScoreCard(
    BuildContext context,
    int correct,
    int total,
    int percentage,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Text(
            '$percentage%',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: _getScoreColor(percentage),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$correct out of $total correct',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 12,
              backgroundColor: context.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(percentage)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildXPCard(BuildContext context, int xpEarned, int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'XP Earned',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '+$xpEarned XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2);
  }

  Widget _buildStatsRow(BuildContext context, QuizProvider quizProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: '⏱️',
            value: '${quizProvider.timeSpent}s',
            label: 'Time Spent',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: '✅',
            value: '${quizProvider.correctAnswers}',
            label: 'Correct',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: '❌',
            value: '${quizProvider.totalQuestions - quizProvider.correctAnswers}',
            label: 'Wrong',
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfectScoreBadge(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perfect Score!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '+50 Bonus XP',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFFD700).withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 900.ms)
        .shimmer(duration: 1500.ms, delay: 1000.ms);
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        // Try Again Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Go back to quiz selection
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Back to Home Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              // Pop until we're back to the dashboard
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.textSecondary,
              side: BorderSide(color: context.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1000.ms);
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 90) return AppColors.success;
    if (percentage >= 70) return AppColors.accent;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }
}