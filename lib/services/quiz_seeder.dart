import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../config/constants.dart';

/// Seeds quiz documents to Firestore using existing lesson data.
/// Creates 3 quizzes for each type: sign_to_text, text_to_sign, timed, spelling.
class QuizSeederService {
  static final FirestoreService _firestoreService = FirestoreService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Public entry point ───────────────────────────────────────────────────

  static Future<SeedResult> seedAllQuizzes() async {
    try {
      final allLessons = await _firestoreService.getAllLessons();

      // Lessons with any media (image or video) — for sign_to_text / timed
      final mediaLessons = allLessons
          .where((l) => l.isActive && (l.imageUrl != null || l.videoUrl != null))
          .toList();

      // Lessons with images only — for text_to_sign (needs images as options)
      final imageLessons = allLessons
          .where((l) => l.isActive && l.imageUrl != null)
          .toList();

      // Alphabet lessons for spelling
      final alphabetLessons = allLessons
          .where((l) =>
              l.isActive &&
              l.categoryId == 'alphabet' &&
              l.signName.length == 1 &&
              l.imageUrl != null)
          .toList();

      if (mediaLessons.length < 4) {
        return SeedResult(
          success: false,
          message:
              'Not enough lessons with images/videos found (need at least 4).\n'
              'Please add lesson content first.',
        );
      }

      int created = 0;

      // --- Sign to Text (3 quizzes) ---
      created += await _seedSignToTextQuizzes(mediaLessons);

      // --- Text to Sign (3 quizzes) ---
      if (imageLessons.length >= 4) {
        created += await _seedTextToSignQuizzes(imageLessons);
      }

      // --- Timed Challenge (3 quizzes) ---
      created += await _seedTimedQuizzes(mediaLessons);

      // --- Spelling (up to 3 quizzes if alphabet images exist) ---
      if (alphabetLessons.length >= 10) {
        created += await _seedSpellingQuizzes(alphabetLessons);
      }

      return SeedResult(
        success: true,
        message: 'Created $created quiz sets successfully!',
      );
    } catch (e) {
      debugPrint('QuizSeeder error: $e');
      return SeedResult(success: false, message: 'Error: $e');
    }
  }

