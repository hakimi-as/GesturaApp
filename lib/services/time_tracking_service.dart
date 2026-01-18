import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to track time spent in the app
class TimeTrackingService {
  static final TimeTrackingService _instance = TimeTrackingService._internal();
  factory TimeTrackingService() => _instance;
  TimeTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _timer;
  String? _userId;
  int _sessionSeconds = 0;
  DateTime? _sessionStart;
  bool _isTracking = false;

  /// Start tracking time for a user
  void startTracking(String userId) {
    if (_isTracking && _userId == userId) return;
    
    _userId = userId;
    _sessionSeconds = 0;
    _sessionStart = DateTime.now();
    _isTracking = true;
    
    // Update every 30 seconds
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateTimeSpent();
    });
    
    debugPrint('⏱️ Time tracking started for user: $userId');
  }

  /// Stop tracking and save final time
  Future<void> stopTracking() async {
    if (!_isTracking || _userId == null) return;
    
    _timer?.cancel();
    _timer = null;
    
    // Save any remaining time
    await _updateTimeSpent();
    
    debugPrint('⏱️ Time tracking stopped. Session: $_sessionSeconds seconds');
    
    _isTracking = false;
    _sessionSeconds = 0;
    _sessionStart = null;
  }

  /// Pause tracking (app goes to background)
  Future<void> pauseTracking() async {
    if (!_isTracking) return;
    
    _timer?.cancel();
    _timer = null;
    
    // Save current progress
    await _updateTimeSpent();
    
    debugPrint('⏱️ Time tracking paused');
  }

  /// Resume tracking (app comes to foreground)
  void resumeTracking() {
    if (!_isTracking || _userId == null) return;
    
    _sessionStart = DateTime.now();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateTimeSpent();
    });
    
    debugPrint('⏱️ Time tracking resumed');
  }

  /// Update time spent in Firestore
  Future<void> _updateTimeSpent() async {
    if (_userId == null || _sessionStart == null) return;
    
    try {
      final now = DateTime.now();
      final elapsed = now.difference(_sessionStart!).inSeconds;
      
      if (elapsed > 0) {
        await _firestore.collection('users').doc(_userId).update({
          'totalTimeSpentSeconds': FieldValue.increment(elapsed),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        
        _sessionSeconds += elapsed;
        _sessionStart = now; // Reset for next interval
        
        debugPrint('⏱️ Updated time: +$elapsed seconds (session total: $_sessionSeconds)');
      }
    } catch (e) {
      debugPrint('⏱️ Error updating time: $e');
    }
  }

  /// Get current session time in seconds
  int get currentSessionSeconds {
    if (_sessionStart == null) return _sessionSeconds;
    return _sessionSeconds + DateTime.now().difference(_sessionStart!).inSeconds;
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Dispose the service
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _isTracking = false;
  }
}