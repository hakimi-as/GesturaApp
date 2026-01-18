import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/badge_model.dart';
import '../models/user_model.dart';
import '../services/badge_service.dart';

class BadgeProvider extends ChangeNotifier {
  final BadgeService _badgeService = BadgeService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BadgeModel> _userBadges = [];
  List<BadgeModel> _newlyUnlockedBadges = [];
  List<BadgeTemplate> _badgePool = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  List<BadgeModel> get userBadges => _userBadges;
  List<BadgeModel> get newlyUnlockedBadges => _newlyUnlockedBadges;
  List<BadgeTemplate> get badgePool => _badgePool;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  List<BadgeModel> get allBadges {
    if (_badgePool.isEmpty) {
      return BadgeModel.allBadges;
    }
    return _badgePool.where((t) => t.isActive).map((t) => t.toBadge()).toList();
  }

  List<BadgeModel> get unlockedBadges => 
      _userBadges.where((b) => b.isUnlocked).toList();

  List<BadgeModel> get lockedBadges {
    final unlockedIds = _userBadges.map((b) => b.id).toSet();
    return allBadges.where((b) => !unlockedIds.contains(b.id)).toList();
  }

  // ============ INITIALIZATION ============

  Future<void> initializeBadgePool() async {
    if (_isInitialized) return;

    try {
      final poolCheck = await _firestore.collection('badgePool').limit(1).get();

      if (poolCheck.docs.isEmpty) {
        debugPrint('🏆 Initializing badge pool with defaults...');
        await _seedDefaultBadges();
      }

      await _loadBadgePool();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing badge pool: $e');
    }
  }

  Future<void> _seedDefaultBadges() async {
    final batch = _firestore.batch();

    for (final badge in BadgeTemplate.defaultBadges) {
      final ref = _firestore.collection('badgePool').doc(badge.id);
      batch.set(ref, badge.toFirestore());
    }

    await batch.commit();
    debugPrint('✅ Badge pool seeded with ${BadgeTemplate.defaultBadges.length} badges');
  }

  Future<void> _loadBadgePool() async {
    try {
      final snapshot = await _firestore
          .collection('badgePool')
          .orderBy('category')
          .orderBy('tier')
          .get();

      _badgePool = snapshot.docs.map((d) => BadgeTemplate.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error loading badge pool: $e');
    }
  }

  // ============ USER BADGES ============

  Future<void> loadUserBadges(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await initializeBadgePool();
      _userBadges = await _badgeService.getUserBadges(userId);
      _stats = await _badgeService.getBadgeStats(userId);
    } catch (e) {
      debugPrint('Error loading badges: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<BadgeModel>> checkForNewBadges({
    required String userId,
    required UserModel user,
    int? quizzesCompleted,
    int? perfectQuizzes,
    bool? completedLessonToday,
    bool? completedCategoryToday,
    int? lessonsCompletedToday,
  }) async {
    try {
      final newBadges = await _badgeService.checkAndUnlockBadges(
        userId: userId,
        user: user,
        quizzesCompleted: quizzesCompleted,
        perfectQuizzes: perfectQuizzes,
        completedLessonToday: completedLessonToday,
        completedCategoryToday: completedCategoryToday,
        lessonsCompletedToday: lessonsCompletedToday,
      );

      if (newBadges.isNotEmpty) {
        _newlyUnlockedBadges = newBadges;
        await loadUserBadges(userId);
        notifyListeners();
      }

      return newBadges;
    } catch (e) {
      debugPrint('Error checking badges: $e');
      return [];
    }
  }

  void clearNewlyUnlocked() {
    _newlyUnlockedBadges = [];
    notifyListeners();
  }

  Future<void> markAsSeen(String userId, String badgeId) async {
    await _badgeService.markBadgeAsSeen(userId, badgeId);
  }

  List<BadgeModel> getBadgesByCategory(BadgeCategory category) {
    return allBadges.where((b) => b.category == category).toList();
  }

  List<BadgeModel> getUserBadgesByCategory(BadgeCategory category) {
    final unlockedIds = _userBadges.map((b) => b.id).toSet();
    return getBadgesByCategory(category)
        .map((b) => unlockedIds.contains(b.id) 
            ? b.copyWith(unlockedAt: DateTime.now()) 
            : b)
        .toList();
  }

  // ============ ADMIN FUNCTIONS ============

  Future<List<BadgeTemplate>> getBadgePoolByCategory(BadgeCategory category) async {
    try {
      final snapshot = await _firestore
          .collection('badgePool')
          .where('category', isEqualTo: category.index)
          .orderBy('tier')
          .get();

      return snapshot.docs.map((d) => BadgeTemplate.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error getting badges by category: $e');
      return [];
    }
  }

  Future<List<BadgeTemplate>> getAllBadgeTemplates() async {
    try {
      final snapshot = await _firestore
          .collection('badgePool')
          .orderBy('category')
          .orderBy('tier')
          .get();

      return snapshot.docs.map((d) => BadgeTemplate.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error getting all badge templates: $e');
      return [];
    }
  }

  Future<void> addBadge(BadgeTemplate badge) async {
    try {
      await _firestore.collection('badgePool').add(badge.toFirestore());
      await _loadBadgePool();
      notifyListeners();
      debugPrint('✅ Badge added to pool');
    } catch (e) {
      debugPrint('Error adding badge: $e');
      rethrow;
    }
  }

  Future<void> updateBadge(BadgeTemplate badge) async {
    try {
      await _firestore.collection('badgePool').doc(badge.id).update(badge.toFirestore());
      await _loadBadgePool();
      notifyListeners();
      debugPrint('✅ Badge updated');
    } catch (e) {
      debugPrint('Error updating badge: $e');
      rethrow;
    }
  }

  Future<void> deleteBadge(String badgeId) async {
    try {
      await _firestore.collection('badgePool').doc(badgeId).delete();
      await _loadBadgePool();
      notifyListeners();
      debugPrint('✅ Badge deleted');
    } catch (e) {
      debugPrint('Error deleting badge: $e');
      rethrow;
    }
  }

  Future<void> toggleBadgeActive(String badgeId, bool isActive) async {
    try {
      await _firestore.collection('badgePool').doc(badgeId).update({'isActive': isActive});
      await _loadBadgePool();
      notifyListeners();
      debugPrint('✅ Badge active status updated');
    } catch (e) {
      debugPrint('Error toggling badge: $e');
      rethrow;
    }
  }
}