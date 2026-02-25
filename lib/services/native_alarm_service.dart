import 'package:flutter/services.dart';

class NativeAlarmService {
  static const MethodChannel _ch = MethodChannel('alarm_native');

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
      // ignore
    }
  }

  /// ✅ IMPORTANT: cancels Android AlarmManager PendingIntent (native)
  static Future<void> cancel({required int id}) async {
    try {
      await _ch.invokeMethod('cancel', {'id': id});
    } catch (e) {
      // ignore
    }
  }

  /// ✅ Opens AlarmActivity immediately (testing button)
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
      // ignore
    }
  }

  /// ✅ Cancels ALL alarms related to a medicine safely
  /// (same behavior you had before)
  static Future<void> cancelForMedicine(int medicineId) async {
    const slotSize = 10000;
    const maxSlots = 50; // adjust if you need more

    for (int idx = 0; idx < maxSlots; idx++) {
      final id = medicineId * slotSize + idx;
      await cancel(id: id);
    }
  }
}