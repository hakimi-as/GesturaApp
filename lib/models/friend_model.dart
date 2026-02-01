import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/// Friendship status enum
enum FriendshipStatus {
  pending,
  accepted,
  declined,
}

/// Represents a friendship relationship between two users
class FriendshipModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String requesterId;
  final String status; // 'pending', 'accepted', 'declined'
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

  factory FriendshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendshipModel(
      id: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      requesterId: data['requesterId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'requesterId': requesterId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  /// Get the other user's ID (not the current user)
  String getOtherUserId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  /// Alias for getOtherUserId for compatibility
  String getFriendId(String currentUserId) => getOtherUserId(currentUserId);

  bool isPending() => status == 'pending';
  bool isAccepted() => status == 'accepted';
  bool isDeclined() => status == 'declined';
}

/// Combines a friendship with the friend's user data
class FriendWithUser {
  final FriendshipModel friendship;
  final UserModel friendUser;

  FriendWithUser({
    required this.friendship,
    required this.friendUser,
  });

  // Convenience getters to access friendUser properties directly
  String get odlerndId => friendUser.id; // Keep for backward compatibility (typo in original)
  String get odlernId => friendUser.id;  // Correct spelling
  String get friendId => friendUser.id;
  String get fullName => friendUser.fullName;
  String get email => friendUser.email;
  String? get photoUrl => friendUser.photoUrl;
  int get totalXP => friendUser.totalXP;
  int get currentStreak => friendUser.currentStreak;
  int get signsLearned => friendUser.signsLearned;
  int get level => friendUser.level;
  String get initials => friendUser.initials;
  // lastActiveAt - returns null if UserModel doesn't track this
  DateTime? get lastActiveAt => null;
}

/// Represents a friend activity in the feed
class FriendActivity {
  final String id;
  final String odlerndId; // Keep for backward compatibility
  final String odlernId;  // Correct spelling
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String activityType; // 'lesson_completed', 'quiz_completed', 'badge_earned', etc.
  final String description;
  final String? title;
  final int xpEarned;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  FriendActivity({
    required this.id,
    String? odlerndId,
    String? odlernId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.activityType,
    required this.description,
    this.title,
    this.xpEarned = 0,
    this.metadata,
    required this.createdAt,
  }) : odlerndId = odlerndId ?? userId,
       odlernId = odlernId ?? userId;

  factory FriendActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final odlernId = data['userId'] ?? '';
    return FriendActivity(
      id: doc.id,
      odlerndId: odlernId,
      odlernId: odlernId,
      userId: odlernId,
      userName: data['userName'] ?? 'Unknown',
      userPhotoUrl: data['userPhotoUrl'],
      activityType: data['activityType'] ?? '',
      description: data['description'] ?? '',
      title: data['title'],
      xpEarned: data['xpEarned'] ?? 0,
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'activityType': activityType,
      'description': description,
      'title': title,
      'xpEarned': xpEarned,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get emoji => activityIcon;

  String get activityIcon {
    switch (activityType) {
      case 'lesson_completed':
        return '📚';
      case 'quiz_completed':
        return '🎯';
      case 'badge_earned':
        return '🏅';
      case 'streak_milestone':
        return '🔥';
      case 'level_up':
        return '⬆️';
      case 'challenge_completed':
        return '🏆';
      default:
        return '✨';
    }
  }

  String get userInitials {
    if (userName.isEmpty) return '?';
    final parts = userName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userName[0].toUpperCase();
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}