import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';

class FirebaseItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _itemsCollection => _firestore.collection('items');
  CollectionReference get _chatsCollection => _firestore.collection('chats');

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Create new item (lost or found)
  Future<String> createItem(Item item) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be logged in to create items');
      }

      final itemData = item.toMap();
      itemData['userId'] = _currentUserId;
      itemData['createdAt'] = FieldValue.serverTimestamp();
      itemData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _itemsCollection.add(itemData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  // Get all items (for home screen)
  Stream<List<Item>> getAllItems() {
    return _itemsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Item.fromMap(data);
          }).toList();
        });
  }

  // Get user's items
  Stream<List<Item>> getUserItems(String userId) {
    try {
      return _itemsCollection
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final items = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return Item.fromMap(data);
            }).toList();

            // Sort in memory to avoid index requirement
            items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return items;
          });
    } catch (e) {
      print('Error getting user items: $e');
      return Stream.value([]);
    }
  }

  // Search items
  Stream<List<Item>> searchItems({
    String? query,
    String? category,
    String? status,
    String? location,
  }) {
    try {
      Query itemQuery = _itemsCollection;

      // Only add one where clause to avoid index requirements
      if (status != null && status.isNotEmpty) {
        itemQuery = itemQuery.where('status', isEqualTo: status);
      } else if (category != null && category.isNotEmpty) {
        itemQuery = itemQuery.where('category', isEqualTo: category);
      }

      return itemQuery.snapshots().map((snapshot) {
        List<Item> items = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Item.fromMap(data);
        }).toList();

        // Apply filters in memory to avoid index requirements
        if (query != null && query.isNotEmpty) {
          final lowercaseQuery = query.toLowerCase();
          items = items.where((item) {
            return item.title.toLowerCase().contains(lowercaseQuery) ||
                item.description.toLowerCase().contains(lowercaseQuery) ||
                item.location.toLowerCase().contains(lowercaseQuery);
          }).toList();
        }

        if (category != null && category.isNotEmpty && status != null) {
          items = items.where((item) => item.category == category).toList();
        }

        if (status != null && status.isNotEmpty && category != null) {
          items = items.where((item) => item.status == status).toList();
        }

        if (location != null && location.isNotEmpty) {
          items = items
              .where(
                (item) => item.location.toLowerCase().contains(
                  location.toLowerCase(),
                ),
              )
              .toList();
        }

        // Sort by creation date (newest first)
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return items;
      });
    } catch (e) {
      print('Error searching items: $e');
      return Stream.value([]);
    }
  }

  // Update item
  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _itemsCollection.doc(itemId).update(data);
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    try {
      await _itemsCollection.doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // Mark item as found/resolved
  Future<void> markItemAsResolved(String itemId) async {
    try {
      await updateItem(itemId, {
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark item as resolved: $e');
    }
  }

  // Get item by ID
  Future<Item?> getItemById(String itemId) async {
    try {
      final doc = await _itemsCollection.doc(itemId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Item.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get item: $e');
    }
  }

  // Get items by location (for map screen)
  Stream<List<Item>> getItemsByLocation(double lat, double lng, double radius) {
    // For now, return all items. In a real app, you'd use geohashing or GeoFlutterFire
    return getAllItems();
  }

  // Report inappropriate item
  Future<void> reportItem(String itemId, String reason) async {
    try {
      await _firestore.collection('reports').add({
        'itemId': itemId,
        'reportedBy': _currentUserId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report item: $e');
    }
  }

  // Get statistics for dashboard
  Future<Map<String, int>> getItemStatistics() async {
    try {
      final snapshot = await _itemsCollection.get();

      int totalItems = snapshot.docs.length;
      int lostItems = 0;
      int foundItems = 0;
      int resolvedItems = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        final type = data['type'] as String?;

        if (status == 'resolved') {
          resolvedItems++;
        } else if (type == 'lost') {
          lostItems++;
        } else if (type == 'found') {
          foundItems++;
        }
      }

      return {
        'total': totalItems,
        'lost': lostItems,
        'found': foundItems,
        'resolved': resolvedItems,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}
