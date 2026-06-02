import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Gestura/config/theme.dart';
import 'package:Gestura/models/badge_model.dart';
import 'package:Gestura/widgets/badges/badge_card.dart';

final _testBadge = BadgeModel(
  id: 'badge_test',
  name: 'First Steps',
  description: 'Complete your first lesson',
  icon: '👣',
  tier: BadgeTier.bronze,
  category: BadgeCategory.learning,
  requirement: 1,
  xpReward: 50,
);

final _unlockedBadge = BadgeModel(
  id: 'badge_unlocked',
  name: 'Scholar',
  description: 'Complete 10 lessons',
  icon: '🎓',
  tier: BadgeTier.gold,
  category: BadgeCategory.learning,
  requirement: 10,
  xpReward: 200,
  unlockedAt: DateTime(2024, 6, 1),
);

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('BadgeCard widget', () {
    testWidgets('compact locked badge renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        BadgeCard(badge: _testBadge, isUnlocked: false, compact: true),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact unlocked badge renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        BadgeCard(badge: _unlockedBadge, isUnlocked: true, compact: true),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('full badge card shows name and description', (tester) async {
      await tester.pumpWidget(_wrap(
        BadgeCard(badge: _testBadge, isUnlocked: false, compact: false),
      ));

      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('Complete your first lesson'), findsOneWidget);
    });

    testWidgets('unlocked badge shows xp reward', (tester) async {
      await tester.pumpWidget(_wrap(
        BadgeCard(badge: _unlockedBadge, isUnlocked: true, compact: false),
      ));

      expect(find.textContaining('200 XP'), findsOneWidget);
    });

    testWidgets('onTap callback is called on tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        BadgeCard(
          badge: _testBadge,
          isUnlocked: false,
          compact: true,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(BadgeCard));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
