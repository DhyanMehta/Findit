import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_item_service.dart';
import '../models/user_model.dart';
import '../models/item.dart';
import '../utils/error_handler.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'item_details_screen.dart';

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
        print('Loading user data for: ${currentUser.uid}'); // Debug log

        // Try to get existing user document
        UserModel? userModel = await _authService.getUserDocument(
          currentUser.uid,
        );

        // If user document doesn't exist, create it
        if (userModel == null) {
          print('User document not found, creating new one...'); // Debug log
          await _createUserDocumentFromCurrentUser(currentUser);
          // Try to get the document again after creating it
          userModel = await _authService.getUserDocument(currentUser.uid);
        }

        setState(() {
          _userData = userModel;
          _isLoadingProfile = false;
        });
      } else {
        print('No current user found'); // Debug log
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      print('Error loading user data: $e'); // Debug log
      setState(() => _isLoadingProfile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Create user document from current Firebase Auth user
  Future<void> _createUserDocumentFromCurrentUser(dynamic currentUser) async {
    try {
      print('Creating user document for: ${currentUser.uid}'); // Debug log

      final userModel = UserModel(
        id: currentUser.uid,
        name:
            currentUser.displayName ??
            currentUser.email?.split('@')[0] ??
            'User',
        email: currentUser.email ?? '',
        phone: currentUser.phoneNumber ?? '',
        avatarUrl: currentUser.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: currentUser.emailVerified ?? false,
        role: 'user',
      );

      // Use the Firebase service to create the document
      await _authService.createOrUpdateUserDocument(userModel);
      print('User document created successfully'); // Debug log
    } catch (e) {
      print('Error creating user document: $e'); // Debug log
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Retry loading user data
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  void _privacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Profile Visibility'),
              subtitle: const Text('Show your profile to other users'),
              value: true,
              onChanged: (value) {
                // TODO: Implement profile visibility toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Location Sharing'),
              subtitle: const Text('Share location data with posts'),
              value: true,
              onChanged: (value) {
                // TODO: Implement location sharing toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Activity Status'),
              subtitle: const Text('Show when you were last active'),
              value: false,
              onChanged: (value) {
                // TODO: Implement activity status toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
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

  void _notifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications for new matches'),
              value: true,
              onChanged: (value) {
                // TODO: Implement push notifications toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Get updates via email'),
              value: false,
              onChanged: (value) {
                // TODO: Implement email notifications toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Chat Messages'),
              subtitle: const Text('Get notified about new messages'),
              value: true,
              onChanged: (value) {
                // TODO: Implement chat notification toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
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
    return StreamBuilder<List<Item>>(
      stream: _itemService.getUserItems(_authService.currentUser!.uid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final lostItems = items.where((item) => item.type == 'lost').length;
        final foundItems = items.where((item) => item.type == 'found').length;

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
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          ],
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
