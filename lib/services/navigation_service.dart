import 'package:flutter/material.dart';

import '../screens/badges/badges_screen.dart';
import '../screens/challenges/challenges_screen.dart';
import '../screens/learn/learn_screen.dart';
import '../screens/progress/progress_screen.dart';

/// Holds the global navigator key and maps notification payloads to screens.
class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Navigates to the screen matching [payload]. No-ops if the navigator is
  /// not ready or the payload has no known destination.
  static void navigateToPayload(String payload) {
    final widget = widgetForPayload(payload);
    if (widget == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => widget));
  }

  /// Handles an FCM data map. Checks for an explicit 'route' key first,
  /// then falls back to the 'type' key.
  static void navigateFromFcmData(Map<String, dynamic> data) {
    final payload = (data['route'] as String?) ?? (data['type'] as String?) ?? '';
    navigateToPayload(payload);
  }

  /// Returns the destination widget for a notification payload string.
  /// Returns null when the payload needs no extra navigation (app just opens).
  /// Exposed for testing.
  static Widget? widgetForPayload(String payload) {
    switch (payload) {
      case 'daily_reminder':
      case 'new_content':
        return const LearnScreen(showBackButton: true);

      case 'streak_at_risk':
      case 'streak_reminder':
      case 'streak_freeze_used':
      case 'streak_milestone':
      case 'daily_goals':
      case 'level_up':
        return const ProgressScreen();

      case 'achievement':
        return const BadgesScreen();

      case 'challenge':
      case 'new_challenge':
        return const ChallengesScreen();

      default:
        return null;
    }
  }
}
