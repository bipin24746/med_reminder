import 'package:flutter/services.dart';

class NativeAlarmService {
  static const MethodChannel _ch = MethodChannel('alarm_native');

  static Future<void> schedule({
    required int id,
    required DateTime triggerAt,
    required String title,
    required String body,
  }) async {
    await _ch.invokeMethod('schedule', {
      'id': id,
      'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      'title': title,
      'body': body,
    });
  }

  static Future<void> cancel(int id) async {
    await _ch.invokeMethod('cancel', {'id': id});
  }

  // ⚠️ only keep this if you also implement openAlarmActivity in MainActivity
  static Future<void> openNow({required String title, required String body}) async {
    await _ch.invokeMethod('openAlarmActivity', {'title': title, 'body': body});
  }
}
