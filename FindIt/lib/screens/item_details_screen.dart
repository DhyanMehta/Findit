import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/item.dart';
import '../services/firebase_chat_service.dart';
import '../services/firebase_auth_service.dart';
import 'chat_detail_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  bool _isContacting = false;
  final FirebaseChatService _chatService = FirebaseChatService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareItem,
            tooltip: 'Share item',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Item Image
              SizedBox(
                height: 300,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: widget.item.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.item.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stack) =>
                                  Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      widget.item.isFound
                                          ? Icons.check_circle_outline
                                          : Icons.help_outline,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                  ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                widget.item.isFound
                                    ? Icons.check_circle_outline
                                    : Icons.help_outline,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.item.isFound
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.item.isFound
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.item.isFound ? 'Found' : 'Lost',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Category
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.item.category,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildDetailSection(
                      icon: Icons.description,
                      title: 'Description',
                      content: widget.item.description,
                    ),
                    const SizedBox(height: 24),

                    // Location
                    _buildDetailSection(
                      icon: Icons.place,
                      title: 'Location',
                      content: widget.item.location,
                      showMap: true,
                    ),
                    const SizedBox(height: 24),

                    // Date and Time
                    _buildDetailSection(
                      icon: Icons.access_time,
                      title: 'Date & Time',
                      content: _formatDateTime(widget.item.dateTime),
                    ),
                    const SizedBox(height: 24),

                    // Contact Method
                    _buildDetailSection(
                      icon: Icons.contact_mail,
                      title: 'Contact Method',
                      content: widget.item.contactMethod,
                    ),
                    const SizedBox(height: 32),

                    // Contact Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isContacting ? null : _contactOwner,
                        icon: _isContacting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.message),
                        label: Text(
                          _isContacting ? 'Contacting...' : 'Contact Finder',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _reportItem,
                            icon: const Icon(Icons.report),
                            label: const Text('Report'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Save button removed per requirements
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
    bool showMap = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          if (showMap) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                _openMaps(
                  widget.item.latitude,
                  widget.item.longitude,
                  widget.item.title,
                );
              },
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 32, color: Colors.blue.shade600),
                      const SizedBox(height: 8),
                      Text(
                        'Open map at ${widget.item.latitude.toStringAsFixed(4)}, ${widget.item.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openMaps(double lat, double lng, String label) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} minutes ago';
    } else {
      timeAgo = 'Just now';
    }

    return '${dateTime.toLocal().toString().split('.')[0]}\n($timeAgo)';
  }

  Future<void> _contactOwner() async {
    setState(() => _isContacting = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to start a chat'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (currentUser.uid == widget.item.userId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You can't chat with yourself"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final chatId = await _chatService.createOrGetChat(
        itemId: widget.item.id,
        otherUserId: widget.item.userId,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversation: {
              'chatId': chatId,
              'itemId': widget.item.id,
              'participants': [currentUser.uid, widget.item.userId],
              'lastMessage': '',
              'lastMessageTime': DateTime.now(),
              'readStatus': {currentUser.uid: true, widget.item.userId: false},
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isContacting = false);
      }
    }
  }

  void _shareItem() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing item...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _reportItem() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reporting item...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Save feature removed
}
