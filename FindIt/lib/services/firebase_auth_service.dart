import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Firebase if not already initialized
  Future<void> _ensureInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      // Firebase is already initialized
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Create user with Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(
          userCredential.user!,
          name: name,
          phone: phone,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthException(e));
    } catch (e) {
      // Handle the specific Pigeon casting error and other unexpected errors
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('List<Object?>')) {
        throw Exception('Authentication service error. Please try again.');
      }
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthException(e));
    } catch (e) {
      // Handle the specific Pigeon casting error and other unexpected errors
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('List<Object?>')) {
        throw Exception('Authentication service error. Please try again.');
      }
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthException(e));
    } catch (e) {
      throw Exception('Failed to send reset email: ${e.toString()}');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    User user, {
    required String name,
    required String phone,
  }) async {
    try {
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: user.email ?? '',
        phone: phone,
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: user.emailVerified,
        role: 'user',
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  // Get user document from Firestore
  Future<UserModel?> getUserDocument(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user document: $e');
    }
  }

  // Update user document
  Future<void> updateUserDocument(UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userModel.id)
          .update(
            userModel.toMap()..['updatedAt'] = FieldValue.serverTimestamp(),
          );
    } catch (e) {
      throw Exception('Failed to update user document: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user signed in');

      // Update Firebase Auth profile
      if (name != null) {
        await user.updateDisplayName(name);
      }

      // Update Firestore document
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user signed in');

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user from Firebase Auth
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user signed in');

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Reload user
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to reload user: $e');
    }
  }

  // Get Firebase Auth exception message
  String _getAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'invalid-credential':
        return 'The credentials provided are invalid.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}
