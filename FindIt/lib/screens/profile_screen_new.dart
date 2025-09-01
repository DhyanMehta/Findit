import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_chat_service.dart';
import '../services/firebase_item_service.dart';
import '../models/user_model.dart';
import '../models/item.dart';
import '../utils/error_handler.dart';
import 'edit_profile_screen.dart';
import 'item_details_screen.dart';
import 'user_items_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = FirebaseAuthService();
  final _itemService = FirebaseItemService();
  bool _isLoading = false;
  UserModel? _userData;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingProfile = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userModel = await _authService.getUserDocument(currentUser.uid);
        setState(() {
          _userData = userModel;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingProfile = false);
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signOut();
      // Navigation is handled automatically by AuthWrapper
    } catch (e) {
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editProfile() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        )
        .then((_) {
          // Reload user data when returning from edit screen
          _loadUserData();
        });
  }

  void _changePassword() {
    _showChangePasswordDialog();
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isUpdating = true);

                      try {
                        await _authService.updatePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          AuthErrorHandler.showErrorSnackBar(context, e);
                        }
                      } finally {
                        setState(() => isUpdating = false);
                      }
                    },
              child: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _privacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings feature coming soon!')),
    );
  }

  void _notifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings feature coming soon!'),
      ),
    );
  }

  void _helpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 16),
            Text('Email: support@findit.com'),
            Text('Phone: +1 (555) 123-4567'),
            SizedBox(height: 16),
            Text('Or visit our FAQ section in the app.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatsSection(),
              const SizedBox(height: 24),

              // User Items Section
              _buildUserItemsSection(),
              const SizedBox(height: 24),

              // Settings Section
              _buildSettingsSection(),
              const SizedBox(height: 24),

              // Sign Out Button
              _buildSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_isLoadingProfile) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_userData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load profile data'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: _userData!.avatarUrl?.isNotEmpty == true
                  ? NetworkImage(_userData!.avatarUrl!)
                  : null,
              child: _userData!.avatarUrl?.isEmpty ?? true
                  ? Text(
                      _userData!.name.isNotEmpty
                          ? _userData!.name[0].toUpperCase()
                          : _userData!.email[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              _userData!.name.isNotEmpty ? _userData!.name : 'No Name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              _userData!.email,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),

            // Phone (if available)
            if (_userData!.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _userData!.phone,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],

            const SizedBox(height: 16),

            // Member since
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Member since ${_formatDate(_userData!.createdAt)}',
                style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      children: [
        StreamBuilder<List<Item>>(
          stream: _itemService.getUserItems(_authService.currentUser!.uid),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            final lostItems = items.where((item) => item.type == 'lost').length;
            final foundItems = items
                .where((item) => item.type == 'found')
                .length;

<<<<<<< HEAD
            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Lost Items',
                    lostItems.toString(),
                    Icons.help_outline,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Found Items',
                    foundItems.toString(),
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // Global dynamic count of items returned
        StreamBuilder<int>(
          stream: FirebaseChatService().completedClaimsCount(),
          builder: (context, snapshot) {
            final returned = snapshot.data ?? 0;
            return _buildStatCard(
              'Items Returned',
              returned.toString(),
              Icons.verified,
              Colors.blue,
            );
          },
        ),
      ],
=======
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Lost Items',
                lostItems.toString(),
                Icons.help_outline,
                Colors.red,
                () => _navigateToUserItems('lost', 'My Lost Items'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Found Items',
                foundItems.toString(),
                Icons.check_circle_outline,
                Colors.green,
                () => _navigateToUserItems('found', 'My Found Items'),
              ),
            ),
          ],
        );
      },
>>>>>>> 44080d534ff88e0a907c419473776d45728b7584
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserItemsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Item>>(
              stream: _itemService.getUserItems(_authService.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading items: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No items posted yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.take(3).length, // Show max 3 items
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.type == 'lost'
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.type == 'lost'
                              ? Icons.help_outline
                              : Icons.check_circle_outline,
                          color: item.type == 'lost'
                              ? Colors.red
                              : Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        item.location,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: Text(
                        _formatDate(item.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailsScreen(item: item),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: _editProfile,
            ),
            _buildSettingTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: _changePassword,
            ),
            _buildSettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Settings',
              onTap: _privacySettings,
            ),
            _buildSettingTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: _notifications,
            ),
            _buildSettingTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: _helpSupport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.logout),
        label: Text(
          _isLoading ? 'Signing Out...' : 'Sign Out',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _navigateToUserItems(String itemType, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserItemsScreen(itemType: itemType, title: title),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
