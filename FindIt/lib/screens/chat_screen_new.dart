import 'package:flutter/material.dart';
import '../services/firebase_chat_service.dart';
import '../services/firebase_auth_service.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = FirebaseChatService();
  final _authService = FirebaseAuthService();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Chats'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by participant name...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Chat> _filterChats(List<Chat> chats) {
    if (_searchQuery.isEmpty) return chats;

    return chats.where((chat) {
      return chat.participants.any(
        (participant) => participant.toLowerCase().contains(_searchQuery),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Please sign in to view chats',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Search Chats',
          ),
        ],
      ),
      body: StreamBuilder<List<Chat>>(
        stream: _chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your internet connection',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Rebuild to retry
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final allChats = snapshot.data ?? [];
          final filteredChats = _filterChats(allChats);

          if (allChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting about lost or found items!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to home screen to find items to chat about
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Browse Items'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (filteredChats.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No chats found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Rebuild to refresh
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredChats.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final chat = filteredChats[index];
                return _ChatCard(
                  chat: chat,
                  currentUserId: currentUser.uid,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          conversation: {
                            'chatId': chat.id,
                            'itemId': chat.itemId,
                            'participants': chat.participants,
                            'lastMessage': chat.lastMessage,
                            'lastMessageTime': chat.lastMessageTime,
                            'readStatus': chat.readStatus,
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChatCard({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  String _getOtherParticipantName() {
    // Find the other participant (not the current user)
    final otherParticipant = chat.participants.firstWhere(
      (participant) => participant != currentUserId,
      orElse: () => 'Unknown User',
    );
    return otherParticipant;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherParticipant = _getOtherParticipantName();
    final currentUserId = FirebaseAuthService().currentUser?.uid ?? '';
    final hasUnreadMessages = chat.readStatus[currentUserId] != true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(
                    otherParticipant.isNotEmpty
                        ? otherParticipant[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Chat Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Participant name and timestamp
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherParticipant,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnreadMessages
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimestamp(chat.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: hasUnreadMessages
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Item title
                      Text(
                        'Item: ${chat.itemId}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Last message
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage.isNotEmpty
                                  ? chat.lastMessage
                                  : 'No messages yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: hasUnreadMessages
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (hasUnreadMessages)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '1',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
