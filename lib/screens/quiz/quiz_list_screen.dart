import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../models/quiz_model.dart';
import '../../services/firestore_service.dart';
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
          .where((q) => q.isActive && q.quizType == widget.quizType && q.questions.isNotEmpty)
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
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getTypeColor().withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(_getTypeEmoji(), style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Text(widget.title),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _quizzes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadQuizzes,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _quizzes.length,
                    itemBuilder: (context, index) => _buildQuizCard(_quizzes[index], index),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_getTypeEmoji(), style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No quizzes available', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Check back later for new quizzes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(QuizModel quiz, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(quizType: widget.quizType, quizId: quiz.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getTypeColor().withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(_getTypeEmoji(), style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quiz.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${quiz.questionCount} questions',
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(quiz.difficulty).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quiz.difficulty.toUpperCase(),
                          style: TextStyle(
                            color: _getDifficultyColor(quiz.difficulty),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '+${quiz.questionCount * 5} XP',
                        style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: context.textMuted, size: 18),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  Color _getTypeColor() {
    switch (widget.quizType) {
      case 'sign_to_text': return const Color(0xFF6366F1);
      case 'text_to_sign': return const Color(0xFFF59E0B);
      case 'timed': return const Color(0xFF10B981);
      case 'spelling': return const Color(0xFFEF4444);
      default: return AppColors.primary;
    }
  }

  String _getTypeEmoji() {
    switch (widget.quizType) {
      case 'sign_to_text': return '👁️';
      case 'text_to_sign': return '👆';
      case 'timed': return '⏱️';
      case 'spelling': return '🔤';
      default: return '🎯';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy': return AppColors.success;
      case 'medium': return AppColors.warning;
      case 'hard': return AppColors.error;
      default: return AppColors.primary;
    }
  }
}