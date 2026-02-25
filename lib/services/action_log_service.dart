import 'dart:convert';
import 'package:flutter/services.dart';

class ActionLogEvent {
  final int ts;
  final String action;
  final int streamId;
  final int notifId;
  final int scheduledAt;
  final String title;
  final String body;
  final String? reason;

  ActionLogEvent({
    required this.ts,
    required this.action,
    required this.streamId,
    required this.notifId,
    required this.scheduledAt,
    required this.title,
    required this.body,
    this.reason,
  });

  factory ActionLogEvent.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return ActionLogEvent(
      ts: toInt(j['ts']),
      action: (j['action'] ?? '').toString(),
      streamId: toInt(j['streamId']),
      notifId: toInt(j['notifId']),
      scheduledAt: toInt(j['scheduledAt']),
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      reason: j['reason']?.toString(),
    );
  }
}

class ActionLogService {
  static const MethodChannel _ch = MethodChannel('alarm_native');

  static Future<List<ActionLogEvent>> fetch() async {
    final jsonStr = await _ch.invokeMethod<String>('getUserActionLogs') ?? '[]';
    final list = (json.decode(jsonStr) as List).cast<dynamic>();
    final events = list
        .map((e) => ActionLogEvent.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    events.sort((a, b) => b.ts.compareTo(a.ts));
    return events;
  }

  static Future<void> clear() async {
    await _ch.invokeMethod('clearUserActionLogs');
  }
}