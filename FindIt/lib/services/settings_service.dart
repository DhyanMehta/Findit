import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_settings.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user settings
  Future<UserSettings?> getUserSettings() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('user_settings')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserSettings.fromMap(doc.data()!);
      } else {
        // Create default settings if none exist
        final defaultSettings = UserSettings(
          userId: userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('user_settings')
            .doc(userId)
            .set(defaultSettings.toMap());

        return defaultSettings;
      }
    } catch (e) {
      print('Error getting user settings: $e');
      return null;
    }
  }

  // Update user settings
  Future<bool> updateUserSettings(UserSettings settings) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('user_settings')
          .doc(userId)
          .set(updatedSettings.toMap(), SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error updating user settings: $e');
      return false;
    }
  }

  // Update specific setting
  Future<bool> updateSetting(String key, dynamic value) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      await _firestore.collection('user_settings').doc(userId).update({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating setting $key: $e');
      return false;
    }
  }

  // Get settings stream for real-time updates
  Stream<UserSettings?> getUserSettingsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(null);

    return _firestore.collection('user_settings').doc(userId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return UserSettings.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Privacy settings methods
  Future<bool> updatePrivacySetting(String setting, bool value) async {
    return updateSetting(setting, value);
  }

  // Notification settings methods
  Future<bool> updateNotificationSetting(String setting, bool value) async {
    return updateSetting(setting, value);
  }

  // Theme setting
  Future<bool> updateTheme(String theme) async {
    return updateSetting('theme', theme);
  }

  // Language setting
  Future<bool> updateLanguage(String language) async {
    return updateSetting('language', language);
  }

  // Delete user settings (for account deletion)
  Future<bool> deleteUserSettings() async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      await _firestore.collection('user_settings').doc(userId).delete();

      return true;
    } catch (e) {
      print('Error deleting user settings: $e');
      return false;
    }
  }
}
