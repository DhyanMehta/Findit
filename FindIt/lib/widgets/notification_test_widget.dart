import 'package:flutter/material.dart';
import '../services/notification_manager.dart';
import '../models/item.dart';

class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationManager = NotificationManager();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔔 Notification Test',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test the notification system:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      _sendTestItemFoundNotification(notificationManager),
                  icon: const Icon(Icons.find_in_page, size: 16),
                  label: const Text('Item Found'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _sendTestItemLostNotification(notificationManager),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Item Lost'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _sendTestMessageNotification(notificationManager),
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _sendTestMatchNotification(notificationManager),
                  icon: const Icon(Icons.connect_without_contact, size: 16),
                  label: const Text('Match'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendTestItemFoundNotification(NotificationManager notificationManager) {
    // Simulate a found item notification
    final testItem = Item(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Lost Wallet',
      description: 'Black leather wallet with cards and cash',
      category: 'Personal Items',
      imageUrl: '',
      location: 'University Library',
      dateTime: DateTime.now(),
      contactMethod: 'email',
      isFound: true,
      userId: 'test_user',
      latitude: 0.0,
      longitude: 0.0,
      type: 'found',
    );

    notificationManager.notifyNewItemPosted(testItem);
  }

  void _sendTestItemLostNotification(NotificationManager notificationManager) {
    // Simulate a lost item notification
    final testItem = Item(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: 'iPhone 15 Pro',
      description: 'Silver iPhone 15 Pro with blue case',
      category: 'Electronics',
      imageUrl: '',
      location: 'Coffee Shop Downtown',
      dateTime: DateTime.now(),
      contactMethod: 'phone',
      isFound: false,
      userId: 'test_user',
      latitude: 0.0,
      longitude: 0.0,
      type: 'lost',
    );

    notificationManager.notifyNewItemPosted(testItem);
  }

  void _sendTestMessageNotification(NotificationManager notificationManager) {
    notificationManager.notifyNewMessage(
      recipientId:
          'current_user', // This will be ignored since we can't send to ourselves
      senderName: 'John Doe',
      messageContent:
          'Hi, I think I found your lost keys. Are they silver with a BMW keychain?',
      itemTitle: 'Lost Keys',
      chatId: 'test_chat_id',
    );
  }

  void _sendTestMatchNotification(NotificationManager notificationManager) {
    notificationManager.notifyItemMatch(
      itemOwnerId: 'current_user',
      matchedItemId: 'match_test_id',
      matchedItemTitle: 'Laptop Charger',
      finderName: 'Sarah Smith',
      itemType: 'lost',
    );
  }
}
