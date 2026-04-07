import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/badge_model.dart';
import '../models/user_model.dart';

/// Dynamic Badge Service
/// 
/// This service checks badges dynamically based on `trackingField` from the badgePool,
/// instead of using hardcoded badge IDs. This means:
/// - Seeded badges will work automatically
/// - New badges added via admin will work immediately
/// - No code changes needed when adding new badges
class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _badgePoolCollection => _firestore.collection('badgePool');

  // ==================== GET USER BADGES ====================

  /// Get user's unlocked badges with full details from badgePool
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data() as Map<String, dynamic>?;
      final badgeIds = List<String>.from(data?['unlockedBadges'] ?? []);

      if (badgeIds.isEmpty) return [];

      // Try to get from badgePool first
      final poolSnapshot = await _badgePoolCollection.get();
      
      if (poolSnapshot.docs.isNotEmpty) {
        final poolBadges = <String, BadgeTemplate>{};
        for (final doc in poolSnapshot.docs) {
          final template = BadgeTemplate.fromFirestore(doc);
          poolBadges[template.id] = template;
        }

        return badgeIds
            .where((id) => poolBadges.containsKey(id))
            .map((id) => poolBadges[id]!.toBadge().copyWith(
                  unlockedAt: DateTime.now(),
                ))
            .toList();
      }

      // Fallback to static badges
      return badgeIds
          .map((id) => BadgeModel.getBadgeById(id))
          .where((badge) => badge != null)
          .cast<BadgeModel>()
          .map((badge) => badge.copyWith(unlockedAt: DateTime.now()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting user badges: $e');
      return [];
    }
  }

  // ==================== DYNAMIC BADGE CHECKING ====================

  /// Check and unlock badges DYNAMICALLY based on trackingField
  /// 
  /// This is the main method that should be called after any user action.
  /// It loads all active badges from badgePool and checks each one based on
  /// its trackingField against the user's current stats.
  Future<List<BadgeModel>> checkAndUnlockBadges({
    required String userId,
    required UserModel user,
    // Optional overrides for real-time values
    int? quizzesCompleted,
    int? perfectQuizzes,
    int? friendsCount,
    int? lessonsCompletedToday,
    int? signsLearnedToday,
    bool? completedLessonToday,
    bool? completedCategoryToday,
    String? completedCategoryId,
  }) async {
    List<BadgeModel> newlyUnlocked = [];

    try {
      // Get current unlocked badges
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final currentBadges = List<String>.from(userData?['unlockedBadges'] ?? []);

      // Load all active badges from pool
      List<BadgeTemplate> allBadges = await _loadActiveBadges();
      
      if (allBadges.isEmpty) {
        debugPrint('⚠️ No badges in pool, using defaults');
        allBadges = BadgeTemplate.defaultBadges;
      }

      // Build user stats map for dynamic checking
      final userStats = _buildUserStatsMap(
        user: user,
        quizzesCompleted: quizzesCompleted,
        perfectQuizzes: perfectQuizzes,
        friendsCount: friendsCount,
        lessonsCompletedToday: lessonsCompletedToday,
        signsLearnedToday: signsLearnedToday,
      );

      // Check each badge
      for (final template in allBadges) {
        if (currentBadges.contains(template.id)) continue;
        if (!template.isActive) continue;

        bool shouldUnlock = _checkBadgeRequirement(
          template: template,
          userStats: userStats,
          completedLessonToday: completedLessonToday ?? false,
          completedCategoryToday: completedCategoryToday ?? false,
          completedCategoryId: completedCategoryId,
        );

        if (shouldUnlock) {
          currentBadges.add(template.id);
          newlyUnlocked.add(template.toBadge().copyWith(
                unlockedAt: DateTime.now(),
              ));
          debugPrint('🏅 Badge unlocked: ${template.name} (${template.id})');
        }
      }

      // Update Firestore if new badges unlocked
      if (newlyUnlocked.isNotEmpty) {
        final totalXpReward = newlyUnlocked.fold(0, (total, badge) => total + badge.xpReward);
        
        await _usersCollection.doc(userId).update({
          'unlockedBadges': currentBadges,
          'totalXP': FieldValue.increment(totalXpReward),
        });

        debugPrint('✅ Unlocked ${newlyUnlocked.length} badges! (+$totalXpReward XP)');

        // Create notifications
        for (final badge in newlyUnlocked) {
          await _createBadgeNotification(userId, badge);
        }
      }

      return newlyUnlocked;
    } catch (e) {
      debugPrint('❌ Error checking badges: $e');
      return [];
    }
  }

  /// Load all active badges from Firestore badgePool
  Future<List<BadgeTemplate>> _loadActiveBadges() async {
    try {
      final snapshot = await _badgePoolCollection
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => BadgeTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Error loading badge pool: $e');
      // Fallback: try without the where clause (in case index doesn't exist)
      try {
        final snapshot = await _badgePoolCollection.get();
        return snapshot.docs
            .map((doc) => BadgeTemplate.fromFirestore(doc))
            .where((b) => b.isActive)
            .toList();
      } catch (e2) {
        debugPrint('⚠️ Fallback also failed: $e2');
        return [];
      }
    }
  }

  /// Build a map of user stats for dynamic checking
  Map<String, int> _buildUserStatsMap({
    required UserModel user,
    int? quizzesCompleted,
    int? perfectQuizzes,
    int? friendsCount,
    int? lessonsCompletedToday,
    int? signsLearnedToday,
  }) {
    return {
      // Learning stats
      'signsLearned': user.signsLearned,
      'lessonsCompleted': user.lessonsCompleted,
      'lessonsToday': lessonsCompletedToday ?? user.lessonsCompletedToday,
      'signsToday': signsLearnedToday ?? 0,
      
      // Quiz stats
      'quizzesCompleted': quizzesCompleted ?? user.quizzesCompleted,
      'perfectQuizzes': perfectQuizzes ?? user.perfectQuizzes,
      
      // Streak stats
      'currentStreak': user.currentStreak,
      'longestStreak': user.longestStreak,
      
      // XP & Level stats
      'totalXP': user.totalXP,
      'level': user.level,
      
      // Social stats
      'friendsCount': friendsCount ?? 0,
      
      // Time-based (these need special handling)
      'earlyBirdLessons': _checkEarlyBird() ? 1 : 0,
      'nightOwlLessons': _checkNightOwl() ? 1 : 0,
      'weekendWarrior': _checkWeekend() ? 1 : 0,
    };
  }

  /// Check if a badge requirement is met
  bool _checkBadgeRequirement({
    required BadgeTemplate template,
    required Map<String, int> userStats,
    required bool completedLessonToday,
    required bool completedCategoryToday,
    String? completedCategoryId,
  }) {
    final field = template.trackingField;
    final requirement = template.requirement;

    // Special handling for category-specific badges
    if (template.lessonCategoryId != null) {
      // This badge is for a specific category
      if (field == 'categoryCompleted') {
        return completedCategoryToday && 
               completedCategoryId == template.lessonCategoryId;
      }
      // Category-specific progress would need additional tracking
      return false;
    }

    // Special cases that need context
    switch (field) {
      case 'categoriesCompleted':
        // Would need to track completed categories separately
        return completedCategoryToday && requirement == 1;
      
      case 'earlyBirdLessons':
        return completedLessonToday && _checkEarlyBird();
      
      case 'nightOwlLessons':
        return completedLessonToday && _checkNightOwl();
      
      case 'weekendWarrior':
        return completedLessonToday && _checkWeekend();
      
      case 'comebacks':
        // Would need to track days since last activity
        return false;
      
      case 'perfectDailyDays':
      case 'challengesCompleted':
      case 'allContentCompleted':
        // These need special tracking, skip for now
        return false;
      
      default:
        // Standard numeric comparison
        final userValue = userStats[field] ?? 0;
        return userValue >= requirement;
    }
  }

  bool _checkEarlyBird() {
    final hour = DateTime.now().hour;
    return hour < 8;
  }

  bool _checkNightOwl() {
    final hour = DateTime.now().hour;
    return hour >= 22;
  }

  bool _checkWeekend() {
    final weekday = DateTime.now().weekday;
    return weekday == 6 || weekday == 7;
  }

  /// Create a notification for badge unlock
  Future<void> _createBadgeNotification(String userId, BadgeModel badge) async {
    try {
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
    } catch (e) {
      debugPrint('⚠️ Error creating badge notification: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Mark badge as seen
  Future<void> markBadgeAsSeen(String userId, String badgeId) async {
    try {
      await _usersCollection.doc(userId).update({
        'seenBadges': FieldValue.arrayUnion([badgeId]),
      });
    } catch (e) {
      debugPrint('Error marking badge as seen: $e');
    }
  }

  /// Get unseen badges
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

  /// Get badge statistics
  Future<Map<String, dynamic>> getBadgeStats(String userId) async {
    try {
      final badges = await getUserBadges(userId);
      
      // Get total from pool or defaults
      int totalBadges;
      try {
        final poolSnapshot = await _badgePoolCollection
            .where('isActive', isEqualTo: true)
            .get();
        totalBadges = poolSnapshot.docs.length;
        if (totalBadges == 0) {
          totalBadges = BadgeTemplate.defaultBadges.length;
        }
      } catch (e) {
        totalBadges = BadgeTemplate.defaultBadges.length;
      }

      final unlockedCount = badges.length;

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
        'percentage': totalBadges > 0 ? (unlockedCount / totalBadges * 100).round() : 0,
        'bronze': bronze,
        'silver': silver,
        'gold': gold,
        'platinum': platinum,
      };
    } catch (e) {
      debugPrint('Error getting badge stats: $e');
      return {
        'total': 0,
        'unlocked': 0,
        'percentage': 0,
        'bronze': 0,
        'silver': 0,
        'gold': 0,
        'platinum': 0,
      };
    }
  }

  // ==================== SPECIFIC ACTION TRIGGERS ====================

  /// Call this after a lesson is completed
  Future<List<BadgeModel>> onLessonCompleted({
    required String userId,
    required UserModel user,
    int lessonsCompletedToday = 1,
  }) async {
    return checkAndUnlockBadges(
      userId: userId,
      user: user,
      lessonsCompletedToday: lessonsCompletedToday,
      completedLessonToday: true,
    );
  }

  /// Call this after a quiz is completed
  Future<List<BadgeModel>> onQuizCompleted({
    required String userId,
    required UserModel user,
    required int totalQuizzes,
    required int totalPerfect,
  }) async {
    return checkAndUnlockBadges(
      userId: userId,
      user: user,
      quizzesCompleted: totalQuizzes,
      perfectQuizzes: totalPerfect,
    );
  }

  /// Call this after a friend is added
  Future<List<BadgeModel>> onFriendAdded({
    required String userId,
    required UserModel user,
    required int totalFriends,
  }) async {
    debugPrint('🤝 Checking social badges for $totalFriends friends');
    return checkAndUnlockBadges(
      userId: userId,
      user: user,
      friendsCount: totalFriends,
    );
  }

  /// Call this after a category is completed
  Future<List<BadgeModel>> onCategoryCompleted({
    required String userId,
    required UserModel user,
    required String categoryId,
  }) async {
    return checkAndUnlockBadges(
      userId: userId,
      user: user,
      completedCategoryToday: true,
      completedCategoryId: categoryId,
    );
  }
}