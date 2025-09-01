import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Top-level function for background message handling
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  await FCMService().handleBackgroundMessage(message);
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;
  String? _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    // Request permissions
    await _requestPermissions();

    // Get FCM token
    await _getFCMToken();

    // Set up message handlers
    await _setupMessageHandlers();

    _initialized = true;
    print('FCM Service initialized successfully');
  }

  Future<void> _requestPermissions() async {
    // Request notification permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'item_alerts',
        'Item Alerts',
        description: 'Notifications for lost/found items',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'Chat messages and communications',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'requests',
        'Requests',
        description: 'Information requests and updates',
        importance: Importance.max,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'general',
        'General',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    ];

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    for (final channel in channels) {
      await androidImplementation?.createNotificationChannel(channel);
    }
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      print('FCM Token: $_fcmToken');

      // Save token to user document for sending notifications
      await _saveTokenToDatabase();

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((token) async {
        _fcmToken = token;
        await _saveTokenToDatabase();
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToDatabase() async {
    final token = await _fcm.getToken();
    if (token == null) return;

    _fcmToken = token;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
      });
      print('FCM token saved to database: ${_fcmToken?.substring(0, 20)}...');
    } catch (e) {
      // If user document doesn't exist, create it
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': _fcmToken,
          'fcmTokenUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('FCM token saved to new user document');
      } catch (e2) {
        print('Error saving FCM token: $e2');
      }
    }
  }

  Future<void> _setupMessageHandlers() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message when app is launched from terminated state
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // Store notification in database
    await _storeNotification(message);

    // Show local notification
    await _showLocalNotification(message);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened app: ${message.messageId}');

    // Handle navigation based on notification type
    final data = message.data;
    final type = data['type'] ?? '';

    // You can implement navigation logic here based on notification type
    switch (type) {
      case 'item_found':
      case 'item_lost':
        // Navigate to item details
        break;
      case 'message':
        // Navigate to chat
        break;
      case 'request':
        // Navigate to requests
        break;
      default:
        // Navigate to notifications screen
        break;
    }
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    await _storeNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] ?? 'general';

    String channelId;
    switch (type) {
      case 'item_found':
      case 'item_lost':
        channelId = 'item_alerts';
        break;
      case 'message':
        channelId = 'messages';
        break;
      case 'request':
        channelId = 'requests';
        break;
      default:
        channelId = 'general';
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        message.notification?.body ?? '',
        htmlFormatBigText: true,
        contentTitle: message.notification?.title ?? '',
        htmlFormatContentTitle: true,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'FindIt',
      message.notification?.body ?? 'New notification',
      details,
      payload: jsonEncode(data),
    );
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'item_alerts':
        return 'Item Alerts';
      case 'messages':
        return 'Messages';
      case 'requests':
        return 'Requests';
      default:
        return 'General';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'item_alerts':
        return 'Notifications for lost/found items';
      case 'messages':
        return 'Chat messages and communications';
      case 'requests':
        return 'Information requests and updates';
      default:
        return 'General app notifications';
    }
  }

  Future<void> _storeNotification(RemoteMessage message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final data = message.data;
      final notification = {
        'id':
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'FindIt',
        'message': message.notification?.body ?? 'New notification',
        'type': data['type'] ?? 'general',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'userId': user.uid,
        'data': data,
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add(notification);

      print('Notification stored in database');
    } catch (e) {
      print('Error storing notification: $e');
    }
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null) {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      print('Notification tapped with data: $data');

      // Handle navigation based on notification data
      // This can be implemented with your navigation system
    }
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        print('User $userId has no FCM token');
        return;
      }

      // Create the notification payload (for future FCM server integration)
      // final notificationData = {
      //   'to': fcmToken,
      //   'notification': {
      //     'title': title,
      //     'body': body,
      //     'sound': 'default',
      //   },
      //   'data': {
      //     'type': type,
      //     'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      //     ...?data,
      //   },
      //   'android': {
      //     'priority': 'high',
      //     'notification': {
      //       'channel_id': _getChannelIdForType(type),
      //       'priority': 'high',
      //     },
      //   },
      //   'apns': {
      //     'payload': {
      //       'aps': {
      //         'sound': 'default',
      //         'badge': 1,
      //       },
      //     },
      //   },
      // };

      // Note: In production, you would send this to FCM server
      // For now, we'll store it directly as a notification
      await _storeNotificationForUser(userId, title, body, type, data);

      print('Notification sent to user $userId');
    } catch (e) {
      print('Error sending notification to user: $e');
    }
  }

  Future<void> _storeNotificationForUser(
    String userId,
    String title,
    String body,
    String type,
    Map<String, dynamic>? data,
  ) async {
    try {
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'message': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'userId': userId,
        'data': data ?? {},
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification);
    } catch (e) {
      print('Error storing notification for user: $e');
    }
  }

  // Get notifications stream for current user
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationDocId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationDocId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get FCM token for current user
  String? get fcmToken => _fcmToken;

  // Dispose resources
  void dispose() {
    // Clean up resources if needed
  }
}
