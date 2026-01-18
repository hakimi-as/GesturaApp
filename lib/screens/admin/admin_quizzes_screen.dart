import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../models/quiz_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';

class AdminQuizzesScreen extends StatefulWidget {
  const AdminQuizzesScreen({super.key});

  @override
  State<AdminQuizzesScreen> createState() => _AdminQuizzesScreenState();
}

class _AdminQuizzesScreenState extends State<AdminQuizzesScreen> {
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
      final quizzes = await _firestoreService.getQuizzes();
      setState(() {
        _quizzes = quizzes;
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
        title: const Text('Manage Quizzes'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.textPrimary),
            onPressed: _loadQuizzes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _quizzes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadQuizzes,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
                    itemCount: _quizzes.length,
                    itemBuilder: (context, index) {
                      return _buildQuizCard(context, _quizzes[index], index);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditQuizDialog(null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Quiz'),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, QuizModel quiz, int index) {
    return GestureDetector(
      onTap: () => _showQuizQuestionsScreen(quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                color: _getQuizTypeColor(quiz.quizType).withAlpha(38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(_getQuizTypeEmoji(quiz.quizType), style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quiz.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textMuted,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${quiz.questionCount} questions',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(quiz.difficulty).withAlpha(38),
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.bgElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getQuizTypeName(quiz.quizType),
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary, size: 22),
                  onPressed: () => _showAddEditQuizDialog(quiz),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error, size: 22),
                  onPressed: () => _showDeleteConfirmation(quiz),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  void _showQuizQuestionsScreen(QuizModel quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QuizQuestionsScreen(
          quiz: quiz,
          onUpdate: _loadQuizzes,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'No quizzes yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first quiz to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textMuted,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditQuizDialog(null),
            icon: const Icon(Icons.add),
            label: const Text('Add Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditQuizDialog(QuizModel? quiz) {
    final isEditing = quiz != null;
    final titleController = TextEditingController(text: quiz?.title ?? '');
    final descController = TextEditingController(text: quiz?.description ?? '');
    String selectedDifficulty = quiz?.difficulty ?? 'easy';
    String selectedType = quiz?.quizType ?? 'sign_to_text';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Edit Quiz' : 'Add Quiz'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Quiz Title',
                    labelStyle: TextStyle(color: context.textMuted),
                    filled: true,
                    fillColor: context.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: TextStyle(color: context.textPrimary),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: context.textMuted),
                    filled: true,
                    fillColor: context.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Difficulty', style: TextStyle(color: context.textMuted, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: ['easy', 'medium', 'hard'].map((diff) {
                    final isSelected = selectedDifficulty == diff;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedDifficulty = diff),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getDifficultyColor(diff).withAlpha(38)
                                : context.bgElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? _getDifficultyColor(diff) : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              diff.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? _getDifficultyColor(diff) : context.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Quiz Type', style: TextStyle(color: context.textMuted, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    dropdownColor: context.bgCard,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'sign_to_text', child: Text('Sign to Text')),
                      DropdownMenuItem(value: 'text_to_sign', child: Text('Text to Sign')),
                      DropdownMenuItem(value: 'timed', child: Text('Timed Challenge')),
                      DropdownMenuItem(value: 'spelling', child: Text('Spelling Quiz')),
                    ],
                    onChanged: (value) => setDialogState(() => selectedType = value!),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showQuizQuestionsScreen(quiz);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.quiz, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Manage ${quiz.questionCount} questions →',
                              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                Navigator.pop(context);

                if (isEditing) {
                  await _firestoreService.updateQuiz(quiz.id, {
                    'title': titleController.text,
                    'description': descController.text,
                    'difficulty': selectedDifficulty,
                    'quizType': selectedType,
                  });
                  _showSnackBar('Quiz updated');
                } else {
                  await _firestoreService.addQuiz({
                    'title': titleController.text,
                    'description': descController.text,
                    'difficulty': selectedDifficulty,
                    'quizType': selectedType,
                    'questions': [],
                    'isActive': true,
                    'createdAt': DateTime.now(),
                  });
                  _showSnackBar('Quiz added');
                }
                _loadQuizzes();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(QuizModel quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Quiz?'),
        content: Text('This will delete "${quiz.title}" and all its questions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.deleteQuiz(quiz.id);
              _loadQuizzes();
              _showSnackBar('Quiz deleted');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy': return AppColors.success;
      case 'medium': return AppColors.warning;
      case 'hard': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  Color _getQuizTypeColor(String type) {
    switch (type) {
      case 'sign_to_text': return const Color(0xFF6366F1);
      case 'text_to_sign': return const Color(0xFFF59E0B);
      case 'timed': return const Color(0xFF10B981);
      case 'spelling': return const Color(0xFFEF4444);
      default: return AppColors.primary;
    }
  }

  String _getQuizTypeEmoji(String type) {
    switch (type) {
      case 'sign_to_text': return '👁️';
      case 'text_to_sign': return '👆';
      case 'timed': return '⏱️';
      case 'spelling': return '🔤';
      default: return '🎯';
    }
  }

  String _getQuizTypeName(String type) {
    switch (type) {
      case 'sign_to_text': return 'Sign to Text';
      case 'text_to_sign': return 'Text to Sign';
      case 'timed': return 'Timed';
      case 'spelling': return 'Spelling';
      default: return type;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ==================== QUIZ QUESTIONS SCREEN ====================

class _QuizQuestionsScreen extends StatefulWidget {
  final QuizModel quiz;
  final VoidCallback onUpdate;

  const _QuizQuestionsScreen({required this.quiz, required this.onUpdate});

  @override
  State<_QuizQuestionsScreen> createState() => _QuizQuestionsScreenState();
}

class _QuizQuestionsScreenState extends State<_QuizQuestionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late List<QuizQuestionModel> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.quiz.questions);
  }

  Future<void> _saveQuestions() async {
    await _firestoreService.updateQuiz(widget.quiz.id, {
      'questions': _questions.map((q) => q.toMap()).toList(),
    });
    widget.onUpdate();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.quiz.title, style: const TextStyle(fontSize: 16)),
            Text(
              '${_questions.length} questions',
              style: TextStyle(fontSize: 12, color: context.textMuted),
            ),
          ],
        ),
      ),
      body: _questions.isEmpty
          ? _buildEmptyState()
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
              itemCount: _questions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _questions.removeAt(oldIndex);
                  _questions.insert(newIndex, item);
                });
                _saveQuestions();
              },
              itemBuilder: (context, index) {
                return _buildQuestionCard(_questions[index], index);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditQuestionDialog(null, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('❓', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No questions yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Add questions to this quiz',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestionModel question, int index) {
    return Container(
      key: ValueKey(question.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          // Question number or media thumbnail
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: question.imageUrl != null
                  ? Image.network(
                      CloudinaryService.getOptimizedImage(question.imageUrl!, width: 100, height: 100),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(question.signEmoji, style: const TextStyle(fontSize: 24)),
                      ),
                    )
                  : question.videoUrl != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(color: context.bgElevated),
                            const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 28),
                          ],
                        )
                      : Center(
                          child: Text(question.signEmoji, style: const TextStyle(fontSize: 24)),
                        ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Q${index + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (question.hasMedia) ...[
                      const SizedBox(width: 6),
                      Icon(
                        question.imageUrl != null ? Icons.image : Icons.videocam,
                        color: AppColors.success,
                        size: 14,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.questionText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Answer: ${question.correctAnswer}',
                  style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Options: ${question.options.join(", ")}',
                  style: TextStyle(color: context.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                onPressed: () => _showAddEditQuestionDialog(question, index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                onPressed: () => _deleteQuestion(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.drag_handle, color: context.textMuted),
        ],
      ),
    );
  }

  void _showAddEditQuestionDialog(QuizQuestionModel? question, int? index) {
    showDialog(
      context: context,
      builder: (dialogContext) => _QuestionDialog(
        question: question,
        onSave: (newQuestion) {
          setState(() {
            if (question != null && index != null) {
              _questions[index] = newQuestion;
            } else {
              _questions.add(newQuestion);
            }
          });
          _saveQuestions();
        },
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Question?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _questions.removeAt(index));
              _saveQuestions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Question Dialog with Image/Video Upload Support
// ============================================================

class _QuestionDialog extends StatefulWidget {
  final QuizQuestionModel? question;
  final Function(QuizQuestionModel) onSave;

  const _QuestionDialog({
    required this.question,
    required this.onSave,
  });

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController questionTextController;
  late TextEditingController pointsController;
  late TextEditingController option1Controller;
  late TextEditingController option2Controller;
  late TextEditingController option3Controller;
  late TextEditingController option4Controller;
  
  // Quiz type: 'sign_to_text' (show sign, pick text) or 'text_to_sign' (show text, pick sign image)
  String quizType = 'sign_to_text';
  
  int correctAnswerIndex = 0;
  
  // Question media (for sign_to_text - show sign image/video)
  String? imageUrl;
  String? videoUrl;
  XFile? selectedImageFile;
  XFile? selectedVideoFile;
  Uint8List? selectedImageBytes;
  Uint8List? selectedVideoBytes;
  bool isUploadingImage = false;
  bool isUploadingVideo = false;
  
  // Option images (for text_to_sign - options have sign images)
  List<String?> optionImageUrls = [null, null, null, null];
  List<XFile?> selectedOptionFiles = [null, null, null, null];
  List<Uint8List?> selectedOptionBytes = [null, null, null, null];
  List<bool> isUploadingOptionImage = [false, false, false, false];
  
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    questionTextController = TextEditingController(text: q?.questionText ?? 'What does this sign mean?');
    pointsController = TextEditingController(text: '${q?.points ?? 10}');
    option1Controller = TextEditingController(text: q?.options.isNotEmpty == true ? q!.options[0] : '');
    option2Controller = TextEditingController(text: (q?.options.length ?? 0) > 1 ? q!.options[1] : '');
    option3Controller = TextEditingController(text: (q?.options.length ?? 0) > 2 ? q!.options[2] : '');
    option4Controller = TextEditingController(text: (q?.options.length ?? 0) > 3 ? q!.options[3] : '');
    correctAnswerIndex = q?.correctAnswerIndex ?? 0;
    imageUrl = q?.imageUrl;
    videoUrl = q?.videoUrl;
    
    // Load option images if exists
    if (q != null && q.optionImages.isNotEmpty) {
      for (int i = 0; i < q.optionImages.length && i < 4; i++) {
        optionImageUrls[i] = q.optionImages[i];
      }
    }
    
    // Determine quiz type based on existing data
    if (q != null && q.hasOptionImages) {
      quizType = 'text_to_sign';
    }
  }

  @override
  void dispose() {
    questionTextController.dispose();
    pointsController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    option3Controller.dispose();
    option4Controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            selectedImageFile = picked;
            selectedImageBytes = bytes;
            selectedVideoFile = null;
            selectedVideoBytes = null;
            videoUrl = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            selectedVideoFile = picked;
            selectedVideoBytes = bytes;
            selectedImageFile = null;
            selectedImageBytes = null;
            imageUrl = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  Future<void> _pickOptionImage(int index) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            selectedOptionFiles[index] = picked;
            selectedOptionBytes[index] = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking option image: $e');
    }
  }

  void _removeOptionImage(int index) {
    setState(() {
      selectedOptionFiles[index] = null;
      selectedOptionBytes[index] = null;
      optionImageUrls[index] = null;
    });
  }

  Future<void> _save() async {
    final optionControllers = [option1Controller, option2Controller, option3Controller, option4Controller];
    final options = optionControllers
        .map((c) => c.text)
        .where((o) => o.isNotEmpty)
        .toList();

    // For text_to_sign, we need option images
    if (quizType == 'text_to_sign') {
      // Count how many options have images
      int optionsWithImages = 0;
      for (int i = 0; i < options.length; i++) {
        if (optionImageUrls[i] != null || selectedOptionFiles[i] != null) {
          optionsWithImages++;
        }
      }
      
      if (optionsWithImages < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Text-to-Sign quiz needs at least 2 options with images'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
    }

    if (options.length < 2 || correctAnswerIndex >= options.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least 2 options and select correct answer'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // Upload question image if selected (for sign_to_text)
      if (selectedImageFile != null) {
        setState(() => isUploadingImage = true);
        final result = await CloudinaryService.uploadImage(
          selectedImageFile!,
          folder: 'gestura/quiz_questions',
        );
        if (result != null) {
          imageUrl = result.secureUrl;
        }
        if (mounted) setState(() => isUploadingImage = false);
      }

      // Upload question video if selected
      if (selectedVideoFile != null) {
        setState(() => isUploadingVideo = true);
        final result = await CloudinaryService.uploadVideo(
          selectedVideoFile!,
          folder: 'gestura/quiz_questions',
        );
        if (result != null) {
          videoUrl = result.secureUrl;
        }
        if (mounted) setState(() => isUploadingVideo = false);
      }

      // Upload option images (for text_to_sign)
      List<String?> finalOptionImages = List<String?>.from(optionImageUrls);
      for (int i = 0; i < 4; i++) {
        if (selectedOptionFiles[i] != null) {
          setState(() => isUploadingOptionImage[i] = true);
          final result = await CloudinaryService.uploadImage(
            selectedOptionFiles[i]!,
            folder: 'gestura/quiz_options',
          );
          if (result != null) {
            finalOptionImages[i] = result.secureUrl;
          }
          if (mounted) setState(() => isUploadingOptionImage[i] = false);
        }
      }

      final newQuestion = QuizQuestionModel(
        id: widget.question?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        questionText: questionTextController.text,
        signEmoji: '🤟',
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        options: options,
        optionImages: finalOptionImages.sublist(0, options.length),
        correctAnswer: options[correctAnswerIndex],
        points: int.tryParse(pointsController.text) ?? 10,
      );

      Navigator.pop(context);
      widget.onSave(newQuestion);
    } catch (e) {
      debugPrint('Error saving question: $e');
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.question != null;
    final hasImageMedia = imageUrl != null || selectedImageFile != null;
    final hasVideoMedia = videoUrl != null || selectedVideoFile != null;

    return AlertDialog(
      backgroundColor: context.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(isEditing ? 'Edit Question' : 'Add Question'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz Type Selector
              Text('Question Type', style: TextStyle(color: context.textMuted, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeChip(
                      label: 'Sign → Text',
                      sublabel: 'Show sign, pick text',
                      icon: Icons.sign_language,
                      isSelected: quizType == 'sign_to_text',
                      onTap: () => setState(() => quizType = 'sign_to_text'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeChip(
                      label: 'Text → Sign',
                      sublabel: 'Show text, pick sign',
                      icon: Icons.text_fields,
                      isSelected: quizType == 'text_to_sign',
                      onTap: () => setState(() => quizType = 'text_to_sign'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Question Media (for sign_to_text)
              if (quizType == 'sign_to_text') ...[
                Text('Sign Media (shown to user)', style: TextStyle(color: context.textMuted, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaCard(
                        context: context,
                        title: 'Image',
                        icon: Icons.image,
                        isUploading: isUploadingImage,
                        hasMedia: hasImageMedia,
                        previewBytes: selectedImageBytes,
                        mediaUrl: imageUrl,
                        onTap: _pickImage,
                        onRemove: () => setState(() {
                          selectedImageFile = null;
                          selectedImageBytes = null;
                          imageUrl = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMediaCard(
                        context: context,
                        title: 'Video',
                        icon: Icons.videocam,
                        isUploading: isUploadingVideo,
                        hasMedia: hasVideoMedia,
                        previewBytes: null,
                        mediaUrl: videoUrl,
                        onTap: _pickVideo,
                        onRemove: () => setState(() {
                          selectedVideoFile = null;
                          selectedVideoBytes = null;
                          videoUrl = null;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Points & Question Text Row
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Points',
                        labelStyle: TextStyle(color: context.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: context.bgElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: questionTextController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Question Text',
                        labelStyle: TextStyle(color: context.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: context.bgElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Options
              Text(
                quizType == 'text_to_sign'
                    ? 'Options - Add sign images (tap to mark correct)'
                    : 'Options (tap to mark correct answer)',
                style: TextStyle(color: context.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),

              _buildOptionField(option1Controller, 0, context),
              const SizedBox(height: 8),
              _buildOptionField(option2Controller, 1, context),
              const SizedBox(height: 8),
              _buildOptionField(option3Controller, 2, context),
              const SizedBox(height: 8),
              _buildOptionField(option4Controller, 3, context),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: isSaving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required String label,
    required String sublabel,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(30) : context.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : context.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : context.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(color: context.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isUploading,
    required bool hasMedia,
    Uint8List? previewBytes,
    String? mediaUrl,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: context.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasMedia ? AppColors.success : context.borderColor,
            width: hasMedia ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (previewBytes != null && title == 'Image')
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(previewBytes, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              )
            else if (mediaUrl != null && title == 'Image')
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  CloudinaryService.getOptimizedImage(mediaUrl, width: 200, height: 200),
                  width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(hasMedia ? Icons.check_circle : icon, color: hasMedia ? AppColors.success : context.textMuted, size: 28),
                    const SizedBox(height: 4),
                    Text(hasMedia ? '$title Added' : 'Add $title', style: TextStyle(color: hasMedia ? AppColors.success : context.textMuted, fontSize: 12)),
                  ],
                ),
              ),

            if (isUploading)
              Container(
                decoration: BoxDecoration(color: Colors.black.withAlpha(128), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              ),

            if (hasMedia && !isUploading)
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionField(TextEditingController controller, int optionIndex, BuildContext context) {
    final isCorrect = optionIndex == correctAnswerIndex;
    final hasOptionImage = optionImageUrls[optionIndex] != null || selectedOptionBytes[optionIndex] != null;
    final isUploadingOption = isUploadingOptionImage[optionIndex];

    return GestureDetector(
      onTap: () => setState(() => correctAnswerIndex = optionIndex),
      child: Container(
        decoration: BoxDecoration(
          color: isCorrect ? AppColors.success.withAlpha(30) : context.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect ? AppColors.success : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Letter/Check indicator
            Container(
              width: 40,
              height: quizType == 'text_to_sign' ? 80 : 48,
              decoration: BoxDecoration(
                color: isCorrect ? AppColors.success : context.bgCard,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Center(
                child: isCorrect
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        String.fromCharCode(65 + optionIndex),
                        style: TextStyle(color: context.textMuted, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            // Option image (for text_to_sign)
            if (quizType == 'text_to_sign') ...[
              GestureDetector(
                onTap: () => _pickOptionImage(optionIndex),
                child: Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: context.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasOptionImage ? AppColors.success : context.borderColor,
                      width: hasOptionImage ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (selectedOptionBytes[optionIndex] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            selectedOptionBytes[optionIndex]!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else if (optionImageUrls[optionIndex] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            CloudinaryService.getOptimizedImage(optionImageUrls[optionIndex]!, width: 140, height: 140),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Center(
                          child: Icon(
                            Icons.add_photo_alternate,
                            color: context.textMuted,
                            size: 24,
                          ),
                        ),
                      
                      if (isUploadingOption)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                        ),
                      
                      if (hasOptionImage && !isUploadingOption)
                        Positioned(
                          top: 2, right: 2,
                          child: GestureDetector(
                            onTap: () => _removeOptionImage(optionIndex),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: quizType == 'text_to_sign' 
                      ? 'Label (optional)'
                      : 'Option ${String.fromCharCode(65 + optionIndex)}',
                  hintStyle: TextStyle(color: context.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}