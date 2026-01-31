import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/friend_model.dart';
import '../models/user_model.dart';

class FriendService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _friendshipsCollection = 'friendships';
  static const String _activitiesCollection = 'friend_activities';

  // ==================== FRIEND REQUESTS ====================

  /// Send a friend request
  static Future<Map<String, dynamic>> sendFriendRequest(
    String senderId,
    String receiverId,
  ) async {
    try {
      // Check if they're the same user
      if (senderId == receiverId) {
        return {'success': false, 'error': 'You cannot add yourself as a friend'};
      }

      // Check if friendship already exists
      final existing = await _getExistingFriendship(senderId, receiverId);
      if (existing != null) {
        if (existing.status == FriendshipStatus.accepted) {
          return {'success': false, 'error': 'You are already friends'};
        }
        if (existing.status == FriendshipStatus.pending) {
          if (existing.requesterId == senderId) {
            return {'success': false, 'error': 'Friend request already sent'};
          } else {
            // The other user already sent a request, auto-accept
            await acceptFriendRequest(receiverId, existing.id);
            return {'success': true, 'message': 'Friend request accepted!'};
          }
        }
      }

      // Create new friendship request
      final friendship = FriendshipModel(
        id: '',
        user1Id: senderId,
        user2Id: receiverId,
        requesterId: senderId,
        status: FriendshipStatus.pending,
        createdAt: DateTime.now(),
      );

      await _db.collection(_friendshipsCollection).add(friendship.toFirestore());

      // Create notification for receiver
      await _createFriendRequestNotification(senderId, receiverId);

      debugPrint('✅ Friend request sent from $senderId to $receiverId');
      return {'success': true, 'message': 'Friend request sent!'};
    } catch (e) {
      debugPrint('❌ Error sending friend request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Accept a friend request
  static Future<bool> acceptFriendRequest(String userId, String friendshipId) async {
    try {
      await _db.collection(_friendshipsCollection).doc(friendshipId).update({
        'status': FriendshipStatus.accepted.name,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Get friendship to find the other user
      final doc = await _db.collection(_friendshipsCollection).doc(friendshipId).get();
      if (doc.exists) {
        final friendship = FriendshipModel.fromFirestore(doc);
        final friendId = friendship.getFriendId(userId);
        
        // Notify the requester that their request was accepted
        await _createFriendAcceptedNotification(userId, friendId);
      }

      debugPrint('✅ Friend request accepted: $friendshipId');
      return true;
    } catch (e) {
      debugPrint('❌ Error accepting friend request: $e');
      return false;
    }
  }

  /// Decline a friend request
  static Future<bool> declineFriendRequest(String friendshipId) async {
    try {
      await _db.collection(_friendshipsCollection).doc(friendshipId).delete();
      debugPrint('✅ Friend request declined: $friendshipId');
      return true;
    } catch (e) {
      debugPrint('❌ Error declining friend request: $e');
      return false;
    }
  }

  /// Remove a friend
  static Future<bool> removeFriend(String friendshipId) async {
    try {
      await _db.collection(_friendshipsCollection).doc(friendshipId).delete();
      debugPrint('✅ Friend removed: $friendshipId');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing friend: $e');
      return false;
    }
  }

  // ==================== GET FRIENDS ====================

  /// Get all accepted friends for a user
  static Future<List<FriendWithUser>> getFriends(String userId) async {
    try {
      // Query friendships where user is user1 or user2 and status is accepted
      final query1 = await _db
          .collection(_friendshipsCollection)
          .where('user1Id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final query2 = await _db
          .collection(_friendshipsCollection)
          .where('user2Id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final allDocs = [...query1.docs, ...query2.docs];
      final friendships = allDocs.map((doc) => FriendshipModel.fromFirestore(doc)).toList();

      // Get friend IDs
      final friendIds = friendships.map((f) => f.getFriendId(userId)).toSet().toList();

      if (friendIds.isEmpty) return [];

      // Fetch user data for all friends
      final friends = <FriendWithUser>[];
      
      for (final friendId in friendIds) {
        final userDoc = await _db.collection('users').doc(friendId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final friendship = friendships.firstWhere(
            (f) => f.getFriendId(userId) == friendId,
          );
          
          friends.add(FriendWithUser(
            friendship: friendship,
            odlerndId: friendId,
            fullName: userData['fullName'] ?? 'User',
            email: userData['email'] ?? '',
            photoUrl: userData['photoUrl'],
            totalXP: userData['totalXP'] ?? 0,
            currentStreak: userData['currentStreak'] ?? 0,
            signsLearned: userData['signsLearned'] ?? 0,
            level: _calculateLevel(userData['totalXP'] ?? 0),
            lastActiveAt: userData['lastActiveAt'] != null
                ? (userData['lastActiveAt'] as Timestamp).toDate()
                : DateTime.now(),
          ));
        }
      }

      // Sort by XP (highest first)
      friends.sort((a, b) => b.totalXP.compareTo(a.totalXP));

      return friends;
    } catch (e) {
      debugPrint('❌ Error getting friends: $e');
      return [];
    }
  }

  /// Get pending friend requests (received)
  static Future<List<FriendWithUser>> getPendingRequests(String userId) async {
    try {
      // Get requests where user is the receiver (user2) and status is pending
      final query1 = await _db
          .collection(_friendshipsCollection)
          .where('user2Id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Also check user1Id in case they're stored differently
      final query2 = await _db
          .collection(_friendshipsCollection)
          .where('user1Id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final allDocs = [...query1.docs, ...query2.docs];
      
      // Filter to only show requests where the OTHER user sent the request
      final friendships = allDocs
          .map((doc) => FriendshipModel.fromFirestore(doc))
          .where((f) => f.requesterId != userId) // Only received requests
          .toList();

      if (friendships.isEmpty) return [];

      // Get sender IDs
      final senderIds = friendships.map((f) => f.requesterId).toSet().toList();

      // Fetch user data for all senders
      final requests = <FriendWithUser>[];
      
      for (final senderId in senderIds) {
        final userDoc = await _db.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final friendship = friendships.firstWhere(
            (f) => f.requesterId == senderId,
          );
          
          requests.add(FriendWithUser(
            friendship: friendship,
            odlerndId: senderId,
            fullName: userData['fullName'] ?? 'User',
            email: userData['email'] ?? '',
            photoUrl: userData['photoUrl'],
            totalXP: userData['totalXP'] ?? 0,
            currentStreak: userData['currentStreak'] ?? 0,
            signsLearned: userData['signsLearned'] ?? 0,
            level: _calculateLevel(userData['totalXP'] ?? 0),
            lastActiveAt: userData['lastActiveAt'] != null
                ? (userData['lastActiveAt'] as Timestamp).toDate()
                : DateTime.now(),
          ));
        }
      }

      // Sort by request date (newest first)
      requests.sort((a, b) => b.friendship.createdAt.compareTo(a.friendship.createdAt));

      return requests;
    } catch (e) {
      debugPrint('❌ Error getting pending requests: $e');
      return [];
    }
  }

  /// Get sent friend requests (outgoing)
  static Future<List<FriendWithUser>> getSentRequests(String userId) async {
    try {
      final query1 = await _db
          .collection(_friendshipsCollection)
          .where('requesterId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final friendships = query1.docs
          .map((doc) => FriendshipModel.fromFirestore(doc))
          .toList();

      if (friendships.isEmpty) return [];

      // Get receiver IDs
      final receiverIds = friendships.map((f) => f.getFriendId(userId)).toSet().toList();

      // Fetch user data
      final requests = <FriendWithUser>[];
      
      for (final odlerndId in receiverIds) {
        final userDoc = await _db.collection('users').doc(odlerndId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final friendship = friendships.firstWhere(
            (f) => f.getFriendId(userId) == odlerndId,
          );
          
          requests.add(FriendWithUser(
            friendship: friendship,
            odlerndId: odlerndId,
            fullName: userData['fullName'] ?? 'User',
            email: userData['email'] ?? '',
            photoUrl: userData['photoUrl'],
            totalXP: userData['totalXP'] ?? 0,
            currentStreak: userData['currentStreak'] ?? 0,
            signsLearned: userData['signsLearned'] ?? 0,
            level: _calculateLevel(userData['totalXP'] ?? 0),
            lastActiveAt: userData['lastActiveAt'] != null
                ? (userData['lastActiveAt'] as Timestamp).toDate()
                : DateTime.now(),
          ));
        }
      }

      return requests;
    } catch (e) {
      debugPrint('❌ Error getting sent requests: $e');
      return [];
    }
  }

  /// Get friend count
  static Future<int> getFriendCount(String userId) async {
    try {
      final query1 = await _db
          .collection(_friendshipsCollection)
          .where('user1Id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .count()
          .get();

      final query2 = await _db
          .collection(_friendshipsCollection)
          .where('user2Id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .count()
          .get();

      return (query1.count ?? 0) + (query2.count ?? 0);
    } catch (e) {
      debugPrint('❌ Error getting friend count: $e');
      return 0;
    }
  }

  /// Get pending request count
  static Future<int> getPendingRequestCount(String userId) async {
    try {
      // Count requests received (where user is not the requester)
      final query1 = await _db
          .collection(_friendshipsCollection)
          .where('user1Id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final query2 = await _db
          .collection(_friendshipsCollection)
          .where('user2Id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      int count = 0;
      for (var doc in [...query1.docs, ...query2.docs]) {
        final data = doc.data();
        if (data['requesterId'] != userId) {
          count++;
        }
      }

      return count;
    } catch (e) {
      debugPrint('❌ Error getting pending request count: $e');
      return 0;
    }
  }

  // ==================== SEARCH USERS ====================

  /// Search users by name or email
  static Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    try {
      if (query.isEmpty || query.length < 2) return [];

      final searchLower = query.toLowerCase();

      // Search by name (case-insensitive using lowercase comparison)
      final snapshot = await _db
          .collection('users')
          .orderBy('fullName')
          .limit(50)
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => 
              user.id != currentUserId && // Exclude current user
              (user.fullName.toLowerCase().contains(searchLower) ||
               user.email.toLowerCase().contains(searchLower)))
          .take(20)
          .toList();

      return users;
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      return [];
    }
  }

  /// Check friendship status with another user
  static Future<String> getFriendshipStatus(String userId, String otherUserId) async {
    try {
      final friendship = await _getExistingFriendship(userId, otherUserId);
      
      if (friendship == null) {
        return 'none';
      }
      
      if (friendship.status == FriendshipStatus.accepted) {
        return 'friends';
      }
      
      if (friendship.status == FriendshipStatus.pending) {
        if (friendship.requesterId == userId) {
          return 'sent'; // Current user sent the request
        } else {
          return 'received'; // Current user received the request
        }
      }
      
      return 'none';
    } catch (e) {
      debugPrint('❌ Error checking friendship status: $e');
      return 'none';
    }
  }

  /// Get friendship ID if exists
  static Future<String?> getFriendshipId(String userId, String otherUserId) async {
    try {
      final friendship = await _getExistingFriendship(userId, otherUserId);
      return friendship?.id;
    } catch (e) {
      return null;
    }
  }

  // ==================== ACTIVITY FEED ====================

  /// Get friend activity feed
  static Future<List<FriendActivity>> getFriendActivityFeed(String userId, {int limit = 20}) async {
    try {
      // First get all friend IDs
      final friends = await getFriends(userId);
      if (friends.isEmpty) return [];

      final friendIds = friends.map((f) => f.odlerndId).toList();

      // Get recent activities from friends
      // We'll get activities from the progress collection
      final activities = <FriendActivity>[];

      for (final friendId in friendIds) {
        final friend = friends.firstWhere((f) => f.odlerndId == friendId);
        
        // Get recent progress for this friend
        final progressSnapshot = await _db
            .collection('progress')
            .where('userId', isEqualTo: friendId)
            .orderBy('lastAccessedAt', descending: true)
            .limit(5)
            .get();

        for (var doc in progressSnapshot.docs) {
          final data = doc.data();
          final isQuiz = data['type'] == 'quiz' || data['categoryId'] == 'quiz';
          
          activities.add(FriendActivity(
            id: doc.id,
            odlerndId: friendId,
            userName: friend.fullName,
            userPhotoUrl: friend.photoUrl,
            activityType: isQuiz ? 'quiz' : 'lesson',
            title: isQuiz ? 'Completed a quiz' : 'Learned a sign',
            description: data['displayTitle'] ?? data['lessonName'] ?? 'Lesson',
            emoji: isQuiz ? '🎯' : '📚',
            xpEarned: data['xpEarned'],
            createdAt: data['lastAccessedAt'] != null
                ? (data['lastAccessedAt'] as Timestamp).toDate()
                : DateTime.now(),
          ));
        }
      }

      // Sort by date (most recent first)
      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return activities.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error getting friend activity feed: $e');
      return [];
    }
  }

  // ==================== LEADERBOARD ====================

  /// Get friends leaderboard
  static Future<List<FriendWithUser>> getFriendsLeaderboard(String userId) async {
    try {
      final friends = await getFriends(userId);
      
      // Add current user to the list for comparison
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        friends.add(FriendWithUser(
          friendship: FriendshipModel(
            id: 'self',
            user1Id: userId,
            user2Id: userId,
            requesterId: userId,
            status: FriendshipStatus.accepted,
            createdAt: DateTime.now(),
          ),
          odlerndId: userId,
          fullName: '${userData['fullName']} (You)',
          email: userData['email'] ?? '',
          photoUrl: userData['photoUrl'],
          totalXP: userData['totalXP'] ?? 0,
          currentStreak: userData['currentStreak'] ?? 0,
          signsLearned: userData['signsLearned'] ?? 0,
          level: _calculateLevel(userData['totalXP'] ?? 0),
          lastActiveAt: userData['lastActiveAt'] != null
              ? (userData['lastActiveAt'] as Timestamp).toDate()
              : DateTime.now(),
        ));
      }

      // Sort by XP
      friends.sort((a, b) => b.totalXP.compareTo(a.totalXP));

      return friends;
    } catch (e) {
      debugPrint('❌ Error getting friends leaderboard: $e');
      return [];
    }
  }

  // ==================== HELPERS ====================

  /// Get existing friendship between two users
  static Future<FriendshipModel?> _getExistingFriendship(String userId1, String userId2) async {
    try {
      // Check both directions
      final query1 = await _db
          .collection(_friendshipsCollection)
          .where('user1Id', isEqualTo: userId1)
          .where('user2Id', isEqualTo: userId2)
          .limit(1)
          .get();

      if (query1.docs.isNotEmpty) {
        return FriendshipModel.fromFirestore(query1.docs.first);
      }

      final query2 = await _db
          .collection(_friendshipsCollection)
          .where('user1Id', isEqualTo: userId2)
          .where('user2Id', isEqualTo: userId1)
          .limit(1)
          .get();

      if (query2.docs.isNotEmpty) {
        return FriendshipModel.fromFirestore(query2.docs.first);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error checking existing friendship: $e');
      return null;
    }
  }

  /// Calculate level from XP
  static int _calculateLevel(int totalXP) {
    const thresholds = [0, 100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500];
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (totalXP >= thresholds[i]) {
        if (i == thresholds.length - 1) {
          return 10 + ((totalXP - thresholds.last) ~/ 1000);
        }
        return i + 1;
      }
    }
    return 1;
  }

  /// Create friend request notification
  static Future<void> _createFriendRequestNotification(String senderId, String receiverId) async {
    try {
      // Get sender name
      final senderDoc = await _db.collection('users').doc(senderId).get();
      final senderName = senderDoc.data()?['fullName'] ?? 'Someone';

      await _db.collection('notifications').add({
        'userId': receiverId,
        'type': 'friend_request',
        'title': 'New Friend Request! 👋',
        'message': '$senderName wants to be your friend',
        'icon': '👥',
        'actionRoute': '/friends',
        'data': {'senderId': senderId},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
    }
  }

  /// Create friend accepted notification
  static Future<void> _createFriendAcceptedNotification(String accepterId, String requesterId) async {
    try {
      final accepterDoc = await _db.collection('users').doc(accepterId).get();
      final accepterName = accepterDoc.data()?['fullName'] ?? 'Someone';

      await _db.collection('notifications').add({
        'userId': requesterId,
        'type': 'friend_accepted',
        'title': 'Friend Request Accepted! 🎉',
        'message': '$accepterName accepted your friend request',
        'icon': '✅',
        'actionRoute': '/friends',
        'data': {'friendId': accepterId},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
    }
  }
}