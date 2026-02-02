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
  String? _lastError;

  // Getters
  List<BadgeModel> get userBadges => _userBadges;
  List<BadgeModel> get newlyUnlockedBadges => _newlyUnlockedBadges;
  List<BadgeTemplate> get badgePool => _badgePool;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

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
      _lastError = null;
      final poolCheck = await _firestore.collection('badgePool').limit(1).get();

      if (poolCheck.docs.isEmpty) {
        debugPrint('🏆 Badge pool empty, seeding defaults...');
        await _seedDefaultBadges();
      }

      await _loadBadgePool();
      _isInitialized = true;
      debugPrint('✅ Badge pool initialized with ${_badgePool.length} badges');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Error initializing badge pool: $e');
    }
  }

  /// Force seed default badges (for admin use)
  Future<bool> forceSeedDefaultBadges() async {
    try {
      _lastError = null;
      debugPrint('🔄 Force seeding badge pool...');
      
      // Delete existing badges first
      final existing = await _firestore.collection('badgePool').get();
      final batch = _firestore.batch();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('🗑️ Cleared ${existing.docs.length} existing badges');
      
      // Seed fresh
      await _seedDefaultBadges();
      await _loadBadgePool();
      
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Error force seeding badges: $e');
      return false;
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
      debugPrint('📦 Loaded ${_badgePool.length} badges from pool');
    } catch (e) {
      debugPrint('Error loading badge pool: $e');
      // If ordering fails (no index), try without ordering
      try {
        final snapshot = await _firestore.collection('badgePool').get();
        _badgePool = snapshot.docs.map((d) => BadgeTemplate.fromFirestore(d)).toList();
        debugPrint('📦 Loaded ${_badgePool.length} badges (unordered)');
      } catch (e2) {
        debugPrint('Error loading badge pool (unordered): $e2');
      }
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
      // Ensure pool is initialized
      await initializeBadgePool();
      
      final snapshot = await _firestore
          .collection('badgePool')
          .where('category', isEqualTo: category.index)
          .get();

      final badges = snapshot.docs.map((d) => BadgeTemplate.fromFirestore(d)).toList();
      
      // Sort by tier locally
      badges.sort((a, b) => a.tier.index.compareTo(b.tier.index));
      
      return badges;
    } catch (e) {
      debugPrint('Error getting badges by category: $e');
      return [];
    }
  }

  Future<List<BadgeTemplate>> getAllBadgeTemplates() async {
    try {
      await initializeBadgePool();
      
      final snapshot = await _firestore.collection('badgePool').get();

      final badges = snapshot.docs.map((d) => BadgeTemplate.fromFirestore(d)).toList();
      
      // Sort locally
      badges.sort((a, b) {
        final catCompare = a.category.index.compareTo(b.category.index);
        if (catCompare != 0) return catCompare;
        return a.tier.index.compareTo(b.tier.index);
      });
      
      return badges;
    } catch (e) {
      debugPrint('Error getting all badge templates: $e');
      return [];
    }
  }

  /// Get stats about the badge pool
  Future<Map<String, int>> getBadgePoolStats() async {
    try {
      final snapshot = await _firestore.collection('badgePool').get();
      final badges = snapshot.docs.map((d) => BadgeTemplate.fromFirestore(d)).toList();
      
      final stats = <String, int>{
        'total': badges.length,
        'active': badges.where((b) => b.isActive).length,
      };
      
      // Count by category
      for (final cat in BadgeCategory.values) {
        stats[cat.name] = badges.where((b) => b.category == cat).length;
      }
      
      return stats;
    } catch (e) {
      return {'total': 0, 'active': 0};
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