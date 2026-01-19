import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
      print('Error getting user: $e');
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
      print('Error creating user: $e');
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
      print('Error updating user: $e');
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
      print('Error getting all users: $e');
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

  // ==================== CATEGORY METHODS ====================

  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .orderBy('order')
          .get();
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    try {
      await _firestore.collection(AppConstants.categoriesCollection).add(data);
    } catch (e) {
      print('Error adding category: $e');
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
      print('Error updating category: $e');
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
      print('Error deleting category: $e');
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
      print('Error getting all lessons: $e');
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
      print('Error adding lesson: $e');
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
      print('Error updating lesson: $e');
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
      print('Error deleting lesson: $e');
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
      print('Error updating category lesson count: $e');
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
      print('Error getting quizzes: $e');
      return [];
    }
  }

  Future<void> addQuiz(Map<String, dynamic> data) async {
    try {
      await _firestore.collection(AppConstants.quizzesCollection).add(data);
    } catch (e) {
      print('Error adding quiz: $e');
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
      print('Error updating quiz: $e');
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
      print('Error deleting quiz: $e');
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
      print('Error getting user progress: $e');
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
      print('Error updating lesson progress: $e');
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
      print('Error getting achievements: $e');
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
      print('Error getting user achievements: $e');
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
      print('Error adding user XP: $e');
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

      print('Initial data seeded successfully');
    } catch (e) {
      print('Error seeding data: $e');
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
        print('No quiz attempts to delete or collection does not exist');
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
        print('No user achievements to delete or collection does not exist');
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
        print('No notifications to delete or collection does not exist');
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
        print('Deleted ${challengeProgress.docs.length} challenge progress documents');
      } catch (e) {
        print('No challenge progress to delete or collection does not exist: $e');
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
        print('No user_challenges to delete or collection does not exist');
      }

      print('User progress reset successfully for user: $userId');
    } catch (e) {
      print('Error resetting user progress: $e');
      rethrow;
    }
  }

  // ==================== SIGN LIBRARY METHODS ====================

  /// Upload a sign animation JSON to Firestore
  Future<void> uploadSign(String word, Map<String, dynamic> jsonData) async {
    try {
      // Clean the word to be a valid ID (lowercase, no spaces)
      final docId = word.toLowerCase().trim().replaceAll(' ', '_');
      
      await _firestore.collection('signs').doc(docId).set({
        'word': word,
        'data': jsonData, // Stores the animation frames
        'uploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Sign uploaded successfully: $docId");
    } catch (e) {
      debugPrint("❌ Error uploading sign: $e");
      rethrow;
    }
  }

  /// Fetch a specific sign animation
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

  /// Get list of all cloud signs (for Admin)
  Stream<QuerySnapshot> getAllSignsStream() {
    return _firestore.collection('signs').orderBy('word').snapshots();
  }

  /// Delete a sign from Cloud
  Future<void> deleteSign(String word) async {
    try {
      final docId = word.toLowerCase().trim().replaceAll(' ', '_');
      await _firestore.collection('signs').doc(docId).delete();
      debugPrint("✅ Sign deleted: $docId");
    } catch (e) {
      debugPrint("❌ Error deleting sign: $e");
      rethrow;
    }
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