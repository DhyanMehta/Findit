import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String type; // 'text', 'image', 'location'

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = 'text',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] ?? 'text',
    );
  }
}

class Chat {
  final String id;
  final String itemId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, bool> readStatus; // userId -> hasRead

  Chat({
    required this.id,
    required this.itemId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.readStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'readStatus': readStatus,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readStatus: Map<String, bool>.from(map['readStatus'] ?? {}),
    );
  }
}

class FirebaseChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _chatsCollection => _firestore.collection('chats');

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Create or get chat between users for an item
  Future<String> createOrGetChat({
    required String itemId,
    required String otherUserId,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be logged in to chat');
      }

      // Check if chat already exists
      final existingChats = await _chatsCollection
          .where('itemId', isEqualTo: itemId)
          .where('participants', arrayContains: _currentUserId)
          .get();

      for (var doc in existingChats.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Create new chat
      final chatData = {
        'itemId': itemId,
        'participants': [_currentUserId!, otherUserId],
        'lastMessage': 'Chat started',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'readStatus': {_currentUserId!: true, otherUserId: false},
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _chatsCollection.add(chatData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be logged in to send messages');
      }

      // Get current user info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId!)
          .get();

      final userName = userDoc.data()?['name'] ?? 'Unknown User';

      final messageData = {
        'senderId': _currentUserId!,
        'senderName': userName,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
      };

      // Add message to chat messages subcollection
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update chat with last message info
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (chatDoc.exists) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        final participants = List<String>.from(chatData['participants']);

        Map<String, bool> readStatus = {};
        for (String participant in participants) {
          readStatus[participant] = participant == _currentUserId;
        }

        await _chatsCollection.doc(chatId).update({
          'lastMessage': content,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'readStatus': readStatus,
        });
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a chat
  Stream<List<Message>> getMessages(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Message.fromMap(data);
          }).toList();
        });
  }

  // Get user's chats
  Stream<List<Chat>> getUserChats() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _chatsCollection
        .where('participants', arrayContains: _currentUserId!)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Chat.fromMap(data);
          }).toList();
        });
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      if (_currentUserId == null) return;

      await _chatsCollection.doc(chatId).update({
        'readStatus.$_currentUserId': true,
      });
    } catch (e) {
      throw Exception('Failed to mark chat as read: $e');
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    try {
      if (_currentUserId == null) return 0;

      final snapshot = await _chatsCollection
          .where('participants', arrayContains: _currentUserId!)
          .get();

      int unreadCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final readStatus = Map<String, bool>.from(data['readStatus'] ?? {});
        if (readStatus[_currentUserId] == false) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      return 0;
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages in the chat
      final messagesSnapshot = await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat document
      batch.delete(_chatsCollection.doc(chatId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }
}
