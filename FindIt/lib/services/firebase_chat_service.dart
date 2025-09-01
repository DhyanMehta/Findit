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
  final String itemTitle;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, bool> readStatus; // userId -> hasRead
  final Map<String, String> aliases; // userId -> alias (e.g., User A/B)
  final Map<String, bool> shareProfile; // userId -> has shared real profile
  final String? lastSenderId;

  Chat({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.readStatus,
    required this.aliases,
    required this.shareProfile,
    this.lastSenderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'readStatus': readStatus,
      'aliases': aliases,
      'shareProfile': shareProfile,
      'lastSenderId': lastSenderId,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      itemTitle: map['itemTitle'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readStatus: Map<String, bool>.from(map['readStatus'] ?? {}),
      aliases: Map<String, String>.from(map['aliases'] ?? {}),
      shareProfile: Map<String, bool>.from(map['shareProfile'] ?? {}),
      lastSenderId: map['lastSenderId'],
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
      final currentId = _currentUserId!;
      final participants = [currentId, otherUserId];
      participants.sort();
      final uidA = participants[0];
      final uidB = participants[1];
      final aliases = {uidA: 'Anonymous User', uidB: 'Anonymous User'};
      final shareProfile = {currentId: false, otherUserId: false};

      // Fetch item title for denormalization
      String itemTitle = '';
      try {
        final itemDoc = await _firestore.collection('items').doc(itemId).get();
        if (itemDoc.exists) {
          final data = itemDoc.data() as Map<String, dynamic>;
          itemTitle = (data['title'] as String?) ?? '';
        }
      } catch (_) {}
      final chatData = {
        'itemId': itemId,
        'itemTitle': itemTitle,
        'participants': [_currentUserId!, otherUserId],
        'lastMessage': 'Chat started',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'readStatus': {_currentUserId!: true, otherUserId: false},
        'aliases': aliases,
        'shareProfile': shareProfile,
        'lastSenderId': _currentUserId!,
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

      // Determine display name based on chat anonymity settings
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }
      final chatData = chatDoc.data() as Map<String, dynamic>;
      final aliases = Map<String, String>.from(chatData['aliases'] ?? {});
      final shareProfile = Map<String, bool>.from(
        chatData['shareProfile'] ?? {},
      );

      String displayName;
      if (shareProfile[_currentUserId] == true) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId!)
            .get();
        displayName = userDoc.data()?['name'] ?? 'User';
      } else {
        displayName = aliases[_currentUserId] ?? 'User';
      }

      final messageData = {
        'senderId': _currentUserId!,
        'senderName': displayName,
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
      final participants = List<String>.from(chatData['participants'] ?? []);
      Map<String, bool> readStatus = {};
      for (String participant in participants) {
        readStatus[participant] = participant == _currentUserId;
      }

      await _chatsCollection.doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'readStatus': readStatus,
        'lastSenderId': _currentUserId,
      });
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
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Chat.fromMap(data);
          }).toList();
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return chats;
        });
  }

  // Stream incoming info requests for current user
  Stream<int> getPendingInfoRequestCount() {
    if (_currentUserId == null) return Stream.value(0);
    return _firestore
        .collectionGroup('requests')
        .where('to', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.size);
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

  // Request to share profile with the other participant (name only for now)
  Future<String> requestProfileShare({
    required String chatId,
    required String toUserId,
    List<String> fields = const ['name'],
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in to request info');
    }

    final requestData = {
      'type': 'profile_share',
      'from': _currentUserId,
      'to': toUserId,
      'fields': fields,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final doc = await _chatsCollection
        .doc(chatId)
        .collection('requests')
        .add(requestData);
    return doc.id;
  }

  // Respond to profile share request
  Future<void> respondProfileShare({
    required String chatId,
    required String requestId,
    required bool approve,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in to respond');
    }

    final reqRef = _chatsCollection
        .doc(chatId)
        .collection('requests')
        .doc(requestId);
    final reqSnap = await reqRef.get();
    if (!reqSnap.exists) {
      throw Exception('Request not found');
    }
    final data = reqSnap.data() as Map<String, dynamic>;
    final toUserId = data['to'] as String?;
    if (toUserId != _currentUserId) {
      throw Exception('Not authorized to respond to this request');
    }

    await reqRef.update({
      'status': approve ? 'approved' : 'denied',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (approve) {
      await _chatsCollection.doc(chatId).update({
        'shareProfile.$_currentUserId': true,
      });
    }
  }

  // ---------------- CLAIM / HANDOVER WORKFLOW ----------------
  // A claim lives under chats/{chatId}/claims
  // Fields: requestedBy, to (finder), itemId, status(pending|scheduled|completed|denied|cancelled),
  // handoverAt (Timestamp), handoverLocation (String), createdAt, updatedAt, completedAt

  Future<String> requestItemClaim({
    required String chatId,
    required String toUserId,
    required String itemId,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in to request item');
    }
    final data = {
      'requestedBy': _currentUserId,
      'to': toUserId,
      'itemId': itemId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final doc = await _chatsCollection
        .doc(chatId)
        .collection('claims')
        .add(data);
    return doc.id;
  }

  Future<void> approveItemClaim({
    required String chatId,
    required String claimId,
    required DateTime handoverAt,
    required String handoverLocation,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in to approve');
    }
    final ref = _chatsCollection.doc(chatId).collection('claims').doc(claimId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Claim not found');
    final data = snap.data() as Map<String, dynamic>;
    final toUserId = data['to'] as String?;
    if (toUserId != _currentUserId) {
      throw Exception('Only the recipient can approve this claim');
    }
    await ref.update({
      'status': 'scheduled',
      'handoverAt': Timestamp.fromDate(handoverAt),
      'handoverLocation': handoverLocation,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markClaimCollected({
    required String chatId,
    required String claimId,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in');
    }
    final ref = _chatsCollection.doc(chatId).collection('claims').doc(claimId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Claim not found');
    final data = snap.data() as Map<String, dynamic>;
    final requestedBy = data['requestedBy'] as String?;
    if (requestedBy != _currentUserId) {
      throw Exception('Only the requester can mark as collected');
    }
    await ref.update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Also mark related item as resolved
    final itemId = (data['itemId'] as String?) ?? '';
    if (itemId.isNotEmpty) {
      try {
        await _firestore.collection('items').doc(itemId).update({
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  // Claims targeting current user (as recipient) and pending approval
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingClaimsForMe(
    String chatId,
  ) {
    if (_currentUserId == null) {
      return const Stream.empty();
    }
    return _chatsCollection
        .doc(chatId)
        .collection('claims')
        .where('to', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Claims for current user as requester that are scheduled (awaiting collection)
  Stream<List<Map<String, dynamic>>> myScheduledClaims() {
    if (_currentUserId == null) return const Stream.empty();
    return _firestore
        .collectionGroup('claims')
        .where('requestedBy', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'scheduled')
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) => {
                  ...d.data(),
                  'claimId': d.id,
                  'chatId': d.reference.parent.parent?.id,
                },
              )
              .toList(),
        );
  }

  // Global count of completed claims (items returned)
  Stream<int> completedClaimsCount() {
    return _firestore
        .collectionGroup('claims')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((s) => s.size);
  }
}
