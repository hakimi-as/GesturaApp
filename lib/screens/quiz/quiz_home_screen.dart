import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'quiz_screen.dart';

class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _recentAttempts = [];
  bool _loadingScores = true;

  @override
  void initState() {
    super.initState();
    _loadRecentScores();
  }

  Future<void> _loadRecentScores() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) {
      setState(() => _loadingScores = false);
      return;
    }
    final attempts =
        await _firestoreService.getRecentQuizAttempts(userId, limit: 5);
    if (mounted) {
      setState(() {
        _recentAttempts = attempts;
        _loadingScores = false;
      });
    }
  }

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
            _buildHeaderCard(context),
            const SizedBox(height: 24),

            Text(
              'Choose Quiz Type',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),

            _buildQuizTypeCard(
              context,
              icon: '👁️',
              title: 'Sign to Text',
              description: 'See a BIM sign and pick what it means',
              color: AppColors.primary,
              quizType: 'sign_to_text',
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
            const SizedBox(height: 12),

            _buildQuizTypeCard(
              context,
              icon: '✋',
              title: 'Text to Sign',
              description: 'Read a word and pick the correct sign image',
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
              description: 'Identify words from fingerspelling sign sequences',
              color: AppColors.accent,
              quizType: 'spelling',
            ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),

            const SizedBox(height: 24),

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
                          color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Take a quiz and earn XP!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total XP: ${user?.totalXP ?? 0}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 14),
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
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScores(BuildContext context) {
    if (_loadingScores) {
      return Container(
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_recentAttempts.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('📝', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No quizzes taken yet',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete a quiz to see your scores here',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.textMuted),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: _recentAttempts.asMap().entries.map((entry) {
          final index = entry.key;
          final attempt = entry.value;
          final isLast = index == _recentAttempts.length - 1;

          final totalQ = attempt['totalQuestions'] as int? ?? 0;
          final correct = attempt['correctAnswers'] as int? ?? 0;
          final scorePercent =
              totalQ > 0 ? (correct / totalQ * 100).toInt() : 0;
          final quizType = attempt['quizType'] as String? ?? '';
          final completedAt = attempt['completedAt'];
          final xpEarned = attempt['xpEarned'] as int? ?? 0;

          String dateLabel = '';
          if (completedAt != null) {
            try {
              final dt = completedAt.toDate();
              final now = DateTime.now();
              final diff = now.difference(dt);
              if (diff.inDays == 0) {
                dateLabel = 'Today';
              } else if (diff.inDays == 1) {
                dateLabel = 'Yesterday';
              } else if (diff.inDays < 7) {
                dateLabel = '${diff.inDays} days ago';
              } else {
                dateLabel = DateFormat('d MMM').format(dt);
              }
            } catch (_) {}
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Score badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getScoreColor(scorePercent).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$scorePercent%',
                          style: TextStyle(
                            color: _getScoreColor(scorePercent),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                            _quizTypeName(quizType),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '$correct/$totalQ correct · $dateLabel',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: context.textMuted),
                          ),
                        ],
                      ),
                    ),
                    // XP tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+$xpEarned XP',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: context.borderColor, indent: 76),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  String _quizTypeName(String type) {
    switch (type) {
      case 'sign_to_text':
        return 'Sign to Text';
      case 'text_to_sign':
        return 'Text to Sign';
      case 'timed':
        return 'Timed Challenge';
      case 'spelling':
        return 'Spelling Quiz';
      default:
        return 'Quiz';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.warning;
    return AppColors.error;
  }
}
