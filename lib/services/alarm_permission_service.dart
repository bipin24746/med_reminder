import 'package:flutter/services.dart';

class AlarmPermissionService {
  static const MethodChannel _ch = MethodChannel('alarm_native');

  static Future<void> ensureAlarmWorks() async {
    // Exact alarm permission (Android 12+)
    final canExact = await _ch.invokeMethod<bool>('canScheduleExactAlarms') ?? true;
    if (!canExact) {
      await _ch.invokeMethod('openExactAlarmSettings');
    }

    // Battery optimization exclusion (all Android versions)
    final ignoring = await _ch.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    if (!ignoring) {
      await _ch.invokeMethod('requestIgnoreBatteryOptimizations');
    }
  }
}