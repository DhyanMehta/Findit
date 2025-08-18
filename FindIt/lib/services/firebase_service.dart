import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Stream of all items
  static Stream<List<Item>> getItemsStream() {
    return _firestore
        .collection('items')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return Item(
                  id: doc.id,
                  title: data['title'] ?? '',
                  description: data['description'] ?? '',
                  category: data['category'] ?? '',
                  imageUrl: data['imageUrl'] ?? '',
                  location: data['location'] ?? '',
                  dateTime: (data['dateTime'] as Timestamp).toDate(),
                  contactMethod: data['contactMethod'] ?? '',
                  isFound: data['isFound'] ?? false,
                  userId: data['userId'] ?? '',
                  latitude: (data['latitude'] ?? 0.0).toDouble(),
                  longitude: (data['longitude'] ?? 0.0).toDouble(),
                );
              })
              .where((item) => item != null)
              .cast<Item>()
              .toList();
        });
  }

  // Add new item
  static Future<void> addItem(Item item) async {
    try {
      await _firestore.collection('items').add({
        'title': item.title,
        'description': item.description,
        'category': item.category,
        'imageUrl': item.imageUrl,
        'location': item.location,
        'dateTime': Timestamp.fromDate(item.dateTime),
        'contactMethod': item.contactMethod,
        'isFound': item.isFound,
        'userId': item.userId,
        'latitude': item.latitude,
        'longitude': item.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  // Update item
  static Future<void> updateItem(Item item) async {
    try {
      await _firestore.collection('items').doc(item.id).update({
        'title': item.title,
        'description': item.description,
        'category': item.category,
        'imageUrl': item.imageUrl,
        'location': item.location,
        'dateTime': Timestamp.fromDate(item.dateTime),
        'contactMethod': item.contactMethod,
        'isFound': item.isFound,
        'latitude': item.latitude,
        'longitude': item.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  // Delete item
  static Future<void> deleteItem(String itemId) async {
    try {
      await _firestore.collection('items').doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // Get items by user
  static Stream<List<Item>> getUserItemsStream(String userId) {
    return _firestore
        .collection('items')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return Item(
                  id: doc.id,
                  title: data['title'] ?? '',
                  description: data['description'] ?? '',
                  category: data['category'] ?? '',
                  imageUrl: data['imageUrl'] ?? '',
                  location: data['location'] ?? '',
                  dateTime: (data['dateTime'] as Timestamp).toDate(),
                  contactMethod: data['contactMethod'] ?? '',
                  isFound: data['isFound'] ?? false,
                  userId: data['userId'] ?? '',
                  latitude: (data['latitude'] ?? 0.0).toDouble(),
                  longitude: (data['longitude'] ?? 0.0).toDouble(),
                );
              })
              .where((item) => item != null)
              .cast<Item>()
              .toList();
        });
  }

  // Search items
  static Stream<List<Item>> searchItemsStream(String query, String? category) {
    Query itemsQuery = _firestore.collection('items');

    if (category != null && category != 'All') {
      itemsQuery = itemsQuery.where('category', isEqualTo: category);
    }

    return itemsQuery.orderBy('dateTime', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Item(
              id: doc.id,
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              category: data['category'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
              location: data['location'] ?? '',
              dateTime: (data['dateTime'] as Timestamp).toDate(),
              contactMethod: data['contactMethod'] ?? '',
              isFound: data['isFound'] ?? false,
              userId: data['userId'] ?? '',
              latitude: (data['latitude'] ?? 0.0).toDouble(),
              longitude: (data['longitude'] ?? 0.0).toDouble(),
            );
          })
          .where((item) {
            if (query.isEmpty) return true;
            return item.title.toLowerCase().contains(query.toLowerCase()) ||
                item.description.toLowerCase().contains(query.toLowerCase());
          })
          .toList();
    });
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}
