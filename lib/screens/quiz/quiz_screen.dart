import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/quiz_model.dart';
import '../../providers/quiz_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/video/video_player_widget.dart';
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
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.textPrimary),
          onPressed: () => _showExitDialog(),
        ),
        title: Consumer<QuizProvider>(
          builder: (context, quizProvider, child) {
            return Text(
              'Question ${quizProvider.currentQuestionIndex + 1}/${quizProvider.totalQuestions}',
            );
          },
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
            WidgetsBinding.instance.addPostFrameCallback((_) => _goToResults());
            return const Center(
              child: CircularProgressIndicator(color: AppColors.warning),
            );
          }

          final question = quizProvider.currentQuestion;
          if (question == null) {
            return const Center(child: Text('No questions available'));
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
                        _buildImageOptionsGrid(context, quizProvider, question)
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

  Widget _buildProgressBar(QuizProvider quizProvider) {
    return Container(
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: quizProvider.progressPercentage,
          backgroundColor: context.bgCard,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
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
                backgroundColor: context.bgCard,
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
          // Sign Display - Video, Image, or Emoji fallback
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
            Container(
              width: 160,
              height: 160,
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  CloudinaryService.getOptimizedImage(
                      question.imageUrl!, width: 400, height: 400),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primary,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(question.signEmoji,
                        style: const TextStyle(fontSize: 60)),
                  ),
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
              child: Center(
                child: Text(
                  question.signEmoji,
                  style: const TextStyle(fontSize: 60),
                ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✍️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'What word is being spelled?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$wordLength-letter word',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textMuted,
                ),
          ),
          const SizedBox(height: 16),

          // Fingerspelling letter images — horizontal scroll
          SizedBox(
            height: 100,
            child: letters.isEmpty
                ? Center(
                    child: Text(
                      question.signEmoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: letters.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final imageUrl = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Container(
                                width: 68,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: context.bgElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.accent.withAlpha(80),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.network(
                                    CloudinaryService.getOptimizedImage(
                                      imageUrl,
                                      width: 140,
                                      height: 160,
                                    ),
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
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
                                    errorBuilder: (_, __, ___) => Center(
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
                              delay: Duration(milliseconds: 80 * idx),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withAlpha(200),
            AppColors.secondary.withAlpha(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Which sign means...',
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✋', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'Pick the correct sign below',
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

    Color bgColor = context.bgCard;
    Color borderColor = context.borderColor;
    Color textColor = context.textPrimary;

    if (isAnswered) {
      if (isCorrect) {
        bgColor = AppColors.success.withAlpha(38);
        borderColor = AppColors.success;
        textColor = AppColors.success;
      } else if (isSelected && !isCorrect) {
        bgColor = AppColors.error.withAlpha(38);
        borderColor = AppColors.error;
        textColor = AppColors.error;
      }
    } else if (isSelected) {
      bgColor = AppColors.primary.withAlpha(38);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: isAnswered ? null : () => _handleOptionSelected(index),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
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
                          color: isSelected ? borderColor : context.textMuted,
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 + (index * 100)),
    ).slideX(begin: 0.1);
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
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(16),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      CloudinaryService.getOptimizedImage(optionImage, width: 300, height: 300),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: context.textMuted, size: 40),
                            const SizedBox(height: 4),
                            Text(option, style: TextStyle(color: context.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Fallback to text if no image
                  Center(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              color: isCorrect || isSelected ? Colors.white : context.textMuted,
                              size: 16,
                            )
                          : Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                color: isSelected ? Colors.white : context.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),

                // Option label at bottom
                if (option.isNotEmpty && optionImage != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
        ).animate().fadeIn(
          delay: Duration(milliseconds: 100 + (index * 100)),
        ).scale(begin: const Offset(0.9, 0.9));
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
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  '⏰ Time\'s up!',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Correct answer: "${quizProvider.currentQuestion?.correctAnswer}"',
                  style: TextStyle(
                    color: AppColors.error.withAlpha(200),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
        ),
      );
    }

    String buttonText;
    if (_isTimed) {
      if (!hasSelection) {
        buttonText = 'Select an answer';
      } else if (!isAnswered) {
        buttonText = 'Submit';
      } else if (isLastQuestion) {
        buttonText = 'See Results';
      } else {
        buttonText = 'Next →';
      }
    } else {
      if (!hasSelection) {
        buttonText = 'Select an answer';
      } else if (!isAnswered) {
        buttonText = 'Submit Answer';
      } else if (isLastQuestion) {
        buttonText = 'See Results';
      } else {
        buttonText = 'Next Question';
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
              feedbackText = '⚡ Lightning fast! +15 pts';
            } else if (elapsed <= 6) {
              feedbackText = '✓ Fast! +12 pts';
            } else {
              feedbackText = '✓ Correct! +10 pts';
            }
          } else {
            feedbackText =
                '✓ Correct! +${quizProvider.currentQuestion?.points ?? 10} XP';
          }
          feedbackColor = AppColors.success;
        } else {
          feedbackText =
              '✗ Wrong! Answer: "${quizProvider.currentQuestion?.correctAnswer}"';
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
                padding: const EdgeInsets.symmetric(vertical: 10),
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
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: hasSelection ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAnswered
                      ? (isLastQuestion ? AppColors.accent : AppColors.primary)
                      : AppColors.primary,
                  disabledBackgroundColor: context.bgElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hasSelection ? Colors.white : context.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quit Quiz?'),
        content: const Text(
          'Your progress will be lost. Are you sure you want to quit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
}