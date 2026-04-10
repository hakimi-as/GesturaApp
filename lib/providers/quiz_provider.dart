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
  bool _isTimedOut = false;
  String? _error;

  // Wrong answers collected during quiz for review
  List<Map<String, dynamic>> _wrongAnswers = [];

  // Global timer (legacy — used by old Firestore quiz docs)
  Timer? _timer;
  int _timeLeft = 60;
  int _timeSpent = 0;

  // Per-question timer (Timed Challenge)
  Timer? _questionTimer;
  int _questionTimeLeft = 10;
  static const int _questionTimerDuration = 10;
  // Getters
  List<QuizModel> get quizzes => _quizzes;
  List<QuizQuestionModel> get currentQuestions => _currentQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get correctAnswers => _correctAnswers;
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get isAnswered => _isAnswered;
  bool get isTimedOut => _isTimedOut;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get timeLeft => _timeLeft;
  int get questionTimeLeft => _questionTimeLeft;
  int get questionTimerDuration => _questionTimerDuration;
  int get timeSpent => _timeSpent;
  List<Map<String, dynamic>> get wrongAnswers => List.unmodifiable(_wrongAnswers);

  QuizQuestionModel? get currentQuestion {
    if (_currentQuestions.isEmpty ||
        _currentQuestionIndex >= _currentQuestions.length) return null;
    return _currentQuestions[_currentQuestionIndex];
  }

  int get totalQuestions => _currentQuestions.length;
  bool get isQuizComplete =>
      _currentQuestionIndex >= _currentQuestions.length;
  double get progressPercentage => _currentQuestions.isEmpty
      ? 0
      : (_currentQuestionIndex + 1) / _currentQuestions.length;
  bool get hasWrongAnswers => _wrongAnswers.isNotEmpty;

  // ── Load quizzes list ────────────────────────────────────────────────────

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

  // ── Sign to Text ─────────────────────────────────────────────────────────

  Future<void> startSignToTextQuiz({String? categoryId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _resetState();

      final questions = await _firestoreService.generateSignToTextQuestions(
        categoryId: categoryId,
        count: 10,
      );

      if (questions.isEmpty) {
        _error = 'Not enough lessons with images to generate a quiz.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentQuestions = questions;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Text to Sign ─────────────────────────────────────────────────────────

  Future<void> startTextToSignQuiz({String? categoryId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _resetState();

      final questions = await _firestoreService.generateTextToSignQuestions(
        categoryId: categoryId,
        count: 10,
      );

      if (questions.isEmpty) {
        _error = 'Not enough lessons with images to generate a quiz.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentQuestions = questions;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Timed Challenge ───────────────────────────────────────────────────────

  Future<void> startTimedChallengeQuiz() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _resetState();

      final questions =
          await _firestoreService.generateTimedChallengeQuestions(count: 15);

      if (questions.isEmpty) {
        _error = 'Not enough lessons with images to generate a quiz.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentQuestions = questions;
      _isLoading = false;
      notifyListeners();

      // Start the first question's timer after loading
      _startQuestionTimer();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimeLeft = _questionTimerDuration;
    _isTimedOut = false;

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isAnswered) {
        timer.cancel();
        return;
      }
      if (_questionTimeLeft > 0) {
        _questionTimeLeft--;
        _timeSpent++;
        notifyListeners();
      } else {
        timer.cancel();
        _onQuestionTimeout();
      }
    });
  }

  void _onQuestionTimeout() {
    if (_isAnswered) return;

    _isAnswered = true;
    _isTimedOut = true;

    // Record as missed
    if (currentQuestion != null) {
      _wrongAnswers.add({
        'question': currentQuestion!,
        'selectedIndex': -1,
        'selectedAnswer': '⏰ Time ran out',
      });
    }
    notifyListeners();

    // Auto-advance after 1.2s pause
    Future.delayed(const Duration(milliseconds: 1200), () {
      _advanceTimedQuestion();
    });
  }

  void _advanceTimedQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      _currentQuestionIndex++;
      _selectedOptionIndex = null;
      _isAnswered = false;
      _isTimedOut = false;
      _startQuestionTimer();
    } else {
      // All questions done — mark quiz complete
      _currentQuestionIndex = _currentQuestions.length;
      _questionTimer?.cancel();
    }
    notifyListeners();
  }

  // ── Spelling Quiz ─────────────────────────────────────────────────────────

  Future<void> startSpellingQuiz() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _resetState();

      final questions =
          await _firestoreService.generateSpellingQuestions(count: 10);

      if (questions.isEmpty) {
        _error =
            'Not enough alphabet letter images found.\nMake sure the Alphabet category has lessons with images.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentQuestions = questions;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── startQuiz dispatcher ─────────────────────────────────────────────────

  Future<void> startQuiz(String quizType, {String? quizId}) async {
    if (quizType == 'sign_to_text') {
      await startSignToTextQuiz();
      return;
    }
    if (quizType == 'text_to_sign') {
      await startTextToSignQuiz();
      return;
    }
    if (quizType == 'timed') {
      await startTimedChallengeQuiz();
      return;
    }

    if (quizType == 'spelling') {
      await startSpellingQuiz();
      return;
    }

    // Any remaining Firestore-backed quiz types
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _resetState();

      final quizzes = await _firestoreService.getQuizzes();
      List<QuizQuestionModel> allQuestions = [];

      if (quizId != null) {
        final quiz = quizzes.firstWhere(
          (q) => q.id == quizId,
          orElse: () => quizzes.first,
        );
        allQuestions = List.from(quiz.questions);
      } else {
        for (var quiz in quizzes) {
          if (quiz.isActive && quiz.quizType == quizType) {
            allQuestions.addAll(quiz.questions);
          }
        }
      }

      allQuestions.shuffle();
      _currentQuestions = allQuestions.take(10).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Answer handling ───────────────────────────────────────────────────────

  void selectAnswer(int optionIndex) {
    if (_isAnswered) return;
    _selectedOptionIndex = optionIndex;
    notifyListeners();
  }

  void submitAnswer({bool isTimedChallenge = false}) {
    if (_selectedOptionIndex == null || _isAnswered) return;
    _questionTimer?.cancel();

    _isAnswered = true;
    _isTimedOut = false;

    final isCorrect =
        _selectedOptionIndex == currentQuestion!.correctAnswerIndex;

    if (isCorrect) {
      _correctAnswers++;
      if (isTimedChallenge) {
        _score += _speedPoints();
      } else {
        _score += currentQuestion!.points;
      }
    } else {
      _wrongAnswers.add({
        'question': currentQuestion!,
        'selectedIndex': _selectedOptionIndex,
        'selectedAnswer': currentQuestion!.options[_selectedOptionIndex!],
      });
    }

    _timeSpent += (_questionTimerDuration - _questionTimeLeft);
    notifyListeners();
  }

  /// Points based on how fast the answer was given (timed challenge only).
  int _speedPoints() {
    final elapsed = _questionTimerDuration - _questionTimeLeft;
    if (elapsed <= 3) return 15; // Lightning fast
    if (elapsed <= 6) return 12; // Fast
    return 10;                   // Standard
  }

  void nextQuestion({bool isTimedChallenge = false}) {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      _currentQuestionIndex++;
      _selectedOptionIndex = null;
      _isAnswered = false;
      _isTimedOut = false;
      if (isTimedChallenge) {
        _startQuestionTimer();
      }
      notifyListeners();
    }
  }

  bool isCorrectAnswer(int optionIndex) {
    return currentQuestion?.correctAnswerIndex == optionIndex;
  }

  int calculateXPEarned() {
    int xp = _correctAnswers * 5;
    if (_correctAnswers == totalQuestions && totalQuestions > 0) {
      xp += 50;
    }
    return xp;
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _resetState() {
    _timer?.cancel();
    _questionTimer?.cancel();
    _currentQuestions = [];
    _currentQuestionIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    _selectedOptionIndex = null;
    _isAnswered = false;
    _isTimedOut = false;
    _timeLeft = 60;
    _questionTimeLeft = _questionTimerDuration;
    _timeSpent = 0;
    _wrongAnswers = [];
  }

  void resetQuiz() {
    _resetState();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionTimer?.cancel();
    super.dispose();
  }
}
