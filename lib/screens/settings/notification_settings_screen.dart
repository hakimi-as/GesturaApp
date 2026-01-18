import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  Map<String, bool> _settings = {};
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _notificationService.getNotificationSettings();
    final reminderTime = await _notificationService.getReminderTime();

    setState(() {
      _settings = settings;
      _reminderTime = reminderTime;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    setState(() {
      _settings[key] = value;
    });
    await _notificationService.updateNotificationSetting(key, value);
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: context.bgCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
      await _notificationService.setReminderTime(time);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMasterToggle(),
                          const SizedBox(height: 24),
                          _buildNotificationTypes(),
                          const SizedBox(height: 24),
                          _buildReminderTime(),
                          const SizedBox(height: 24),
                          _buildTestNotification(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Icon(
                Icons.arrow_back,
                color: context.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text('🔔', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildMasterToggle() {
    final isEnabled = _settings['push_enabled'] ?? true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEnabled
              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
              : [context.bgCard, context.bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isEnabled ? null : Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled
                  ? Colors.white.withAlpha(50)
                  : context.bgElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                isEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: isEnabled ? Colors.white : context.textMuted,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notifications',
                  style: TextStyle(
                    color: isEnabled ? Colors.white : context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? 'You\'ll receive important updates'
                      : 'Notifications are disabled',
                  style: TextStyle(
                    color: isEnabled
                        ? Colors.white.withAlpha(180)
                        : context.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) => _updateSetting('push_enabled', value),
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withAlpha(80),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildNotificationTypes() {
    final isEnabled = _settings['push_enabled'] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⚙️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              _buildNotificationTile(
                icon: '🔥',
                title: 'Streak Reminders',
                subtitle: 'Don\'t lose your learning streak',
                settingKey: 'streak_reminder',
                enabled: isEnabled,
              ),
              _buildDivider(),
              _buildNotificationTile(
                icon: '🎯',
                title: 'Daily Goals',
                subtitle: 'Reminders to complete your goals',
                settingKey: 'daily_goals',
                enabled: isEnabled,
              ),
              _buildDivider(),
              _buildNotificationTile(
                icon: '🏆',
                title: 'Achievements',
                subtitle: 'When you unlock new badges',
                settingKey: 'achievements',
                enabled: isEnabled,
              ),
              _buildDivider(),
              _buildNotificationTile(
                icon: '🎯',
                title: 'Challenges',
                subtitle: 'New challenges and completions',
                settingKey: 'challenges',
                enabled: isEnabled,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNotificationTile({
    required String icon,
    required String title,
    required String subtitle,
    required String settingKey,
    required bool enabled,
  }) {
    final isOn = _settings[settingKey] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled && isOn
                  ? AppColors.primary.withAlpha(30)
                  : context.bgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 20,
                  color: enabled ? null : context.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: enabled ? context.textPrimary : context.textMuted,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled
                        ? context.textMuted
                        : context.textMuted.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOn && enabled,
            onChanged: enabled
                ? (value) => _updateSetting(settingKey, value)
                : null,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 74,
      endIndent: 16,
      color: context.borderColor,
    );
  }

  Widget _buildReminderTime() {
    final isEnabled = _settings['push_enabled'] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⏰', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Daily Reminder Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: isEnabled ? _selectReminderTime : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppColors.primary.withAlpha(30)
                        : context.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.access_time,
                      color: isEnabled ? AppColors.primary : context.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminder Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isEnabled
                              ? context.textPrimary
                              : context.textMuted,
                        ),
                      ),
                      Text(
                        'When to send daily reminders',
                        style: TextStyle(
                          fontSize: 12,
                          color: isEnabled
                              ? context.textMuted
                              : context.textMuted.withAlpha(128),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppColors.primary.withAlpha(26)
                        : context.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatTime(_reminderTime),
                    style: TextStyle(
                      color: isEnabled ? AppColors.primary : context.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildTestNotification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🧪', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Test Notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await _notificationService.showLocalNotification(
                title: '🧪 Test Notification',
                body: 'If you see this, notifications are working!',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.bgCard,
              foregroundColor: context.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: context.borderColor),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 20),
                SizedBox(width: 10),
                Text(
                  'Send Test Notification',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}