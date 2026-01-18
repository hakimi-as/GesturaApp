import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? _firebaseUser;
  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Alias for compatibility
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _firebaseUser != null && _currentUser != null;
  bool get isLoggedIn => isAuthenticated;
  String? get userId => _firebaseUser?.uid;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        await _loadUserData(user.uid);
        _status = AuthStatus.authenticated;
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _currentUser = await _firestoreService.getUser(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (_firebaseUser != null) {
      await _loadUserData(_firebaseUser!.uid);
    }
  }

  // Sign in with named parameters (for compatibility)
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Sign up (alias for register, for compatibility)
  // Sign up (alias for register, for compatibility)
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? userType,
  }) async {
    return register(email: email, password: password, fullName: fullName, userType: userType);
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? userType,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Create user in Firestore
        final newUser = UserModel(
          id: credential.user!.uid,
          email: email.trim(),
          fullName: fullName.trim(),
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isAdmin: userType == 'admin',
        );

        await _firestoreService.createUser(newUser);
        await _loadUserData(credential.user!.uid);

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profileImagePath');
      
      // Clear user data BEFORE signing out
      _currentUser = null;
      _firebaseUser = null;
      _status = AuthStatus.unauthenticated;
      
      // Sign out from Firebase
      await _auth.signOut();
      
      notifyListeners();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
      // Force clear even on error
      _currentUser = null;
      _firebaseUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email.trim());

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Add XP to user (for quiz results)
  Future<void> addXP(int xp) async {
    if (_currentUser == null || _firebaseUser == null) return;

    try {
      final oldXP = _currentUser!.totalXP;
      final newXP = oldXP + xp;
      
      // Calculate level change (100 XP per level)
      final oldLevel = (oldXP / 100).floor() + 1;
      final newLevel = (newXP / 100).floor() + 1;
      
      await _firestoreService.updateUserField(_firebaseUser!.uid, 'totalXP', newXP);
      
      // Check for level up and create notification
      if (newLevel > oldLevel) {
        await _firestoreService.notifyLevelUp(_firebaseUser!.uid, newLevel);
      }
      
      // Check for XP milestones (every 100 XP)
      final oldMilestone = (oldXP / 100).floor();
      final newMilestone = (newXP / 100).floor();
      if (newMilestone > oldMilestone && newXP >= 100) {
        await _firestoreService.notifyXpMilestone(_firebaseUser!.uid, newMilestone * 100);
      }
      
      await refreshUser();
    } catch (e) {
      debugPrint('Error adding XP: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}