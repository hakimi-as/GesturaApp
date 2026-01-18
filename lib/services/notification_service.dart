import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification channels
  static const String _channelId = 'gestura_notifications';
  static const String _channelName = 'Gestura Notifications';
  static const String _channelDesc = 'Notifications from Gestura app';

  // Notification settings keys
  static const String _keyPushEnabled = 'notifications_push_enabled';
  static const String _keyStreakReminder = 'notifications_streak_reminder';
  static const String _keyDailyGoals = 'notifications_daily_goals';
  static const String _keyAchievements = 'notifications_achievements';
  static const String _keyChallenges = 'notifications_challenges';
  static const String _keyReminderTime = 'notifications_reminder_time';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure FCM handlers
    _configureFCMHandlers();

    _isInitialized = true;
    debugPrint('NotificationService initialized');
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

    debugPrint('Notification permission: ${settings.authorizationStatus}');
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

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
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
    debugPrint('Foreground message received: ${message.notification?.title}');

    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'Gestura',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.notification?.title}');
    // Handle navigation based on message data
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool(_keyPushEnabled) ?? true;

    if (!pushEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
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

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
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
    );
  }

  Future<void> showLevelUp(int newLevel) async {
    await showLocalNotification(
      id: 6,
      title: '🎉 Level Up!',
      body: 'Congratulations! You reached Level $newLevel!',
      payload: 'level_up',
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