import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Gestura/config/theme.dart';
import 'package:Gestura/widgets/cards/stat_card.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('StatCard widget', () {
    testWidgets('renders icon, value, and label', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(
          icon: '🔥',
          value: '42',
          label: 'Day Streak',
          color: Colors.orange,
        ),
      ));

      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Day Streak'), findsOneWidget);
    });

    testWidgets('renders with zero value without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(
          icon: '⭐',
          value: '0',
          label: 'Total XP',
          color: Colors.amber,
        ),
      ));

      expect(find.text('0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with long label without overflow error', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 120,
          child: StatCard(
            icon: '📚',
            value: '999',
            label: 'Very Long Label Text Here',
            color: Colors.blue,
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });
  });
}
