import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize settings if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().initializeSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            if (settingsProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Push Notifications Section
                _buildSectionHeader('Push Notifications'),
                _buildSettingCard(
                  title: 'Push Notifications',
                  subtitle: 'Receive notifications for matches and messages',
                  icon: Icons.notifications,
                  value: settingsProvider.pushNotifications,
                  onChanged: (value) async {
                    final success = await settingsProvider
                        .updateNotificationSetting('pushNotifications', value);
                    if (!success && mounted) {
                      _showErrorSnackBar('Failed to update push notifications');
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Email Notifications Section
                _buildSectionHeader('Email Notifications'),
                _buildSettingCard(
                  title: 'Email Notifications',
                  subtitle: 'Receive important updates via email',
                  icon: Icons.email,
                  value: settingsProvider.emailNotifications,
                  onChanged: (value) async {
                    final success = await settingsProvider
                        .updateNotificationSetting('emailNotifications', value);
                    if (!success && mounted) {
                      _showErrorSnackBar(
                        'Failed to update email notifications',
                      );
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Chat Notifications Section
                _buildSectionHeader('Chat Notifications'),
                _buildSettingCard(
                  title: 'Chat Notifications',
                  subtitle: 'Get notified when you receive new messages',
                  icon: Icons.chat,
                  value: settingsProvider.chatNotifications,
                  onChanged: (value) async {
                    final success = await settingsProvider
                        .updateNotificationSetting('chatNotifications', value);
                    if (!success && mounted) {
                      _showErrorSnackBar('Failed to update chat notifications');
                    }
                  },
                ),

                const SizedBox(height: 30),

                // Notification Schedule (Future Enhancement)
                _buildScheduleSection(),

                const SizedBox(height: 20),

                // Notification Information
                _buildNotificationInfo(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 24),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue.shade600,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Do Not Disturb',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set quiet hours to avoid notifications during specific times',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTimeCard('From', '22:00')),
              const SizedBox(width: 16),
              Expanded(child: _buildTimeCard('To', '08:00')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Coming soon - Schedule your quiet hours',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String label, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'About Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Push notifications appear instantly on your device\n\n'
            '• Email notifications are sent for important updates and matches\n\n'
            '• Chat notifications help you stay connected with your contacts\n\n'
            '• You can customize which types of notifications you receive\n\n'
            '• All notifications can be managed in your device settings as well',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
