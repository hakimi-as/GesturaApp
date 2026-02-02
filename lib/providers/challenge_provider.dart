import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/challenge_model.dart';
import '../models/user_model.dart';

class ChallengeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ChallengeModel> _dailyChallenges = [];
  List<ChallengeModel> _weeklyChallenges = [];
  List<ChallengeModel> _specialChallenges = [];
  
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _lastError;

  List<ChallengeModel> get dailyChallenges => _dailyChallenges;
  List<ChallengeModel> get weeklyChallenges => _weeklyChallenges;
  List<ChallengeModel> get specialChallenges => _specialChallenges;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  int get totalActiveChallenges =>
      _dailyChallenges.length + _weeklyChallenges.length + _specialChallenges.length;
  
  int get completedDailyCount => _dailyChallenges.where((c) => c.isCompleted).length;
  int get completedWeeklyCount => _weeklyChallenges.where((c) => c.isCompleted).length;
  int get completedSpecialCount => _specialChallenges.where((c) => c.isCompleted).length;
  
  int get totalXPAvailable {
    return [..._dailyChallenges, ..._weeklyChallenges, ..._specialChallenges]
        .fold(0, (int sum, c) => sum + c.xpReward);
  }

  /// Initialize challenge pools in Firestore (run once)
  Future<void> initializeChallengePool() async {
    if (_isInitialized) return;
    
    try {
      _lastError = null;
      final poolCheck = await _firestore.collection('challengePool').limit(1).get();

      if (poolCheck.docs.isEmpty) {
        debugPrint('🎯 Challenge pool empty, seeding defaults...');
        await _seedDefaultChallenges();
      }
      
      _isInitialized = true;
      debugPrint('✅ Challenge pool initialized');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Error initializing challenge pool: $e');
    }
  }

  /// Force seed default challenges (for admin use)
  Future<bool> forceSeedDefaultChallenges() async {
    try {
      _lastError = null;
      debugPrint('🔄 Force seeding challenge pool...');
      
      // Delete existing challenges first
      final existing = await _firestore.collection('challengePool').get();
      final batch = _firestore.batch();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('🗑️ Cleared ${existing.docs.length} existing challenges');
      
      // Clear active challenges too
      final activeDocs = await _firestore.collection('activeChallenges').get();
      final batch2 = _firestore.batch();
      for (final doc in activeDocs.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();
      debugPrint('🗑️ Cleared ${activeDocs.docs.length} active challenges');
      
      // Seed fresh
      await _seedDefaultChallenges();
      
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Error force seeding challenges: $e');
      return false;
    }
  }

  Future<void> _seedDefaultChallenges() async {
    final batch = _firestore.batch();

    // Seed daily challenges
    for (final challenge in ChallengeTemplate.defaultDailyChallenges) {
      final ref = _firestore.collection('challengePool').doc(challenge.id);
      batch.set(ref, challenge.toFirestore());
    }

    // Seed weekly challenges
    for (final challenge in ChallengeTemplate.defaultWeeklyChallenges) {
      final ref = _firestore.collection('challengePool').doc(challenge.id);
      batch.set(ref, challenge.toFirestore());
    }

    // Seed special challenges
    for (final challenge in ChallengeTemplate.defaultSpecialChallenges) {
      final ref = _firestore.collection('challengePool').doc(challenge.id);
      batch.set(ref, challenge.toFirestore());
    }

    await batch.commit();
    
    final totalCount = ChallengeTemplate.defaultDailyChallenges.length +
        ChallengeTemplate.defaultWeeklyChallenges.length +
        ChallengeTemplate.defaultSpecialChallenges.length;
    
    debugPrint('✅ Challenge pool seeded with $totalCount challenges');
  }

  Future<void> loadChallenges(String userId, UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      await initializeChallengePool();

      final now = DateTime.now();
      final todayKey = _getTodayKey();
      final weekKey = _getWeekKey();
      final monthKey = 'monthly_${now.year}_${now.month}';

      // Load or select challenges for each type
      _dailyChallenges = await _loadOrSelectChallenges(
        userId: userId,
        user: user,
        periodKey: '${todayKey}_type0',
        type: ChallengeType.daily,
        count: 3,
      );

      _weeklyChallenges = await _loadOrSelectChallenges(
        userId: userId,
        user: user,
        periodKey: '${weekKey}_type1',
        type: ChallengeType.weekly,
        count: 4,
      );

      _specialChallenges = await _loadOrSelectChallenges(
        userId: userId,
        user: user,
        periodKey: '${monthKey}_type2',
        type: ChallengeType.special,
        count: 2,
      );
      
      debugPrint('📦 Loaded challenges: ${_dailyChallenges.length} daily, ${_weeklyChallenges.length} weekly, ${_specialChallenges.length} special');
    } catch (e) {
      debugPrint('Error loading challenges: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<ChallengeModel>> _loadOrSelectChallenges({
    required String userId,
    required UserModel user,
    required String periodKey,
    required ChallengeType type,
    required int count,
  }) async {
    // Check if we already have challenges for this period
    final activeDoc = await _firestore.collection('activeChallenges').doc(periodKey).get();

    if (activeDoc.exists) {
      // Load existing challenges
      final data = activeDoc.data()!;
      final challengeIds = List<String>.from(data['challengeIds'] ?? []);
      
      List<ChallengeModel> challenges = [];
      for (final id in challengeIds) {
        final templateDoc = await _firestore.collection('challengePool').doc(id).get();
        if (templateDoc.exists) {
          final template = ChallengeTemplate.fromFirestore(templateDoc);
          final progress = await _getUserProgress(userId, user, template.trackingField, template.categoryId);
          challenges.add(template.toChallenge().copyWith(currentValue: progress));
        }
      }
      return challenges;
    } else {
      // Select new random challenges
      final selected = await _selectRandomChallenges(type, count, periodKey);
      
      List<ChallengeModel> challenges = [];
      for (final template in selected) {
        final progress = await _getUserProgress(userId, user, template.trackingField, template.categoryId);
        challenges.add(template.toChallenge().copyWith(currentValue: progress));
      }
      return challenges;
    }
  }

  Future<List<ChallengeTemplate>> _selectRandomChallenges(
    ChallengeType type,
    int count,
    String periodKey,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('challengePool')
          .where('type', isEqualTo: type.index)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No ${type.name} challenges in pool');
        return [];
      }

      final templates = snapshot.docs.map((d) => ChallengeTemplate.fromFirestore(d)).toList();
      
      // Use date-based seed for consistent random selection
      final random = Random(periodKey.hashCode);
      templates.shuffle(random);

      final selected = templates.take(count).toList();

      // Save selection
      await _firestore.collection('activeChallenges').doc(periodKey).set({
        'challengeIds': selected.map((t) => t.id).toList(),
        'type': type.index,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return selected;
    } catch (e) {
      debugPrint('Error selecting challenges: $e');
      return [];
    }
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return 'daily_${now.year}_${now.month}_${now.day}';
  }

  String _getWeekKey() {
    final now = DateTime.now();
    final weekNumber = ((now.day - 1) ~/ 7) + 1;
    return 'weekly_${now.year}_${now.month}_$weekNumber';
  }

  /// Get user progress for a tracking field, optionally filtered by category
  Future<int> _getUserProgress(String userId, UserModel user, String trackingField, String? categoryId) async {
    final todayKey = _getTodayKey();
    final weekKey = _getWeekKey();

    final dailyDoc = await _firestore.collection('users').doc(userId)
        .collection('challengeProgress').doc(todayKey).get();
    final weeklyDoc = await _firestore.collection('users').doc(userId)
        .collection('challengeProgress').doc(weekKey).get();

    final dailyData = dailyDoc.exists ? dailyDoc.data() ?? {} : <String, dynamic>{};
    final weeklyData = weeklyDoc.exists ? weeklyDoc.data() ?? {} : <String, dynamic>{};

    // Category-specific tracking
    if (categoryId != null && categoryId.isNotEmpty) {
      switch (trackingField) {
        case 'lessonsInCategoryToday':
          return dailyData['lessonsToday_$categoryId'] ?? 0;
        case 'signsInCategoryToday':
          return dailyData['signsToday_$categoryId'] ?? 0;
        case 'lessonsInCategoryThisWeek':
          return weeklyData['lessonsThisWeek_$categoryId'] ?? 0;
        case 'signsInCategoryThisWeek':
          return weeklyData['signsThisWeek_$categoryId'] ?? 0;
        case 'signsInCategory':
          return await _getCategoryProgress(userId, categoryId, 'signsLearned');
        case 'categoryCompleted':
          return await _isCategoryCompleted(userId, categoryId) ? 1 : 0;
      }
    }

    // General tracking
    switch (trackingField) {
      case 'lessonsToday':
        return dailyData['lessonsToday'] ?? 0;
      case 'quizzesToday':
        return dailyData['quizzesToday'] ?? 0;
      case 'xpToday':
        return dailyData['xpToday'] ?? 0;
      case 'signsToday':
        return dailyData['signsToday'] ?? 0;
      case 'perfectQuizzesToday':
        return dailyData['perfectQuizzesToday'] ?? 0;
      case 'lessonsThisWeek':
        return weeklyData['lessonsThisWeek'] ?? 0;
      case 'quizzesThisWeek':
        return weeklyData['quizzesThisWeek'] ?? 0;
      case 'xpThisWeek':
        return weeklyData['xpThisWeek'] ?? 0;
      case 'signsThisWeek':
        return weeklyData['signsThisWeek'] ?? 0;
      case 'currentStreak':
        return user.currentStreak;
      case 'totalSigns':
        return user.signsLearned;
      case 'totalXP':
        return user.totalXP;
      case 'totalQuizzes':
        return weeklyData['totalQuizzes'] ?? 0;
      case 'perfectQuizzes':
        return user.perfectQuizzes;
      case 'categoriesCompleted':
        return weeklyData['categoriesCompleted'] ?? 0;
      default:
        return 0;
    }
  }

  /// Get category-specific progress from user's category stats
  Future<int> _getCategoryProgress(String userId, String categoryId, String field) async {
    try {
      final doc = await _firestore.collection('users').doc(userId)
          .collection('categoryProgress').doc(categoryId).get();
      if (doc.exists) {
        return doc.data()?[field] ?? 0;
      }
    } catch (e) {
      debugPrint('Error getting category progress: $e');
    }
    return 0;
  }

  /// Check if a category is completed
  Future<bool> _isCategoryCompleted(String userId, String categoryId) async {
    try {
      final categoryDoc = await _firestore.collection('categories').doc(categoryId).get();
      if (!categoryDoc.exists) return false;
      
      final lessonCount = await _firestore.collection('lessons')
          .where('categoryId', isEqualTo: categoryId)
          .count()
          .get();
      
      final completedCount = await _firestore.collection('users').doc(userId)
          .collection('completedLessons')
          .where('categoryId', isEqualTo: categoryId)
          .count()
          .get();
      
      return completedCount.count != null && 
             lessonCount.count != null &&
             completedCount.count! >= lessonCount.count!;
    } catch (e) {
      debugPrint('Error checking category completion: $e');
      return false;
    }
  }

  /// Update progress with optional category tracking
  Future<List<ChallengeModel>> updateProgress({
    required String userId,
    required UserModel user,
    int lessonsCompleted = 0,
    int quizzesCompleted = 0,
    int xpEarned = 0,
    int signsLearned = 0,
    bool perfectQuiz = false,
    bool categoryCompleted = false,
    String? categoryId, // NEW: Track progress for specific category
  }) async {
    List<ChallengeModel> newlyCompleted = [];

    try {
      final todayKey = _getTodayKey();
      final weekKey = _getWeekKey();
      
      final dailyDoc = await _firestore.collection('users').doc(userId)
          .collection('challengeProgress').doc(todayKey).get();
      final weeklyDoc = await _firestore.collection('users').doc(userId)
          .collection('challengeProgress').doc(weekKey).get();

      final dailyData = dailyDoc.exists ? dailyDoc.data() ?? {} : <String, dynamic>{};
      final weeklyData = weeklyDoc.exists ? weeklyDoc.data() ?? {} : <String, dynamic>{};

      // General progress
      final newDailyProgress = <String, dynamic>{
        'lessonsToday': (dailyData['lessonsToday'] ?? 0) + lessonsCompleted,
        'quizzesToday': (dailyData['quizzesToday'] ?? 0) + quizzesCompleted,
        'xpToday': (dailyData['xpToday'] ?? 0) + xpEarned,
        'signsToday': (dailyData['signsToday'] ?? 0) + signsLearned,
        'perfectQuizzesToday': (dailyData['perfectQuizzesToday'] ?? 0) + (perfectQuiz ? 1 : 0),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final newWeeklyProgress = <String, dynamic>{
        'lessonsThisWeek': (weeklyData['lessonsThisWeek'] ?? 0) + lessonsCompleted,
        'quizzesThisWeek': (weeklyData['quizzesThisWeek'] ?? 0) + quizzesCompleted,
        'xpThisWeek': (weeklyData['xpThisWeek'] ?? 0) + xpEarned,
        'signsThisWeek': (weeklyData['signsThisWeek'] ?? 0) + signsLearned,
        'totalQuizzes': (weeklyData['totalQuizzes'] ?? 0) + quizzesCompleted,
        'categoriesCompleted': (weeklyData['categoriesCompleted'] ?? 0) + (categoryCompleted ? 1 : 0),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Category-specific progress
      if (categoryId != null && categoryId.isNotEmpty) {
        if (lessonsCompleted > 0) {
          newDailyProgress['lessonsToday_$categoryId'] = (dailyData['lessonsToday_$categoryId'] ?? 0) + lessonsCompleted;
          newWeeklyProgress['lessonsThisWeek_$categoryId'] = (weeklyData['lessonsThisWeek_$categoryId'] ?? 0) + lessonsCompleted;
        }
        if (signsLearned > 0) {
          newDailyProgress['signsToday_$categoryId'] = (dailyData['signsToday_$categoryId'] ?? 0) + signsLearned;
          newWeeklyProgress['signsThisWeek_$categoryId'] = (weeklyData['signsThisWeek_$categoryId'] ?? 0) + signsLearned;
        }
        
        // Also update category progress collection
        await _firestore.collection('users').doc(userId)
            .collection('categoryProgress').doc(categoryId)
            .set({
              'signsLearned': FieldValue.increment(signsLearned),
              'lessonsCompleted': FieldValue.increment(lessonsCompleted),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      await _firestore.collection('users').doc(userId)
          .collection('challengeProgress').doc(todayKey)
          .set(newDailyProgress, SetOptions(merge: true));

      await _firestore.collection('users').doc(userId)
          .collection('challengeProgress').doc(weekKey)
          .set(newWeeklyProgress, SetOptions(merge: true));

      // Track previously completed
      final oldDailyCompleted = _dailyChallenges.map((c) => c.isCompleted).toList();
      final oldWeeklyCompleted = _weeklyChallenges.map((c) => c.isCompleted).toList();
      final oldSpecialCompleted = _specialChallenges.map((c) => c.isCompleted).toList();

      // Reload challenges with updated progress
      await loadChallenges(userId, user);

      // Check for newly completed
      for (int i = 0; i < _dailyChallenges.length && i < oldDailyCompleted.length; i++) {
        if (_dailyChallenges[i].isCompleted && !oldDailyCompleted[i]) {
          newlyCompleted.add(_dailyChallenges[i]);
          await _awardChallengeXP(userId, _dailyChallenges[i].xpReward);
        }
      }

      for (int i = 0; i < _weeklyChallenges.length && i < oldWeeklyCompleted.length; i++) {
        if (_weeklyChallenges[i].isCompleted && !oldWeeklyCompleted[i]) {
          newlyCompleted.add(_weeklyChallenges[i]);
          await _awardChallengeXP(userId, _weeklyChallenges[i].xpReward);
        }
      }

      for (int i = 0; i < _specialChallenges.length && i < oldSpecialCompleted.length; i++) {
        if (_specialChallenges[i].isCompleted && !oldSpecialCompleted[i]) {
          newlyCompleted.add(_specialChallenges[i]);
          await _awardChallengeXP(userId, _specialChallenges[i].xpReward);
        }
      }

      if (newlyCompleted.isNotEmpty) {
        debugPrint('🎯 Completed ${newlyCompleted.length} challenges!');
      }
    } catch (e) {
      debugPrint('Error updating progress: $e');
    }

    return newlyCompleted;
  }

  Future<void> _awardChallengeXP(String userId, int xp) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'totalXP': FieldValue.increment(xp),
      });
    } catch (e) {
      debugPrint('Error awarding XP: $e');
    }
  }

  // ============ ADMIN FUNCTIONS ============

  Future<List<ChallengeTemplate>> getChallengePool() async {
    try {
      await initializeChallengePool();
      
      final snapshot = await _firestore.collection('challengePool').get();

      final challenges = snapshot.docs.map((d) => ChallengeTemplate.fromFirestore(d)).toList();
      
      // Sort locally
      challenges.sort((a, b) {
        final typeCompare = a.type.index.compareTo(b.type.index);
        if (typeCompare != 0) return typeCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return challenges;
    } catch (e) {
      debugPrint('Error getting challenge pool: $e');
      return [];
    }
  }

  Future<List<ChallengeTemplate>> getChallengesByType(ChallengeType type) async {
    try {
      await initializeChallengePool();
      
      final snapshot = await _firestore
          .collection('challengePool')
          .where('type', isEqualTo: type.index)
          .get();

      final challenges = snapshot.docs.map((d) => ChallengeTemplate.fromFirestore(d)).toList();
      challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return challenges;
    } catch (e) {
      debugPrint('Error getting challenges by type: $e');
      return [];
    }
  }

  /// Get stats about the challenge pool
  Future<Map<String, int>> getChallengePoolStats() async {
    try {
      final snapshot = await _firestore.collection('challengePool').get();
      final challenges = snapshot.docs.map((d) => ChallengeTemplate.fromFirestore(d)).toList();
      
      return {
        'total': challenges.length,
        'active': challenges.where((c) => c.isActive).length,
        'daily': challenges.where((c) => c.type == ChallengeType.daily).length,
        'weekly': challenges.where((c) => c.type == ChallengeType.weekly).length,
        'special': challenges.where((c) => c.type == ChallengeType.special).length,
      };
    } catch (e) {
      return {'total': 0, 'active': 0, 'daily': 0, 'weekly': 0, 'special': 0};
    }
  }

  Future<void> addChallenge(ChallengeTemplate challenge) async {
    try {
      await _firestore.collection('challengePool').add(challenge.toFirestore());
      notifyListeners();
      debugPrint('✅ Challenge added to pool');
    } catch (e) {
      debugPrint('Error adding challenge: $e');
      rethrow;
    }
  }

  Future<void> updateChallenge(ChallengeTemplate challenge) async {
    try {
      await _firestore.collection('challengePool').doc(challenge.id).update(challenge.toFirestore());
      notifyListeners();
      debugPrint('✅ Challenge updated');
    } catch (e) {
      debugPrint('Error updating challenge: $e');
      rethrow;
    }
  }

  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _firestore.collection('challengePool').doc(challengeId).delete();
      notifyListeners();
      debugPrint('✅ Challenge deleted');
    } catch (e) {
      debugPrint('Error deleting challenge: $e');
      rethrow;
    }
  }

  Future<void> toggleChallengeActive(String challengeId, bool isActive) async {
    try {
      await _firestore.collection('challengePool').doc(challengeId).update({'isActive': isActive});
      notifyListeners();
      debugPrint('✅ Challenge active status updated');
    } catch (e) {
      debugPrint('Error toggling challenge: $e');
      rethrow;
    }
  }

  Future<void> forceRefreshActiveChallenges() async {
    try {
      final batch = _firestore.batch();
      final activeDocs = await _firestore.collection('activeChallenges').get();
      for (final doc in activeDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _isInitialized = false;
      debugPrint('✅ Active challenges cleared - will re-select on next load');
    } catch (e) {
      debugPrint('Error force refreshing: $e');
      rethrow;
    }
  }
}