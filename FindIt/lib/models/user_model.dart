import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.role = 'user',
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'role': role,
    };
  }

  // Create UserModel from Map (Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      avatarUrl: map['avatarUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
      role: map['role'] ?? 'user',
    );
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, phone: $phone, '
        'avatarUrl: $avatarUrl, createdAt: $createdAt, updatedAt: $updatedAt, '
        'isVerified: $isVerified, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.avatarUrl == avatarUrl &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isVerified == isVerified &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        avatarUrl.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isVerified.hashCode ^
        role.hashCode;
  }
}
