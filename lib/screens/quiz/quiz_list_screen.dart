import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/quiz_model.dart';
import '../../services/firestore_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/glass_ui.dart';
import 'quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  final String quizType;
  final String title;

  const QuizListScreen({
    super.key,
    required this.quizType,
    required this.title,
  });

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<QuizModel> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final allQuizzes = await _firestoreService.getQuizzes();
      final filteredQuizzes = allQuizzes
          .where((q) =>
              q.isActive &&
              q.quizType == widget.quizType &&
              q.questions.isNotEmpty)
          .toList();
      setState(() {
        _quizzes = filteredQuizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: widget.title,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _quizzes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadQuizzes,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _quizzes.length,
                    itemBuilder: (context, index) =>
                        _buildQuizCard(_quizzes[index], index),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return GlassEmptyState(
      icon: _getTypeIcon(),
      title: AppLocalizations.of(context).noQuizzesAvailable,
      subtitle: AppLocalizations.of(context).checkBackLater,
      actionLabel: AppLocalizations.of(context).quickStart,
      onAction: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(quizType: widget.quizType),
        ),
      ),
    );
  }

  Widget _buildQuizCard(QuizModel quiz, int index) {
    final diffColor = _getDifficultyColor(quiz.difficulty);

    return GestureTileWrapper(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              QuizScreen(quizType: widget.quizType, quizId: quiz.id),
        ),
      ),
      child: GlassTile(
        alternate: index.isOdd,
        padding: const EdgeInsets.all(18),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _getTypeColor().withAlpha(30),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(_getTypeIcon(), color: _getTypeColor(), size: 28),
          ),
        ),
        title: Text(
          quiz.title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          quiz.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            color: context.textMuted, size: 18),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index))
        .slideX(begin: 0.1);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _getTypeColor() {
    switch (widget.quizType) {
      case 'sign_to_text':
        return const Color(0xFF6366F1);
      case 'text_to_sign':
        return const Color(0xFFF59E0B);
      case 'timed':
        return const Color(0xFF10B981);
      case 'spelling':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.quizType) {
      case 'sign_to_text':
        return Icons.visibility_rounded;
      case 'text_to_sign':
        return Icons.back_hand_rounded;
      case 'timed':
        return Icons.timer_rounded;
      case 'spelling':
        return Icons.spellcheck_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return AppColors.primary; // teal for easy
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return const Color(0xFFF59E0B); // amber for hard
      default:
        return AppColors.primary;
    }
  }
}

/// Helper widget: wraps a child with GestureDetector so GlassTile can receive
/// an external onTap without duplicating the tile layout.
class GestureTileWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const GestureTileWrapper(
      {super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: child,
      ),
    );
  }
}
