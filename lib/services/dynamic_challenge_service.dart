import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/challenge_model.dart';

/// Holds the result of a personalized daily challenge selection.
class PersonalizedSelectionResult {
  final List<ChallengeTemplate> templates;

  /// IDs that were selected because they matched the user's recent categories.
  final Set<String> personalizedIds;

  const PersonalizedSelectionResult(this.templates, this.personalizedIds);
}

/// Provides three dynamic challenge features:
/// 1. Personalized selection — prefers categories the user has been learning.
/// 2. Difficulty adaptation — scales targetValue based on historical completion rate.
/// 3. Auto-generation — creates challenge templates from live Firestore categories.
class DynamicChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auto-generated template in-memory cache
  List<ChallengeTemplate> _cachedAutoTemplates = [];
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(hours: 12);

  bool get _cacheValid =>
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  // ── PUBLIC ENTRY POINT ────────────────────────────────────────────────────

  /// Selects [count] daily challenges from [pool] using personalization.
  /// Falls back to date-seeded random on any error.
  Future<PersonalizedSelectionResult> selectDailyChallenges({
    required String userId,
    required List<ChallengeTemplate> pool,
    required int count,
    required String periodKey,
  }) async {
    try {
      if (pool.isEmpty) return const PersonalizedSelectionResult([], {});

      final recentCategoryIds = await getRecentCategoryIds(userId: userId);
      final selected = _buildPersonalizedSelection(
        pool: pool,
        recentCategoryIds: recentCategoryIds,
        count: count,
        periodKey: periodKey,
      );

      final personalizedIds = <String>{};
      for (final t in selected) {
        if (t.categoryId != null && recentCategoryIds.contains(t.categoryId)) {
          personalizedIds.add(t.id);
        }
      }

      return PersonalizedSelectionResult(selected, personalizedIds);
    } catch (e) {
      debugPrint('⚠️ Dynamic selection failed, using fallback: $e');
      final rng = Random(periodKey.hashCode);
      final shuffled = List<ChallengeTemplate>.from(pool)..shuffle(rng);
      return PersonalizedSelectionResult(shuffled.take(count).toList(), {});
    }
  }

  // ── FEATURE 1: PERSONALIZATION ────────────────────────────────────────────

  /// Returns category IDs the user studied in the last [lookbackDays] days,
  /// ordered by total activity descending.
  Future<List<String>> getRecentCategoryIds({
    required String userId,
    int lookbackDays = 7,
  }) async {
    final Map<String, int> activity = {};
    final now = DateTime.now();

    for (int i = 0; i < lookbackDays; i++) {
      final date = now.subtract(Duration(days: i));
      final key = 'daily_${date.year}_${date.month}_${date.day}';
      try {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('challengeProgress')
            .doc(key)
            .get();
        if (!doc.exists) continue;

        for (final entry in doc.data()!.entries) {
          final k = entry.key;
          final v = entry.value;
          if (v is! int || v <= 0) continue;
          String? categoryId;
          if (k.startsWith('lessonsToday_')) {
            categoryId = k.substring('lessonsToday_'.length);
          } else if (k.startsWith('signsToday_')) {
            categoryId = k.substring('signsToday_'.length);
          }
          if (categoryId != null && categoryId.isNotEmpty) {
            activity[categoryId] = (activity[categoryId] ?? 0) + v;
          }
        }
      } catch (_) {
        continue;
      }
    }

    final sorted = activity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  List<ChallengeTemplate> _buildPersonalizedSelection({
    required List<ChallengeTemplate> pool,
    required List<String> recentCategoryIds,
    required int count,
    required String periodKey,
  }) {
    final rng = Random(periodKey.hashCode);

    if (recentCategoryIds.isEmpty) {
      final shuffled = List<ChallengeTemplate>.from(pool)..shuffle(rng);
      return shuffled.take(count).toList();
    }

    // Partition into category-relevant and general buckets
    final relevant = pool
        .where((t) =>
            t.categoryId != null && recentCategoryIds.contains(t.categoryId))
        .toList()
      ..shuffle(rng);
    final general = pool
        .where((t) =>
            t.categoryId == null || !recentCategoryIds.contains(t.categoryId))
        .toList()
      ..shuffle(rng);

    // 60% from relevant, 40% from general
    final relevantCount = (count * 0.6).ceil().clamp(0, relevant.length);
    final generalCount = (count - relevantCount).clamp(0, general.length);

    final selected = [
      ...relevant.take(relevantCount),
      ...general.take(generalCount),
    ];

    // Fill remaining slots if counts didn't add up
    if (selected.length < count) {
      final usedIds = selected.map((t) => t.id).toSet();
      final remaining = pool.where((t) => !usedIds.contains(t.id)).toList()
        ..shuffle(rng);
      selected.addAll(remaining.take(count - selected.length));
    }

    return selected;
  }

  // ── FEATURE 2: DIFFICULTY ADAPTATION ─────────────────────────────────────

  /// Reads the user's current difficulty multiplier (default 1.0).
  Future<double> getDifficultyMultiplier(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 1.0;
      return ((doc.data()!['challengeDifficultyMultiplier']) ?? 1.0).toDouble();
    } catch (_) {
      return 1.0;
    }
  }

  /// Returns a copy of [template] with targetValue and xpReward scaled by [multiplier].
  ChallengeTemplate applyDifficulty(
      ChallengeTemplate template, double multiplier) {
    if (multiplier == 1.0) return template;
    return template.copyWith(
      targetValue: (template.targetValue * multiplier).round().clamp(1, 9999),
      xpReward: (template.xpReward * multiplier).round().clamp(1, 9999),
    );
  }

  /// Checks yesterday's completion rate and updates the difficulty multiplier
  /// stored on the user doc. Runs at most once per day.
  Future<void> recalculateMultiplierIfNeeded({
    required String userId,
    required String yesterdayPeriodKey,
  }) async {
    try {
      // Guard: only run once per day
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final lastReset =
            userDoc.data()?['challengeLastResetDate'] as String?;
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month}-${now.day}';
        if (lastReset == todayStr) return;
      }

      final activeDoc = await _firestore
          .collection('activeChallenges')
          .doc(yesterdayPeriodKey)
          .get();
      if (!activeDoc.exists) return;

      final data = activeDoc.data()!;
      final challengeIds = List<String>.from(data['challengeIds'] ?? []);
      if (challengeIds.isEmpty) return;

      final storedMultiplier = (data['difficultyMultiplier'] ?? 1.0).toDouble();

      // Get yesterday's progress doc
      final progressKey = yesterdayPeriodKey.replaceAll('_type0', '');
      final progressDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challengeProgress')
          .doc(progressKey)
          .get();
      final progressData =
          progressDoc.exists ? progressDoc.data()! : <String, dynamic>{};

      int completedCount = 0;
      for (final id in challengeIds) {
        final templateDoc =
            await _firestore.collection('challengePool').doc(id).get();
        if (!templateDoc.exists) continue;
        final template = ChallengeTemplate.fromFirestore(templateDoc);
        final scaledTarget =
            (template.targetValue * storedMultiplier).round().clamp(1, 9999);
        final progress = (progressData[template.trackingField] ?? 0) as int;
        if (progress >= scaledTarget) completedCount++;
      }

      final completionRate = completedCount / challengeIds.length;
      final currentMultiplier = await getDifficultyMultiplier(userId);
      final newMultiplier = _adjustMultiplier(currentMultiplier, completionRate);

      final now = DateTime.now();
      await _firestore.collection('users').doc(userId).update({
        'challengeDifficultyMultiplier': newMultiplier,
        'challengeLastResetDate': '${now.year}-${now.month}-${now.day}',
      });

      debugPrint(
          '📊 Difficulty: ${currentMultiplier.toStringAsFixed(2)} → '
          '${newMultiplier.toStringAsFixed(2)} '
          '(${(completionRate * 100).toStringAsFixed(0)}% completion yesterday)');
    } catch (e) {
      debugPrint('⚠️ Could not update difficulty multiplier: $e');
    }
  }

  double _adjustMultiplier(double current, double completionRate) {
    if (completionRate > 0.8) return (current * 1.15).clamp(0.5, 3.0);
    if (completionRate < 0.4) return (current * 0.9).clamp(0.5, 3.0);
    return current;
  }

  // ── FEATURE 3: AUTO-GENERATED TEMPLATES ──────────────────────────────────

  /// Generates in-memory daily challenge templates from active Firestore categories.
  /// Results are cached for [_cacheTtl] to avoid repeated reads.
  Future<List<ChallengeTemplate>> generateCategoryTemplates() async {
    if (_cacheValid && _cachedAutoTemplates.isNotEmpty) {
      return _cachedAutoTemplates;
    }

    try {
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('categories')
            .where('isActive', isEqualTo: true)
            .limit(8)
            .get();
      } catch (_) {
        // Fallback if 'isActive' field doesn't exist
        snapshot = await _firestore.collection('categories').limit(8).get();
      }

      if (snapshot.docs.isEmpty) return [];

      final templates = <ChallengeTemplate>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final categoryId = doc.id;
        final categoryName =
            (data['name'] ?? data['title'] ?? 'Category') as String;
        final emoji = (data['emoji'] ?? '📚') as String;

        // Learn signs in this category
        templates.add(ChallengeTemplate(
          id: 'auto_signs_$categoryId',
          title: 'Learn $categoryName Signs',
          description: 'Learn 3 new signs in $categoryName today',
          emoji: emoji,
          type: ChallengeType.daily,
          targetValue: 3,
          xpReward: 45,
          trackingField: 'signsInCategoryToday',
          categoryId: categoryId,
          categoryName: categoryName,
          isActive: true,
          isAutoGenerated: true,
          createdAt: DateTime.now(),
        ));

        // Complete a lesson in this category
        templates.add(ChallengeTemplate(
          id: 'auto_lesson_$categoryId',
          title: '$categoryName Lesson',
          description: 'Complete a lesson in $categoryName',
          emoji: emoji,
          type: ChallengeType.daily,
          targetValue: 1,
          xpReward: 30,
          trackingField: 'lessonsInCategoryToday',
          categoryId: categoryId,
          categoryName: categoryName,
          isActive: true,
          isAutoGenerated: true,
          createdAt: DateTime.now(),
        ));
      }

      _cachedAutoTemplates = templates;
      _cacheTimestamp = DateTime.now();
      debugPrint(
          '🔄 Generated ${templates.length} auto-challenges '
          'from ${snapshot.docs.length} categories');
      return templates;
    } catch (e) {
      debugPrint('⚠️ Could not generate category templates: $e');
      return [];
    }
  }

  /// Returns up to [maxCount] auto-generated challenges relevant to the user's
  /// most active categories. These are supplementary to the normal challenge set.
  Future<List<ChallengeTemplate>> getSupplementaryTemplates({
    required String userId,
    int maxCount = 2,
  }) async {
    try {
      final allAuto = await generateCategoryTemplates();
      if (allAuto.isEmpty) return [];

      final recentCategoryIds = await getRecentCategoryIds(userId: userId);
      if (recentCategoryIds.isEmpty) return [];

      // Pick templates matching the user's top categories
      final relevant = allAuto
          .where((t) =>
              t.categoryId != null &&
              recentCategoryIds.contains(t.categoryId))
          .toList();

      // Prefer sign challenges over lesson challenges for variety
      final signs = relevant.where((t) => t.id.startsWith('auto_signs_')).toList();
      final lessons = relevant.where((t) => t.id.startsWith('auto_lesson_')).toList();

      final result = <ChallengeTemplate>[];
      if (signs.isNotEmpty) result.add(signs.first);
      if (result.length < maxCount && lessons.isNotEmpty) result.add(lessons.first);

      return result.take(maxCount).toList();
    } catch (e) {
      return [];
    }
  }
}
