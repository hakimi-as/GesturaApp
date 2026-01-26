import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Centralized haptic feedback service for consistent tactile feedback
class HapticService {
  /// Light tap feedback - for button taps, selections
  static Future<void> lightTap() async {
    if (kIsWeb) return; // No haptics on web
    await HapticFeedback.lightImpact();
  }

  /// Medium tap feedback - for successful actions
  static Future<void> mediumTap() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap feedback - for major achievements, errors
  static Future<void> heavyTap() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection click - for toggle switches, checkboxes
  static Future<void> selectionClick() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibrate pattern - for notifications, alerts
  static Future<void> vibrate() async {
    if (kIsWeb) return;
    await HapticFeedback.vibrate();
  }

  // ==================== CONTEXTUAL METHODS ====================

  /// Button tap - standard button press
  static Future<void> buttonTap() async {
    await lightTap();
  }

  /// Success feedback - lesson complete, quiz correct
  static Future<void> success() async {
    await mediumTap();
  }

  /// Achievement unlocked - badges, milestones
  static Future<void> achievement() async {
    await heavyTap();
  }

  /// Error feedback - wrong answer, failed action
  static Future<void> error() async {
    await heavyTap();
  }

  /// Streak milestone - streak achievements
  static Future<void> streakMilestone() async {
    await heavyTap();
  }

  /// XP earned - when XP is added
  static Future<void> xpEarned() async {
    await lightTap();
  }

  /// Level up - when user levels up
  static Future<void> levelUp() async {
    await heavyTap();
  }

  /// Correct answer in quiz
  static Future<void> correctAnswer() async {
    await mediumTap();
  }

  /// Wrong answer in quiz
  static Future<void> wrongAnswer() async {
    await heavyTap();
  }

  /// Challenge completed
  static Future<void> challengeComplete() async {
    await heavyTap();
  }

  /// Toggle switch changed
  static Future<void> toggle() async {
    await selectionClick();
  }

  /// Swipe action - for swipe gestures
  static Future<void> swipe() async {
    await lightTap();
  }

  /// Refresh action - pull to refresh
  static Future<void> refresh() async {
    await lightTap();
  }

  /// Navigation - screen transitions
  static Future<void> navigate() async {
    await lightTap();
  }

  /// Warning feedback
  static Future<void> warning() async {
    await mediumTap();
  }

  /// Streak freeze used
  static Future<void> streakFreezeUsed() async {
    await mediumTap();
  }

  /// Certificate generated
  static Future<void> certificateGenerated() async {
    await heavyTap();
  }

  /// Badge unlocked
  static Future<void> badgeUnlocked() async {
    await heavyTap();
  }

  /// Friend request sent/received
  static Future<void> socialInteraction() async {
    await mediumTap();
  }

  /// Download complete
  static Future<void> downloadComplete() async {
    await mediumTap();
  }
}


// ==================== EXTENSION FOR EASY ACCESS ====================

/// Extension to add haptic feedback to GestureDetector easily
/// Usage: GestureDetector(onTap: () => myAction().withHaptic())

extension HapticExtension on Future<void> Function() {
  Future<void> Function() withLightHaptic() {
    return () async {
      await HapticService.lightTap();
      await this();
    };
  }

  Future<void> Function() withMediumHaptic() {
    return () async {
      await HapticService.mediumTap();
      await this();
    };
  }

  Future<void> Function() withHeavyHaptic() {
    return () async {
      await HapticService.heavyTap();
      await this();
    };
  }
}