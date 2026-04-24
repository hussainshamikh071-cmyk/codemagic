import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<SettingsService>(
        builder: (context, settingsService, child) {
          if (settingsService.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          }

          final settings = settingsService.settings;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              SettingsSection(
                title: 'SOS Settings',
                children: [
                  SettingsTile(
                    title: 'Auto SOS',
                    subtitle: 'Trigger SOS automatically on detection',
                    icon: Icons.auto_fix_high,
                    trailing: Switch(
                      value: settings.autoSOSEnabled,
                      onChanged: settingsService.toggleAutoSOS,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  SettingsTile(
                    title: 'Voice Activation',
                    subtitle: 'Listen for "HELP" or "SOS"',
                    icon: Icons.mic,
                    trailing: Switch(
                      value: settings.voiceDetectionEnabled,
                      onChanged: settingsService.toggleVoiceDetection,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  SettingsTile(
                    title: 'Fall Detection',
                    subtitle: 'Detect sudden impacts and inactivity',
                    icon: Icons.accessibility_new,
                    trailing: Switch(
                      value: settings.fallDetectionEnabled,
                      onChanged: settingsService.toggleFallDetection,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              SettingsSection(
                title: 'Location Settings',
                children: [
                  SettingsTile(
                    title: 'Live Tracking',
                    subtitle: 'Allow real-time location sharing',
                    icon: Icons.location_on,
                    trailing: Switch(
                      value: settings.liveTrackingEnabled,
                      onChanged: settingsService.toggleLiveTracking,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  SettingsTile(
                    title: 'Background Updates',
                    subtitle: 'Track location even when app is closed',
                    icon: Icons.history,
                    trailing: Switch(
                      value: settings.backgroundLocationEnabled,
                      onChanged: settingsService.toggleBackgroundLocation,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  SettingsTile(
                    title: 'Update Interval',
                    subtitle: '${settings.locationInterval} seconds',
                    icon: Icons.timer,
                    onTap: () => _showIntervalPicker(context, settingsService),
                  ),
                ],
              ),
              SettingsSection(
                title: 'Notification Settings',
                children: [
                  SettingsTile(
                    title: 'Push Notifications',
                    icon: Icons.notifications_active,
                    trailing: Switch(
                      value: settings.pushNotificationsEnabled,
                      onChanged: settingsService.toggleNotifications,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  SettingsTile(
                    title: 'SMS Alerts',
                    icon: Icons.sms,
                    trailing: Switch(
                      value: settings.smsAlertsEnabled,
                      onChanged: settingsService.toggleSMSAlerts,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  SettingsTile(
                    title: 'Sound Alarm',
                    icon: Icons.volume_up,
                    trailing: Switch(
                      value: settings.soundAlarmEnabled,
                      onChanged: settingsService.toggleSoundAlarm,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              SettingsSection(
                title: 'Privacy & Account',
                children: [
                  SettingsTile(
                    title: 'Hide Location',
                    subtitle: 'Hide your location from all contacts',
                    icon: Icons.visibility_off,
                    trailing: Switch(
                      value: settings.hideLocationFromContacts,
                      onChanged: settingsService.toggleHideLocation,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  SettingsTile(
                    title: 'Data Encryption',
                    icon: Icons.lock,
                    trailing: Switch(
                      value: settings.dataEncryptionEnabled,
                      onChanged: settingsService.toggleEncryption,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                  SettingsTile(
                    title: 'Logout',
                    icon: Icons.exit_to_app,
                    iconColor: Colors.white54,
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showIntervalPicker(BuildContext context, SettingsService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update Interval', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...[5, 10, 30, 60].map((interval) => ListTile(
              title: Text('$interval seconds', style: const TextStyle(color: Colors.white)),
              trailing: service.settings.locationInterval == interval ? const Icon(Icons.check, color: Colors.redAccent) : null,
              onTap: () {
                service.setLocationInterval(interval);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
