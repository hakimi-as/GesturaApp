import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String quizType;
  final String difficulty;
  final List<QuizQuestionModel> questions;
  final bool isActive;
  final DateTime? createdAt;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    this.quizType = 'sign_to_text',
    this.difficulty = 'easy',
    this.questions = const [],
    this.isActive = true,
    this.createdAt,
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      quizType: data['quizType'] ?? 'sign_to_text',
      difficulty: data['difficulty'] ?? 'easy',
      questions: (data['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestionModel.fromMap(q))
              .toList() ??
          [],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'quizType': quizType,
      'difficulty': difficulty,
      'questions': questions.map((q) => q.toMap()).toList(),
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  int get questionCount => questions.length;
}

class QuizQuestionModel {
  final String id;
  final String questionText;
  final String signEmoji;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> options;
  final List<String?> optionImages;
  final String correctAnswer;
  final int points;

  // New fields
  final String? hint;        // Short description shown after wrong answer
  final String? category;    // Which BIM category this belongs to
  final List<String>? letterImages; // For spelling quiz — one image URL per letter

  QuizQuestionModel({
    required this.id,
    required this.questionText,
    this.signEmoji = '🤟',
    this.imageUrl,
    this.videoUrl,
    required this.options,
    this.optionImages = const [],
    required this.correctAnswer,
    this.points = 10,
    this.hint,
    this.category,
    this.letterImages,
  });

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    final options = List<String>.from(map['options'] ?? []);
    final rawOptionImages = map['optionImages'] as List<dynamic>?;

    List<String?> optionImages = [];
    if (rawOptionImages != null) {
      optionImages = rawOptionImages.map((e) => e as String?).toList();
    }
    while (optionImages.length < options.length) {
      optionImages.add(null);
    }

    return QuizQuestionModel(
      id: map['id'] ?? '',
      questionText: map['questionText'] ?? '',
      signEmoji: map['signEmoji'] ?? '🤟',
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      options: options,
      optionImages: optionImages,
      correctAnswer: map['correctAnswer'] ?? '',
      points: map['points'] ?? 10,
      hint: map['hint'],
      category: map['category'],
      letterImages: map['letterImages'] != null
          ? List<String>.from(map['letterImages'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'signEmoji': signEmoji,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'options': options,
      'optionImages': optionImages,
      'correctAnswer': correctAnswer,
      'points': points,
      'hint': hint,
      'category': category,
      'letterImages': letterImages,
    };
  }

  bool get hasMedia => imageUrl != null || videoUrl != null;
  bool get hasOptionImages => optionImages.any((img) => img != null && img.isNotEmpty);

  String? getOptionImage(int index) {
    if (index < 0 || index >= optionImages.length) return null;
    return optionImages[index];
  }

  int get correctOptionIndex => options.indexOf(correctAnswer);
  int get correctAnswerIndex => correctOptionIndex;
}

class QuizAttemptModel {
  final String id;
  final String userId; // fixed: was oderId
  final String quizId;
  final String quizType;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpentSeconds;
  final DateTime completedAt;

  QuizAttemptModel({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.quizType,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpentSeconds,
    required this.completedAt,
  });

  factory QuizAttemptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizAttemptModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      quizId: data['quizId'] ?? '',
      quizType: data['quizType'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      timeSpentSeconds: data['timeSpentSeconds'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory QuizAttemptModel.fromMap(Map<String, dynamic> data, String id) {
    return QuizAttemptModel(
      id: id,
      userId: data['userId'] ?? '',
      quizId: data['quizId'] ?? '',
      quizType: data['quizType'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      timeSpentSeconds: data['timeSpentSeconds'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'quizId': quizId,
      'quizType': quizType,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'timeSpentSeconds': timeSpentSeconds,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  double get percentage =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;
  bool get isPassed => percentage >= 70;
  bool get isPerfect => percentage == 100;
}
