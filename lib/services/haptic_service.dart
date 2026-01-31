import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized haptic feedback service for consistent tactile feedback
/// Respects user's vibration preference from settings
class HapticService {
  static bool _vibrationEnabled = true;
  static bool _initialized = false;

  /// Initialize the service - call this once at app startup
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _vibrationEnabled = prefs.getBool('vibration') ?? true;
      _initialized = true;
      debugPrint('🎮 HapticService initialized. Vibration: $_vibrationEnabled');
    } catch (e) {
      debugPrint('⚠️ HapticService init failed: $e');
      _vibrationEnabled = true;
    }
  }

  /// Update vibration setting (call when user changes setting)
  static void setEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    debugPrint('🎮 Haptic feedback ${enabled ? "enabled" : "disabled"}');
  }

  /// Check if haptic should fire
  static bool get _shouldVibrate {
    if (kIsWeb) return false;  // No haptics on web
    return _vibrationEnabled;
  }

  // ==================== BASE METHODS ====================

  /// Light tap feedback - for button taps, selections
  static Future<void> lightTap() async {
    if (!_shouldVibrate) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  /// Medium tap feedback - for successful actions
  static Future<void> mediumTap() async {
    if (!_shouldVibrate) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  /// Heavy tap feedback - for major achievements, errors
  static Future<void> heavyTap() async {
    if (!_shouldVibrate) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  /// Selection click - for toggle switches, checkboxes
  static Future<void> selectionClick() async {
    if (!_shouldVibrate) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  /// Vibrate pattern - for notifications, alerts
  static Future<void> vibrate() async {
    if (!_shouldVibrate) return;
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  // ==================== CONTEXTUAL METHODS ====================

  /// Button tap - standard button press
  static Future<void> buttonTap() async => await lightTap();

  /// Success feedback - lesson complete, quiz correct
  static Future<void> success() async => await mediumTap();

  /// Achievement unlocked - badges, milestones
  static Future<void> achievement() async => await heavyTap();

  /// Error feedback - wrong answer, failed action
  static Future<void> error() async => await heavyTap();

  /// Streak milestone - streak achievements
  static Future<void> streakMilestone() async => await heavyTap();

  /// XP earned - when XP is added
  static Future<void> xpEarned() async => await lightTap();

  /// Level up - when user levels up
  static Future<void> levelUp() async => await heavyTap();

  /// Correct answer in quiz
  static Future<void> correctAnswer() async => await mediumTap();

  /// Wrong answer in quiz
  static Future<void> wrongAnswer() async => await heavyTap();

  /// Challenge completed
  static Future<void> challengeComplete() async => await heavyTap();

  /// Toggle switch changed
  static Future<void> toggle() async => await selectionClick();

  /// Swipe action - for swipe gestures
  static Future<void> swipe() async => await lightTap();

  /// Refresh action - pull to refresh
  static Future<void> refresh() async => await lightTap();

  /// Navigation - screen transitions
  static Future<void> navigate() async => await lightTap();

  /// Warning feedback
  static Future<void> warning() async => await mediumTap();

  /// Streak freeze used
  static Future<void> streakFreezeUsed() async => await mediumTap();

  /// Certificate generated
  static Future<void> certificateGenerated() async => await heavyTap();

  /// Badge unlocked
  static Future<void> badgeUnlocked() async => await heavyTap();

  /// Friend request sent/received
  static Future<void> socialInteraction() async => await mediumTap();

  /// Download complete
  static Future<void> downloadComplete() async => await mediumTap();
}