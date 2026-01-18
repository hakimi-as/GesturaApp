import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    String userType = 'learner',
    String preferredSignLanguage = 'ASL',
  }) async {
    try {
      // Create Firebase auth user
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }

      // Create user model
      final userModel = UserModel(
        id: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        userType: userType,
        preferredSignLanguage: preferredSignLanguage,
        totalXP: 0,
        currentStreak: 0,
        longestStreak: 0,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        isAdmin: false,
      );

      // Save user to Firestore
      await _firestoreService.createUser(userModel);

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(fullName);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to sign in');
      }

      // Get user from Firestore
      final userModel = await _firestoreService.getUser(userCredential.user!.uid);

      // Update last active time
      if (userModel != null) {
        await _firestoreService.updateUser(userCredential.user!.uid, {
          'lastActiveAt': DateTime.now(),
        });
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    return await _firestoreService.getUser(userId);
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}