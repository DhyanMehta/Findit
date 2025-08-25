import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _flnp =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;
  final List<StreamSubscription> _subscriptions = [];

  Future<void> initialize() async {
    if (_initialized) return;
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _flnp.initialize(settings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for chat messages and requests',
      importance: Importance.high,
    );
    await _flnp
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> start() async {
    await initialize();
    await _attachListeners();
  }

  Future<void> stop() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> _attachListeners() async {
    await stop();
    final user = _auth.currentUser;
    if (user == null) return;
    final userId = user.uid;

    // Listen to latest message per chat and notify if from other user
    final chatsSub = _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
          for (final chat in snapshot.docs) {
            final chatData = chat.data();
            final itemTitle =
                (chatData['itemTitle'] as String?) ?? 'New message';
            final messagesSub = chat.reference
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots()
                .listen((ms) {
                  if (ms.docs.isEmpty) return;
                  final m = ms.docs.first.data();
                  final senderId = m['senderId'] as String?;
                  final content = (m['content'] as String?) ?? '';
                  final ts = (m['timestamp'] as Timestamp?);
                  if (senderId == null || senderId == userId || ts == null)
                    return;

                  _show('New message', '$itemTitle: $content');
                });
            _subscriptions.add(messagesSub);
          }
        });
    _subscriptions.add(chatsSub);

    // Listen to info requests to current user
    final reqsSub = _firestore
        .collectionGroup('requests')
        .where('to', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            _show('Info request', 'Someone requested to view your info');
          }
        });
    _subscriptions.add(reqsSub);
  }

  Future<void> _show(String title, String body) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for chat messages and requests',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }
}
