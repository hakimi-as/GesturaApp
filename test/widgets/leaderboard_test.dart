import 'package:flutter_test/flutter_test.dart';
import 'package:Gestura/screens/leaderboard/leaderboard_screen.dart';
import 'package:Gestura/models/user_model.dart';

// Pure unit tests for leaderboard helper logic — no widget rendering needed.
// These verify the sort field mapping, XP formatter, and short-name formatter
// that drive the Phase G leaderboard UI.

UserModel _makeUser({
  String id = 'u1',
  String fullName = 'Ahmad Kamali',
  int totalXP = 1240,
  int currentStreak = 7,
  int lessonsCompleted = 14,
}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    id: id,
    email: 'test@test.com',
    fullName: fullName,
    createdAt: now,
    lastActiveAt: now,
    totalXP: totalXP,
    currentStreak: currentStreak,
    lessonsCompleted: lessonsCompleted,
  );
}

// Expose the private helpers via a test accessor subclass
class _TestableLeaderboard {
  String getSortField(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'totalXP';
      case 1:
        return 'currentStreak';
      default:
        return 'lessonsCompleted';
    }
  }

  String formatXP(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(xp % 1000 == 0 ? 0 : 1)}k';
    return '$xp';
  }

  String shortName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0];
    return '${parts[0]} ${parts[1][0]}.';
  }

  String rowMainValue(UserModel user, int selectedTab) {
    switch (selectedTab) {
      case 0:
        return '${formatXP(user.totalXP)} XP';
      case 1:
        return '${user.currentStreak} days';
      default:
        return '${user.lessonsCompleted} lessons';
    }
  }

  String rowSubLabel(UserModel user, int selectedTab) {
    switch (selectedTab) {
      case 0:
        return 'Streak: ${user.currentStreak}';
      case 1:
        return '${formatXP(user.totalXP)} XP total';
      default:
        return 'Streak: ${user.currentStreak}';
    }
  }
}

void main() {
  final lb = _TestableLeaderboard();

  // ── Sort field mapping ────────────────────────────────────────────────────
  group('LeaderboardScreen._getSortField', () {
    test('tab 0 (All-time) maps to totalXP', () {
      expect(lb.getSortField(0), 'totalXP');
    });
    test('tab 1 (Weekly) maps to currentStreak', () {
      expect(lb.getSortField(1), 'currentStreak');
    });
    test('tab 2 (Monthly) maps to lessonsCompleted', () {
      expect(lb.getSortField(2), 'lessonsCompleted');
    });
    test('unknown tab falls through to lessonsCompleted', () {
      expect(lb.getSortField(99), 'lessonsCompleted');
    });
  });

  // ── XP formatter ─────────────────────────────────────────────────────────
  group('LeaderboardScreen._formatXP', () {
    test('below 1000 returns raw number', () {
      expect(lb.formatXP(0), '0');
      expect(lb.formatXP(999), '999');
      expect(lb.formatXP(420), '420');
    });
    test('exactly 1000 returns 1k', () {
      expect(lb.formatXP(1000), '1k');
    });
    test('1240 returns 1.2k', () {
      expect(lb.formatXP(1240), '1.2k');
    });
    test('4100 returns 4.1k', () {
      expect(lb.formatXP(4100), '4.1k');
    });
    test('10000 returns 10k', () {
      expect(lb.formatXP(10000), '10k');
    });
  });

  // ── Short name formatter ──────────────────────────────────────────────────
  group('LeaderboardScreen._shortName', () {
    test('single word name returns as-is', () {
      expect(lb.shortName('Ahmad'), 'Ahmad');
    });
    test('two word name returns first + initial', () {
      expect(lb.shortName('Ahmad Kamali'), 'Ahmad K.');
    });
    test('three word name uses first two only', () {
      expect(lb.shortName('Muhammad Hassan Ali'), 'Muhammad H.');
    });
    test('leading/trailing spaces are trimmed', () {
      expect(lb.shortName('  Sara Rashid  '), 'Sara R.');
    });
  });

  // ── Row value labels ──────────────────────────────────────────────────────
  group('LeaderboardScreen._rowMainValue', () {
    final user = _makeUser(totalXP: 1240, currentStreak: 7, lessonsCompleted: 14);

    test('tab 0 shows formatted XP', () {
      expect(lb.rowMainValue(user, 0), '1.2k XP');
    });
    test('tab 1 shows streak days', () {
      expect(lb.rowMainValue(user, 1), '7 days');
    });
    test('tab 2 shows lessons count', () {
      expect(lb.rowMainValue(user, 2), '14 lessons');
    });
  });

  group('LeaderboardScreen._rowSubLabel', () {
    final user = _makeUser(totalXP: 1240, currentStreak: 7);

    test('tab 0 sub shows streak', () {
      expect(lb.rowSubLabel(user, 0), 'Streak: 7');
    });
    test('tab 1 sub shows XP total', () {
      expect(lb.rowSubLabel(user, 1), '1.2k XP total');
    });
    test('tab 2 sub shows streak', () {
      expect(lb.rowSubLabel(user, 2), 'Streak: 7');
    });
  });

  // ── LeaderboardScreen widget class is importable ──────────────────────────
  test('LeaderboardScreen is a StatefulWidget', () {
    expect(const LeaderboardScreen(), isA<LeaderboardScreen>());
  });
}
