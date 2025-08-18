import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    await _ensureInitialized();

    try {
      // Add a small delay to ensure Firebase is ready
      await Future.delayed(const Duration(milliseconds: 100));

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
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        throw Exception(
          'Authentication service error. Please restart the app and try again.',
        );
      }
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();

    try {
      print('🔐 Attempting to sign in with email: $email'); // Debug log

      // Add a small delay to ensure Firebase is ready
      await Future.delayed(const Duration(milliseconds: 100));

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
        '✅ Sign in successful for user: ${userCredential.user?.email}',
      ); // Debug log
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('🔥 FirebaseAuthException: ${e.code} - ${e.message}'); // Debug log
      throw Exception(_getAuthException(e));
    } catch (e, stackTrace) {
      print('❌ Unexpected error during sign in: $e'); // Debug log
      print('📍 Stack trace: $stackTrace'); // Debug log

      // Handle the specific Pigeon casting error and other unexpected errors
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        throw Exception(
          'Authentication service error. Please restart the app and try again.',
        );
      }
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    await _ensureInitialized();

    try {
      print('🔐 Attempting Google Sign-In'); // Debug log

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        print('❌ Google Sign-In cancelled by user'); // Debug log
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Create or update user document in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateGoogleUserDocument(userCredential.user!);
      }

      print(
        '✅ Google Sign-In successful for user: ${userCredential.user?.email}',
      ); // Debug log
      return userCredential;
    } catch (e, stackTrace) {
      print('❌ Google Sign-In error: $e'); // Debug log
      print('📍 Stack trace: $stackTrace'); // Debug log
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  // Create or update user document for Google sign-in
  Future<void> _createOrUpdateGoogleUserDocument(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create new user document
        final userModel = UserModel(
          id: user.uid,
          name: user.displayName ?? 'Google User',
          email: user.email ?? '',
          phone: '', // Google sign-in doesn't provide phone by default
          avatarUrl: user.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: user.emailVerified,
          role: 'user',
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      } else {
        // Update existing user document
        await _firestore.collection('users').doc(user.uid).update({
          'avatarUrl': user.photoURL,
          'isVerified': user.emailVerified,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to create/update user document: $e');
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
      print('Attempting to get user document for UID: $uid'); // Debug log
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        print('User document found for UID: $uid'); // Debug log
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      } else {
        print('User document does not exist for UID: $uid'); // Debug log
        return null;
      }
    } catch (e) {
      print('Error getting user document for UID $uid: $e'); // Debug log
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

  // Create or update user document (uses set with merge)
  Future<void> createOrUpdateUserDocument(UserModel userModel) async {
    try {
      final docData = userModel.toMap();
      docData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userModel.id)
          .set(docData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create/update user document: $e');
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

      // Update Firestore document using set with merge to handle non-existent documents
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      // Use set with merge instead of update to handle cases where document doesn't exist
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));
      
      print('Profile updated successfully in Firestore');
    } catch (e) {
      print('Error updating profile: $e');
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

  // Update password
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user currently signed in');
      }

      // Re-authenticate the user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      } else if (e.code == 'weak-password') {
        throw Exception('New password is too weak');
      } else if (e.code == 'requires-recent-login') {
        throw Exception(
          'Please sign out and sign in again before updating password',
        );
      }
      throw Exception(_getAuthException(e));
    } catch (e) {
      throw Exception('Failed to update password: $e');
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
