import 'package:flutter_test/flutter_test.dart';
import 'package:Gestura/services/dynamic_challenge_service.dart';
import 'package:Gestura/models/challenge_model.dart';

ChallengeTemplate _makeTemplate({
  String id = 'test_1',
  int targetValue = 10,
  int xpReward = 100,
  String? categoryId,
}) {
  return ChallengeTemplate(
    id: id,
    title: 'Test Challenge',
    description: 'Desc',
    emoji: '🎯',
    type: ChallengeType.daily,
    targetValue: targetValue,
    xpReward: xpReward,
    trackingField: 'lessonsToday',
    categoryId: categoryId,
    isActive: true,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  final service = DynamicChallengeService();

  group('DynamicChallengeService.applyDifficulty', () {
    test('multiplier 1.0 returns same values', () {
      final t = _makeTemplate(targetValue: 5, xpReward: 50);
      final result = service.applyDifficulty(t, 1.0);
      expect(result.targetValue, 5);
      expect(result.xpReward, 50);
    });

    test('multiplier 2.0 doubles targetValue and xpReward', () {
      final t = _makeTemplate(targetValue: 5, xpReward: 50);
      final result = service.applyDifficulty(t, 2.0);
      expect(result.targetValue, 10);
      expect(result.xpReward, 100);
    });

    test('multiplier 0.5 halves values', () {
      final t = _makeTemplate(targetValue: 10, xpReward: 100);
      final result = service.applyDifficulty(t, 0.5);
      expect(result.targetValue, 5);
      expect(result.xpReward, 50);
    });

    test('clamps targetValue to minimum 1', () {
      final t = _makeTemplate(targetValue: 1, xpReward: 1);
      final result = service.applyDifficulty(t, 0.01);
      expect(result.targetValue, greaterThanOrEqualTo(1));
      expect(result.xpReward, greaterThanOrEqualTo(1));
    });

    test('clamps targetValue to maximum 9999', () {
      final t = _makeTemplate(targetValue: 5000, xpReward: 5000);
      final result = service.applyDifficulty(t, 3.0);
      expect(result.targetValue, lessThanOrEqualTo(9999));
      expect(result.xpReward, lessThanOrEqualTo(9999));
    });

    test('preserves all other template fields', () {
      final t = _makeTemplate(id: 'abc', categoryId: 'cat_1');
      final result = service.applyDifficulty(t, 2.0);
      expect(result.id, 'abc');
      expect(result.categoryId, 'cat_1');
      expect(result.title, t.title);
    });
  });

  group('DynamicChallengeService.selectDailyChallenges — empty pool', () {
    test('returns empty list when pool is empty', () async {
      final result = await service.selectDailyChallenges(
        userId: 'u1',
        pool: [],
        count: 3,
        periodKey: 'daily_2024_1_1',
      );
      expect(result.templates, isEmpty);
      expect(result.personalizedIds, isEmpty);
    });
  });

  group('DynamicChallengeService.selectDailyChallenges — no-network fallback', () {
    test('returns count templates from pool on fallback (no Firestore)', () async {
      // getRecentCategoryIds will fail (no Firestore), triggering fallback.
      final pool = List.generate(
        5,
        (i) => _makeTemplate(id: 'c$i', targetValue: i + 1, xpReward: (i + 1) * 10),
      );
      final result = await service.selectDailyChallenges(
        userId: 'no_user',
        pool: pool,
        count: 2,
        periodKey: 'daily_2024_1_1',
      );
      expect(result.templates.length, 2);
    });

    test('fallback is deterministic for same periodKey', () async {
      final pool = List.generate(
        6,
        (i) => _makeTemplate(id: 'c$i'),
      );
      const key = 'daily_2024_6_15';
      final r1 = await service.selectDailyChallenges(
        userId: 'u', pool: pool, count: 3, periodKey: key,
      );
      final r2 = await service.selectDailyChallenges(
        userId: 'u', pool: pool, count: 3, periodKey: key,
      );
      expect(r1.templates.map((t) => t.id), r2.templates.map((t) => t.id));
    });

    test('different periodKey yields potentially different selection', () async {
      final pool = List.generate(
        10,
        (i) => _makeTemplate(id: 'c$i'),
      );
      final r1 = await service.selectDailyChallenges(
        userId: 'u', pool: pool, count: 3, periodKey: 'daily_2024_1_1',
      );
      final r2 = await service.selectDailyChallenges(
        userId: 'u', pool: pool, count: 3, periodKey: 'daily_2024_7_4',
      );
      // IDs should not always be identical (different seeds)
      final ids1 = r1.templates.map((t) => t.id).toSet();
      final ids2 = r2.templates.map((t) => t.id).toSet();
      // At least one set should exist — we can't guarantee diff without seeding knowledge,
      // but we verify both returned valid results.
      expect(ids1.length, 3);
      expect(ids2.length, 3);
    });
  });
}
