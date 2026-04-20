import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../config/design_system.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'quiz_list_screen.dart';

class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _recentAttempts = [];
  bool _loadingScores = true;

  /// Best score (0–100) per quiz type from recent attempts.
  Map<String, int> get _bestScoreByType {
    final Map<String, int> best = {};
    for (final attempt in _recentAttempts) {
      final type = attempt['quizType'] as String? ?? '';
      final total = attempt['totalQuestions'] as int? ?? 0;
      final correct = attempt['correctAnswers'] as int? ?? 0;
      final score = total > 0 ? (correct / total * 100).round() : 0;
      if (!best.containsKey(type) || best[type]! < score) {
        best[type] = score;
      }
    }
    return best;
  }

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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.quizTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 24),

            Text(
              l10n.chooseQuizType,
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),

            _buildQuizGrid(context),

            const SizedBox(height: 24),

            Text(
              l10n.recentScores,
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
    final l10n = AppLocalizations.of(context);
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
                color: AppColors.accent.withValues(alpha: 0.3),
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
                      l10n.testKnowledge,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.quizHeaderSubtitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.totalXP}: ${user?.totalXP ?? 0}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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

  Widget _buildQuizGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quizTypes = [
      _QuizCardData(
        icon: '👁️',
        title: l10n.signToText,
        description: l10n.signToTextFullDesc,
        color: AppColors.primary,
        quizType: 'sign_to_text',
        questionCount: 10,
        xp: 50,
      ),
      _QuizCardData(
        icon: '✋',
        title: l10n.textToSign,
        description: l10n.textToSignFullDesc,
        color: AppColors.secondary,
        quizType: 'text_to_sign',
        questionCount: 10,
        xp: 50,
      ),
      _QuizCardData(
        icon: '⏱️',
        title: l10n.timedChallenge,
        description: l10n.timedChallengeFullDesc,
        color: AppColors.warning,
        quizType: 'timed',
        questionCount: 15,
        xp: 75,
      ),
      _QuizCardData(
        icon: '✍️',
        title: l10n.spellingQuiz,
        description: l10n.spellingQuizFullDesc,
        color: AppColors.accent,
        quizType: 'spelling',
        questionCount: 10,
        xp: 50,
      ),
      _QuizCardData(
        icon: '✏️',
        title: l10n.fillInBlank,
        description: l10n.fillInBlankFullDesc,
        color: const Color(0xFF8B5CF6),
        quizType: 'fill_in_blank',
        questionCount: 10,
        xp: 60,
      ),
    ];

    final bestScores = _bestScoreByType;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.82,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: quizTypes.asMap().entries.map((entry) {
        final i = entry.key;
        final data = entry.value;
        final best = bestScores[data.quizType] ?? 0;

        return _buildQuizTypeCard(context, data, best)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 300 + i * 100))
            .slideY(begin: 0.1);
      }).toList(),
    );
  }

  Widget _buildQuizTypeCard(
    BuildContext context,
    _QuizCardData data,
    int bestScore,
  ) {
    final l10n = AppLocalizations.of(context);
    return TapScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizListScreen(quizType: data.quizType, title: data.title),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(data.icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              data.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            // Description
            Expanded(
              child: Text(
                data.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textMuted,
                      height: 1.3,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Bottom row: question count + XP
            Row(
              children: [
                Text(
                  '${data.questionCount} ${l10n.questions}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textMuted,
                        fontSize: 11,
                      ),
                ),
                const Spacer(),
                Text(
                  '+${data.xp} XP',
                  style: TextStyle(
                    color: data.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Progress bar (shows best score, always visible)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: bestScore / 100,
                minHeight: 6,
                backgroundColor: data.color.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation<Color>(data.color),
              ),
            ),
            const SizedBox(height: 4),
            // Label below bar
            Text(
              bestScore > 0 ? '${l10n.bestScore}: $bestScore%' : l10n.notPlayedYet,
              style: TextStyle(
                color: bestScore > 0 ? data.color : context.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
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
              AppLocalizations.of(context).noQuizzesYet,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).completeQuizPrompt,
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

          final l10n = AppLocalizations.of(context);
          String dateLabel = '';
          if (completedAt != null) {
            try {
              final dt = completedAt.toDate();
              final now = DateTime.now();
              final diff = now.difference(dt);
              if (diff.inDays == 0) {
                dateLabel = l10n.today;
              } else if (diff.inDays == 1) {
                dateLabel = l10n.yesterday;
              } else if (diff.inDays < 7) {
                dateLabel = '${diff.inDays} ${l10n.daysAgoLabel}';
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
                            _quizTypeName(context, quizType),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '$correct/$totalQ ${l10n.correct} · $dateLabel',
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

  String _quizTypeName(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case 'sign_to_text':
        return l10n.signToText;
      case 'text_to_sign':
        return l10n.textToSign;
      case 'timed':
        return l10n.timedChallenge;
      case 'spelling':
        return l10n.spellingQuiz;
      case 'fill_in_blank':
        return l10n.fillInBlank;
      default:
        return l10n.quizTitle;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.warning;
    return AppColors.error;
  }
}

class _QuizCardData {
  final String icon;
  final String title;
  final String description;
  final Color color;
  final String quizType;
  final int questionCount;
  final int xp;

  const _QuizCardData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.quizType,
    required this.questionCount,
    required this.xp,
  });
}
