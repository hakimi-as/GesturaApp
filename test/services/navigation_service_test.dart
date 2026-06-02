import 'package:flutter_test/flutter_test.dart';
import 'package:Gestura/services/navigation_service.dart';
import 'package:Gestura/screens/learn/learn_screen.dart';
import 'package:Gestura/screens/progress/enhanced_progress_screen.dart';
import 'package:Gestura/screens/badges/badges_screen.dart';
import 'package:Gestura/screens/challenges/challenges_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('NavigationService.widgetForPayload', () {
    test('daily_reminder routes to LearnScreen', () {
      expect(NavigationService.widgetForPayload('daily_reminder'), isA<LearnScreen>());
    });

    test('new_content routes to LearnScreen', () {
      expect(NavigationService.widgetForPayload('new_content'), isA<LearnScreen>());
    });

    test('LearnScreen from notification has showBackButton = true', () {
      final w = NavigationService.widgetForPayload('daily_reminder') as LearnScreen;
      expect(w.showBackButton, isTrue);
    });

    test('streak_at_risk routes to EnhancedProgressScreen', () {
      expect(NavigationService.widgetForPayload('streak_at_risk'), isA<EnhancedProgressScreen>());
    });

    test('streak_reminder routes to EnhancedProgressScreen', () {
      expect(NavigationService.widgetForPayload('streak_reminder'), isA<EnhancedProgressScreen>());
    });

    test('streak_freeze_used routes to EnhancedProgressScreen', () {
      expect(NavigationService.widgetForPayload('streak_freeze_used'), isA<EnhancedProgressScreen>());
    });

    test('streak_milestone routes to EnhancedProgressScreen', () {
      expect(NavigationService.widgetForPayload('streak_milestone'), isA<EnhancedProgressScreen>());
    });

    test('daily_goals routes to EnhancedProgressScreen', () {
      expect(NavigationService.widgetForPayload('daily_goals'), isA<EnhancedProgressScreen>());
    });

    test('level_up routes to EnhancedProgressScreen', () {
      expect(NavigationService.widgetForPayload('level_up'), isA<EnhancedProgressScreen>());
    });

    test('achievement routes to BadgesScreen', () {
      expect(NavigationService.widgetForPayload('achievement'), isA<BadgesScreen>());
    });

    test('challenge routes to ChallengesScreen', () {
      expect(NavigationService.widgetForPayload('challenge'), isA<ChallengesScreen>());
    });

    test('new_challenge routes to ChallengesScreen', () {
      expect(NavigationService.widgetForPayload('new_challenge'), isA<ChallengesScreen>());
    });

    test('unknown payload returns null', () {
      expect(NavigationService.widgetForPayload('unknown_type'), isNull);
    });

    test('empty payload returns null', () {
      expect(NavigationService.widgetForPayload(''), isNull);
    });
  });

  group('NavigationService.navigateFromFcmData', () {
    test('uses route key when present', () {
      // We can only verify this does not throw — real navigation needs a context.
      expect(
        () => NavigationService.navigateFromFcmData({'route': 'achievement'}),
        returnsNormally,
      );
    });

    test('falls back to type key when route is absent', () {
      expect(
        () => NavigationService.navigateFromFcmData({'type': 'new_challenge'}),
        returnsNormally,
      );
    });

    test('handles empty data map without throwing', () {
      expect(
        () => NavigationService.navigateFromFcmData({}),
        returnsNormally,
      );
    });
  });
}
