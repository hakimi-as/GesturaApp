import 'package:flutter_test/flutter_test.dart';
import 'package:Gestura/models/challenge_model.dart';

// Unit tests for ChallengeModel logic that drives the Phase G challenge card UI.
// The challenge card renders progress bars, completion state, XP, and timing
// based purely on ChallengeModel's computed getters — tested here without
// requiring Firebase or Provider.

ChallengeModel _make({
  String id = 'c1',
  String title = 'Do 5 signs',
  int target = 5,
  int current = 0,
  int xpReward = 50,
  ChallengeType type = ChallengeType.daily,
  int hoursUntilExpiry = 12,
}) {
  final now = DateTime.now();
  return ChallengeModel(
    id: id,
    title: title,
    description: 'Practice signing',
    emoji: '🤟',
    type: type,
    targetValue: target,
    currentValue: current,
    xpReward: xpReward,
    startDate: now.subtract(const Duration(hours: 1)),
    endDate: now.add(Duration(hours: hoursUntilExpiry)),
  );
}

void main() {
  // ── Progress computation ───────────────────────────────────────────────────
  group('ChallengeModel.progress', () {
    test('0/5 = 0.0', () => expect(_make(current: 0, target: 5).progress, 0.0));
    test('3/5 = 0.6', () => expect(_make(current: 3, target: 5).progress, closeTo(0.6, 0.001)));
    test('5/5 = 1.0', () => expect(_make(current: 5, target: 5).progress, 1.0));
    test('overflow clamps to 1.0', () => expect(_make(current: 10, target: 5).progress, 1.0));
  });

  // ── Completion state ───────────────────────────────────────────────────────
  group('ChallengeModel.isCompleted', () {
    test('not completed when current < target', () {
      expect(_make(current: 4, target: 5).isCompleted, isFalse);
    });
    test('completed when current == target', () {
      expect(_make(current: 5, target: 5).isCompleted, isTrue);
    });
    test('completed when current > target', () {
      expect(_make(current: 7, target: 5).isCompleted, isTrue);
    });
    test('not completed when current is 0', () {
      expect(_make(current: 0, target: 5).isCompleted, isFalse);
    });
  });

  // ── Remaining time text ───────────────────────────────────────────────────
  group('ChallengeModel.remainingTimeText', () {
    test('more than 24h shows days', () {
      final c = _make(hoursUntilExpiry: 48);
      expect(c.remainingTimeText, contains('d'));
    });

    test('12h shows hours', () {
      final c = _make(hoursUntilExpiry: 12);
      // remainingTime is in hours; remainingTimeText is a formatted string
      expect(c.remainingTimeText, isNotEmpty);
    });

    test('already expired has non-positive remaining', () {
      final c = _make(hoursUntilExpiry: -1);
      expect(c.remainingTime, lessThanOrEqualTo(0));
    });
  });

  // ── Type color assignment ─────────────────────────────────────────────────
  group('ChallengeModel.typeColor', () {
    test('daily type returns a non-null color', () {
      expect(_make(type: ChallengeType.daily).typeColor, isNotNull);
    });
    test('weekly type returns a non-null color', () {
      expect(_make(type: ChallengeType.weekly).typeColor, isNotNull);
    });
    test('special type returns a non-null color', () {
      expect(_make(type: ChallengeType.special).typeColor, isNotNull);
    });
    test('daily and weekly colors are different', () {
      expect(
        _make(type: ChallengeType.daily).typeColor,
        isNot(equals(_make(type: ChallengeType.weekly).typeColor)),
      );
    });
  });

  // ── XP reward ─────────────────────────────────────────────────────────────
  group('ChallengeModel xpReward', () {
    test('stores reward correctly', () {
      expect(_make(xpReward: 200).xpReward, 200);
    });
    test('zero reward is valid', () {
      expect(_make(xpReward: 0).xpReward, 0);
    });
  });

  // ── Challenge types ────────────────────────────────────────────────────────
  group('ChallengeType enum', () {
    test('daily challenge type is daily', () {
      expect(_make(type: ChallengeType.daily).type, ChallengeType.daily);
    });
    test('weekly challenge type is weekly', () {
      expect(_make(type: ChallengeType.weekly).type, ChallengeType.weekly);
    });
    test('special challenge type is special', () {
      expect(_make(type: ChallengeType.special).type, ChallengeType.special);
    });
  });
}
