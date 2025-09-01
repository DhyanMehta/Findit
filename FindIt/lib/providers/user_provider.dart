import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _authService.currentUser;

  // Initialize user data
  Future<void> initializeUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      await loadUserData();
    }
  }

  // Load user data from Firestore
  Future<void> loadUserData() async {
    _setLoading(true);
    _setError(null);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userModel = await _authService.getUserDocument(user.uid);
        _userModel = userModel;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      print('UserProvider: Starting profile update...');
      print('UserProvider: name=$name, phone=$phone, avatarUrl=$avatarUrl');

      await _authService.updateUserProfile(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      print('UserProvider: Profile update service call completed');

      // Reload user data after update
      await loadUserData();
      print('UserProvider: User data reloaded after update');

      return true;
    } catch (e) {
      print('UserProvider: Error in updateProfile: $e');
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _setError('Failed to send verification email: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.updatePassword(currentPassword, newPassword);
      return true;
    } catch (e) {
      _setError('Failed to change password: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reload user authentication data
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      await loadUserData();
    } catch (e) {
      _setError('Failed to reload user: $e');
    }
  }

  // Sign out user
  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.signOut();
      _userModel = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.deleteUserAccount();
      _userModel = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete account: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    if (error != null) {
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check if user email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Get display name
  String get displayName =>
      userModel?.name ?? currentUser?.displayName ?? 'User';

  // Get email
  String get email => userModel?.email ?? currentUser?.email ?? '';

  // Get phone
  String get phone => userModel?.phone ?? '';

  // Get avatar URL
  String? get avatarUrl => userModel?.avatarUrl;
}
