import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'privacy_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'help_support_screen.dart';
import 'change_password_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Settings Summary Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.settings,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Settings',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage your preferences',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Quick Status Overview
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusItem(
                                context,
                                'Push Notifications',
                                settingsProvider.settings?.pushNotifications ??
                                    true,
                                Icons.notifications,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatusItem(
                                context,
                                'Profile Visible',
                                settingsProvider.settings?.profileVisibility ??
                                    true,
                                Icons.visibility,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Settings Categories
                _buildSettingsCategory(context, 'Account & Security', [
                  _SettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Settings',
                    subtitle: 'Control your privacy preferences',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySettingsScreen(),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                _buildSettingsCategory(context, 'Notifications', [
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notification Settings',
                    subtitle: 'Manage notification preferences',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                _buildSettingsCategory(context, 'Support', [
                  _SettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.info_outline,
                    title: 'App Information',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAppInfo(context),
                  ),
                ]),

                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String title,
    bool isEnabled,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isEnabled ? Colors.green.shade600 : Colors.grey.shade500,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isEnabled ? Colors.green.shade700 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCategory(
    BuildContext context,
    String title,
    List<_SettingsItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(item.subtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: item.onTap,
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            const Text('App Information'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FindIt - Lost & Found App'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            Text('Build: 1'),
            SizedBox(height: 12),
            Text(
              'A comprehensive lost and found application with advanced features.',
              style: TextStyle(color: Colors.grey),
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
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
