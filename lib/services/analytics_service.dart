import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralised wrapper around FirebaseAnalytics.
/// Call the static methods from anywhere in the app.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// NavigatorObserver to wire into MaterialApp for automatic screen tracking.
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── AUTH ─────────────────────────────────────────────────────────────────

  static Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  static Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics logSignUp error: $e');
    }
  }

  static Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics setUserId error: $e');
    }
  }

  // ── LEARNING ──────────────────────────────────────────────────────────────

  static Future<void> logLessonStarted({
    required String lessonId,
    required String lessonName,
    required String categoryId,
    required String categoryName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'lesson_started',
        parameters: {
          'lesson_id': lessonId,
          'lesson_name': lessonName,
          'category_id': categoryId,
          'category_name': categoryName,
        },
      );
    } catch (e) {
      debugPrint('Analytics logLessonStarted error: $e');
    }
  }

  static Future<void> logLessonCompleted({
    required String lessonId,
    required String lessonName,
    required String categoryId,
    required String categoryName,
    required int xpEarned,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'lesson_completed',
        parameters: {
          'lesson_id': lessonId,
          'lesson_name': lessonName,
          'category_id': categoryId,
          'category_name': categoryName,
          'xp_earned': xpEarned,
        },
      );
    } catch (e) {
      debugPrint('Analytics logLessonCompleted error: $e');
    }
  }

  // ── QUIZ ──────────────────────────────────────────────────────────────────

  static Future<void> logQuizStarted({required String quizType}) async {
    try {
      await _analytics.logEvent(
        name: 'quiz_started',
        parameters: {'quiz_type': quizType},
      );
    } catch (e) {
      debugPrint('Analytics logQuizStarted error: $e');
    }
  }

  static Future<void> logQuizCompleted({
    required String quizType,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required int xpEarned,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'quiz_completed',
        parameters: {
          'quiz_type': quizType,
          'score': score,
          'correct_answers': correctAnswers,
          'total_questions': totalQuestions,
          'xp_earned': xpEarned,
        },
      );
    } catch (e) {
      debugPrint('Analytics logQuizCompleted error: $e');
    }
  }

  // ── CHALLENGES ────────────────────────────────────────────────────────────

  static Future<void> logChallengeCompleted({
    required String challengeId,
    required String challengeTitle,
    required String challengeType,
    required int xpReward,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'challenge_completed',
        parameters: {
          'challenge_id': challengeId,
          'challenge_title': challengeTitle,
          'challenge_type': challengeType,
          'xp_reward': xpReward,
        },
      );
    } catch (e) {
      debugPrint('Analytics logChallengeCompleted error: $e');
    }
  }

  // ── BADGES ────────────────────────────────────────────────────────────────

  static Future<void> logBadgeEarned({
    required String badgeId,
    required String badgeName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'badge_earned',
        parameters: {
          'badge_id': badgeId,
          'badge_name': badgeName,
        },
      );
    } catch (e) {
      debugPrint('Analytics logBadgeEarned error: $e');
    }
  }

  // ── STREAK ───────────────────────────────────────────────────────────────

  static Future<void> logStreakMilestone({required int streakDays}) async {
    try {
      await _analytics.logEvent(
        name: 'streak_milestone',
        parameters: {'streak_days': streakDays},
      );
    } catch (e) {
      debugPrint('Analytics logStreakMilestone error: $e');
    }
  }

  // ── LEVEL UP ──────────────────────────────────────────────────────────────

  static Future<void> logLevelUp({
    required int newLevel,
    required int totalXP,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'level_up',
        parameters: {
          'new_level': newLevel,
          'total_xp': totalXP,
        },
      );
    } catch (e) {
      debugPrint('Analytics logLevelUp error: $e');
    }
  }

  // ── SOCIAL ───────────────────────────────────────────────────────────────

  static Future<void> logFriendAdded() async {
    try {
      await _analytics.logEvent(name: 'friend_added');
    } catch (e) {
      debugPrint('Analytics logFriendAdded error: $e');
    }
  }

  static Future<void> logChallengeIssuedToFriend({
    required String quizType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'friend_challenge_sent',
        parameters: {'quiz_type': quizType},
      );
    } catch (e) {
      debugPrint('Analytics logChallengeIssuedToFriend error: $e');
    }
  }

  // ── CATEGORY ─────────────────────────────────────────────────────────────

  static Future<void> logCategoryCompleted({
    required String categoryId,
    required String categoryName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'category_completed',
        parameters: {
          'category_id': categoryId,
          'category_name': categoryName,
        },
      );
    } catch (e) {
      debugPrint('Analytics logCategoryCompleted error: $e');
    }
  }

  // ── USER PROPERTIES ───────────────────────────────────────────────────────

  static Future<void> setUserProperties({
    required int level,
    required int streak,
    required String userType,
  }) async {
    try {
      await _analytics.setUserProperty(name: 'user_level', value: '$level');
      await _analytics.setUserProperty(name: 'current_streak', value: '$streak');
      await _analytics.setUserProperty(name: 'user_type', value: userType);
    } catch (e) {
      debugPrint('Analytics setUserProperties error: $e');
    }
  }

  // ── SCREEN ────────────────────────────────────────────────────────────────

  static Future<void> logScreenView({required String screenName}) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Analytics logScreenView error: $e');
    }
  }
}
