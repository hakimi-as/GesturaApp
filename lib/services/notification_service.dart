import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification channels
  static const String _channelIdGeneral = 'gestura_general';
  static const String _channelIdReminders = 'gestura_reminders';
  static const String _channelIdStreaks = 'gestura_streaks';
  static const String _channelIdAchievements = 'gestura_achievements';

  // Notification IDs (fixed IDs for scheduled notifications)
  static const int _idDailyReminder = 1001;
  static const int _idStreakAtRisk = 1002;

  // Notification settings keys
  static const String _keyPushEnabled = 'notifications_push_enabled';
  static const String _keyStreakReminder = 'notifications_streak_reminder';
  static const String _keyDailyGoals = 'notifications_daily_goals';
  static const String _keyAchievements = 'notifications_achievements';
  static const String _keyChallenges = 'notifications_challenges';
  static const String _keyReminderTime = 'notifications_reminder_time';
  static const String _keyDailyReminderEnabled = 'notifications_daily_reminder_enabled';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone for scheduled notifications
    tz_data.initializeTimeZones();

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure FCM handlers
    _configureFCMHandlers();

    _isInitialized = true;
    debugPrint('🔔 NotificationService initialized');
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (!kIsWeb && Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // General channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelIdGeneral,
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    );

    // Reminders channel (high importance for daily reminders)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelIdReminders,
        'Daily Reminders',
        description: 'Daily learning reminders',
        importance: Importance.high,
        playSound: true,
      ),
    );

    // Streaks channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelIdStreaks,
        'Streak Alerts',
        description: 'Streak protection alerts',
        importance: Importance.high,
        playSound: true,
      ),
    );

    // Achievements channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelIdAchievements,
        'Achievements',
        description: 'Badge and achievement notifications',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );
  }

  void _configureFCMHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app opened from terminated state)
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state with message');
      _handleMessageOpenedApp(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground message received: ${message.notification?.title}');

    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'Gestura',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📬 Message opened app: ${message.notification?.title}');
    // TODO: Handle navigation based on message data
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // TODO: Handle navigation based on payload
  }

  // ============ PUBLIC METHODS ============

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
    String channelId = _channelIdGeneral,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool(_keyPushEnabled) ?? true;

    if (!pushEnabled) return;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: 'Gestura notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case _channelIdReminders:
        return 'Daily Reminders';
      case _channelIdStreaks:
        return 'Streak Alerts';
      case _channelIdAchievements:
        return 'Achievements';
      default:
        return 'General Notifications';
    }
  }

  // ============ SCHEDULED NOTIFICATIONS ============

  /// Schedule a daily reminder at a specific time
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = 'Time to Learn! 🤟',
    String body = 'Keep your streak going! Practice sign language today.',
  }) async {
    // Cancel existing reminder first
    await cancelDailyReminder();

    // Save settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReminderTime, '$hour:$minute');
    await prefs.setBool(_keyDailyReminderEnabled, true);

    // Calculate next occurrence
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      _channelIdReminders,
      'Daily Reminders',
      channelDescription: 'Daily learning reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.zonedSchedule(
      _idDailyReminder,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily!
      payload: 'daily_reminder',
    );

    debugPrint('📅 Daily reminder scheduled for $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Cancel the daily reminder
  Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(_idDailyReminder);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyReminderEnabled, false);
    debugPrint('📅 Daily reminder cancelled');
  }

  /// Check if daily reminder is enabled
  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyReminderEnabled) ?? false;
  }

  /// Schedule streak at risk reminder for 8 PM (if user hasn't practiced today)
  Future<void> scheduleStreakAtRiskReminder({int currentStreak = 0}) async {
    // Cancel any existing one first
    await cancelStreakAtRiskReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 8 PM
      0,
    );

    // Don't schedule if already past 8 PM
    if (scheduledDate.isBefore(now)) {
      debugPrint('📅 Past 8 PM, not scheduling streak reminder');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _channelIdStreaks,
      'Streak Alerts',
      channelDescription: 'Streak protection alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final streakText = currentStreak > 0 ? '$currentStreak-day ' : '';
    
    await _localNotifications.zonedSchedule(
      _idStreakAtRisk,
      'Your Streak is at Risk! 🔥',
      'Don\'t lose your ${streakText}streak! Complete a lesson before midnight.',
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'streak_at_risk',
    );

    debugPrint('📅 Streak at risk reminder scheduled for 8 PM');
  }

  /// Cancel streak at risk reminder (call when user completes a lesson)
  Future<void> cancelStreakAtRiskReminder() async {
    await _localNotifications.cancel(_idStreakAtRisk);
    debugPrint('📅 Streak at risk reminder cancelled');
  }

  // ============ SPECIFIC NOTIFICATION TYPES ============

  Future<void> showStreakReminder(int currentStreak) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyStreakReminder) ?? true;

    if (!enabled) return;

    await showLocalNotification(
      id: 1,
      title: '🔥 Don\'t lose your streak!',
      body: 'You have a $currentStreak day streak. Learn today to keep it going!',
      payload: 'streak_reminder',
      channelId: _channelIdStreaks,
    );
  }

  Future<void> showDailyGoalReminder(int goalsCompleted, int totalGoals) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyDailyGoals) ?? true;

    if (!enabled) return;

    final remaining = totalGoals - goalsCompleted;
    await showLocalNotification(
      id: 2,
      title: '🎯 Daily Goals Reminder',
      body: 'You have $remaining goals left to complete today. Keep going!',
      payload: 'daily_goals',
      channelId: _channelIdReminders,
    );
  }

  Future<void> showAchievementUnlocked(String badgeName, int xpReward) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyAchievements) ?? true;

    if (!enabled) return;

    await showLocalNotification(
      id: 3,
      title: '🏆 Achievement Unlocked!',
      body: 'You earned "$badgeName" and +$xpReward XP!',
      payload: 'achievement',
      channelId: _channelIdAchievements,
    );
  }

  Future<void> showChallengeCompleted(String challengeName, int xpReward) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyChallenges) ?? true;

    if (!enabled) return;

    await showLocalNotification(
      id: 4,
      title: '🎯 Challenge Completed!',
      body: 'You completed "$challengeName" and earned +$xpReward XP!',
      payload: 'challenge',
      channelId: _channelIdAchievements,
    );
  }

  Future<void> showNewChallengeAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyChallenges) ?? true;

    if (!enabled) return;

    await showLocalNotification(
      id: 5,
      title: '🎯 New Challenges Available!',
      body: 'New daily challenges are ready. Complete them for bonus XP!',
      payload: 'new_challenge',
      channelId: _channelIdGeneral,
    );
  }

  Future<void> showLevelUp(int newLevel) async {
    await showLocalNotification(
      id: 6,
      title: '🎉 Level Up!',
      body: 'Congratulations! You reached Level $newLevel!',
      payload: 'level_up',
      channelId: _channelIdAchievements,
    );
  }

  /// Show streak freeze used notification
  Future<void> showStreakFreezeUsed(int remainingFreezes, int streakProtected) async {
    await showLocalNotification(
      id: 7,
      title: '🧊 Streak Protected!',
      body: 'Your $streakProtected-day streak was saved by a freeze! $remainingFreezes freeze${remainingFreezes == 1 ? '' : 's'} remaining.',
      payload: 'streak_freeze_used',
      channelId: _channelIdStreaks,
    );
  }

  /// Show streak milestone notification
  Future<void> showStreakMilestone(int streakDays) async {
    await showLocalNotification(
      id: 8,
      title: '🔥 Streak Milestone!',
      body: 'Amazing! You\'ve reached a $streakDays day streak! Keep it up!',
      payload: 'streak_milestone',
      channelId: _channelIdAchievements,
    );
  }

  /// Show new content available notification
  Future<void> showNewContentAvailable(String contentName) async {
    await showLocalNotification(
      id: 9,
      title: '📚 New Content Available!',
      body: 'Check out the new "$contentName" lessons!',
      payload: 'new_content',
      channelId: _channelIdGeneral,
    );
  }

  // ============ SETTINGS MANAGEMENT ============

  Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'push_enabled': prefs.getBool(_keyPushEnabled) ?? true,
      'streak_reminder': prefs.getBool(_keyStreakReminder) ?? true,
      'daily_goals': prefs.getBool(_keyDailyGoals) ?? true,
      'achievements': prefs.getBool(_keyAchievements) ?? true,
      'challenges': prefs.getBool(_keyChallenges) ?? true,
      'daily_reminder_enabled': prefs.getBool(_keyDailyReminderEnabled) ?? false,
    };
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    String prefKey;

    switch (key) {
      case 'push_enabled':
        prefKey = _keyPushEnabled;
        break;
      case 'streak_reminder':
        prefKey = _keyStreakReminder;
        break;
      case 'daily_goals':
        prefKey = _keyDailyGoals;
        break;
      case 'achievements':
        prefKey = _keyAchievements;
        break;
      case 'challenges':
        prefKey = _keyChallenges;
        break;
      case 'daily_reminder_enabled':
        prefKey = _keyDailyReminderEnabled;
        if (!value) {
          await cancelDailyReminder();
        }
        break;
      default:
        return;
    }

    await prefs.setBool(prefKey, value);
  }

  Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_keyReminderTime);

    if (timeString != null) {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return const TimeOfDay(hour: 19, minute: 0); // Default 7:00 PM
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReminderTime, '${time.hour}:${time.minute}');
    
    // If daily reminder is enabled, reschedule with new time
    final isEnabled = await isDailyReminderEnabled();
    if (isEnabled) {
      await scheduleDailyReminder(hour: time.hour, minute: time.minute);
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}