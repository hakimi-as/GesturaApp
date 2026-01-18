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
  final List<String?> optionImages; // Image URLs for each option (for text-to-sign quiz)
  final String correctAnswer;
  final int points;

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
  });

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    final options = List<String>.from(map['options'] ?? []);
    final rawOptionImages = map['optionImages'] as List<dynamic>?;
    
    // Convert optionImages, ensuring same length as options
    List<String?> optionImages = [];
    if (rawOptionImages != null) {
      optionImages = rawOptionImages.map((e) => e as String?).toList();
    }
    // Pad with nulls if needed
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
    };
  }

  /// Check if question has media (image or video)
  bool get hasMedia => imageUrl != null || videoUrl != null;

  /// Check if any option has an image (for text-to-sign quiz)
  bool get hasOptionImages => optionImages.any((img) => img != null && img.isNotEmpty);

  /// Get image URL for a specific option index
  String? getOptionImage(int index) {
    if (index < 0 || index >= optionImages.length) return null;
    return optionImages[index];
  }

  int get correctOptionIndex => options.indexOf(correctAnswer);
  int get correctAnswerIndex => correctOptionIndex;
}

class QuizAttemptModel {
  final String id;
  final String oderId;
  final String quizId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpentSeconds;
  final DateTime completedAt;

  QuizAttemptModel({
    required this.id,
    required this.oderId,
    required this.quizId,
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
      oderId: data['userId'] ?? '',
      quizId: data['quizId'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      timeSpentSeconds: data['timeSpentSeconds'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': oderId,
      'quizId': quizId,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'timeSpentSeconds': timeSpentSeconds,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  double get percentage => totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;
  bool get isPassed => percentage >= 70;
  bool get isPerfect => percentage == 100;
}