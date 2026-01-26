import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/progress_model.dart';

import '../config/constants.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../models/achievement_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER METHODS ====================

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(data);
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  Future<void> updateUserField(String userId, String field, dynamic value) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({field: value});
      debugPrint('✅ Updated $field for user $userId');
    } catch (e) {
      debugPrint('❌ Error updating user field: $e');
      rethrow;
    }
  }

  // ==================== LESSON CATEGORY METHODS (Main App) ====================

  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .orderBy('order')
          .get();
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    try {
      await _firestore.collection(AppConstants.categoriesCollection).add(data);
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .update(data);
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      final lessons = await _firestore
          .collection(AppConstants.lessonsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .get();

      for (var doc in lessons.docs) {
        await doc.reference.delete();
      }

      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  // ==================== LESSON METHODS ====================

  /// Natural sort comparison for lesson names
  int _naturalCompare(String a, String b) {
    final numA = int.tryParse(a);
    final numB = int.tryParse(b);
    
    if (numA != null && numB != null) {
      return numA.compareTo(numB);
    } else if (numA != null) {
      return -1;
    } else if (numB != null) {
      return 1;
    } else {
      return a.toLowerCase().compareTo(b.toLowerCase());
    }
  }

  Future<List<LessonModel>> getLessons(String categoryId) async {
    try {
      debugPrint('🔥 Getting lessons for categoryId: "$categoryId"');
      
      final snapshot = await _firestore
          .collection(AppConstants.lessonsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .get();

      debugPrint('🔥 Found ${snapshot.docs.length} lessons');

      final lessons = snapshot.docs.map((doc) => LessonModel.fromFirestore(doc)).toList();
      
      // Sort alphabetically/numerically by signName
      lessons.sort((a, b) => _naturalCompare(a.signName, b.signName));
      
      return lessons;
    } catch (e) {
      debugPrint('❌ Error getting lessons: $e');
      return [];
    }
  }

  Future<List<LessonModel>> getAllLessons() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.lessonsCollection)
          .get();
      final lessons = snapshot.docs.map((doc) => LessonModel.fromFirestore(doc)).toList();
      
      // Sort alphabetically/numerically by signName
      lessons.sort((a, b) => _naturalCompare(a.signName, b.signName));
      
      return lessons;
    } catch (e) {
      debugPrint('Error getting all lessons: $e');
      return [];
    }
  }

  Future<void> addLesson(Map<String, dynamic> data) async {
    try {
      await _firestore.collection(AppConstants.lessonsCollection).add(data);

      if (data['categoryId'] != null) {
        await _updateCategoryLessonCount(data['categoryId']);
      }
    } catch (e) {
      debugPrint('Error adding lesson: $e');
      rethrow;
    }
  }

  Future<void> updateLesson(String lessonId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.lessonsCollection)
          .doc(lessonId)
          .update(data);
    } catch (e) {
      debugPrint('Error updating lesson: $e');
      rethrow;
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    try {
      final lessonDoc = await _firestore
          .collection(AppConstants.lessonsCollection)
          .doc(lessonId)
          .get();

      final categoryId = lessonDoc.data()?['categoryId'];

      await _firestore
          .collection(AppConstants.lessonsCollection)
          .doc(lessonId)
          .delete();

      if (categoryId != null) {
        await _updateCategoryLessonCount(categoryId);
      }
    } catch (e) {
      debugPrint('Error deleting lesson: $e');
      rethrow;
    }
  }

  Future<void> _updateCategoryLessonCount(String categoryId) async {
    try {
      final lessons = await _firestore
          .collection(AppConstants.lessonsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .get();

      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .update({'lessonCount': lessons.docs.length});
    } catch (e) {
      debugPrint('Error updating category lesson count: $e');
    }
  }

  // ==================== QUIZ METHODS ====================

  Future<List<QuizModel>> getQuizzes() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.quizzesCollection)
          .get();
      return snapshot.docs.map((doc) => QuizModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting quizzes: $e');
      return [];
    }
  }

  Future<void> addQuiz(Map<String, dynamic> data) async {
    try {
      await _firestore.collection(AppConstants.quizzesCollection).add(data);
    } catch (e) {
      debugPrint('Error adding quiz: $e');
      rethrow;
    }
  }

  Future<void> updateQuiz(String quizId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.quizzesCollection)
          .doc(quizId)
          .update(data);
    } catch (e) {
      debugPrint('Error updating quiz: $e');
      rethrow;
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      await _firestore
          .collection(AppConstants.quizzesCollection)
          .doc(quizId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting quiz: $e');
      rethrow;
    }
  }

  // ==================== QUIZ COMPLETION ====================

  Future<void> completeQuiz({
    required String userId,
    required String quizType,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
    required int xpEarned,
    String? quizId,
    String? quizTitle,
  }) async {
    try {
      final now = DateTime.now();
      final quizTypeName = _getQuizTypeName(quizType);
      final displayTitle = quizTitle ?? quizTypeName;

      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final currentXP = userData['totalXP'] ?? 0;

      await _firestore.collection(AppConstants.progressCollection).add({
        'userId': userId,
        'lessonId': 'quiz_${quizId ?? quizType}_${now.millisecondsSinceEpoch}',
        'categoryId': 'quiz',
        'lessonName': displayTitle,
        'categoryName': quizTypeName,
        'displayTitle': displayTitle,
        'type': 'quiz',
        'quizType': quizType,
        'quizId': quizId,
        'status': 'completed',
        'isCompleted': true,
        'completionPercentage': 100.0,
        'xpEarned': xpEarned,
        'score': score,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'accuracy': totalQuestions > 0 ? (correctAnswers / totalQuestions * 100) : 0,
        'completedAt': Timestamp.fromDate(now),
        'lastAccessedAt': Timestamp.fromDate(now),
        'startedAt': Timestamp.fromDate(now),
      });

      final isPerfect = totalQuestions > 0 && correctAnswers == totalQuestions;

      Map<String, dynamic> updates = {
        'totalXP': currentXP + xpEarned,
        'lastActiveAt': Timestamp.fromDate(now),
        'quizzesCompleted': FieldValue.increment(1),
      };

      if (isPerfect) {
        updates['perfectQuizzes'] = FieldValue.increment(1);
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updates);

      debugPrint('✅ Quiz activity saved: $displayTitle (+$xpEarned XP)${isPerfect ? ' - PERFECT!' : ''}');
    } catch (e) {
      debugPrint('❌ Error saving quiz activity: $e');
      rethrow;
    }
  }

  String _getQuizTypeName(String type) {
    switch (type) {
      case 'sign_to_text':
        return 'Sign to Text Quiz';
      case 'text_to_sign':
        return 'Text to Sign Quiz';
      case 'timed':
        return 'Timed Challenge';
      case 'spelling':
        return 'Spelling Quiz';
      default:
        return 'Quiz';
    }
  }

  Future<double> getAverageQuizAccuracy(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.progressCollection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'quiz')
          .get();

      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      double totalAccuracy = 0;
      int count = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        if (data['accuracy'] != null) {
          totalAccuracy += (data['accuracy'] as num).toDouble();
          count++;
        } else if (data['correctAnswers'] != null && data['totalQuestions'] != null) {
          final correct = data['correctAnswers'] as int;
          final total = data['totalQuestions'] as int;
          if (total > 0) {
            totalAccuracy += (correct / total * 100);
            count++;
          }
        } else if (data['score'] != null) {
          totalAccuracy += (data['score'] as num).toDouble();
          count++;
        }
      }

      if (count == 0) return 0.0;
      
      final avgAccuracy = totalAccuracy / count;
      debugPrint('📊 Average quiz accuracy: ${avgAccuracy.toStringAsFixed(1)}% (from $count quizzes)');
      return avgAccuracy;
    } catch (e) {
      debugPrint('Error getting average quiz accuracy: $e');
      return 0.0;
    }
  }

  // ==================== PROGRESS METHODS ====================

  Future<List<LearningProgressModel>> getUserProgress(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.progressCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      final progressList = snapshot.docs
          .map((doc) => LearningProgressModel.fromFirestore(doc))
          .toList();
      
      progressList.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
      
      return progressList;
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      return [];
    }
  }

  Future<Set<String>> getCompletedLessonIdsForUser(String userId) async {
    try {
      Set<String> completedIds = {};

      final allProgress = await _firestore
          .collection(AppConstants.progressCollection)
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('📊 Found ${allProgress.docs.length} total progress records for user $userId');

      for (var doc in allProgress.docs) {
        final data = doc.data();
        final lessonId = data['lessonId'] as String?;
        
        if (data['type'] == 'quiz' || data['categoryId'] == 'quiz') {
          continue;
        }
        
        final isCompletedByStatus = data['status'] == 'completed';
        final isCompletedByBool = data['isCompleted'] == true;
        final isCompletedByPercentage = (data['completionPercentage'] ?? 0) >= 100;
        
        final isCompleted = isCompletedByStatus || isCompletedByBool || isCompletedByPercentage;
        
        debugPrint('  📝 Lesson: $lessonId | status=${data['status']} | isCompleted=${data['isCompleted']} | percentage=${data['completionPercentage']} | COMPLETED: $isCompleted');
        
        if (lessonId != null && isCompleted) {
          completedIds.add(lessonId);
        }
      }

      debugPrint('✅ Total completed lessons: ${completedIds.length}');
      debugPrint('✅ Completed IDs: $completedIds');
      
      return completedIds;
    } catch (e) {
      debugPrint('❌ Error getting completed lessons: $e');
      return {};
    }
  }

  Future<void> updateLessonProgress(
      String userId, LearningProgressModel progress) async {
    try {
      final existing = await _firestore
          .collection(AppConstants.progressCollection)
          .where('userId', isEqualTo: userId)
          .where('lessonId', isEqualTo: progress.lessonId)
          .get();

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update(progress.toFirestore());
      } else {
        await _firestore
            .collection(AppConstants.progressCollection)
            .add(progress.toFirestore());
      }
    } catch (e) {
      debugPrint('Error updating lesson progress: $e');
      rethrow;
    }
  }

  // ==================== ACHIEVEMENT METHODS ====================

  Future<List<AchievementModel>> getAchievements() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.achievementsCollection)
          .get();
      return snapshot.docs
          .map((doc) => AchievementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return [];
    }
  }

  Future<List<UserAchievementModel>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.userAchievementsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) => UserAchievementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      return [];
    }
  }

  // ==================== ADDITIONAL USER METHODS ====================

  Future<void> addUserXP(String userId, int xpAmount) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final currentXP = userDoc.data()?['totalXP'] ?? 0;
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({'totalXP': currentXP + xpAmount});
      }
    } catch (e) {
      debugPrint('Error adding user XP: $e');
      rethrow;
    }
  }

  Future<List<LessonModel>> getLessonsByCategory(String categoryId) async {
    return getLessons(categoryId);
  }

  // ==================== DAILY GOALS ====================

  static String getDailyGoalText() {
    return DailyGoalModel.getDailyGoalText();
  }

  static int getDailyGoalTarget() {
    return DailyGoalModel.getDailyGoalTarget();
  }

  Future<void> checkAndResetDailyGoal(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      DateTime? lastLessonDate;
      if (userData['lastLessonDate'] != null) {
        lastLessonDate = (userData['lastLessonDate'] as Timestamp).toDate();
      }

      Map<String, dynamic> updates = {};

      if (lastLessonDate != null) {
        final lastDate = DateTime(lastLessonDate.year, lastLessonDate.month, lastLessonDate.day);
        
        if (lastDate.isBefore(today)) {
          updates['dailyGoalProgress'] = 0;
          updates['dailyGoalTarget'] = getDailyGoalTarget();
          updates['dailyGoalText'] = getDailyGoalText();
          updates['lessonsCompletedToday'] = 0;
          debugPrint('✅ Daily goal reset for new day');
        }

        if (lastDate.isBefore(yesterday)) {
          final currentStreak = userData['currentStreak'] ?? 0;
          if (currentStreak > 0) {
            updates['currentStreak'] = 0;
            debugPrint('⚠️ Streak reset - user missed a day (last: $lastDate, yesterday: $yesterday)');
          }
        }
      } else {
        updates['dailyGoalProgress'] = 0;
        updates['dailyGoalTarget'] = getDailyGoalTarget();
        updates['dailyGoalText'] = getDailyGoalText();
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update(updates);
      }
    } catch (e) {
      debugPrint('⚠️ Error checking daily goal: $e');
    }
  }

  // ==================== LESSON COMPLETION ====================

  Future<void> completeLesson(
    String userId, 
    String lessonId, 
    int xpReward, 
    {String lessonName = '', String categoryName = ''}
  ) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int currentXP = userData['totalXP'] ?? 0;
      int signsLearned = userData['signsLearned'] ?? 0;
      int currentStreak = userData['currentStreak'] ?? 0;
      int longestStreak = userData['longestStreak'] ?? 0;
      int dailyGoalProgress = userData['dailyGoalProgress'] ?? 0;
      int dailyGoalTarget = userData['dailyGoalTarget'] ?? getDailyGoalTarget();
      int lessonsCompletedToday = userData['lessonsCompletedToday'] ?? 0;

      DateTime? lastLessonDate;
      if (userData['lastLessonDate'] != null) {
        lastLessonDate = (userData['lastLessonDate'] as Timestamp).toDate();
      }

      final existingProgress = await _firestore
          .collection(AppConstants.progressCollection)
          .where('userId', isEqualTo: userId)
          .where('lessonId', isEqualTo: lessonId)
          .get();

      bool isNewLesson = true;
      for (var doc in existingProgress.docs) {
        final data = doc.data();
        final isCompletedByStatus = data['status'] == 'completed';
        final isCompletedByBool = data['isCompleted'] == true;
        final isCompletedByPercentage = (data['completionPercentage'] ?? 0) >= 100;
        
        if (isCompletedByStatus || isCompletedByBool || isCompletedByPercentage) {
          isNewLesson = false;
          break;
        }
      }

      debugPrint('🔍 Checking lesson $lessonId for user $userId');
      debugPrint('   Lesson: $lessonName | Category: $categoryName');
      debugPrint('   Is new lesson: $isNewLesson');

      Map<String, dynamic> updates = {
        'lastActiveAt': Timestamp.fromDate(now),
      };

      if (isNewLesson) {
        updates['signsLearned'] = signsLearned + 1;
        updates['totalXP'] = currentXP + xpReward;

        if (lastLessonDate != null) {
          final lastDate = DateTime(lastLessonDate.year, lastLessonDate.month, lastLessonDate.day);
          if (lastDate.isBefore(today)) {
            updates['dailyGoalProgress'] = 1;
            updates['dailyGoalTarget'] = getDailyGoalTarget();
            updates['dailyGoalText'] = getDailyGoalText();
            updates['lessonsCompletedToday'] = 1; 
          } else {
            if (dailyGoalProgress < dailyGoalTarget) {
              updates['dailyGoalProgress'] = dailyGoalProgress + 1;
            }
            updates['lessonsCompletedToday'] = lessonsCompletedToday + 1;
          }
        } else {
          updates['dailyGoalProgress'] = 1;
          updates['dailyGoalTarget'] = getDailyGoalTarget();
          updates['dailyGoalText'] = getDailyGoalText();
          updates['lessonsCompletedToday'] = 1;
        }

        if (lastLessonDate != null) {
          final lastDate = DateTime(lastLessonDate.year, lastLessonDate.month, lastLessonDate.day);
          final yesterday = today.subtract(const Duration(days: 1));

          if (lastDate.isBefore(today)) {
            if (lastDate.isAtSameMomentAs(yesterday) ||
                lastDate.isAfter(yesterday.subtract(const Duration(days: 1)))) {
              int newStreak = currentStreak + 1;
              updates['currentStreak'] = newStreak;
              if (newStreak > longestStreak) {
                updates['longestStreak'] = newStreak;
              }
            } else {
              updates['currentStreak'] = 1;
            }
          }
        } else {
          updates['currentStreak'] = 1;
          if (longestStreak == 0) {
            updates['longestStreak'] = 1;
          }
        }

        updates['lastLessonDate'] = Timestamp.fromDate(now);

        await _firestore.collection(AppConstants.progressCollection).add({
          'userId': userId,
          'lessonId': lessonId,
          'categoryId': '',
          'lessonName': lessonName,
          'categoryName': categoryName,
          'displayTitle': '$categoryName - $lessonName',
          'type': 'lesson',
          'status': 'completed',
          'isCompleted': true,
          'completionPercentage': 100.0,
          'xpEarned': xpReward,
          'completedAt': Timestamp.fromDate(now),
          'lastAccessedAt': Timestamp.fromDate(now),
          'startedAt': Timestamp.fromDate(now),
          'timeSpentSeconds': 0,
          'practiceCount': 1,
          'bestAccuracy': 100.0,
        });

        debugPrint('✅ Progress saved: $categoryName - $lessonName');
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updates);

      debugPrint('✅ Lesson completed successfully');
    } catch (e) {
      debugPrint('❌ Error completing lesson: $e');
      rethrow;
    }
  }

  // ==================== SEED DATA ====================

  Future<void> seedInitialData() async {
    try {
      final categories = await getCategories();
      if (categories.isNotEmpty) return;

      for (var category in CategoryModel.defaultCategories) {
        await _firestore
            .collection(AppConstants.categoriesCollection)
            .doc(category.id)
            .set({
          'name': category.name,
          'description': category.description,
          'icon': category.icon,
          'lessonCount': category.lessonCount,
          'order': category.order,
          'isActive': category.isActive,
        });
      }

      final sampleLessons = [
        {
          'signName': 'Hello',
          'description': 'Wave your hand side to side',
          'categoryId': 'greetings',
          'emoji': '👋',
          'xpReward': 10,
          'tips': ['Keep your fingers together', 'Wave from the wrist'],
          'signLanguage': 'ASL',
          'order': 0,
          'isActive': true,
        },
        {
          'signName': 'Thank You',
          'description': 'Touch your chin and move hand forward',
          'categoryId': 'greetings',
          'emoji': '🙏',
          'xpReward': 10,
          'tips': ['Start at lips/chin', 'Move hand outward gracefully'],
          'signLanguage': 'ASL',
          'order': 1,
          'isActive': true,
        },
        {
          'signName': 'Yes',
          'description': 'Make a fist and nod it up and down',
          'categoryId': 'common',
          'emoji': '👍',
          'xpReward': 10,
          'tips': ['Like your hand is nodding', 'Keep movements small'],
          'signLanguage': 'ASL',
          'order': 0,
          'isActive': true,
        },
        {
          'signName': 'No',
          'description': 'Extend index and middle finger, tap them to thumb',
          'categoryId': 'common',
          'emoji': '👎',
          'xpReward': 10,
          'tips': ['Quick snapping motion', 'Like closing a tiny mouth'],
          'signLanguage': 'ASL',
          'order': 1,
          'isActive': true,
        },
        {
          'signName': 'I Love You',
          'description': 'Extend thumb, index finger, and pinky',
          'categoryId': 'common',
          'emoji': '🤟',
          'xpReward': 15,
          'tips': ['Combines I, L, and Y', 'Palm faces outward'],
          'signLanguage': 'ASL',
          'order': 2,
          'isActive': true,
        },
      ];

      for (var lesson in sampleLessons) {
        await _firestore.collection(AppConstants.lessonsCollection).add(lesson);
      }

      final defaultAchievements = [
        {
          'name': 'First Steps',
          'description': 'Complete your first lesson',
          'icon': '🎯',
          'tier': 'bronze',
          'xpReward': 50,
        },
        {
          'name': 'Quick Learner',
          'description': 'Complete 10 lessons',
          'icon': '📚',
          'tier': 'silver',
          'xpReward': 100,
        },
        {
          'name': 'Quiz Master',
          'description': 'Score 100% on any quiz',
          'icon': '🏆',
          'tier': 'gold',
          'xpReward': 150,
        },
        {
          'name': 'Dedicated',
          'description': 'Maintain a 7-day streak',
          'icon': '🔥',
          'tier': 'silver',
          'xpReward': 100,
        },
        {
          'name': 'Scholar',
          'description': 'Earn 1000 XP',
          'icon': '⭐',
          'tier': 'gold',
          'xpReward': 200,
        },
        {
          'name': 'Sign Expert',
          'description': 'Learn 50 signs',
          'icon': '🤟',
          'tier': 'platinum',
          'xpReward': 300,
        },
      ];

      for (var achievement in defaultAchievements) {
        await _firestore
            .collection(AppConstants.achievementsCollection)
            .add(achievement);
      }

      debugPrint('Initial data seeded successfully');
    } catch (e) {
      debugPrint('Error seeding data: $e');
    }
  }

  // ==================== RESET USER PROGRESS ====================

  Future<void> resetUserProgress(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'totalXP': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'signsLearned': 0,
        'quizzesCompleted': 0,
        'perfectQuizzes': 0,
        'lessonsCompletedToday': 0,
        'dailyGoalProgress': 0,
        'dailyGoalTarget': getDailyGoalTarget(),
        'dailyGoalText': getDailyGoalText(),
        'lastLessonDate': null,
        'unlockedBadges': [], 
        'seenBadges': [], 
        'totalTimeSpentSeconds': 0, 
      });

      final progressDocs = await _firestore
          .collection(AppConstants.progressCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in progressDocs.docs) {
        await doc.reference.delete();
      }

      try {
        final quizAttempts = await _firestore
            .collection('quizAttempts')
            .where('userId', isEqualTo: userId)
            .get();

        for (var doc in quizAttempts.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('No quiz attempts to delete or collection does not exist');
      }

      try {
        final userAchievements = await _firestore
            .collection(AppConstants.userAchievementsCollection)
            .where('userId', isEqualTo: userId)
            .get();

        for (var doc in userAchievements.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('No user achievements to delete or collection does not exist');
      }

      try {
        final notifications = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();

        for (var doc in notifications.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('No notifications to delete or collection does not exist');
      }

      try {
        final challengeProgress = await _firestore
            .collection('users')
            .doc(userId)
            .collection('challengeProgress')
            .get();

        for (var doc in challengeProgress.docs) {
          await doc.reference.delete();
        }
        debugPrint('Deleted ${challengeProgress.docs.length} challenge progress documents');
      } catch (e) {
        debugPrint('No challenge progress to delete or collection does not exist: $e');
      }

      try {
        final challenges = await _firestore
            .collection('user_challenges')
            .where('userId', isEqualTo: userId)
            .get();

        for (var doc in challenges.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('No user_challenges to delete or collection does not exist');
      }

      debugPrint('User progress reset successfully for user: $userId');
    } catch (e) {
      debugPrint('Error resetting user progress: $e');
      rethrow;
    }
  }

  // ==================== SIGN LIBRARY METHODS (OPTIMIZED) ====================

  /// Get the special categories just for the Sign Library
  Stream<QuerySnapshot> getSignLibraryCategoriesStream() {
    return _firestore
        .collection('sign_library_categories')
        .orderBy('name')
        .snapshots();
  }

  /// Add a new category specifically for the library
  Future<void> addSignLibraryCategory(String name) async {
    final docId = name.trim().toLowerCase().replaceAll(' ', '_');
    await _firestore.collection('sign_library_categories').doc(docId).set({
      'name': name.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a library category
  Future<void> deleteSignLibraryCategory(String docId) async {
    await _firestore.collection('sign_library_categories').doc(docId).delete();
  }

  /// OPTIMIZED: Upload sign with separate animation data
  /// Metadata goes to 'signs', animation data goes to 'sign_animations'
  Future<void> uploadSign(String word, String category, Map<String, dynamic> jsonData) async {
    try {
      final docId = word.toLowerCase().trim().replaceAll(' ', '_');
      final searchKey = word.toLowerCase();

      // Compress animation data to reduce size
      final compressedData = _compressAnimationData(jsonData);

      // Use batched write for both operations (faster than 2 separate writes)
      final batch = _firestore.batch();

      // 1. Save lightweight metadata to 'signs' collection
      final signRef = _firestore.collection('signs').doc(docId);
      batch.set(signRef, {
        'word': word,
        'searchKey': searchKey,
        'category': category,
        'uploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Save heavy animation data to separate 'sign_animations' collection
      final animRef = _firestore.collection('sign_animations').doc(docId);
      batch.set(animRef, {
        'word': word,
        'data': compressedData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit both writes at once
      await batch.commit();

      debugPrint("✅ Sign uploaded (optimized): $docId (Category: $category)");
    } catch (e) {
      debugPrint("❌ Error uploading sign: $e");
      rethrow;
    }
  }

  /// BULK UPLOAD: Upload multiple signs at once (much faster)
  /// Firestore limit: 10MB per batch, so we use small batches
  Future<Map<String, dynamic>> uploadSignsBulk(
    List<Map<String, dynamic>> signs,
    String category, {
    Function(int current, int total)? onProgress,
  }) async {
    int success = 0;
    int failed = 0;
    List<String> failedWords = [];

    try {
      // Process in batches of 10 (each sign ~200-400KB, staying well under 10MB limit)
      const batchSize = 10;
      
      for (int i = 0; i < signs.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize > signs.length) ? signs.length : i + batchSize;
        final chunk = signs.sublist(i, end);
        int chunkSuccess = 0;

        for (var sign in chunk) {
          try {
            final word = sign['word'] as String;
            final data = sign['data'] as Map<String, dynamic>;
            
            final docId = word.toLowerCase().trim().replaceAll(' ', '_');
            final searchKey = word.toLowerCase();
            final compressedData = _compressAnimationData(data);

            // Add metadata write
            final signRef = _firestore.collection('signs').doc(docId);
            batch.set(signRef, {
              'word': word,
              'searchKey': searchKey,
              'category': category,
              'uploadedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // Add animation write
            final animRef = _firestore.collection('sign_animations').doc(docId);
            batch.set(animRef, {
              'word': word,
              'data': compressedData,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            chunkSuccess++;
          } catch (e) {
            failed++;
            failedWords.add(sign['word'] ?? 'unknown');
            debugPrint("❌ Error preparing ${sign['word']}: $e");
          }
        }

        // Commit this batch
        await batch.commit();
        success += chunkSuccess;
        
        onProgress?.call(i + chunk.length, signs.length);
        debugPrint("✅ Uploaded batch ${(i ~/ batchSize) + 1}: ${i + chunk.length}/${signs.length}");
        
        // Small delay between batches
        if (i + batchSize < signs.length) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    } catch (e) {
      debugPrint("❌ Bulk upload error: $e");
      rethrow; // Let caller handle the error
    }

    return {
      'success': success,
      'failed': failed,
      'failedWords': failedWords,
    };
  }

  /// Compress JSON by reducing decimal precision (0.123456789 → 0.123)
  Map<String, dynamic> _compressAnimationData(Map<String, dynamic> data) {
    try {
      String jsonStr = json.encode(data);
      final originalSize = jsonStr.length;
      
      // Level 1: Reduce to 3 decimals (default)
      jsonStr = jsonStr.replaceAllMapped(
        RegExp(r'(\d+\.\d{3})\d+'),
        (match) => match.group(1)!,
      );
      
      // If still > 800KB, use Level 2: Reduce to 2 decimals
      if (jsonStr.length > 800000) {
        jsonStr = json.encode(data);
        jsonStr = jsonStr.replaceAllMapped(
          RegExp(r'(\d+\.\d{2})\d+'),
          (match) => match.group(1)!,
        );
        debugPrint("⚠️ Large file - using 2 decimal compression");
      }
      
      // If still > 900KB, use Level 3: Reduce to 1 decimal + remove face landmarks
      if (jsonStr.length > 900000) {
        Map<String, dynamic> reduced = json.decode(jsonStr);
        reduced = _removeUnnecessaryLandmarks(reduced);
        jsonStr = json.encode(reduced);
        jsonStr = jsonStr.replaceAllMapped(
          RegExp(r'(\d+\.\d{1})\d+'),
          (match) => match.group(1)!,
        );
        debugPrint("⚠️ Very large file - using 1 decimal + removing extra landmarks");
      }
      
      final compressedSize = jsonStr.length;
      final savings = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
      debugPrint("📦 Compressed: ${(originalSize/1024).toStringAsFixed(0)}KB → ${(compressedSize/1024).toStringAsFixed(0)}KB ($savings% saved)");
      
      return json.decode(jsonStr);
    } catch (e) {
      debugPrint("⚠️ Compression failed, using original: $e");
      return data;
    }
  }

  /// Remove unnecessary landmarks to reduce file size
  /// Keeps only essential points for sign language recognition
  Map<String, dynamic> _removeUnnecessaryLandmarks(Map<String, dynamic> data) {
    try {
      // Key face landmark indices to keep (eyes, nose, mouth outline, eyebrows)
      // Full face mesh has 468 points, we only keep ~30 key points
      const keyFaceIndices = {
        // Eyes
        33, 133, 157, 158, 159, 160, 161, 246,  // Left eye
        263, 362, 384, 385, 386, 387, 388, 466, // Right eye
        // Eyebrows
        70, 63, 105, 66, 107,   // Left eyebrow
        300, 293, 334, 296, 336, // Right eyebrow
        // Nose
        1, 2, 4, 5, 6, 19, 94, 168,
        // Mouth
        0, 13, 14, 17, 37, 39, 40, 61, 78, 80, 81, 82, 84, 87, 88, 91, 95,
        146, 178, 181, 185, 191, 267, 269, 270, 291, 308, 310, 311, 312, 314, 317, 318, 321, 324, 375, 402, 405, 409, 415,
      };

      if (data['frames'] != null) {
        for (var frame in data['frames']) {
          // Filter face landmarks if present
          if (frame['face_landmarks'] != null && frame['face_landmarks'] is List) {
            final faceList = frame['face_landmarks'] as List;
            if (faceList.length > 50) {
              // Keep only key indices
              List filteredFace = [];
              for (int i = 0; i < faceList.length && i < 468; i++) {
                if (keyFaceIndices.contains(i)) {
                  filteredFace.add(faceList[i]);
                }
              }
              frame['face_landmarks'] = filteredFace;
            }
          }
          
          // Also reduce frame sampling if too many frames (keep every 2nd frame)
          // This is handled separately below
        }
        
        // If more than 300 frames, sample every 2nd frame
        if (data['frames'].length > 300) {
          List sampledFrames = [];
          for (int i = 0; i < data['frames'].length; i += 2) {
            sampledFrames.add(data['frames'][i]);
          }
          data['frames'] = sampledFrames;
          debugPrint("📉 Reduced frames: ${data['frames'].length * 2} → ${sampledFrames.length}");
        }
      }
      
      return data;
    } catch (e) {
      debugPrint("⚠️ Could not remove landmarks: $e");
      return data;
    }
  }

  /// OPTIMIZED: Get sign metadata only (for listing - no animation data)
  /// This is what makes the library fast!
  Future<List<Map<String, dynamic>>> getSignsMetadataPaginated({
    String? category,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('signs');
      
      if (category != null && category != "New Uploads") {
        query = query.where('category', isEqualTo: category);
      }
      
      query = query.orderBy('word').limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'word': data['word'] ?? '',
          'category': data['category'] ?? '',
          'uploadedAt': data['uploadedAt'],
          'snapshot': doc, // Keep reference for pagination
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching signs metadata: $e");
      return [];
    }
  }

  /// OPTIMIZED: Load animation data ONLY when user wants to play a sign
  Future<Map<String, dynamic>?> getSignAnimationData(String word) async {
    try {
      final docId = word.toLowerCase().trim().replaceAll(' ', '_');
      
      // First try the new optimized structure (sign_animations collection)
      final animDoc = await _firestore.collection('sign_animations').doc(docId).get();
      if (animDoc.exists && animDoc.data()?['data'] != null) {
        debugPrint("✅ Loaded animation from sign_animations: $docId");
        return animDoc.data()!['data'] as Map<String, dynamic>;
      }
      
      // Fallback to old structure (data embedded in signs collection)
      final signDoc = await _firestore.collection('signs').doc(docId).get();
      if (signDoc.exists && signDoc.data()?['data'] != null) {
        debugPrint("✅ Loaded animation from signs (legacy): $docId");
        return signDoc.data()!['data'] as Map<String, dynamic>;
      }
      
      debugPrint("⚠️ No animation data found for: $docId");
      return null;
    } catch (e) {
      debugPrint("❌ Error fetching sign animation: $e");
      return null;
    }
  }

  /// Load sign from local assets (fast, offline)
  Future<Map<String, dynamic>?> getLocalSignData(String word) async {
    try {
      final fileName = word.toLowerCase().trim().replaceAll(' ', '_');
      final jsonString = await rootBundle.loadString('assets/signs/$fileName.json');
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Not found locally - this is normal, not an error
      return null;
    }
  }

  /// Hybrid: Try local first, then cloud (best of both worlds)
  Future<Map<String, dynamic>?> getSignData(String word) async {
    // Try local first (instant, offline)
    final localData = await getLocalSignData(word);
    if (localData != null) {
      debugPrint("✅ Loaded sign from local assets: $word");
      return localData;
    }
    
    // Fall back to cloud
    return await getSignAnimationData(word);
  }

  /// Get sign metadata (for display in lists)
  Future<Map<String, dynamic>?> getSign(String word) async {
    try {
      final docId = word.toLowerCase().trim().replaceAll(' ', '_');
      final doc = await _firestore.collection('signs').doc(docId).get();
      
      if (doc.exists && doc.data() != null) {
        return doc.data(); 
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error fetching sign: $e");
      return null;
    }
  }

  /// LEGACY: Get list of all cloud signs - Stream (kept for compatibility)
  /// Note: This still downloads full documents. Use getSignsMetadataPaginated for better performance.
  Stream<QuerySnapshot> getAllSignsStream() {
    return _firestore.collection('signs').orderBy('uploadedAt', descending: true).snapshots();
  }

  /// LEGACY: Get signs filtered by Category - Stream
  Stream<QuerySnapshot> getSignsByCategory(String category) {
    return _firestore
        .collection('signs')
        .where('category', isEqualTo: category)
        .orderBy('word')
        .snapshots();
  }

  /// Search signs by word - Stream
  Stream<QuerySnapshot> searchSigns(String query) {
    final searchKey = query.toLowerCase();
    return _firestore
        .collection('signs')
        .where('searchKey', isGreaterThanOrEqualTo: searchKey)
        .where('searchKey', isLessThan: '${searchKey}z')
        .snapshots();
  }

  /// Update a sign's category (Move functionality)
  Future<void> updateSignCategory(String word, String newCategory) async {
    try {
      final docId = word.toLowerCase().trim().replaceAll(' ', '_');
      await _firestore.collection('signs').doc(docId).update({
        'category': newCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Moved '$word' to '$newCategory'");
    } catch (e) {
      debugPrint("❌ Error moving sign: $e");
      rethrow;
    }
  }

  /// Bulk move multiple signs to a category
  Future<void> moveMultipleSigns(List<String> words, String newCategory) async {
    try {
      final batch = _firestore.batch();

      for (var word in words) {
        final docId = word.toLowerCase().trim().replaceAll(' ', '_');
        final docRef = _firestore.collection('signs').doc(docId);
        
        batch.update(docRef, {
          'category': newCategory,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint("✅ Bulk moved ${words.length} signs to '$newCategory'");
    } catch (e) {
      debugPrint("❌ Error bulk moving: $e");
      rethrow;
    }
  }

  /// Delete a sign from Cloud (both metadata and animation)
  Future<void> deleteSign(String word) async {
    try {
      final docId = word.toLowerCase().trim().replaceAll(' ', '_');
      
      // Delete from both collections
      await _firestore.collection('signs').doc(docId).delete();
      await _firestore.collection('sign_animations').doc(docId).delete();
      
      debugPrint("✅ Sign deleted: $docId");
    } catch (e) {
      debugPrint("❌ Error deleting sign: $e");
      rethrow;
    }
  }

  // ==================== MIGRATION HELPER ====================

  /// ONE-TIME MIGRATION: Move animation data from 'signs' to 'sign_animations'
  /// Run this once from admin screen to optimize existing data
  /// Uses BATCHED processing to avoid timeout on large datasets
  Future<Map<String, int>> migrateSignsToSeparateDataBatched({
    Function(int current, int total, String status)? onProgress,
  }) async {
    int migrated = 0;
    int skipped = 0;
    int failed = 0;
    int processed = 0;

    try {
      // First, get just the document count (lightweight query)
      onProgress?.call(0, 0, "Counting signs...");
      debugPrint("🔄 Counting signs to migrate...");
      
      final countSnapshot = await _firestore.collection('signs').count().get();
      final total = countSnapshot.count ?? 0;
      
      debugPrint("🔄 Found $total signs to process");
      onProgress?.call(0, total, "Found $total signs");

      if (total == 0) {
        return {'migrated': 0, 'skipped': 0, 'failed': 0};
      }

      // Process in batches of 20
      const batchSize = 20;
      DocumentSnapshot? lastDoc;
      bool hasMore = true;

      while (hasMore && processed < total) {
        onProgress?.call(processed, total, "Fetching batch...");
        
        // Fetch a small batch
        Query query = _firestore
            .collection('signs')
            .orderBy(FieldPath.documentId)
            .limit(batchSize);
            
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final batch = await query.get();
        
        if (batch.docs.isEmpty) {
          debugPrint("⚠️ No more documents to process");
          hasMore = false;
          break;
        }

        lastDoc = batch.docs.last;

        // Process each document in this batch
        for (var doc in batch.docs) {
          processed++;
          final data = doc.data() as Map<String, dynamic>;
          final animationData = data['data'];
          final word = data['word'] ?? doc.id;

          onProgress?.call(processed, total, "Processing: $word");

          if (animationData != null) {
            try {
              // 1. Save animation data to separate collection
              await _firestore.collection('sign_animations').doc(doc.id).set({
                'word': data['word'],
                'data': animationData,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              // 2. Remove 'data' field from main signs collection
              await _firestore.collection('signs').doc(doc.id).update({
                'data': FieldValue.delete(),
              });

              migrated++;
              debugPrint("✅ Migrated ($processed/$total): $word");
            } catch (e) {
              failed++;
              debugPrint("❌ Failed to migrate $word: $e");
            }
          } else {
            skipped++;
            debugPrint("⏭️ Skipped ($processed/$total): $word (already optimized)");
          }
        }

        // Check if this was the last batch
        if (batch.docs.length < batchSize) {
          hasMore = false;
        }

        // Small delay between batches to prevent rate limiting
        await Future.delayed(const Duration(milliseconds: 200));
      }

      onProgress?.call(total, total, "Complete!");
      debugPrint("✅ Migration complete! Migrated: $migrated, Skipped: $skipped, Failed: $failed");
    } catch (e) {
      debugPrint("❌ Migration error: $e");
      onProgress?.call(processed, processed, "Error: $e");
      rethrow;
    }

    return {
      'migrated': migrated,
      'skipped': skipped,
      'failed': failed,
    };
  }

  // ==================== NOTIFICATION METHODS ====================

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? icon,
    String? actionRoute,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'icon': icon,
        'actionRoute': actionRoute,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Notification created: $title');
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
    }
  }

  Future<void> notifyBadgeUnlocked(String userId, String badgeName, String badgeIcon) async {
    await createNotification(
      userId: userId,
      type: 'achievement',
      title: 'Badge Unlocked! 🎉',
      message: 'You earned the "$badgeName" badge!',
      icon: badgeIcon,
      actionRoute: '/badges',
    );
  }

  Future<void> notifyLevelUp(String userId, int newLevel) async {
    await createNotification(
      userId: userId,
      type: 'levelUp',
      title: 'Level Up! ⭐',
      message: 'Congratulations! You reached Level $newLevel!',
      icon: '🎊',
      actionRoute: '/progress',
    );
  }

  Future<void> notifyStreakMilestone(String userId, int streakDays) async {
    await createNotification(
      userId: userId,
      type: 'streak',
      title: '$streakDays Day Streak! 🔥',
      message: 'Amazing! Keep up the great work!',
      icon: '🔥',
    );
  }

  Future<void> notifyChallengeCompleted(String userId, String challengeName, int xpEarned) async {
    await createNotification(
      userId: userId,
      type: 'challenge',
      title: 'Challenge Completed! 🎯',
      message: '$challengeName - You earned $xpEarned XP!',
      icon: '✅',
      actionRoute: '/challenges',
    );
  }

  Future<void> notifyPerfectQuiz(String userId, String quizName) async {
    await createNotification(
      userId: userId,
      type: 'achievement',
      title: 'Perfect Score! 💯',
      message: 'You aced the "$quizName" quiz!',
      icon: '🌟',
    );
  }

  Future<void> notifyXpMilestone(String userId, int totalXp) async {
    await createNotification(
      userId: userId,
      type: 'milestone',
      title: 'XP Milestone! ⭐',
      message: 'You\'ve earned $totalXp total XP! Keep going!',
      icon: '⭐',
      actionRoute: '/progress',
    );
  }

  Future<void> notifySignsLearned(String userId, int signCount) async {
    await createNotification(
      userId: userId,
      type: 'milestone',
      title: 'Learning Milestone! 📚',
      message: 'You\'ve learned $signCount signs! Great progress!',
      icon: '🤟',
      actionRoute: '/learn',
    );
  }

  Future<void> notifyCategoryCompleted(String userId, String categoryName) async {
    await createNotification(
      userId: userId,
      type: 'achievement',
      title: 'Category Complete! 🎓',
      message: 'You finished all lessons in $categoryName!',
      icon: '🏅',
      actionRoute: '/learn',
    );
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
}