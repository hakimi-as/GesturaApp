import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/quiz_model.dart';
import '../../providers/quiz_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/video/video_player_widget.dart';
import '../../widgets/common/glass_ui.dart';
import '../../l10n/app_localizations.dart';
import '../../services/analytics_service.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String quizType;
  final String? quizId;

  const QuizScreen({
    super.key,
    required this.quizType,
    this.quizId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  Future<void> _startQuiz() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    await quizProvider.startQuiz(widget.quizType, quizId: widget.quizId);
    AnalyticsService.logQuizStarted(quizType: widget.quizType);
  }

  @override
  void dispose() {
    Provider.of<QuizProvider>(context, listen: false).resetQuiz();
    super.dispose();
  }

  void _handleOptionSelected(int index) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    quizProvider.selectAnswer(index);
  }

  bool get _isTimed => widget.quizType == 'timed';

  void _handleSubmit() {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    if (!quizProvider.isAnswered) {
      quizProvider.submitAnswer(isTimedChallenge: _isTimed);
    } else {
      if (quizProvider.currentQuestionIndex < quizProvider.totalQuestions - 1) {
        quizProvider.nextQuestion(isTimedChallenge: _isTimed);
      } else {
        _goToResults();
      }
    }
  }

  void _goToResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(quizType: widget.quizType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: _quizTitle(context),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.primary),
          onPressed: () => _showExitDialog(),
        ),
        actions: const [],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // Timed challenge auto-navigates to results when all questions done
          if (_isTimed && quizProvider.isQuizComplete) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _goToResults());
            return const Center(
              child: CircularProgressIndicator(color: AppColors.warning),
            );
          }

          final question = quizProvider.currentQuestion;
          if (question == null) {
            return Center(
                child: Text(
                    AppLocalizations.of(context).noQuestionsAvailable));
          }

          return Column(
            children: [
              _buildProgressBar(quizProvider),
              if (_isTimed) _buildTimerBar(quizProvider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildQuestionCard(context, quizProvider),
                      const SizedBox(height: 24),
                      if (question.hasOptionImages)
                        _buildImageOptionsGrid(
                            context, quizProvider, question)
                      else
                        ...question.options.asMap().entries.map((entry) {
                          return _buildOptionCard(
                            context,
                            quizProvider,
                            entry.key,
                            entry.value,
                          );
                        }),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(context, quizProvider),
            ],
          );
        },
      ),
    );
  }

  String _quizTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (widget.quizType) {
      case 'sign_to_text':
        return l10n.signToText;
      case 'text_to_sign':
        return l10n.textToSign;
      case 'timed':
        return l10n.timedChallenge;
      case 'spelling':
        return l10n.spellingQuiz;
      default:
        return l10n.quizTitle;
    }
  }

  Widget _buildProgressBar(QuizProvider quizProvider) {
    final current = quizProvider.currentQuestionIndex + 1;
    final total = quizProvider.totalQuestions;
    final percent = total > 0 ? ((current / total) * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$current / $total',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).questions,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassProgressBar(
              value: total > 0 ? current / total : 0),
        ],
      ),
    );
  }

  /// Colored draining timer bar for Timed Challenge — green → yellow → red.
  Widget _buildTimerBar(QuizProvider quizProvider) {
    final timeLeft = quizProvider.questionTimeLeft;
    final total = quizProvider.questionTimerDuration;
    final ratio = timeLeft / total;

    Color barColor;
    if (ratio > 0.6) {
      barColor = AppColors.success;
    } else if (ratio > 0.3) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, size: 18, color: barColor),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor:
                    Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '${timeLeft}s',
              style: TextStyle(
                color: barColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, QuizProvider quizProvider) {
    final question = quizProvider.currentQuestion!;

    // Spelling Quiz: show fingerspelling letter images
    if (widget.quizType == 'spelling') {
      return _buildSpellingQuestionCard(context, question);
    }

    // Text to Sign: the word IS the question — show it as a styled word card
    if (widget.quizType == 'text_to_sign') {
      return _buildTextToSignQuestionCard(context, question);
    }

    final hasImage = question.imageUrl != null;
    final hasVideo = question.videoUrl != null;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Sign Display - Video, Image, or Icon fallback
          if (hasVideo)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: VideoPlayerWidget(
                  videoUrl: question.videoUrl!,
                  autoPlay: true,
                  looping: true,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms)
          else if (hasImage)
            GestureDetector(
              onTap: () =>
                  _showFullscreenImage(context, question.imageUrl!),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: context.bgElevated,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(51),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        CloudinaryService.getOptimizedImage(
                            question.imageUrl!,
                            width: 400,
                            height: 400),
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        loadingBuilder:
                            (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress
                                          .expectedTotalBytes !=
                                      null
                                  ? loadingProgress
                                          .cumulativeBytesLoaded /
                                      loadingProgress
                                          .expectedTotalBytes!
                                  : null,
                              color: AppColors.primary,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.sign_language_rounded,
                              size: 60, color: context.textMuted),
                        ),
                      ),
                    ),
                    // Tap-to-enlarge hint
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(120),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.zoom_in,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut)
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(51),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.sign_language_rounded,
                    size: 60, color: AppColors.primary),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            question.questionText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${question.points} XP',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  /// Question card for Spelling Quiz — shows a horizontal row of fingerspelling
  /// sign images (one per letter). User picks which word is being spelled.
  Widget _buildSpellingQuestionCard(
      BuildContext context, QuizQuestionModel question) {
    final letters = question.letterImages ?? [];
    final wordLength = question.correctAnswer.length;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.spellcheck_rounded,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).whatWordSpelled,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).nLetterWord(wordLength),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textMuted,
                ),
          ),
          const SizedBox(height: 16),

          // Fingerspelling letter images — horizontal scroll
          SizedBox(
            height: 100,
            child: letters.isEmpty
                ? const Center(
                    child: Icon(Icons.sign_language_rounded,
                        size: 48, color: AppColors.accent),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          letters.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final imageUrl = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4),
                          child: Column(
                            children: [
                              Container(
                                width: 68,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: context.bgElevated,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppColors.accent.withAlpha(80),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(11),
                                  child: Image.network(
                                    CloudinaryService.getOptimizedImage(
                                      imageUrl,
                                      width: 140,
                                      height: 160,
                                    ),
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child,
                                        loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.accent,
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) =>
                                        Center(
                                      child: Text(
                                        question.correctAnswer[idx],
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(
                              delay:
                                  Duration(milliseconds: 80 * idx),
                            );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // Letter count hint: _ _ _ (blank tiles)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(wordLength, (i) {
              return Container(
                width: 24,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(120),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${question.points} XP',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  /// Question card for Text to Sign — shows the word prominently,
  /// users will pick the matching sign from the image grid below.
  Widget _buildTextToSignQuestionCard(
      BuildContext context, QuizQuestionModel question) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [
          AppColors.secondary.withAlpha(200),
          AppColors.secondary.withAlpha(150),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Text(
            '${AppLocalizations.of(context).whichSignMeans}...',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question.questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.back_hand_rounded,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).pickCorrectSign,
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05);
  }

  Widget _buildOptionCard(
    BuildContext context,
    QuizProvider quizProvider,
    int index,
    String option,
  ) {
    final isSelected = quizProvider.selectedOptionIndex == index;
    final isAnswered = quizProvider.isAnswered;
    final isCorrect = quizProvider.isCorrectAnswer(index);

    // Determine gradient / tint based on answer state
    Gradient? cardGradient;
    Color borderColor = context.borderColor;
    Color textColor = context.textPrimary;

    if (isAnswered) {
      if (isCorrect) {
        cardGradient = LinearGradient(
          colors: [
            const Color(0xFF14B8A6).withAlpha(60),
            const Color(0xFF06B6D4).withAlpha(40),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = AppColors.success;
        textColor = AppColors.success;
      } else if (isSelected && !isCorrect) {
        cardGradient = LinearGradient(
          colors: [
            AppColors.error.withAlpha(50),
            AppColors.error.withAlpha(30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = AppColors.error;
        textColor = AppColors.error;
      }
    } else if (isSelected) {
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: isAnswered ? null : () => _handleOptionSelected(index),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: context.glassCardDecoration().copyWith(
          gradient: cardGradient,
          border: Border.all(
              color: borderColor, width: isSelected ? 2 : 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected || (isAnswered && isCorrect)
                    ? borderColor.withAlpha(51)
                    : context.bgElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isAnswered
                    ? Icon(
                        isCorrect
                            ? Icons.check
                            : (isSelected ? Icons.close : null),
                        color: isCorrect
                            ? AppColors.success
                            : (isSelected ? AppColors.error : null),
                        size: 20,
                      )
                    : Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          color: isSelected
                              ? borderColor
                              : context.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
              ),
            ),
            if (isSelected && !isAnswered)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + (index * 100)))
        .slideX(begin: 0.1);
  }

  /// Build a 2x2 grid of image options for text-to-sign quiz
  Widget _buildImageOptionsGrid(
    BuildContext context,
    QuizProvider quizProvider,
    QuizQuestionModel question,
  ) {
    final isAnswered = quizProvider.isAnswered;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final optionImage = question.getOptionImage(index);
        final isSelected = quizProvider.selectedOptionIndex == index;
        final isCorrect = quizProvider.isCorrectAnswer(index);

        Color borderColor = context.borderColor;
        Color overlayColor = Colors.transparent;

        if (isAnswered) {
          if (isCorrect) {
            borderColor = AppColors.success;
            overlayColor = AppColors.success.withAlpha(50);
          } else if (isSelected && !isCorrect) {
            borderColor = AppColors.error;
            overlayColor = AppColors.error.withAlpha(50);
          }
        } else if (isSelected) {
          borderColor = AppColors.primary;
          overlayColor = AppColors.primary.withAlpha(30);
        }

        return GestureDetector(
          onTap: isAnswered ? null : () => _handleOptionSelected(index),
          child: Container(
            decoration: context.glassCardDecoration().copyWith(
              border: Border.all(
                color: borderColor,
                width: isSelected || (isAnswered && isCorrect) ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: borderColor.withAlpha(50),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Option image
                if (optionImage != null)
                  GestureDetector(
                    onLongPress: () =>
                        _showFullscreenImage(context, optionImage),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        CloudinaryService.getOptimizedImage(
                            optionImage,
                            width: 300,
                            height: 300),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        loadingBuilder:
                            (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress
                                          .expectedTotalBytes !=
                                      null
                                  ? loadingProgress
                                          .cumulativeBytesLoaded /
                                      loadingProgress
                                          .expectedTotalBytes!
                                  : null,
                              color: AppColors.primary,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  color: context.textMuted, size: 40),
                              const SizedBox(height: 4),
                              Text(option,
                                  style: TextStyle(
                                      color: context.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  // Fallback to text if no image
                  Center(
                    child: Text(
                      option,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Overlay for selection/answer state
                if (overlayColor != Colors.transparent)
                  Container(
                    decoration: BoxDecoration(
                      color: overlayColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                // Letter indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected || (isAnswered && isCorrect)
                          ? borderColor
                          : context.bgElevated.withAlpha(230),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isAnswered
                          ? Icon(
                              isCorrect
                                  ? Icons.check
                                  : (isSelected ? Icons.close : null),
                              color: isCorrect || isSelected
                                  ? Colors.white
                                  : context.textMuted,
                              size: 16,
                            )
                          : Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : context.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),

                // Check mark for selected
                if (isSelected && !isAnswered)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(
                delay: Duration(milliseconds: 100 + (index * 100)))
            .scale(begin: const Offset(0.9, 0.9));
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, QuizProvider quizProvider) {
    final isAnswered = quizProvider.isAnswered;
    final isTimedOut = quizProvider.isTimedOut;
    final hasSelection = quizProvider.selectedOptionIndex != null;
    final isLastQuestion =
        quizProvider.currentQuestionIndex >= quizProvider.totalQuestions - 1;

    // Timed challenge: auto-advancing on timeout — button hidden, feedback shown
    if (_isTimed && isTimedOut) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.bgSecondary,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Builder(builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alarm_off_rounded,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        l10n.timeUp,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.correctAnswerIs}: "${quizProvider.currentQuestion?.correctAnswer}"',
                    style: TextStyle(
                      color: AppColors.error.withAlpha(200),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms);
          }),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    String buttonText;
    if (_isTimed) {
      if (!hasSelection) {
        buttonText = l10n.selectAnAnswer;
      } else if (!isAnswered) {
        buttonText = l10n.submit;
      } else if (isLastQuestion) {
        buttonText = l10n.seeResults;
      } else {
        buttonText = '${l10n.next} →';
      }
    } else {
      if (!hasSelection) {
        buttonText = l10n.selectAnAnswer;
      } else if (!isAnswered) {
        buttonText = l10n.submitAnswer;
      } else if (isLastQuestion) {
        buttonText = l10n.seeResults;
      } else {
        buttonText = l10n.nextQuestion;
      }
    }

    String? feedbackText;
    Color feedbackColor = AppColors.success;

    if (isAnswered && !isTimedOut) {
      final selectedIdx = quizProvider.selectedOptionIndex;
      if (selectedIdx != null) {
        final isCorrect = quizProvider.isCorrectAnswer(selectedIdx);
        if (isCorrect) {
          if (_isTimed) {
            final elapsed = quizProvider.questionTimerDuration -
                quizProvider.questionTimeLeft;
            if (elapsed <= 3) {
              feedbackText =
                  '${l10n.lightningFastFeedback} +15 pts';
            } else if (elapsed <= 6) {
              feedbackText = '${l10n.fastFeedback} +12 pts';
            } else {
              feedbackText = '${l10n.correctFeedback} +10 pts';
            }
          } else {
            feedbackText =
                '${l10n.correctFeedback} +${quizProvider.currentQuestion?.points ?? 10} XP';
          }
          feedbackColor = AppColors.success;
        } else {
          feedbackText =
              '${l10n.wrongFeedback} "${quizProvider.currentQuestion?.correctAnswer}"';
          feedbackColor = AppColors.error;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 10,
              offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (feedbackText != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: feedbackColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  feedbackText,
                  style: TextStyle(
                    color: feedbackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(duration: 300.ms),
            GlassPrimaryButton(
              label: buttonText,
              onPressed: hasSelection ? _handleSubmit : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    CloudinaryService.getOptimizedImage(imageUrl,
                        width: 800, height: 800),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 48,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).quitQuiz),
        content: Text(AppLocalizations.of(context).quitQuizMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(AppLocalizations.of(context).quit),
          ),
        ],
      ),
    );
  }
}
