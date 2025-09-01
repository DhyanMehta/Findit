import 'package:flutter/foundation.dart';
import '../models/user_settings.dart';
import '../services/settings_service.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  UserSettings? _settings;
  bool _isLoading = false;
  String? _errorMessage;

  UserSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize settings
  Future<void> initializeSettings() async {
    await loadSettings();
  }

  // Load user settings
  Future<void> loadSettings() async {
    _setLoading(true);
    _setError(null);

    try {
      _settings = await _settingsService.getUserSettings();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update notification settings
  Future<bool> updateNotificationSetting(String setting, bool value) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _settingsService.updateNotificationSetting(
        setting,
        value,
      );

      if (success && _settings != null) {
        // Update local settings
        switch (setting) {
          case 'pushNotifications':
            _settings = _settings!.copyWith(
              pushNotifications: value,
              updatedAt: DateTime.now(),
            );
            break;
          case 'emailNotifications':
            _settings = _settings!.copyWith(
              emailNotifications: value,
              updatedAt: DateTime.now(),
            );
            break;
          case 'chatNotifications':
            _settings = _settings!.copyWith(
              chatNotifications: value,
              updatedAt: DateTime.now(),
            );
            break;
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Failed to update notification setting: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update privacy settings
  Future<bool> updatePrivacySetting(String setting, bool value) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _settingsService.updatePrivacySetting(
        setting,
        value,
      );

      if (success && _settings != null) {
        // Update local settings
        switch (setting) {
          case 'profileVisibility':
            _settings = _settings!.copyWith(
              profileVisibility: value,
              updatedAt: DateTime.now(),
            );
            break;
          case 'showOnlineStatus':
            _settings = _settings!.copyWith(
              showOnlineStatus: value,
              updatedAt: DateTime.now(),
            );
            break;
          case 'locationServices':
            _settings = _settings!.copyWith(
              locationServices: value,
              updatedAt: DateTime.now(),
            );
            break;
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Failed to update privacy setting: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update theme
  Future<bool> updateTheme(String theme) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _settingsService.updateTheme(theme);

      if (success && _settings != null) {
        _settings = _settings!.copyWith(
          theme: theme,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Failed to update theme: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update language
  Future<bool> updateLanguage(String language) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _settingsService.updateLanguage(language);

      if (success && _settings != null) {
        _settings = _settings!.copyWith(
          language: language,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Failed to update language: $e');
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
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Getters for specific settings
  bool get pushNotifications => _settings?.pushNotifications ?? true;
  bool get emailNotifications => _settings?.emailNotifications ?? true;
  bool get chatNotifications => _settings?.chatNotifications ?? true;
  bool get locationServices => _settings?.locationServices ?? false;
  bool get profileVisibility => _settings?.profileVisibility ?? true;
  bool get showOnlineStatus => _settings?.showOnlineStatus ?? true;
  String get theme => _settings?.theme ?? 'system';
  String get language => _settings?.language ?? 'en';
}
