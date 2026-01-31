import 'package:cloud_firestore/cloud_firestore.dart';

/// Friendship status enum
enum FriendshipStatus {
  pending,
  accepted,
  declined,
}

/// Model representing a friendship between two users
class FriendshipModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String requesterId; // Who sent the request
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  FriendshipModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.requesterId,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  /// Get the friend's ID (the other user)
  String getFriendId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  /// Check if current user sent the request
  bool didSendRequest(String currentUserId) {
    return requesterId == currentUserId;
  }

  factory FriendshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendshipModel(
      id: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      requesterId: data['requesterId'] ?? '',
      status: _parseStatus(data['status']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'requesterId': requesterId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    };
  }

  static FriendshipStatus _parseStatus(String? status) {
    switch (status) {
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'declined':
        return FriendshipStatus.declined;
      default:
        return FriendshipStatus.pending;
    }
  }

  FriendshipModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? requesterId,
    FriendshipStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      requesterId: requesterId ?? this.requesterId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}

/// Model for displaying a friend with their user info
class FriendWithUser {
  final FriendshipModel friendship;
  final String odlerndId;
  final String fullName;
  final String email;
  final String? photoUrl;
  final int totalXP;
  final int currentStreak;
  final int signsLearned;
  final int level;
  final DateTime lastActiveAt;

  FriendWithUser({
    required this.friendship,
    required this.odlerndId,
    required this.fullName,
    required this.email,
    this.photoUrl,
    required this.totalXP,
    required this.currentStreak,
    required this.signsLearned,
    required this.level,
    required this.lastActiveAt,
  });

  /// Get initials for avatar
  String get initials {
    final names = fullName.trim().split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    } else if (names.isNotEmpty && names.first.isNotEmpty) {
      return names.first[0].toUpperCase();
    }
    return 'U';
  }

  /// Check if friend is online (active in last 5 minutes)
  bool get isOnline {
    return DateTime.now().difference(lastActiveAt).inMinutes < 5;
  }

  /// Check if friend was recently active (last 24 hours)
  bool get isRecentlyActive {
    return DateTime.now().difference(lastActiveAt).inHours < 24;
  }

  /// Format last active time
  String get lastActiveText {
    final diff = DateTime.now().difference(lastActiveAt);
    if (diff.inMinutes < 5) return 'Online now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return 'Long time ago';
  }
}

/// Model for friend activity feed
class FriendActivity {
  final String id;
  final String odlerndId;
  final String userName;
  final String? userPhotoUrl;
  final String activityType; // 'lesson', 'quiz', 'badge', 'streak', 'level_up'
  final String title;
  final String description;
  final String? emoji;
  final int? xpEarned;
  final DateTime createdAt;

  FriendActivity({
    required this.id,
    required this.odlerndId,
    required this.userName,
    this.userPhotoUrl,
    required this.activityType,
    required this.title,
    required this.description,
    this.emoji,
    this.xpEarned,
    required this.createdAt,
  });

  /// Get initials for avatar
  String get userInitials {
    final names = userName.trim().split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    } else if (names.isNotEmpty && names.first.isNotEmpty) {
      return names.first[0].toUpperCase();
    }
    return 'U';
  }

  /// Format time ago
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  /// Get icon for activity type
  String get activityIcon {
    switch (activityType) {
      case 'lesson':
        return '📚';
      case 'quiz':
        return '🎯';
      case 'badge':
        return '🏆';
      case 'streak':
        return '🔥';
      case 'level_up':
        return '⭐';
      case 'challenge':
        return '🎯';
      default:
        return emoji ?? '📝';
    }
  }

  factory FriendActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendActivity(
      id: doc.id,
      odlerndId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      userPhotoUrl: data['userPhotoUrl'],
      activityType: data['activityType'] ?? 'lesson',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      emoji: data['emoji'],
      xpEarned: data['xpEarned'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': odlerndId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'activityType': activityType,
      'title': title,
      'description': description,
      'emoji': emoji,
      'xpEarned': xpEarned,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}