  static Future<void> deleteAllSeededQuizzes() async {
    final snapshot = await _firestore
        .collection(AppConstants.quizzesCollection)
        .where('isSeeded', isEqualTo: true)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ── Sign to Text ─────────────────────────────────────────────────────────

  static Future<int> _seedSignToTextQuizzes(
      List<LessonModel> lessons) async {
    final allNames = lessons.map((l) => l.signName).toList();
    final configs = [
      _QuizConfig(
        title: 'Sign to Text — Beginner',
        description: 'Identify basic BIM signs. See a sign and pick the correct word.',
        difficulty: 'easy',
        lessonFilter: (l) => l.difficulty == 'beginner' || l.difficulty == 'easy',
        count: 10,
      ),
      _QuizConfig(
        title: 'Sign to Text — Intermediate',
        description: 'Test your knowledge of intermediate BIM vocabulary.',
        difficulty: 'medium',
        lessonFilter: (l) => l.difficulty == 'intermediate' || l.difficulty == 'medium',
        count: 10,
      ),
      _QuizConfig(
        title: 'Sign to Text — Mixed Signs',
        description: 'A mixed set of signs from all categories. Can you identify them all?',
        difficulty: 'hard',
        lessonFilter: (_) => true,
        count: 10,
      ),
    ];

    int created = 0;
    for (final config in configs) {
      var pool = lessons.where(config.lessonFilter).toList();
      if (pool.length < 4) pool = lessons; // fallback to all
      pool = [...pool]..shuffle();
      final targets = pool.take(config.count).toList();

      final questions = targets.map((lesson) {
        final distractors = (allNames
              .where((n) => n != lesson.signName)
              .toList()
              ..shuffle())
            .take(3)
            .toList();
        final options = [...distractors, lesson.signName]..shuffle();
        return _buildQuestion(
          lesson: lesson,
          questionText: 'What sign is this?',
          options: options,
          optionImages: const [],
          correctAnswer: lesson.signName,
        );
      }).toList();

      await _saveQuiz(
        title: config.title,
        description: config.description,
        quizType: 'sign_to_text',
        difficulty: config.difficulty,
        questions: questions,
      );
      created++;
    }
    return created;
  }

  // ── Text to Sign ─────────────────────────────────────────────────────────

  static Future<int> _seedTextToSignQuizzes(
      List<LessonModel> lessons) async {
    final configs = [
      _QuizConfig(
        title: 'Text to Sign — Common Words',
        description: 'See a word and pick the correct sign image.',
        difficulty: 'easy',
        lessonFilter: (l) => l.difficulty == 'beginner' || l.difficulty == 'easy',
        count: 10,
      ),
      _QuizConfig(
        title: 'Text to Sign — Greetings & Phrases',
        description: 'Match phrases to their BIM signs.',
        difficulty: 'medium',
        lessonFilter: (l) =>
            l.categoryId == 'greetings' || l.categoryId == 'common',
        count: 10,
      ),
      _QuizConfig(
        title: 'Text to Sign — Challenge Round',
        description: 'A harder mix of signs from across all categories.',
        difficulty: 'hard',
        lessonFilter: (_) => true,
        count: 10,
      ),
    ];

    int created = 0;
    for (final config in configs) {
      var pool = lessons.where(config.lessonFilter).toList();
      if (pool.length < 4) pool = lessons;
      pool = [...pool]..shuffle();
      final targets = pool.take(config.count).toList();

      final questions = targets.map((lesson) {
        final distractors = (pool
              .where((l) => l.id != lesson.id && l.imageUrl != null)
              .toList()
              ..shuffle())
            .take(3)
            .toList();

        final allFour = [lesson, ...distractors]..shuffle();
        final options = allFour.map((l) => l.signName).toList();
        final optionImages = allFour.map((l) => l.imageUrl).toList();

        return _buildQuestion(
          lesson: lesson,
          questionText: lesson.signName,
          options: options,
          optionImages: optionImages,
          correctAnswer: lesson.signName,
          imageUrl: null,   // question shows text, not image
          videoUrl: null,
        );
      }).toList();

      await _saveQuiz(
        title: config.title,
        description: config.description,
        quizType: 'text_to_sign',
        difficulty: config.difficulty,
        questions: questions,
      );
      created++;
    }
    return created;
  }

  // ── Timed Challenge ───────────────────────────────────────────────────────

  static Future<int> _seedTimedQuizzes(List<LessonModel> lessons) async {
    final allNames = lessons.map((l) => l.signName).toList();
    final configs = [
      _QuizConfig(
        title: 'Timed Challenge — Sprint',
        description: '15 signs, 10 seconds each. How many can you get right?',
        difficulty: 'easy',
        lessonFilter: (l) => l.difficulty == 'beginner' || l.difficulty == 'easy',
        count: 15,
      ),
      _QuizConfig(
        title: 'Timed Challenge — Speed Round',
        description: 'Mixed signs under time pressure. Think fast!',
        difficulty: 'medium',
        lessonFilter: (_) => true,
        count: 15,
      ),
      _QuizConfig(
        title: 'Timed Challenge — Expert',
        description: 'Advanced signs, limited time. Only the best will ace this.',
        difficulty: 'hard',
        lessonFilter: (l) =>
            l.difficulty == 'advanced' ||
            l.difficulty == 'intermediate' ||
            l.difficulty == 'hard',
        count: 15,
      ),
    ];

    int created = 0;
    for (final config in configs) {
      var pool = lessons.where(config.lessonFilter).toList();
      if (pool.length < 4) pool = lessons;
      pool = [...pool]..shuffle();
      final targets = pool.take(config.count).toList();

      final questions = targets.map((lesson) {
        final distractors = (allNames
              .where((n) => n != lesson.signName)
              .toList()
              ..shuffle())
            .take(3)
            .toList();
        final options = [...distractors, lesson.signName]..shuffle();
        return _buildQuestion(
          lesson: lesson,
          questionText: 'What sign is this?',
          options: options,
          optionImages: const [],
          correctAnswer: lesson.signName,
          points: 15,
        );
      }).toList();

      await _saveQuiz(
        title: config.title,
        description: config.description,
        quizType: 'timed',
        difficulty: config.difficulty,
        questions: questions,
      );
      created++;
    }
    return created;
  }

  // ── Spelling ──────────────────────────────────────────────────────────────

  static Future<int> _seedSpellingQuizzes(
      List<LessonModel> alphabetLessons) async {
    final Map<String, String> letterToImage = {};
    for (final lesson in alphabetLessons) {
      letterToImage[lesson.signName.toUpperCase()] = lesson.imageUrl!;
    }

    const wordsByDifficulty = {
      'easy': [
        'CAT', 'DOG', 'BUS', 'CAR', 'SUN', 'MAP', 'BAG', 'CUP', 'PEN', 'BOX',
      ],
      'medium': [
        'FISH', 'BIRD', 'BOOK', 'CAKE', 'BALL', 'DOOR', 'FIRE', 'HAND', 'MILK', 'RICE',
      ],
      'hard': [
        'APPLE', 'BLACK', 'BREAD', 'CHAIR', 'CLEAN', 'DANCE', 'EARTH', 'FLAME', 'GLASS', 'HAPPY',
      ],
    };

    final configs = [
      ('Spelling Quiz — Short Words', 'easy', 'Identify 3-letter words from fingerspelling signs.'),
      ('Spelling Quiz — Common Words', 'medium', 'Spell out 4-letter vocabulary words using BIM finger signs.'),
      ('Spelling Quiz — Challenge', 'hard', 'Longer words, trickier spellings. Can you decode them?'),
    ];

    int created = 0;
    final allWordList = wordsByDifficulty.values.expand((w) => w).toList();

    for (final (title, difficulty, description) in configs) {
      final wordPool = wordsByDifficulty[difficulty]!
          .where((w) => w.split('').every(letterToImage.containsKey))
          .toList();

      if (wordPool.length < 4) continue;

      final questions = wordPool.take(10).map((word) {
        final letterImages =
            word.split('').map((l) => letterToImage[l]!).toList();

        final distractors = (allWordList
              .where((w) =>
                  w != word &&
                  w.split('').every(letterToImage.containsKey))
              .toList()
              ..shuffle())
            .take(3)
            .toList();

        final options = [...distractors, word]..shuffle();

        return QuizQuestionModel(
          id: 'spelling_${word.toLowerCase()}',
          questionText: 'What word is being spelled?',
          signEmoji: '✍️',
          imageUrl: null,
          videoUrl: null,
          options: options,
          optionImages: const [],
          correctAnswer: word,
          points: 10,
          hint: '${word.length}-letter word',
          category: 'alphabet',
          letterImages: letterImages,
        );
      }).toList();

      if (questions.isEmpty) continue;

      await _saveQuiz(
        title: title,
        description: description,
        quizType: 'spelling',
        difficulty: difficulty,
        questions: questions,
      );
      created++;
    }
    return created;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static QuizQuestionModel _buildQuestion({
    required LessonModel lesson,
    required String questionText,
    required List<String> options,
    required List<String?> optionImages,
    required String correctAnswer,
    String? imageUrl,
    String? videoUrl,
    int points = 10,
  }) {
    return QuizQuestionModel(
      id: lesson.id,
      questionText: questionText,
      signEmoji: lesson.emoji,
      imageUrl: imageUrl ?? lesson.imageUrl,
      videoUrl: videoUrl ?? lesson.videoUrl,
      options: options,
      optionImages: optionImages,
      correctAnswer: correctAnswer,
      points: points,
      hint: lesson.description,
      category: lesson.categoryId,
    );
  }

  static Future<void> _saveQuiz({
    required String title,
    required String description,
    required String quizType,
    required String difficulty,
    required List<QuizQuestionModel> questions,
  }) async {
    await _firestore.collection(AppConstants.quizzesCollection).add({
      'title': title,
      'description': description,
      'quizType': quizType,
      'difficulty': difficulty,
      'questions': questions.map((q) => q.toMap()).toList(),
      'isActive': true,
      'isSeeded': true,
      'createdAt': Timestamp.now(),
    });
  }
}

class _QuizConfig {
  final String title;
  final String description;
  final String difficulty;
  final bool Function(LessonModel) lessonFilter;
  final int count;

  const _QuizConfig({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.lessonFilter,
    required this.count,
  });
}

class SeedResult {
  final bool success;
  final String message;
  const SeedResult({required this.success, required this.message});
}
