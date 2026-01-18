import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';

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
            content: const Text('All notifications marked as read'),
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
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
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
            content: const Text('All notifications cleared'),
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
    
    // Handle navigation based on actionRoute
    if (notification.actionRoute != null) {
      // For now, just close and let dashboard handle it
      // Could implement navigation here if needed
      Navigator.pop(context, notification.actionRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            if (unreadCount > 0)
              TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Read All'),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: context.bgCard,
              onSelected: (value) {
                if (value == 'clear') _clearAllNotifications();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text('Clear All', style: TextStyle(color: AppColors.error)),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! Check back later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.textMuted,
            ),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? context.bgCard
                : AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? context.borderColor
                  : AppColors.primary.withAlpha(50),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    notification.displayIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.timeAgo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chevron if has action
              if (notification.actionRoute != null)
                Icon(
                  Icons.chevron_right,
                  color: context.textMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 50 * index),
    ).slideX(begin: 0.1);
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
}