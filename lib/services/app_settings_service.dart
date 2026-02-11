import 'package:flutter/services.dart';

class AppSettingsService {
  static const _ch = MethodChannel('app_settings');

  static Future<void> openAlarmPermission() async {
    await _ch.invokeMethod('openAlarmPermission');
  }

  static Future<void> openAppBattery() async {
    await _ch.invokeMethod('openAppBattery');
  }

  static Future<void> openNotificationSettings() async {
    await _ch.invokeMethod('openNotificationSettings');
  }

  static Future<void> openOverlayPermission() async {
    await _ch.invokeMethod('openOverlayPermission');
  }
}
