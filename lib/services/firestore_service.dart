import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../config/constants.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../models/achievement_model.dart';
import '../models/progress_model.dart';
// import '../models/daily_goal_model.dart'; // Ensure this import exists based on your code usage

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== STREAK FREEZE CONSTANTS ====================
  static const int maxFreezes = 2;
  static const int streakDaysToEarnFreeze = 7;
  static const int xpCostToBuyFreeze = 500;

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

  // ==================== STREAK FREEZE METHODS (NEW) ====================

  /// Award a streak freeze to user (earned through streaks)
  Future<bool> awardStreakFreeze(String userId) async {
    try {
      final userRef = _firestore.collection(AppConstants.usersCollection).doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final currentFreezes = userData['streakFreezes'] ?? 0;

      // Check if user can earn more freezes
      if (currentFreezes >= maxFreezes) {
        debugPrint('⚠️ User already has max freezes ($maxFreezes)');
        return false;
      }

      await userRef.update({
        'streakFreezes': currentFreezes + 1,
        'totalFreezesEarned': FieldValue.increment(1),
        'lastFreezeEarned': FieldValue.serverTimestamp(),
      });

      // Notify user
      await createNotification(
        userId: userId,
        type: 'streak_freeze_earned',
        title: 'Streak Freeze Earned! 🧊',
        message: 'You earned a freeze for your streak!',
        icon: '🧊',
      );

      debugPrint('🧊 Streak freeze awarded! User now has ${currentFreezes + 1} freezes');
      return true;
    } catch (e) {
      debugPrint('❌ Error awarding streak freeze: $e');
      return false;
    }
  }

  /// Use a streak freeze (called when user misses a day)
  Future<bool> useStreakFreeze(String userId) async {
    try {
      final userRef = _firestore.collection(AppConstants.usersCollection).doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final currentFreezes = userData['streakFreezes'] ?? 0;
      final autoUse = userData['autoUseFreeze'] ?? true;

      // Check if user has freezes and auto-use is enabled
      if (currentFreezes <= 0) {
        debugPrint('⚠️ User has no streak freezes');
        return false;
      }

      if (!autoUse) {
        debugPrint('⚠️ Auto-use freeze is disabled');
        return false;
      }

      await userRef.update({
        'streakFreezes': currentFreezes - 1,
        'lastFreezeUsed': FieldValue.serverTimestamp(),
      });

      // Create notification
      await createNotification(
        userId: userId,
        type: 'streak_freeze_used',
        title: 'Streak Protected! 🧊',
        message: 'A streak freeze was used to save your streak.',
        icon: '🛡️',
      );

      debugPrint('🧊 Streak freeze used! Streak protected. ${currentFreezes - 1} freezes remaining');
      return true;
    } catch (e) {
      debugPrint('❌ Error using streak freeze: $e');
      return false;
    }
  }

  /// Buy a streak freeze with XP
  Future<Map<String, dynamic>> buyStreakFreeze(String userId) async {
    try {
      final userRef = _firestore.collection(AppConstants.usersCollection).doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        return {'success': false, 'error': 'User not found'};
      }

      final userData = userDoc.data()!;
      final currentFreezes = userData['streakFreezes'] ?? 0;
      final currentXP = userData['totalXP'] ?? 0;

      // Check if user can buy more freezes
      if (currentFreezes >= maxFreezes) {
        return {'success': false, 'error': 'Maximum freezes reached ($maxFreezes)'};
      }

      // Check if user has enough XP
      if (currentXP < xpCostToBuyFreeze) {
        return {'success': false, 'error': 'Not enough XP. Need $xpCostToBuyFreeze XP.'};
      }

      await userRef.update({
        'streakFreezes': currentFreezes + 1,
        'totalXP': currentXP - xpCostToBuyFreeze,
        'totalFreezesEarned': FieldValue.increment(1),
        'lastFreezeEarned': FieldValue.serverTimestamp(),
      });

      debugPrint('🧊 Streak freeze purchased for $xpCostToBuyFreeze XP!');
      return {
        'success': true,
        'newFreezeCount': currentFreezes + 1,
        'newXP': currentXP - xpCostToBuyFreeze,
      };
    } catch (e) {
      debugPrint('❌ Error buying streak freeze: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Toggle auto-use freeze setting
  Future<void> setAutoUseFreeze(String userId, bool enabled) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'autoUseFreeze': enabled,
      });
      debugPrint('🧊 Auto-use freeze set to: $enabled');
    } catch (e) {
      debugPrint('❌ Error setting auto-use freeze: $e');
    }
  }

  /// Check and potentially award freeze for streak milestone
  Future<bool> checkAndAwardStreakFreeze(String userId, int currentStreak) async {
    if (currentStreak > 0 && currentStreak % streakDaysToEarnFreeze == 0) {
      return await awardStreakFreeze(userId);
    }
    return false;
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
      
      // Record daily XP
      if (xpEarned > 0) {
        await recordDailyXP(userId, xpEarned);
      }

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
        
        if (lessonId != null && isCompleted) {
          completedIds.add(lessonId);
        }
      }

      debugPrint('✅ Total completed lessons: ${completedIds.length}');
      
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
        
        await recordDailyXP(userId, xpAmount);
      }
    } catch (e) {
      debugPrint('Error adding user XP: $e');
      rethrow;
    }
  }

  Future<void> recordDailyXP(String userId, int xpEarned) async {
    final today = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(today);
    
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('daily_xp')
        .doc(dateKey);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      
      if (doc.exists) {
        final currentXP = doc.data()?['xpEarned'] ?? 0;
        transaction.update(docRef, {
          'xpEarned': currentXP + xpEarned,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'date': Timestamp.fromDate(DateTime(today.year, today.month, today.day)),
          'xpEarned': xpEarned,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
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

  // UPDATED: Check and Reset Daily Goal with Streak Freeze Logic
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
          // Check if we can use a streak freeze
          bool freezeUsed = await useStreakFreeze(userId);
          
          if (freezeUsed) {
            debugPrint('🧊 Streak protected by freeze!');
            // Streak preserved, do not reset to 0
          } else {
            final currentStreak = userData['currentStreak'] ?? 0;
            if (currentStreak > 0) {
              updates['currentStreak'] = 0;
              debugPrint('⚠️ Streak reset - user missed a day (last: $lastDate, yesterday: $yesterday)');
            }
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

  // UPDATED: Complete Lesson with Freeze Awarding Logic
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

              // CHECK FOR FREEZE AWARD (Every 7 days)
              if (newStreak > 0 && newStreak % streakDaysToEarnFreeze == 0) {
                 await awardStreakFreeze(userId);
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

      // Record daily XP
      if (isNewLesson && xpReward > 0) {
        await recordDailyXP(userId, xpReward);
      }

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
        // Also reset streak freeze data
        'streakFreezes': 0,
        'totalFreezesEarned': 0,
        'lastFreezeUsed': null,
        'lastFreezeEarned': null,
      });

      final progressDocs = await _firestore
          .collection(AppConstants.progressCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in progressDocs.docs) {
        await doc.reference.delete();
      }

      // Also reset daily XP
      try {
        final dailyXpDocs = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection('daily_xp')
            .get();
        for (var doc in dailyXpDocs.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('No daily XP to delete or collection does not exist');
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

  Stream<QuerySnapshot> getSignLibraryCategoriesStream() {
    return _firestore
        .collection('sign_library_categories')
        .orderBy('name')
        .snapshots();
  }

  Future<void> addSignLibraryCategory(String name) async {
    final docId = name.trim().toLowerCase().replaceAll(' ', '_');
    await _firestore.collection('sign_library_categories').doc(docId).set({
      'name': name.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSignLibraryCategory(String docId) async {
    await _firestore.collection('sign_library_categories').doc(docId).delete();
  }

  Future<void> uploadSign(String word, String category, Map<String, dynamic> jsonData) async {
    try {
      final docId = word.toLowerCase().trim().replaceAll(' ', '_');
      final searchKey = word.toLowerCase();

      final compressedData = _compressAnimationData(jsonData);

      final batch = _firestore.batch();

      final signRef = _firestore.collection('signs').doc(docId);
      batch.set(signRef, {
        'word': word,
        'searchKey': searchKey,
        'category': category,
        'uploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final animRef = _firestore.collection('sign_animations').doc(docId);
      batch.set(animRef, {
        'word': word,
        'data': compressedData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      debugPrint("✅ Sign uploaded (optimized): $docId (Category: $category)");
    } catch (e) {
      debugPrint("❌ Error uploading sign: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadSignsBulk(
    List<Map<String, dynamic>> signs,
    String category, {
    Function(int current, int total)? onProgress,
  }) async {
    int success = 0;
    int failed = 0;
    List<String> failedWords = [];

    try {
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

            final signRef = _firestore.collection('signs').doc(docId);
            batch.set(signRef, {
              'word': word,
              'searchKey': searchKey,
              'category': category,
              'uploadedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

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

        await batch.commit();
        success += chunkSuccess;
        
        onProgress?.call(i + chunk.length, signs.length);
        debugPrint("✅ Uploaded batch ${(i ~/ batchSize) + 1}: ${i + chunk.length}/${signs.length}");
        
        if (i + batchSize < signs.length) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    } catch (e) {
      debugPrint("❌ Bulk upload error: $e");
      rethrow;
    }

    return {
      'success': success,
      'failed': failed,
      'failedWords': failedWords,
    };
  }

  Map<String, dynamic> _compressAnimationData(Map<String, dynamic> data) {
    try {
      String jsonStr = json.encode(data);
      final originalSize = jsonStr.length;
      
      jsonStr = jsonStr.replaceAllMapped(
        RegExp(r'(\d+\.\d{3})\d+'),
        (match) => match.group(1)!,
      );
      
      if (jsonStr.length > 800000) {
        jsonStr = json.encode(data);
        jsonStr = jsonStr.replaceAllMapped(
          RegExp(r'(\d+\.\d{2})\d+'),
          (match) => match.group(1)!,
        );
        debugPrint("⚠️ Large file - using 2 decimal compression");
      }
      
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

  Map<String, dynamic> _removeUnnecessaryLandmarks(Map<String, dynamic> data) {
    try {
      const keyFaceIndices = {
        33, 133, 157, 158, 159, 160, 161, 246,
        263, 362, 384, 385, 386, 387, 388, 466,
        70, 63, 105, 66, 107,
        300, 293, 334, 296, 336,
        1, 2, 4, 5, 6, 19, 94, 168,
        0, 13, 14, 17, 37, 39, 40, 61, 78, 80, 81, 82, 84, 87, 88, 91, 95,
        146, 178, 181, 185, 191, 267, 269, 270, 291, 308, 310, 311, 312, 314, 317, 318, 321, 324, 375, 402, 405, 409, 415,
      };

      if (data['frames'] != null) {
        for (var frame in data['frames']) {
          if (frame['face_landmarks'] != null && frame['face_landmarks'] is List) {
            final faceList = frame['face_landmarks'] as List;
            if (faceList.length > 50) {
              List filteredFace = [];
              for (int i = 0; i < faceList.length && i < 468; i++) {
                if (keyFaceIndices.contains(i)) {
                  filteredFace.add(faceList[i]);
                }
              }
              frame['face_landmarks'] = filteredFace;
            }
          }
        }
        
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
          'snapshot': doc,
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error fetching signs metadata: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSignAnimationData(String word) async {
    try {
      final docId = word.toLowerCase().trim().replaceAll(' ', '_');
      
      final animDoc = await _firestore.collection('sign_animations').doc(docId).get();
      if (animDoc.exists && animDoc.data()?['data'] != null) {
        debugPrint("✅ Loaded animation from sign_animations: $docId");
        return animDoc.data()!['data'] as Map<String, dynamic>;
      }
      
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

  Future<Map<String, dynamic>?> getLocalSignData(String word) async {
    try {
      final fileName = word.toLowerCase().trim().replaceAll(' ', '_');
      final jsonString = await rootBundle.loadString('assets/signs/$fileName.json');
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSignData(String word) async {
    final localData = await getLocalSignData(word);
    if (localData != null) {
      debugPrint("✅ Loaded sign from local assets: $word");
      return localData;
    }
    return await getSignAnimationData(word);
  }

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

  Stream<QuerySnapshot> getAllSignsStream() {
    return _firestore.collection('signs').orderBy('uploadedAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getSignsByCategory(String category) {
    return _firestore
        .collection('signs')
        .where('category', isEqualTo: category)
        .orderBy('word')
        .snapshots();
  }

  Stream<QuerySnapshot> searchSigns(String query) {
    final searchKey = query.toLowerCase();
    return _firestore
        .collection('signs')
        .where('searchKey', isGreaterThanOrEqualTo: searchKey)
        .where('searchKey', isLessThan: '${searchKey}z')
        .snapshots();
  }

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

  Future<void> deleteSign(String word) async {
    try {
      final docId = word.toLowerCase().trim().replaceAll(' ', '_');
      
      await _firestore.collection('signs').doc(docId).delete();
      await _firestore.collection('sign_animations').doc(docId).delete();
      
      debugPrint("✅ Sign deleted: $docId");
    } catch (e) {
      debugPrint("❌ Error deleting sign: $e");
      rethrow;
    }
  }

  // ==================== MIGRATION HELPER ====================

  Future<Map<String, int>> migrateSignsToSeparateDataBatched({
    Function(int current, int total, String status)? onProgress,
  }) async {
    int migrated = 0;
    int skipped = 0;
    int failed = 0;
    int processed = 0;

    try {
      onProgress?.call(0, 0, "Counting signs...");
      debugPrint("🔄 Counting signs to migrate...");
      
      final countSnapshot = await _firestore.collection('signs').count().get();
      final total = countSnapshot.count ?? 0;
      
      debugPrint("🔄 Found $total signs to process");
      onProgress?.call(0, total, "Found $total signs");

      if (total == 0) {
        return {'migrated': 0, 'skipped': 0, 'failed': 0};
      }

      const batchSize = 20;
      DocumentSnapshot? lastDoc;
      bool hasMore = true;

      while (hasMore && processed < total) {
        onProgress?.call(processed, total, "Fetching batch...");
        
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

        for (var doc in batch.docs) {
          processed++;
          final data = doc.data() as Map<String, dynamic>;
          final animationData = data['data'];
          final word = data['word'] ?? doc.id;

          onProgress?.call(processed, total, "Processing: $word");

          if (animationData != null) {
            try {
              await _firestore.collection('sign_animations').doc(doc.id).set({
                'word': data['word'],
                'data': animationData,
                'updatedAt': FieldValue.serverTimestamp(),
              });

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

        if (batch.docs.length < batchSize) {
          hasMore = false;
        }

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
  /// Get a single lesson by ID
  Future<LessonModel?> getLesson(String lessonId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('lessons').doc(lessonId).get();
      if (doc.exists) {
        return LessonModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting lesson: $e');
      return null;
    }
  }
}