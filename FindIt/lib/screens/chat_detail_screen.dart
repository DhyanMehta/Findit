import 'package:flutter/material.dart';
import '../services/firebase_chat_service.dart';
import '../services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseChatService _chatService = FirebaseChatService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  String? _chatId;
  String? _itemId;
  List<String> _participants = [];
  Map<String, String> _aliases = {};
  Map<String, bool> _shareProfile = {};
  String _otherUserId = '';

  @override
  void initState() {
    super.initState();
    _initializeFromConversation();
  }

  void _initializeFromConversation() {
    final convo = widget.conversation;
    _chatId = convo['chatId'] ?? convo['id'];
    _itemId = convo['itemId'];
    if (convo['participants'] != null) {
      _participants = List<String>.from(convo['participants']);
    }

    // Fetch chat metadata (aliases/shareProfile/participants) when available
    if (_chatId != null) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .snapshots()
          .listen((doc) {
            if (!mounted || !doc.exists) return;
            final data = doc.data() as Map<String, dynamic>;
            setState(() {
              _participants = List<String>.from(
                data['participants'] ?? _participants,
              );
              _aliases = Map<String, String>.from(data['aliases'] ?? {});
              _shareProfile = Map<String, bool>.from(
                data['shareProfile'] ?? {},
              );
              final current = _authService.currentUser?.uid;
              if (current != null) {
                _otherUserId = _participants.firstWhere(
                  (p) => p != current,
                  orElse: () => '',
                );
              }
            });
          });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    if (_chatId == null) return;
    final content = _messageController.text.trim();
    _messageController.clear();
    _chatService.sendMessage(chatId: _chatId!, content: content);
  }

  Future<void> _requestInfo() async {
    if (_chatId == null || _otherUserId.isEmpty) return;
    await _chatService.requestProfileShare(
      chatId: _chatId!,
      toUserId: _otherUserId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Info request sent')));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _requestsStream() {
    if (_chatId == null || _authService.currentUser == null) return null;
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('requests')
        .where('to', isEqualTo: _authService.currentUser!.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid ?? '';
    final otherDisplayName = _shareProfile[_otherUserId] == true
        ? 'User' // Real name will show per message when shared
        : (_aliases[_otherUserId] ?? 'User');
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(radius: 18, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherDisplayName, style: const TextStyle(fontSize: 16)),
                  const Text(
                    'Anonymous chat',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Request info',
            onPressed: _requestInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Item info banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _itemId ?? 'Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Lost item discussion',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item details coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Pending info requests banner for current user
          if (_requestsStream() != null)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _requestsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }
                final req = snapshot.data!.docs.first;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.privacy_tip, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'The other user requested to view your name. Share?',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _chatService.respondProfileShare(
                            chatId: _chatId!,
                            requestId: req.id,
                            approve: false,
                          );
                        },
                        child: const Text('Deny'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _chatService.respondProfileShare(
                            chatId: _chatId!,
                            requestId: req.id,
                            approve: true,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Share'),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Messages
          Expanded(
            child: _chatId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<Message>>(
                    stream: _chatService.getMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages = snapshot.data ?? [];
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUserId;
                          return _buildMessageBubble(
                            text: message.content,
                            isMe: isMe,
                            timestamp: message.timestamp,
                          );
                        },
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message... (anonymous until you share)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    required DateTime timestamp,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const CircleAvatar(radius: 16, child: Icon(Icons.person)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMe
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(radius: 16, child: Icon(Icons.person)),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
