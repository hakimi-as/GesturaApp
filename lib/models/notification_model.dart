import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  achievement,    // Badge unlocked
  streak,         // Streak related
  levelUp,        // Level up
  challenge,      // Challenge completed/available
  milestone,      // Learning milestones
  reminder,       // Practice reminders
  newContent,     // New lessons/quizzes
  system,         // System notifications
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? icon;           // Emoji or icon name
  final String? actionRoute;    // Optional navigation route
  final Map<String, dynamic>? data;  // Additional data
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.icon,
    this.actionRoute,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      icon: data['icon'],
      actionRoute: data['actionRoute'],
      data: data['data'] as Map<String, dynamic>?,
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'icon': icon,
      'actionRoute': actionRoute,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    String? icon,
    String? actionRoute,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      actionRoute: actionRoute ?? this.actionRoute,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get default icon based on notification type
  String get defaultIcon {
    switch (type) {
      case NotificationType.achievement:
        return '🏆';
      case NotificationType.streak:
        return '🔥';
      case NotificationType.levelUp:
        return '⭐';
      case NotificationType.challenge:
        return '🎯';
      case NotificationType.milestone:
        return '🏅';
      case NotificationType.reminder:
        return '⏰';
      case NotificationType.newContent:
        return '📚';
      case NotificationType.system:
        return '📢';
    }
  }

  /// Get display icon (custom or default)
  String get displayIcon => icon ?? defaultIcon;

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}