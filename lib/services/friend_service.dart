import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';

class FriendService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _friendshipsCollection = _firestore.collection('friendships');
  static final CollectionReference _usersCollection = _firestore.collection('users');
  static final CollectionReference _activitiesCollection = _firestore.collection('activities');

  /// Send a friend request
  static Future<Map<String, dynamic>> sendFriendRequest(String fromUserId, String toUserId) async {
    try {
      // Check if friendship already exists
      final existingFriendship = await _getFriendshipBetweenUsers(fromUserId, toUserId);
      
      if (existingFriendship != null) {
        if (existingFriendship.status == 'accepted') {
          return {'success': false, 'message': 'You are already friends!'};
        } else if (existingFriendship.status == 'pending') {
          if (existingFriendship.requesterId == fromUserId) {
            return {'success': false, 'message': 'Friend request already sent!'};
          } else {
            // The other user sent a request, so accept it
            await acceptFriendRequest(fromUserId, existingFriendship.id);
            return {'success': true, 'message': 'Friend request accepted!'};
          }
        }
      }

      // Create new friendship with ordered user IDs
      final users = [fromUserId, toUserId]..sort();
      final friendship = FriendshipModel(
        id: '',
        user1Id: users[0],
        user2Id: users[1],
        requesterId: fromUserId,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _friendshipsCollection.add(friendship.toFirestore());

      return {'success': true, 'message': 'Friend request sent!'};
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return {'success': false, 'message': 'Failed to send friend request'};
    }
  }

  /// Accept a friend request
  static Future<bool> acceptFriendRequest(String userId, String friendshipId) async {
    try {
      await _friendshipsCollection.doc(friendshipId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      return false;
    }
  }

  /// Decline a friend request
  static Future<bool> declineFriendRequest(String friendshipId) async {
    try {
      await _friendshipsCollection.doc(friendshipId).update({
        'status': 'declined',
      });
      return true;
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      return false;
    }
  }

  /// Remove a friend
  static Future<bool> removeFriend(String friendshipId) async {
    try {
      await _friendshipsCollection.doc(friendshipId).delete();
      return true;
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return false;
    }
  }

  /// Get all friends for a user
  static Future<List<FriendWithUser>> getFriends(String userId) async {
    try {
      // Query where user is user1Id
      final query1 = await _friendshipsCollection
          .where('user1Id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      // Query where user is user2Id
      final query2 = await _friendshipsCollection
          .where('user2Id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final allDocs = [...query1.docs, ...query2.docs];
      final List<FriendWithUser> friends = [];

      for (final doc in allDocs) {
        final friendship = FriendshipModel.fromFirestore(doc);
        final friendId = friendship.getFriendId(userId);

        final friendDoc = await _usersCollection.doc(friendId).get();
        if (friendDoc.exists) {
          final friendUser = UserModel.fromFirestore(friendDoc);
          friends.add(FriendWithUser(
            friendship: friendship,
            friendUser: friendUser,
          ));
        }
      }

      // Sort by XP (highest first)
      friends.sort((a, b) => b.friendUser.totalXP.compareTo(a.friendUser.totalXP));

      return friends;
    } catch (e) {
      debugPrint('Error getting friends: $e');
      return [];
    }
  }

  /// Get pending friend requests for a user
  static Future<List<FriendWithUser>> getPendingRequests(String userId) async {
    try {
      // Query where user is user1Id
      final query1 = await _friendshipsCollection
          .where('user1Id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Query where user is user2Id
      final query2 = await _friendshipsCollection
          .where('user2Id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final allDocs = [...query1.docs, ...query2.docs];
      final List<FriendWithUser> requests = [];

      for (final doc in allDocs) {
        final friendship = FriendshipModel.fromFirestore(doc);
        
        // Only show requests where the other user sent the request
        if (friendship.requesterId != userId) {
          final requesterId = friendship.requesterId;
          final requesterDoc = await _usersCollection.doc(requesterId).get();
          
          if (requesterDoc.exists) {
            final requesterUser = UserModel.fromFirestore(requesterDoc);
            requests.add(FriendWithUser(
              friendship: friendship,
              friendUser: requesterUser,
            ));
          }
        }
      }

      return requests;
    } catch (e) {
      debugPrint('Error getting pending requests: $e');
      return [];
    }
  }

  /// Get friendship status between two users
  static Future<String> getFriendshipStatus(String userId, String otherUserId) async {
    try {
      final friendship = await _getFriendshipBetweenUsers(userId, otherUserId);
      
      if (friendship == null) {
        return 'none';
      }

      if (friendship.status == 'accepted') {
        return 'friends';
      }

      if (friendship.status == 'pending') {
        if (friendship.requesterId == userId) {
          return 'sent';
        } else {
          return 'received';
        }
      }

      return 'none';
    } catch (e) {
      debugPrint('Error getting friendship status: $e');
      return 'none';
    }
  }

  /// Get friendship ID between two users
  static Future<String?> getFriendshipId(String userId, String otherUserId) async {
    try {
      final friendship = await _getFriendshipBetweenUsers(userId, otherUserId);
      return friendship?.id;
    } catch (e) {
      debugPrint('Error getting friendship ID: $e');
      return null;
    }
  }

  /// Search users by name or email
  static Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    try {
      final queryLower = query.toLowerCase();
      
      // Get all users and filter client-side for case-insensitive search
      final usersSnapshot = await _usersCollection.limit(50).get();
      
      final List<UserModel> results = [];
      
      for (final doc in usersSnapshot.docs) {
        if (doc.id == currentUserId) continue;
        
        final user = UserModel.fromFirestore(doc);
        final fullNameLower = user.fullName.toLowerCase();
        final emailLower = user.email.toLowerCase();
        
        if (fullNameLower.contains(queryLower) || emailLower.contains(queryLower)) {
          results.add(user);
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Get friend activities for a user's feed
  static Future<List<FriendActivity>> getFriendActivities(String userId) async {
    try {
      final friends = await getFriends(userId);
      final friendIds = friends.map((f) => f.friendUser.id).toList();

      if (friendIds.isEmpty) return [];

      // Get activities from friends (limited batches of 10 due to Firestore whereIn limit)
      final List<FriendActivity> activities = [];
      
      for (var i = 0; i < friendIds.length; i += 10) {
        final batch = friendIds.skip(i).take(10).toList();
        final snapshot = await _activitiesCollection
            .where('userId', whereIn: batch)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

        for (final doc in snapshot.docs) {
          activities.add(FriendActivity.fromFirestore(doc));
        }
      }

      // Sort all activities by date
      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return activities.take(50).toList();
    } catch (e) {
      debugPrint('Error getting friend activities: $e');
      return [];
    }
  }

  /// Post an activity (for the current user)
  static Future<bool> postActivity({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String activityType,
    required String description,
    String? title,
    int xpEarned = 0,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activity = FriendActivity(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        activityType: activityType,
        description: description,
        title: title,
        xpEarned: xpEarned,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      await _activitiesCollection.add(activity.toMap());
      return true;
    } catch (e) {
      debugPrint('Error posting activity: $e');
      return false;
    }
  }

  /// Get friends count
  static Future<int> getFriendsCount(String userId) async {
    try {
      final friends = await getFriends(userId);
      return friends.length;
    } catch (e) {
      debugPrint('Error getting friends count: $e');
      return 0;
    }
  }

  /// Get pending requests count
  static Future<int> getPendingRequestsCount(String userId) async {
    try {
      final requests = await getPendingRequests(userId);
      return requests.length;
    } catch (e) {
      debugPrint('Error getting pending requests count: $e');
      return 0;
    }
  }

  /// Alias for getPendingRequestsCount (for compatibility)
  static Future<int> getPendingRequestCount(String userId) => getPendingRequestsCount(userId);

  /// Private helper to get friendship between two users
  static Future<FriendshipModel?> _getFriendshipBetweenUsers(String userId1, String userId2) async {
    try {
      // Sort user IDs for consistent querying
      final users = [userId1, userId2]..sort();
      
      final snapshot = await _friendshipsCollection
          .where('user1Id', isEqualTo: users[0])
          .where('user2Id', isEqualTo: users[1])
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return FriendshipModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting friendship: $e');
      return null;
    }
  }

  /// Get leaderboard (friends sorted by XP)
  static Future<List<FriendWithUser>> getLeaderboard(String userId) async {
    try {
      final friends = await getFriends(userId);
      
      // Add current user to the list
      final currentUserDoc = await _usersCollection.doc(userId).get();
      if (currentUserDoc.exists) {
        final currentUser = UserModel.fromFirestore(currentUserDoc);
        // Create a dummy friendship for the current user
        friends.add(FriendWithUser(
          friendship: FriendshipModel(
            id: 'self',
            user1Id: userId,
            user2Id: userId,
            requesterId: userId,
            status: 'accepted',
            createdAt: DateTime.now(),
          ),
          friendUser: currentUser,
        ));
      }

      // Sort by XP
      friends.sort((a, b) => b.friendUser.totalXP.compareTo(a.friendUser.totalXP));

      return friends;
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }
}