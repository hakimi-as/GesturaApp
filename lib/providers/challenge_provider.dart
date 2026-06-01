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

  // ── Progress cache ─────────────────────────────────────────────────────────
  // Populated once per loadChallenges; reused by all sub-calls and quickUpdate.
  Map<String, dynamic> _cachedDailyData = {};
  Map<String, dynamic> _cachedWeeklyData = {};
  String? _cachedUserId;
  String? _cachedTodayKey;
  UserModel? _cachedUser;

  // ── Getters ────────────────────────────────────────────────────────────────
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

  // ── Pool initialization ────────────────────────────────────────────────────

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

  Future<bool> forceSeedDefaultChallenges() async {
    try {
      _lastError = null;
      final existing = await _firestore.collection('challengePool').get();
      final batch = _firestore.batch();
      for (final doc in existing.docs) batch.delete(doc.reference);
      await batch.commit();

      final activeDocs = await _firestore.collection('activeChallenges').get();
      final batch2 = _firestore.batch();
      for (final doc in activeDocs.docs) batch2.delete(doc.reference);
      await batch2.commit();

      await _seedDefaultChallenges();
      _isInitialized = true;
      _cachedTodayKey = null; // Force full reload next time
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<void> _seedDefaultChallenges() async {
    final batch = _firestore.batch();
    for (final c in ChallengeTemplate.defaultDailyChallenges) {
      batch.set(_firestore.collection('challengePool').doc(c.id), c.toFirestore());
    }
    for (final c in ChallengeTemplate.defaultWeeklyChallenges) {
      batch.set(_firestore.collection('challengePool').doc(c.id), c.toFirestore());
    }
    for (final c in ChallengeTemplate.defaultSpecialChallenges) {
      batch.set(_firestore.collection('challengePool').doc(c.id), c.toFirestore());
    }
    await batch.commit();
  }

  // ── Main load ──────────────────────────────────────────────────────────────

  Future<void> loadChallenges(String userId, UserModel user) async {
    final todayKey = _getTodayKey();

    // Fast path: already loaded today — just refresh progress values (2 reads vs 40+).
    if (_cachedUserId == userId &&
        _cachedTodayKey == todayKey &&
        _dailyChallenges.isNotEmpty &&
        !_isLoading) {
      await _refreshProgressValues(userId, user);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await initializeChallengePool();

      final weekKey = _getWeekKey();
      final now = DateTime.now();
      final monthKey = 'monthly_${now.year}_${now.month}';

      // Read daily + weekly progress ONCE and cache them.
      // Previously these were re-read for every single challenge (18+ reads).
      final progressDocs = await Future.wait([
        _firestore
            .collection('users')
            .doc(userId)
            .collection('challengeProgress')
            .doc(todayKey)
            .get(),
        _firestore
            .collection('users')
            .doc(userId)
            .collection('challengeProgress')
            .doc(weekKey)
            .get(),
      ]);
      _cachedDailyData = progressDocs[0].exists ? progressDocs[0].data() ?? {} : {};
      _cachedWeeklyData = progressDocs[1].exists ? progressDocs[1].data() ?? {} : {};
      _cachedUserId = userId;
      _cachedTodayKey = todayKey;
      _cachedUser = user;

      // Personalized challenges are cached for the day so they never change
      // mid-session (fixes the "Explore Food disappears after completing a lesson" bug).
      final personalized = await _loadPersonalizedChallenges(userId, user, todayKey);

      final regularDaily = await _loadOrSelectChallenges(
        userId: userId,
        user: user,
        periodKey: '${todayKey}_type0',
        type: ChallengeType.daily,
        count: 3,
      );
      _dailyChallenges = [...personalized, ...regularDaily];

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

      debugPrint(
          '📦 Loaded ${_dailyChallenges.length} daily / ${_weeklyChallenges.length} weekly / ${_specialChallenges.length} special');
    } catch (e) {
      debugPrint('Error loading challenges: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Fast-path refresh ──────────────────────────────────────────────────────

  /// Refresh only the currentValue of already-loaded challenges (2 Firestore reads).
  Future<void> _refreshProgressValues(String userId, UserModel user) async {
    try {
      final todayKey = _getTodayKey();
      final weekKey = _getWeekKey();
      final docs = await Future.wait([
        _firestore
            .collection('users')
            .doc(userId)
            .collection('challengeProgress')
            .doc(todayKey)
            .get(),
        _firestore
            .collection('users')
            .doc(userId)
            .collection('challengeProgress')
            .doc(weekKey)
            .get(),
      ]);
      _cachedDailyData = docs[0].exists ? docs[0].data() ?? {} : {};
      _cachedWeeklyData = docs[1].exists ? docs[1].data() ?? {} : {};
      _cachedUser = user;

      _dailyChallenges = _dailyChallenges
          .map((c) => c.copyWith(currentValue: _getUserProgressSync(c.trackingField, c.categoryId, user)))
          .toList();
      _weeklyChallenges = _weeklyChallenges
          .map((c) => c.copyWith(currentValue: _getUserProgressSync(c.trackingField, c.categoryId, user)))
          .toList();
      _specialChallenges = _specialChallenges
          .map((c) => c.copyWith(currentValue: _getUserProgressSync(c.trackingField, c.categoryId, user)))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing progress values: $e');
    }
  }

  // ── Personalized challenges with day-level caching ─────────────────────────

  /// Load today's personalized challenges from cache, or generate and cache them.
  /// Once generated for a day they NEVER change, so completing one category's
  /// lesson won't swap the goals out from under the user.
  Future<List<ChallengeModel>> _loadPersonalizedChallenges(
      String userId, UserModel user, String todayKey) async {
    final cacheKey = 'personalized_${userId}_$todayKey';
    try {
      final cachedDoc =
          await _firestore.collection('activeChallenges').doc(cacheKey).get();
      if (cachedDoc.exists) {
        final rawList = cachedDoc.data()?['challenges'] as List<dynamic>? ?? [];
        final challenges = rawList
            .map((e) => ChallengeModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (challenges.isNotEmpty) {
          // Only update progress values — categories stay the same all day.
          return challenges
              .map((c) => c.copyWith(
                    currentValue: _getUserProgressSync(c.trackingField, c.categoryId, user),
                  ))
              .toList();
        }
      }
    } catch (_) {}

    // Generate fresh and save for the day.
    final generated = await _generatePersonalizedChallenges(userId, user);
    if (generated.isNotEmpty) {
      try {
        await _firestore.collection('activeChallenges').doc(cacheKey).set({
          'challenges': generated.map((c) => c.toMap()).toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
    return generated;
  }

  Future<List<ChallengeModel>> _generatePersonalizedChallenges(
      String userId, UserModel user) async {
    try {
      final categoriesSnap =
          await _firestore.collection('categories').orderBy('order').get();
      if (categoriesSnap.docs.isEmpty) return [];

      final progressSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categoryProgress')
          .get();
      final progressMap = {for (final doc in progressSnap.docs) doc.id: doc.data()};

      final scored = categoriesSnap.docs.map((cat) {
        final lessonsCompleted =
            (progressMap[cat.id]?['lessonsCompleted'] as int?) ?? 0;
        return {
          'id': cat.id,
          'name': cat.data()['name'] as String? ?? 'Unknown',
          'lessonsCompleted': lessonsCompleted,
        };
      }).toList()
        ..sort((a, b) =>
            (a['lessonsCompleted'] as int).compareTo(b['lessonsCompleted'] as int));

      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final todayKey = _getTodayKey();

      final List<ChallengeModel> challenges = [];
      for (final cat in scored) {
        if (challenges.length >= 2) break;
        final catId = cat['id'] as String;
        final catName = cat['name'] as String;
        final lessonsCompleted = cat['lessonsCompleted'] as int;
        final todayProgress =
            (_cachedDailyData['lessonsToday_$catId'] as int?) ?? 0;

        String title, description, emoji;
        int target, xpReward;
        if (lessonsCompleted == 0) {
          title = 'Explore $catName';
          description = 'Start your first lesson in $catName';
          emoji = '🌟';
          target = 1;
          xpReward = 50;
        } else if (lessonsCompleted < 3) {
          title = 'Strengthen $catName';
          description = 'Complete 2 lessons in $catName today';
          emoji = '💪';
          target = 2;
          xpReward = 65;
        } else {
          title = 'Master $catName';
          description = 'Complete 3 lessons in $catName today';
          emoji = '🎯';
          target = 3;
          xpReward = 80;
        }

        challenges.add(ChallengeModel(
          id: 'personalized_${catId}_$todayKey',
          title: title,
          description: description,
          emoji: emoji,
          type: ChallengeType.daily,
          targetValue: target,
          currentValue: todayProgress,
          xpReward: xpReward,
          startDate: now,
          endDate: endOfDay,
          trackingField: 'lessonsInCategoryToday',
          categoryId: catId,
          isPersonalized: true,
        ));
      }
      return challenges;
    } catch (e) {
      debugPrint('Error generating personalized challenges: $e');
      return [];
    }
  }

  // ── Synchronous progress lookup (uses cached data — no Firestore reads) ────

  int _getUserProgressSync(
      String trackingField, String? categoryId, UserModel user) {
    if (categoryId != null && categoryId.isNotEmpty) {
      switch (trackingField) {
        case 'lessonsInCategoryToday':
          return (_cachedDailyData['lessonsToday_$categoryId'] as int?) ?? 0;
        case 'signsInCategoryToday':
          return (_cachedDailyData['signsToday_$categoryId'] as int?) ?? 0;
        case 'lessonsInCategoryThisWeek':
          return (_cachedWeeklyData['lessonsThisWeek_$categoryId'] as int?) ?? 0;
        case 'signsInCategoryThisWeek':
          return (_cachedWeeklyData['signsThisWeek_$categoryId'] as int?) ?? 0;
        // signsInCategory / categoryCompleted need async reads — default to 0
        default:
          return 0;
      }
    }
    switch (trackingField) {
      case 'lessonsToday':
        return (_cachedDailyData['lessonsToday'] as int?) ?? 0;
      case 'quizzesToday':
        return (_cachedDailyData['quizzesToday'] as int?) ?? 0;
      case 'xpToday':
        return (_cachedDailyData['xpToday'] as int?) ?? 0;
      case 'signsToday':
        return (_cachedDailyData['signsToday'] as int?) ?? 0;
      case 'perfectQuizzesToday':
        return (_cachedDailyData['perfectQuizzesToday'] as int?) ?? 0;
      case 'lessonsThisWeek':
        return (_cachedWeeklyData['lessonsThisWeek'] as int?) ?? 0;
      case 'quizzesThisWeek':
        return (_cachedWeeklyData['quizzesThisWeek'] as int?) ?? 0;
      case 'xpThisWeek':
        return (_cachedWeeklyData['xpThisWeek'] as int?) ?? 0;
      case 'signsThisWeek':
        return (_cachedWeeklyData['signsThisWeek'] as int?) ?? 0;
      case 'currentStreak':
        return user.currentStreak;
      case 'totalSigns':
        return user.signsLearned;
      case 'totalXP':
        return user.totalXP;
      case 'totalQuizzes':
        return (_cachedWeeklyData['totalQuizzes'] as int?) ?? 0;
      case 'perfectQuizzes':
        return user.perfectQuizzes;
      case 'categoriesCompleted':
        return (_cachedWeeklyData['categoriesCompleted'] as int?) ?? 0;
      default:
        return 0;
    }
  }

  // ── Instant in-memory update (called right after lesson completion) ─────────

  /// Updates challenge progress in memory with zero Firestore reads.
  /// Call this immediately after a lesson is saved so goals update instantly.
  void quickUpdateInMemory({
    required int lessonsCompleted,
    required int xpEarned,
    required int signsLearned,
    String? categoryId,
  }) {
    // Patch the cached progress maps.
    _cachedDailyData['lessonsToday'] =
        (_cachedDailyData['lessonsToday'] as int? ?? 0) + lessonsCompleted;
    _cachedDailyData['xpToday'] =
        (_cachedDailyData['xpToday'] as int? ?? 0) + xpEarned;
    _cachedDailyData['signsToday'] =
        (_cachedDailyData['signsToday'] as int? ?? 0) + signsLearned;
    _cachedWeeklyData['lessonsThisWeek'] =
        (_cachedWeeklyData['lessonsThisWeek'] as int? ?? 0) + lessonsCompleted;
    _cachedWeeklyData['xpThisWeek'] =
        (_cachedWeeklyData['xpThisWeek'] as int? ?? 0) + xpEarned;
    _cachedWeeklyData['signsThisWeek'] =
        (_cachedWeeklyData['signsThisWeek'] as int? ?? 0) + signsLearned;

    if (categoryId != null && categoryId.isNotEmpty) {
      _cachedDailyData['lessonsToday_$categoryId'] =
          (_cachedDailyData['lessonsToday_$categoryId'] as int? ?? 0) + lessonsCompleted;
      _cachedDailyData['signsToday_$categoryId'] =
          (_cachedDailyData['signsToday_$categoryId'] as int? ?? 0) + signsLearned;
      _cachedWeeklyData['lessonsThisWeek_$categoryId'] =
          (_cachedWeeklyData['lessonsThisWeek_$categoryId'] as int? ?? 0) + lessonsCompleted;
    }

    final user = _cachedUser;
    if (user == null) return;

    // Re-compute each challenge's currentValue from the updated cache.
    _dailyChallenges = _dailyChallenges
        .map((c) => c.copyWith(
              currentValue: _getUserProgressSync(c.trackingField, c.categoryId, user),
            ))
        .toList();
    _weeklyChallenges = _weeklyChallenges
        .map((c) => c.copyWith(
              currentValue: _getUserProgressSync(c.trackingField, c.categoryId, user),
            ))
        .toList();

    notifyListeners();
  }

  // ── Challenge selection & loading ──────────────────────────────────────────

  Future<List<ChallengeModel>> _loadOrSelectChallenges({
    required String userId,
    required UserModel user,
    required String periodKey,
    required ChallengeType type,
    required int count,
  }) async {
    try {
      final activeDoc =
          await _firestore.collection('activeChallenges').doc(periodKey).get();
      if (activeDoc.exists) {
        final ids = List<String>.from(activeDoc.data()?['challengeIds'] ?? []);
        if (ids.isNotEmpty) {
          // Batch-read all pool documents in one go.
          final poolDocs = await Future.wait(
            ids.map((id) => _firestore.collection('challengePool').doc(id).get()),
          );
          final challenges = <ChallengeModel>[];
          for (final doc in poolDocs) {
            if (doc.exists) {
              final template = ChallengeTemplate.fromFirestore(doc);
              // Synchronous lookup — no extra Firestore reads.
              final progress =
                  _getUserProgressSync(template.trackingField, template.categoryId, user);
              challenges.add(template.toChallenge().copyWith(currentValue: progress));
            }
          }
          if (challenges.isNotEmpty) return challenges;
        }
      }
    } catch (_) {}

    final selected = await _selectRandomChallenges(type, count, periodKey);
    return selected.map((template) {
      final progress =
          _getUserProgressSync(template.trackingField, template.categoryId, user);
      return template.toChallenge().copyWith(currentValue: progress);
    }).toList();
  }

  Future<List<ChallengeTemplate>> _selectRandomChallenges(
      ChallengeType type, int count, String periodKey) async {
    List<ChallengeTemplate> templates = [];
    try {
      final snapshot = await _firestore
          .collection('challengePool')
          .where('type', isEqualTo: type.index)
          .get();
      templates = snapshot.docs
          .map((d) => ChallengeTemplate.fromFirestore(d))
          .where((t) => t.isActive)
          .toList();
    } catch (e) {
      debugPrint('⚠️ Pool unavailable, using built-in defaults: $e');
    }

    if (templates.isEmpty) {
      templates = List.from(type == ChallengeType.daily
          ? ChallengeTemplate.defaultDailyChallenges
          : type == ChallengeType.weekly
              ? ChallengeTemplate.defaultWeeklyChallenges
              : ChallengeTemplate.defaultSpecialChallenges);
    }

    final random = Random(periodKey.hashCode);
    templates.shuffle(random);
    final selected = templates.take(count).toList();

    try {
      await _firestore.collection('activeChallenges').doc(periodKey).set({
        'challengeIds': selected.map((t) => t.id).toList(),
        'type': type.index,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return selected;
  }

  // ── Progress update ────────────────────────────────────────────────────────

  /// Write progress to Firestore and instantly update the in-memory challenge
  /// values — no full reload needed.
  Future<List<ChallengeModel>> updateProgress({
    required String userId,
    required UserModel user,
    int lessonsCompleted = 0,
    int quizzesCompleted = 0,
    int xpEarned = 0,
    int signsLearned = 0,
    bool perfectQuiz = false,
    bool categoryCompleted = false,
    String? categoryId,
  }) async {
    final List<ChallengeModel> newlyCompleted = [];

    try {
      final todayKey = _getTodayKey();
      final weekKey = _getWeekKey();

      // Snapshot old completion state before update.
      final oldDailyCompleted = _dailyChallenges.map((c) => c.isCompleted).toList();
      final oldWeeklyCompleted = _weeklyChallenges.map((c) => c.isCompleted).toList();
      final oldSpecialCompleted = _specialChallenges.map((c) => c.isCompleted).toList();

      // Build Firestore update maps.
      final newDailyProgress = <String, dynamic>{
        'lessonsToday': FieldValue.increment(lessonsCompleted),
        'quizzesToday': FieldValue.increment(quizzesCompleted),
        'xpToday': FieldValue.increment(xpEarned),
        'signsToday': FieldValue.increment(signsLearned),
        'perfectQuizzesToday': FieldValue.increment(perfectQuiz ? 1 : 0),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final newWeeklyProgress = <String, dynamic>{
        'lessonsThisWeek': FieldValue.increment(lessonsCompleted),
        'quizzesThisWeek': FieldValue.increment(quizzesCompleted),
        'xpThisWeek': FieldValue.increment(xpEarned),
        'signsThisWeek': FieldValue.increment(signsLearned),
        'totalQuizzes': FieldValue.increment(quizzesCompleted),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (categoryId != null && categoryId.isNotEmpty) {
        if (lessonsCompleted > 0) {
          newDailyProgress['lessonsToday_$categoryId'] = FieldValue.increment(lessonsCompleted);
          newWeeklyProgress['lessonsThisWeek_$categoryId'] = FieldValue.increment(lessonsCompleted);
        }
        if (signsLearned > 0) {
          newDailyProgress['signsToday_$categoryId'] = FieldValue.increment(signsLearned);
          newWeeklyProgress['signsThisWeek_$categoryId'] = FieldValue.increment(signsLearned);
        }
      }
      if (categoryCompleted) {
        newWeeklyProgress['categoriesCompleted'] = FieldValue.increment(1);
      }

      // Fire-and-forget the Firestore writes; update in-memory immediately.
      _firestore
          .collection('users')
          .doc(userId)
          .collection('challengeProgress')
          .doc(todayKey)
          .set(newDailyProgress, SetOptions(merge: true));
      _firestore
          .collection('users')
          .doc(userId)
          .collection('challengeProgress')
          .doc(weekKey)
          .set(newWeeklyProgress, SetOptions(merge: true));

      if (categoryId != null && categoryId.isNotEmpty) {
        _firestore
            .collection('users')
            .doc(userId)
            .collection('categoryProgress')
            .doc(categoryId)
            .set({
          'signsLearned': FieldValue.increment(signsLearned),
          'lessonsCompleted': FieldValue.increment(lessonsCompleted),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Instantly reflect the progress in the UI — zero Firestore reads.
      quickUpdateInMemory(
        lessonsCompleted: lessonsCompleted,
        xpEarned: xpEarned,
        signsLearned: signsLearned,
        categoryId: categoryId,
      );

      // Detect newly completed challenges.
      for (int i = 0; i < _dailyChallenges.length && i < oldDailyCompleted.length; i++) {
        if (_dailyChallenges[i].isCompleted && !oldDailyCompleted[i]) {
          newlyCompleted.add(_dailyChallenges[i]);
          _awardChallengeXP(userId, _dailyChallenges[i].xpReward);
        }
      }
      for (int i = 0; i < _weeklyChallenges.length && i < oldWeeklyCompleted.length; i++) {
        if (_weeklyChallenges[i].isCompleted && !oldWeeklyCompleted[i]) {
          newlyCompleted.add(_weeklyChallenges[i]);
          _awardChallengeXP(userId, _weeklyChallenges[i].xpReward);
        }
      }
      for (int i = 0; i < _specialChallenges.length && i < oldSpecialCompleted.length; i++) {
        if (_specialChallenges[i].isCompleted && !oldSpecialCompleted[i]) {
          newlyCompleted.add(_specialChallenges[i]);
          _awardChallengeXP(userId, _specialChallenges[i].xpReward);
        }
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _getTodayKey() {
    final now = DateTime.now();
    return 'daily_${now.year}_${now.month}_${now.day}';
  }

  String _getWeekKey() {
    final now = DateTime.now();
    final weekNumber = ((now.day - 1) ~/ 7) + 1;
    return 'weekly_${now.year}_${now.month}_$weekNumber';
  }

  // Keep async version for admin/diagnostic use.
  Future<int> _getUserProgress(
      String userId, UserModel user, String trackingField, String? categoryId) async {
    final todayKey = _getTodayKey();
    final weekKey = _getWeekKey();
    final dailyDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('challengeProgress')
        .doc(todayKey)
        .get();
    final weeklyDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('challengeProgress')
        .doc(weekKey)
        .get();
    final dailyData = dailyDoc.exists ? dailyDoc.data() ?? {} : <String, dynamic>{};
    final weeklyData = weeklyDoc.exists ? weeklyDoc.data() ?? {} : <String, dynamic>{};

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

  Future<int> _getCategoryProgress(
      String userId, String categoryId, String field) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categoryProgress')
          .doc(categoryId)
          .get();
      if (doc.exists) return doc.data()?[field] ?? 0;
    } catch (e) {
      debugPrint('Error getting category progress: $e');
    }
    return 0;
  }

  Future<bool> _isCategoryCompleted(String userId, String categoryId) async {
    try {
      final categoryDoc =
          await _firestore.collection('categories').doc(categoryId).get();
      if (!categoryDoc.exists) return false;
      final lessonCount = await _firestore
          .collection('lessons')
          .where('categoryId', isEqualTo: categoryId)
          .count()
          .get();
      final completedCount = await _firestore
          .collection('users')
          .doc(userId)
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

  // ── Admin functions ────────────────────────────────────────────────────────

  Future<List<ChallengeTemplate>> getChallengePool() async {
    try {
      await initializeChallengePool();
      final snapshot = await _firestore.collection('challengePool').get();
      final challenges =
          snapshot.docs.map((d) => ChallengeTemplate.fromFirestore(d)).toList();
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
      final challenges =
          snapshot.docs.map((d) => ChallengeTemplate.fromFirestore(d)).toList();
      challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return challenges;
    } catch (e) {
      debugPrint('Error getting challenges by type: $e');
      return [];
    }
  }

  Future<Map<String, int>> getChallengePoolStats() async {
    try {
      final snapshot = await _firestore.collection('challengePool').get();
      final challenges =
          snapshot.docs.map((d) => ChallengeTemplate.fromFirestore(d)).toList();
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
    } catch (e) {
      debugPrint('Error adding challenge: $e');
      rethrow;
    }
  }

  Future<void> updateChallenge(ChallengeTemplate challenge) async {
    try {
      await _firestore
          .collection('challengePool')
          .doc(challenge.id)
          .update(challenge.toFirestore());
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating challenge: $e');
      rethrow;
    }
  }

  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _firestore.collection('challengePool').doc(challengeId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting challenge: $e');
      rethrow;
    }
  }

  Future<void> toggleChallengeActive(String challengeId, bool isActive) async {
    try {
      await _firestore
          .collection('challengePool')
          .doc(challengeId)
          .update({'isActive': isActive});
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling challenge: $e');
      rethrow;
    }
  }

  Future<void> forceRefreshActiveChallenges() async {
    try {
      final batch = _firestore.batch();
      final activeDocs = await _firestore.collection('activeChallenges').get();
      for (final doc in activeDocs.docs) batch.delete(doc.reference);
      await batch.commit();
      _isInitialized = false;
      _cachedTodayKey = null; // Force full reload next time
      debugPrint('✅ Active challenges cleared');
    } catch (e) {
      debugPrint('Error force refreshing: $e');
      rethrow;
    }
  }
}
