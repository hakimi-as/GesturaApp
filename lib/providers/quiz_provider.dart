import 'package:flutter/material.dart';
import 'dart:async';
import '../services/firestore_service.dart';
import '../models/quiz_model.dart';

class QuizProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<QuizModel> _quizzes = [];
  List<QuizQuestionModel> _currentQuestions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  bool _isLoading = false;
  String? _error;

  // Timer
  Timer? _timer;
  int _timeLeft = 60;
  int _timeSpent = 0;

  // Getters
  List<QuizModel> get quizzes => _quizzes;
  List<QuizQuestionModel> get currentQuestions => _currentQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get correctAnswers => _correctAnswers;
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get isAnswered => _isAnswered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get timeLeft => _timeLeft;
  int get timeSpent => _timeSpent;

  QuizQuestionModel? get currentQuestion {
    if (_currentQuestions.isEmpty || _currentQuestionIndex >= _currentQuestions.length) {
      return null;
    }
    return _currentQuestions[_currentQuestionIndex];
  }

  int get totalQuestions => _currentQuestions.length;
  bool get isQuizComplete => _currentQuestionIndex >= _currentQuestions.length;
  double get progressPercentage =>
      _currentQuestions.isEmpty ? 0 : (_currentQuestionIndex + 1) / _currentQuestions.length;

  // Load quizzes
  Future<void> loadQuizzes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _quizzes = await _firestoreService.getQuizzes();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Start quiz - fetches questions from Firestore
  // Start quiz - fetches questions from Firestore
  Future<void> startQuiz(String quizType, {String? quizId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Reset state
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _selectedOptionIndex = null;
      _isAnswered = false;
      _timeSpent = 0;

      // Fetch quizzes from Firestore
      final quizzes = await _firestoreService.getQuizzes();
      
      List<QuizQuestionModel> allQuestions = [];
      
      if (quizId != null) {
        // Load specific quiz
        final quiz = quizzes.firstWhere(
          (q) => q.id == quizId,
          orElse: () => quizzes.first,
        );
        allQuestions = List.from(quiz.questions);
      } else {
        // Load all questions from quizzes of this type
        for (var quiz in quizzes) {
          if (quiz.isActive && quiz.quizType == quizType) {
            allQuestions.addAll(quiz.questions);
          }
        }
      }
      
      // Shuffle and limit to 10 questions max
      allQuestions.shuffle();
      _currentQuestions = allQuestions.take(10).toList();

      // Start timer for timed quizzes
      if (quizType == 'timed') {
        _startTimer();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Select answer
  void selectAnswer(int optionIndex) {
    if (_isAnswered) return;
    _selectedOptionIndex = optionIndex;
    notifyListeners();
  }

  // Submit answer
  void submitAnswer() {
    if (_selectedOptionIndex == null || _isAnswered) return;

    _isAnswered = true;

    if (currentQuestion != null &&
        _selectedOptionIndex == currentQuestion!.correctAnswerIndex) {
      _correctAnswers++;
      _score += currentQuestion!.points;
    }

    notifyListeners();
  }

  // Next question
  void nextQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      _currentQuestionIndex++;
      _selectedOptionIndex = null;
      _isAnswered = false;
      notifyListeners();
    }
  }

  // Check if answer is correct
  bool isCorrectAnswer(int optionIndex) {
    return currentQuestion?.correctAnswerIndex == optionIndex;
  }

  // Calculate XP earned
  int calculateXPEarned() {
    int xp = _correctAnswers * 5;
    if (_correctAnswers == totalQuestions) {
      xp += 50; // Perfect score bonus
    }
    return xp;
  }

  // Timer methods
  void _startTimer() {
    _timeLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        _timeSpent++;
        notifyListeners();
      } else {
        timer.cancel();
        notifyListeners();
      }
    });
  }

  // Reset quiz
  void resetQuiz() {
    _timer?.cancel();
    _currentQuestions = [];
    _currentQuestionIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    _selectedOptionIndex = null;
    _isAnswered = false;
    _timeLeft = 60;
    _timeSpent = 0;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}