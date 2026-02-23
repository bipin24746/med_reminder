import 'package:flutter/services.dart';

class NativeAlarmService {
  static const MethodChannel _ch = MethodChannel('alarm_native');

  static const int _slotSize = 10000;
  static const int _maxSlots = 50;
  // 50 is more than enough (12 max times/day)

  static Future<void> schedule({
    required int id,
    required DateTime triggerAt,
    required String title,
    required String body,
    Map<String, dynamic>? extras,
  }) async {
    try {
      await _ch.invokeMethod('schedule', {
        'id': id,
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'extras': extras ?? {},
      });
    } catch (e) {
      print('Alarm schedule failed: $e');
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _ch.invokeMethod('cancel', {'id': id});
    } catch (e) {
      print('Alarm cancel failed: $e');
    }
  }

  static Future<void> openNow({
    required String title,
    required String body,
  }) async {
    try {
      await _ch.invokeMethod('openAlarmActivity', {
        'title': title,
        'body': body,
      });
    } catch (e) {
      print('Open alarm activity failed: $e');
    }
  }

  /// ✅ Cancels ALL alarms related to a medicine safely
  static Future<void> cancelForMedicine(int medicineId) async {
    for (int idx = 0; idx < _maxSlots; idx++) {
      final id = medicineId * _slotSize + idx;
      await cancel(id);
    }
  }
}