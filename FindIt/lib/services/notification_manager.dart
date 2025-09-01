import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';
import 'fcm_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();

  Future<void> initialize() async {
    await _fcmService.initialize();
  }

  // Send notification when a new item is posted
  Future<void> notifyNewItemPosted(Item item) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get all users except the current user to notify them about new item
      final usersSnapshot = await _firestore.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        if (userDoc.id != currentUser.uid) {
          final itemType = item.type == 'lost' ? 'Lost' : 'Found';

          await _fcmService.sendNotificationToUser(
            userId: userDoc.id,
            title: 'New $itemType Item Posted!',
            body:
                '${item.title} has been reported ${item.type}. Check if it matches what you\'re looking for!',
            type: item.type == 'lost' ? 'item_lost' : 'item_found',
            data: {
              'itemId': item.id,
              'itemTitle': item.title,
              'itemType': item.type,
              'postedBy': currentUser.uid,
              'action': 'view_item',
            },
          );
        }
      }

      print('Notifications sent for new item: ${item.title}');
    } catch (e) {
      print('Error sending new item notifications: $e');
    }
  }

  // Send notification for item matches (when someone finds something similar)
  Future<void> notifyItemMatch({
    required String itemOwnerId,
    required String matchedItemId,
    required String matchedItemTitle,
    required String finderName,
    required String itemType,
  }) async {
    try {
      final action = itemType == 'lost' ? 'found' : 'might have lost';

      await _fcmService.sendNotificationToUser(
        userId: itemOwnerId,
        title: 'Possible Match Found! 🎉',
        body:
            '$finderName $action an item that matches your "$matchedItemTitle". Click to view details and connect!',
        type: 'item_match',
        data: {
          'matchedItemId': matchedItemId,
          'matchedItemTitle': matchedItemTitle,
          'finderName': finderName,
          'action': 'view_match',
        },
      );

      print('Match notification sent to $itemOwnerId');
    } catch (e) {
      print('Error sending match notification: $e');
    }
  }

  // Send notification when someone requests item information
  Future<void> notifyInfoRequest({
    required String itemOwnerId,
    required String requesterName,
    required String itemTitle,
    required String requestId,
  }) async {
    try {
      await _fcmService.sendNotificationToUser(
        userId: itemOwnerId,
        title: 'Info Request Received 📩',
        body:
            '$requesterName wants to know more about your "$itemTitle". Respond to help them!',
        type: 'request',
        data: {
          'requestId': requestId,
          'requesterName': requesterName,
          'itemTitle': itemTitle,
          'action': 'view_request',
        },
      );

      print('Info request notification sent to $itemOwnerId');
    } catch (e) {
      print('Error sending info request notification: $e');
    }
  }

  // Send notification for new chat messages
  Future<void> notifyNewMessage({
    required String recipientId,
    required String senderName,
    required String messageContent,
    required String itemTitle,
    required String chatId,
  }) async {
    try {
      await _fcmService.sendNotificationToUser(
        userId: recipientId,
        title: 'New Message from $senderName 💬',
        body:
            'About "$itemTitle": ${messageContent.length > 50 ? messageContent.substring(0, 50) + '...' : messageContent}',
        type: 'message',
        data: {
          'chatId': chatId,
          'senderName': senderName,
          'itemTitle': itemTitle,
          'action': 'open_chat',
        },
      );

      print('Message notification sent to $recipientId');
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }

  // Send notification when an item is marked as resolved/found
  Future<void> notifyItemResolved({
    required String itemOwnerId,
    required String itemTitle,
    required String itemType,
  }) async {
    try {
      final message = itemType == 'lost'
          ? 'Great news! Your lost "$itemTitle" has been marked as found!'
          : 'Your found "$itemTitle" has been returned to its owner!';

      await _fcmService.sendNotificationToUser(
        userId: itemOwnerId,
        title: 'Item Resolved! ✅',
        body: message,
        type: 'item_resolved',
        data: {
          'itemTitle': itemTitle,
          'itemType': itemType,
          'action': 'view_resolved',
        },
      );

      print('Resolution notification sent to $itemOwnerId');
    } catch (e) {
      print('Error sending resolution notification: $e');
    }
  }

  // Send location-based notifications
  Future<void> notifyNearbyItemActivity({
    required String userId,
    required String itemTitle,
    required String location,
    required String activityType, // 'posted', 'found', 'updated'
  }) async {
    try {
      String title = '';
      String body = '';

      switch (activityType) {
        case 'posted':
          title = 'Nearby Item Posted 📍';
          body =
              'Someone posted about "$itemTitle" near $location. Check if it\'s relevant to you!';
          break;
        case 'found':
          title = 'Item Found Nearby! 🎯';
          body =
              '"$itemTitle" was found near $location. Could this be what you\'re looking for?';
          break;
        case 'updated':
          title = 'Nearby Item Updated 📌';
          body =
              'Information about "$itemTitle" near $location has been updated.';
          break;
      }

      if (title.isNotEmpty) {
        await _fcmService.sendNotificationToUser(
          userId: userId,
          title: title,
          body: body,
          type: 'location_update',
          data: {
            'itemTitle': itemTitle,
            'location': location,
            'activityType': activityType,
            'action': 'view_nearby',
          },
        );
      }

      print('Location-based notification sent to $userId');
    } catch (e) {
      print('Error sending location notification: $e');
    }
  }

  // Send notification reminders
  Future<void> notifyReminder({
    required String userId,
    required String reminderType,
    required String itemTitle,
  }) async {
    try {
      String title = '';
      String body = '';

      switch (reminderType) {
        case 'update_item':
          title = 'Update Reminder 📝';
          body =
              'Don\'t forget to update the status of your "$itemTitle" if there are any developments!';
          break;
        case 'check_messages':
          title = 'Unread Messages 📨';
          body = 'You have unread messages about "$itemTitle". Check them out!';
          break;
        case 'item_expires':
          title = 'Item Expiring Soon ⏰';
          body =
              'Your "$itemTitle" post will expire soon. Renew it if it\'s still relevant!';
          break;
      }

      if (title.isNotEmpty) {
        await _fcmService.sendNotificationToUser(
          userId: userId,
          title: title,
          body: body,
          type: 'reminder',
          data: {
            'itemTitle': itemTitle,
            'reminderType': reminderType,
            'action': 'handle_reminder',
          },
        );
      }

      print('Reminder notification sent to $userId');
    } catch (e) {
      print('Error sending reminder notification: $e');
    }
  }

  // Get notifications stream
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return _fcmService.getNotificationsStream();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationDocId) async {
    return _fcmService.markAsRead(notificationDocId);
  }

  // Get unread notifications count
  Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final unreadNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('All notifications marked as read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationDocId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationDocId)
          .delete();

      print('Notification deleted');
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final notifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All notifications cleared');
    } catch (e) {
      print('Error clearing all notifications: $e');
    }
  }
}
