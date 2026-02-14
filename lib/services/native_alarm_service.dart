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

  static Future<void> cancelForMedicine(int medicineId) async {
    const slotSize = 10000; // must match your scheduling slotSize
    const maxSlotsToCancel = 3000; // enough for 365 days * 6 times/day = 2190

    for (int idx = 0; idx < maxSlotsToCancel; idx++) {
      final id = medicineId * slotSize + idx;
      try {
        await cancel(id);
      } catch (_) {}
    }
  }

}
