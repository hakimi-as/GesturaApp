import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/glass_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      setState(() {
        _notifications = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .update({'isRead': true});

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (userId == null) return;

      final batch = _firestore.batch();
      for (var notification in _notifications.where((n) => !n.isRead)) {
        batch.update(
          _firestore.collection('notifications').doc(notification.id),
          {'isRead': true},
        );
      }
      await batch.commit();

      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).allMarkedRead),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _firestore.collection('notifications').doc(notification.id).delete();

      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDark.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).clearAllNotifications),
        content: Text(AppLocalizations.of(context).clearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context).clearAll),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (userId == null) return;

      final batch = _firestore.batch();
      for (var notification in _notifications) {
        batch.delete(_firestore.collection('notifications').doc(notification.id));
      }
      await batch.commit();

      setState(() => _notifications.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).allNotificationsCleared),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    _markAsRead(notification);

    if (notification.actionRoute != null) {
      Navigator.pop(context, notification.actionRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: AppLocalizations.of(context).notifications,
        actions: [
          if (_notifications.isNotEmpty) ...[
            if (unreadCount > 0)
              TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                label: Text(
                  AppLocalizations.of(context).readAll,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: context.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppColorsDark.bgCard,
              onSelected: (value) {
                if (value == 'clear') _clearAllNotifications();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).clearAll,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return GlassEmptyState(
      icon: Icons.notifications_none_rounded,
      title: AppLocalizations.of(context).noNotifications,
      subtitle: AppLocalizations.of(context).allCaughtUp,
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: kGlassRadius,
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassTile(
          alternate: index.isOdd,
          onTap: () => _handleNotificationTap(notification),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getTypeColor(notification.type).withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getTypeIcon(notification.type),
                    color: _getTypeColor(notification.type),
                    size: 22,
                  ),
                ),
              ),
              if (!notification.isRead)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.w500 : FontWeight.w700,
              color: notification.isRead
                  ? context.textSecondary
                  : context.textPrimary,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notification.timeAgo,
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          trailing: notification.actionRoute != null
              ? Icon(Icons.chevron_right_rounded,
                  color: context.textMuted, size: 20)
              : null,
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.achievement:
        return AppColors.warning;
      case NotificationType.streak:
        return Colors.orange;
      case NotificationType.levelUp:
        return AppColors.accent;
      case NotificationType.challenge:
        return AppColors.primary;
      case NotificationType.milestone:
        return AppColors.success;
      case NotificationType.reminder:
        return Colors.blue;
      case NotificationType.newContent:
        return Colors.green;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.achievement:
        return Icons.emoji_events_rounded;
      case NotificationType.streak:
        return Icons.local_fire_department_rounded;
      case NotificationType.levelUp:
        return Icons.arrow_upward_rounded;
      case NotificationType.challenge:
        return Icons.flag_rounded;
      case NotificationType.milestone:
        return Icons.stars_rounded;
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.newContent:
        return Icons.new_releases_rounded;
      case NotificationType.system:
        return Icons.info_outline_rounded;
    }
  }
}
