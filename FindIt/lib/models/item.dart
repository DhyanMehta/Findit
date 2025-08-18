import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String location;
  final DateTime dateTime;
  final String contactMethod;
  final bool isFound;
  final String userId;
  final double latitude;
  final double longitude;
  final String status; // 'active', 'resolved'
  final String type; // 'lost', 'found'
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.location,
    required this.dateTime,
    required this.contactMethod,
    required this.isFound,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.status = 'active',
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : type = type ?? (isFound ? 'found' : 'lost'),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert Item to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'location': location,
      'dateTime': Timestamp.fromDate(dateTime),
      'contactMethod': contactMethod,
      'isFound': isFound,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create Item from Map (Firestore document)
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      location: map['location'] ?? '',
      dateTime: (map['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      contactMethod: map['contactMethod'] ?? '',
      isFound: map['isFound'] ?? false,
      userId: map['userId'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'active',
      type: map['type'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create a copy of Item with updated fields
  Item copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    String? location,
    DateTime? dateTime,
    String? contactMethod,
    bool? isFound,
    String? userId,
    double? latitude,
    double? longitude,
    String? status,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      dateTime: dateTime ?? this.dateTime,
      contactMethod: contactMethod ?? this.contactMethod,
      isFound: isFound ?? this.isFound,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Item(id: $id, title: $title, type: $type, status: $status, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
