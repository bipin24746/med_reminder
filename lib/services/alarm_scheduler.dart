import 'dart:convert';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/models/medicine.dart';
import 'notification_services.dart';
import 'timezone_service.dart';

class AlarmScheduler {
  /// Schedules alarms for a medicine using Android AlarmManager.
  static Future<void> scheduleMedicine(Medicine med) async {
    if (med.id == null) throw Exception("Medicine must have id first");

    final loc = TimezoneService.locationFromName(med.timezone);
    final start = DateTime.fromMillisecondsSinceEpoch(med.startDateMillis);
    final times = (jsonDecode(med.timesJson) as List).cast<String>();

    int index = 0;

    for (int day = 0; day < med.days; day++) {
      final date = DateTime(start.year, start.month, start.day).add(Duration(days: day));

      for (final t in times) {
        final parts = t.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final scheduled = tz.TZDateTime(loc, date.year, date.month, date.day, hour, minute);

        if (scheduled.isBefore(tz.TZDateTime.now(loc))) continue;

        final alarmId = med.id! * 1000 + index;

        // IMPORTANT: AlarmManager needs a normal DateTime (device local)
        await AndroidAlarmManager.oneShotAt(
          scheduled.toLocal(),
          alarmId,
          alarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: <String, dynamic>{
            "title": "Time for ${med.name}",
            "body": (med.note?.isNotEmpty == true) ? med.note : "Take your medicine",
            "id": alarmId,
          },
        );

        if (kDebugMode) {
          debugPrint("✅ Alarm scheduled id=$alarmId at $scheduled tz=${med.timezone}");
        }
        index++;
      }
    }

    if (index == 0) throw Exception("No future alarms were scheduled.");
  }
}

/// Must be TOP-LEVEL + entry-point for background isolate
@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
  // Re-init notifications inside background isolate
  await NotificationService.init();

  final title = (params["title"] ?? "Medicine Reminder").toString();
  final body = (params["body"] ?? "Time to take your medicine").toString();

  // Show an alarm-style notification (full screen), user taps => opens AlarmActivity
  await NotificationService.showImmediateAlarm(
    id: id,
    title: title,
    body: body,
  );
}
