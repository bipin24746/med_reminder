import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/models/medicine.dart';
import 'timezone_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'med_alarm_channel';
  static const String _channelName = 'Medicine Alarms';

  // Opens AlarmActivity from notification tap/action
  static const MethodChannel _alarmChannel = MethodChannel('alarm_settings');

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings, // ✅ v20 requires named param
      onDidReceiveNotificationResponse: (resp) async {
        final action = resp.actionId;
        final payload = resp.payload ?? '';

        String title = 'Medicine Reminder';
        String body = 'Time to take your medicine';

        if (payload.startsWith('alarm:')) {
          final data = payload.substring(6);
          final parts = data.split('|');
          title = parts.isNotEmpty ? parts[0] : title;
          body = parts.length > 1 ? parts[1] : body;
        }

        // ✅ TAKEN button: just dismiss notification (you can also log if needed)
        if (action == 'TAKEN') {
          final id = resp.id ?? 0;
          if (id != 0) await _plugin.cancel(id: id);
          return;
        }

        // ✅ SKIP button: open AlarmActivity (native will schedule repeat)
        if (action == 'SKIP_5') {
          try {
            await _alarmChannel.invokeMethod('openAlarmActivity', {
              'title': title,
              'body': body,
              // you can also pass id if you want
            });
          } catch (e) {
            if (kDebugMode) debugPrint('Failed to open AlarmActivity: $e');
          }
          return;
        }

        // ✅ Normal tap: open AlarmActivity
        if (payload.startsWith('alarm:')) {
          try {
            await _alarmChannel.invokeMethod('openAlarmActivity', {
              'title': title,
              'body': body,
            });
          } catch (e) {
            if (kDebugMode) debugPrint('Failed to open AlarmActivity: $e');
          }
        }
      },
    );

    final androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Android 13+ permission
    await androidPlugin?.requestNotificationsPermission();

    // Channel settings cached by Android → delete + recreate
    try {
      await androidPlugin?.deleteNotificationChannel(channelId: _channelId);
    } catch (_) {}

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Alarm-like medicine reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      showBadge: true,
    );

    await androidPlugin?.createNotificationChannel(channel);

    if (kDebugMode) {
      debugPrint('✅ Channel created: $_channelId (sound=alarm)');
    }
  }

  /// Show alarm-style notification NOW (used by AlarmManager callback)
  static Future<void> showImmediateAlarm({
    required int id,
    required String title,
    required String body,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Alarm-like medicine reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        sound: const RawResourceAndroidNotificationSound('alarm'),
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,

        // ✅ ACTION BUTTONS
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'SKIP_5',
            'Skip for 5 minutes',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'TAKEN',
            'Taken',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
    );

    await _plugin.show(
      id: id, // ✅ named param in v20
      title: title,
      body: body,
      notificationDetails: details, // ✅ named param in v20
      payload: 'alarm:$title|$body',
    );
  }

  /// Cancel notification IDs for a medicine
  static Future<void> cancelForMedicine(int medicineId) async {
    const maxPerMed = 80;
    final futures = <Future<void>>[];

    for (int i = 0; i < maxPerMed; i++) {
      futures.add(_plugin.cancel(id: medicineId * 1000 + i));
    }
    await Future.wait(futures);
  }

  /// Optional schedule using flutter_local_notifications (not AlarmManager)
  static Future<void> scheduleMedicine(Medicine med) async {
    if (med.id == null) {
      throw Exception('Medicine id is null. Insert into DB first.');
    }

    final loc = TimezoneService.locationFromName(med.timezone);
    final start = DateTime.fromMillisecondsSinceEpoch(med.startDateMillis);
    final times = (jsonDecode(med.timesJson) as List).cast<String>();

    await cancelForMedicine(med.id!);

    final maxDaysForDemo = med.days.clamp(1, 30);
    int notifIndex = 0;

    for (int day = 0; day < maxDaysForDemo; day++) {
      final date = DateTime(start.year, start.month, start.day)
          .add(Duration(days: day));

      for (final t in times) {
        final parts = t.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final scheduledLocal =
        tz.TZDateTime(loc, date.year, date.month, date.day, hour, minute);

        if (scheduledLocal.isBefore(tz.TZDateTime.now(loc))) continue;

        final id = med.id! * 1000 + notifIndex;

        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Alarm-like medicine reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            sound: const RawResourceAndroidNotificationSound('alarm'),
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        );

        await _plugin.zonedSchedule(
          id: id, // ✅ named
          title: 'Time for ${med.name}',
          body: (med.note?.isNotEmpty == true) ? med.note! : 'Take your medicine',
          scheduledDate: scheduledLocal, // ✅ named
          notificationDetails: details, // ✅ named
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload:
          'alarm:Time for ${med.name}|${(med.note?.isNotEmpty == true) ? med.note! : 'Take your medicine'}',
          matchDateTimeComponents: null,
        );

        notifIndex++;
      }
    }

    if (notifIndex == 0) {
      throw Exception('No future reminders. Choose a time 2–3 minutes ahead.');
    }
  }
}
