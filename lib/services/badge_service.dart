import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/badge_model.dart';
import '../models/user_model.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Get user's unlocked badges
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>?;
      final badgeIds = List<String>.from(data?['unlockedBadges'] ?? []);

      return badgeIds
          .map((id) => BadgeModel.getBadgeById(id))
          .where((badge) => badge != null)
          .cast<BadgeModel>()
          .map((badge) => badge.copyWith(unlockedAt: DateTime.now()))
          .toList();
    } catch (e) {
      debugPrint('Error getting user badges: $e');
      return [];
    }
  }

  // Check and unlock badges based on user stats
  Future<List<BadgeModel>> checkAndUnlockBadges({
    required String userId,
    required UserModel user,
    int? quizzesCompleted,
    int? perfectQuizzes,
    bool? completedLessonToday,
    bool? completedCategoryToday,
    int? lessonsCompletedToday,
  }) async {
    List<BadgeModel> newlyUnlocked = [];

    try {
      final doc = await _usersCollection.doc(userId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final currentBadges = List<String>.from(data?['unlockedBadges'] ?? []);

      // Check each badge type
      for (final badge in BadgeModel.allBadges) {
        if (currentBadges.contains(badge.id)) continue;

        bool shouldUnlock = false;

        switch (badge.id) {
          // Learning badges
          case 'first_sign':
            shouldUnlock = user.signsLearned >= 1;
            break;
          case 'sign_beginner':
            shouldUnlock = user.signsLearned >= 10;
            break;
          case 'sign_learner':
            shouldUnlock = user.signsLearned >= 25;
            break;
          case 'sign_expert':
            shouldUnlock = user.signsLearned >= 50;
            break;
          case 'sign_master':
            shouldUnlock = user.signsLearned >= 100;
            break;

          // Streak badges
          case 'streak_starter':
            shouldUnlock = user.currentStreak >= 3;
            break;
          case 'week_warrior':
            shouldUnlock = user.currentStreak >= 7;
            break;
          case 'fortnight_fighter':
            shouldUnlock = user.currentStreak >= 14;
            break;
          case 'monthly_master':
            shouldUnlock = user.currentStreak >= 30;
            break;

          // Quiz badges
          case 'first_quiz':
            shouldUnlock = (quizzesCompleted ?? user.quizzesCompleted) >= 1;
            break;
          case 'quiz_enthusiast':
            shouldUnlock = (quizzesCompleted ?? user.quizzesCompleted) >= 10;
            break;
          case 'perfect_score':
            shouldUnlock = (perfectQuizzes ?? 0) >= 1;
            break;
          case 'quiz_master':
            shouldUnlock = (quizzesCompleted ?? user.quizzesCompleted) >= 50;
            break;

          // XP milestones
          case 'xp_collector':
            shouldUnlock = user.totalXP >= 100;
            break;
          case 'xp_hunter':
            shouldUnlock = user.totalXP >= 500;
            break;
          case 'xp_champion':
            shouldUnlock = user.totalXP >= 1000;
            break;
          case 'xp_legend':
            shouldUnlock = user.totalXP >= 5000;
            break;

          // Special badges
          case 'early_bird':
            final hour = DateTime.now().hour;
            shouldUnlock = (completedLessonToday ?? false) && hour < 8;
            break;
          case 'night_owl':
            final nightHour = DateTime.now().hour;
            shouldUnlock = (completedLessonToday ?? false) && nightHour >= 22;
            break;
          case 'weekend_learner':
            final weekday = DateTime.now().weekday;
            shouldUnlock = (completedLessonToday ?? false) && (weekday == 6 || weekday == 7);
            break;
          case 'category_complete':
            shouldUnlock = completedCategoryToday ?? false;
            break;
          case 'speed_learner':
            shouldUnlock = (lessonsCompletedToday ?? 0) >= 5;
            break;
        }

        if (shouldUnlock) {
          currentBadges.add(badge.id);
          newlyUnlocked.add(badge.copyWith(unlockedAt: DateTime.now()));
        }
      }

      // Update Firestore if new badges unlocked
      if (newlyUnlocked.isNotEmpty) {
        await _usersCollection.doc(userId).update({
          'unlockedBadges': currentBadges,
          'totalXP': FieldValue.increment(
            newlyUnlocked.fold(0, (total, badge) => total + badge.xpReward),
          ),
        });
        debugPrint('✅ Unlocked ${newlyUnlocked.length} new badges!');

        // Create notifications for each badge unlocked
        for (final badge in newlyUnlocked) {
          await _firestore.collection('notifications').add({
            'userId': userId,
            'type': 'achievement',
            'title': 'Badge Unlocked! 🎉',
            'message': 'You earned the "${badge.name}" badge! +${badge.xpReward} XP',
            'icon': badge.icon,
            'actionRoute': '/badges',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return newlyUnlocked;
    } catch (e) {
      debugPrint('Error checking badges: $e');
      return [];
    }
  }

  // Mark badge as seen
  Future<void> markBadgeAsSeen(String userId, String badgeId) async {
    try {
      await _usersCollection.doc(userId).update({
        'seenBadges': FieldValue.arrayUnion([badgeId]),
      });
    } catch (e) {
      debugPrint('Error marking badge as seen: $e');
    }
  }

  // Get unseen badges
  Future<List<String>> getUnseenBadges(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      final data = doc.data() as Map<String, dynamic>?;
      
      final unlocked = List<String>.from(data?['unlockedBadges'] ?? []);
      final seen = List<String>.from(data?['seenBadges'] ?? []);
      
      return unlocked.where((id) => !seen.contains(id)).toList();
    } catch (e) {
      debugPrint('Error getting unseen badges: $e');
      return [];
    }
  }

  // Get badge statistics
  Future<Map<String, dynamic>> getBadgeStats(String userId) async {
    try {
      final badges = await getUserBadges(userId);
      final totalBadges = BadgeModel.allBadges.length;
      final unlockedCount = badges.length;

      // Count by tier
      int bronze = 0, silver = 0, gold = 0, platinum = 0;
      for (final badge in badges) {
        switch (badge.tier) {
          case BadgeTier.bronze:
            bronze++;
            break;
          case BadgeTier.silver:
            silver++;
            break;
          case BadgeTier.gold:
            gold++;
            break;
          case BadgeTier.platinum:
            platinum++;
            break;
        }
      }

      return {
        'total': totalBadges,
        'unlocked': unlockedCount,
        'percentage': (unlockedCount / totalBadges * 100).round(),
        'bronze': bronze,
        'silver': silver,
        'gold': gold,
        'platinum': platinum,
      };
    } catch (e) {
      debugPrint('Error getting badge stats: $e');
      return {
        'total': BadgeModel.allBadges.length,
        'unlocked': 0,
        'percentage': 0,
        'bronze': 0,
        'silver': 0,
        'gold': 0,
        'platinum': 0,
      };
    }
  }
}