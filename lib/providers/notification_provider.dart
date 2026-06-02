import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  DateTime? _lastLoadedAt;
  String? _lastLoadedUserId;
  static const _ttl = Duration(minutes: 2);

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  bool isStale(String userId) {
    if (_lastLoadedUserId != userId) return true;
    if (_lastLoadedAt == null) return true;
    return DateTime.now().difference(_lastLoadedAt!) > _ttl;
  }

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      _lastLoadedAt = DateTime.now();
      _lastLoadedUserId = userId;
    } catch (e) {
      debugPrint('NotificationProvider: error loading — $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;

    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider: markAsRead error — $e');
    }
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (final n in unread) {
        batch.update(_firestore.collection('notifications').doc(n.id), {'isRead': true});
      }
      await batch.commit();

      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider: markAllAsRead error — $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider: delete error — $e');
    }
  }

  Future<void> clearAll() async {
    if (_notifications.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (final n in _notifications) {
        batch.delete(_firestore.collection('notifications').doc(n.id));
      }
      await batch.commit();
      _notifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider: clearAll error — $e');
    }
  }

  void clear() {
    _notifications.clear();
    notifyListeners();
  }
}
