import 'package:flutter/material.dart';
import 'package:med_reminder_fixed/services/app_settings_service.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enable Alarm Permissions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'To ring alarms when the app is closed, please enable:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              title: const Text('Allow Alarms & reminders (Exact alarms)'),
              subtitle: const Text('Required for Android 12+ (especially Android 15).'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AppSettingsService.openAlarmPermission(),
            ),
          ),

          Card(
            child: ListTile(
              title: const Text('Disable battery restriction'),
              subtitle: const Text('Set Battery to “Unrestricted” / Don’t optimize.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AppSettingsService.openAppBattery(),
            ),
          ),

          Card(
            child: ListTile(
              title: const Text('Enable full-screen notifications'),
              subtitle: const Text('Allow alarms to pop the alarm screen.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AppSettingsService.openNotificationSettings(),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          Card(
            child: ListTile(
              title: const Text('Optional: Display over other apps (Overlay)'),
              subtitle: const Text('Only if your phone blocks full-screen alarms.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AppSettingsService.openOverlayPermission(),
            ),
          ),
        ],
      ),
    );
  }
}
