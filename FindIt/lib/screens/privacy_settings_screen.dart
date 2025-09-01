import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
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
        title: const Text('Privacy Settings'),
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
                // Profile Visibility Section
                _buildSectionHeader('Profile Visibility'),
                _buildSettingCard(
                  title: 'Profile Visibility',
                  subtitle: 'Allow others to find and view your profile',
                  icon: Icons.visibility,
                  value: settingsProvider.profileVisibility,
                  onChanged: (value) async {
                    final success = await settingsProvider.updatePrivacySetting(
                      'profileVisibility',
                      value,
                    );
                    if (!success && mounted) {
                      _showErrorSnackBar('Failed to update profile visibility');
                    }
                  },
                ),

                _buildSettingCard(
                  title: 'Show Online Status',
                  subtitle: 'Let others see when you\'re online',
                  icon: Icons.online_prediction,
                  value: settingsProvider.showOnlineStatus,
                  onChanged: (value) async {
                    final success = await settingsProvider.updatePrivacySetting(
                      'showOnlineStatus',
                      value,
                    );
                    if (!success && mounted) {
                      _showErrorSnackBar(
                        'Failed to update online status setting',
                      );
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Location Services Section
                _buildSectionHeader('Location Services'),
                _buildSettingCard(
                  title: 'Location Services',
                  subtitle:
                      'Enable location-based features and nearby suggestions',
                  icon: Icons.location_on,
                  value: settingsProvider.locationServices,
                  onChanged: (value) async {
                    final success = await settingsProvider.updatePrivacySetting(
                      'locationServices',
                      value,
                    );
                    if (!success && mounted) {
                      _showErrorSnackBar('Failed to update location services');
                    }
                  },
                ),

                const SizedBox(height: 30),

                // Privacy Information
                _buildPrivacyInfo(),
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

  Widget _buildPrivacyInfo() {
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
                'Privacy Information',
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
            '• Your privacy is important to us. We only collect data necessary to provide our services.\n\n'
            '• Profile visibility controls who can find and view your profile in search results.\n\n'
            '• Online status helps friends know when you\'re available to chat.\n\n'
            '• Location services enable features like nearby recommendations and location-based matching.\n\n'
            '• You can change these settings anytime.',
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
