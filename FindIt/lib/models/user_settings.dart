class UserSettings {
  final String userId;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool chatNotifications;
  final bool locationServices;
  final bool profileVisibility;
  final bool showOnlineStatus;
  final String theme; // 'light', 'dark', 'system'
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.userId,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.chatNotifications = true,
    this.locationServices = false,
    this.profileVisibility = true,
    this.showOnlineStatus = true,
    this.theme = 'system',
    this.language = 'en',
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'chatNotifications': chatNotifications,
      'locationServices': locationServices,
      'profileVisibility': profileVisibility,
      'showOnlineStatus': showOnlineStatus,
      'theme': theme,
      'language': language,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Firestore Map
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      userId: map['userId'] ?? '',
      pushNotifications: map['pushNotifications'] ?? true,
      emailNotifications: map['emailNotifications'] ?? true,
      chatNotifications: map['chatNotifications'] ?? true,
      locationServices: map['locationServices'] ?? false,
      profileVisibility: map['profileVisibility'] ?? true,
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      theme: map['theme'] ?? 'system',
      language: map['language'] ?? 'en',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  // Create a copy with updated values
  UserSettings copyWith({
    String? userId,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? chatNotifications,
    bool? locationServices,
    bool? profileVisibility,
    bool? showOnlineStatus,
    String? theme,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      chatNotifications: chatNotifications ?? this.chatNotifications,
      locationServices: locationServices ?? this.locationServices,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserSettings(userId: $userId, pushNotifications: $pushNotifications, emailNotifications: $emailNotifications, chatNotifications: $chatNotifications, locationServices: $locationServices, profileVisibility: $profileVisibility, showOnlineStatus: $showOnlineStatus, theme: $theme, language: $language, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserSettings &&
        other.userId == userId &&
        other.pushNotifications == pushNotifications &&
        other.emailNotifications == emailNotifications &&
        other.chatNotifications == chatNotifications &&
        other.locationServices == locationServices &&
        other.profileVisibility == profileVisibility &&
        other.showOnlineStatus == showOnlineStatus &&
        other.theme == theme &&
        other.language == language &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        pushNotifications.hashCode ^
        emailNotifications.hashCode ^
        chatNotifications.hashCode ^
        locationServices.hashCode ^
        profileVisibility.hashCode ^
        showOnlineStatus.hashCode ^
        theme.hashCode ^
        language.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
