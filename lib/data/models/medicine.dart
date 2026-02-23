import 'package:flutter/foundation.dart';

@immutable
class Medicine {
  final int? id;
  final String name;
  final String? note;

  final int timesPerDay;

  /// Legacy field (keep for now to avoid migration pain).
  /// Not used in new repeating schedule logic.
  final int days;

  final String timezone;
  final String timesJson;
  final int startDateMillis;

  final String form;
  final String doseAmount;

  /// NEW scheduling fields (stored in DB)
  /// freqType: 0=daily, 1=intervalHours, 2=weekly, 3=monthly
  final int frequencyType;
  final int intervalHours;

  /// Mon bit0 ... Sun bit6
  final int weeklyMask;

  /// 1..31
  final int monthlyDay;

  const Medicine({
    this.id,
    required this.name,
    this.note,
    required this.timesPerDay,

    // ✅ make optional with default so you don't have to pass it anymore
    this.days = 1,

    required this.timezone,
    required this.timesJson,
    required this.startDateMillis,
    required this.form,
    required this.doseAmount,

    // ✅ new fields with defaults
    this.frequencyType = 0,
    this.intervalHours = 8,
    this.weeklyMask = 0,
    this.monthlyDay = 1,
  });

  Medicine copyWith({
    int? id,
    String? name,
    String? note,
    int? timesPerDay,
    int? days,
    String? timezone,
    String? timesJson,
    int? startDateMillis,
    String? form,
    String? doseAmount,
    int? frequencyType,
    int? intervalHours,
    int? weeklyMask,
    int? monthlyDay,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      days: days ?? this.days,
      timezone: timezone ?? this.timezone,
      timesJson: timesJson ?? this.timesJson,
      startDateMillis: startDateMillis ?? this.startDateMillis,
      form: form ?? this.form,
      doseAmount: doseAmount ?? this.doseAmount,
      frequencyType: frequencyType ?? this.frequencyType,
      intervalHours: intervalHours ?? this.intervalHours,
      weeklyMask: weeklyMask ?? this.weeklyMask,
      monthlyDay: monthlyDay ?? this.monthlyDay,
    );
  }

  factory Medicine.fromMap(Map<String, Object?> map) {
    int _asInt(Object? v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return fallback;
    }

    return Medicine(
      id: _asInt(map['id'], 0) == 0 ? null : _asInt(map['id'], 0),
      name: (map['name'] as String?) ?? '',
      note: map['note'] as String?,
      timesPerDay: _asInt(map['timesPerDay'], 1),

      // legacy
      days: _asInt(map['days'], 1),

      timezone: (map['timezone'] as String?) ?? 'UTC',
      timesJson: (map['timesJson'] as String?) ?? '[]',
      startDateMillis: _asInt(map['startDateMillis'], 0),
      form: (map['form'] as String?) ?? 'pill',
      doseAmount: (map['doseAmount'] as String?) ?? '1',

      // new fields (safe defaults if column doesn't exist yet)
      frequencyType: _asInt(map['frequencyType'], 0),
      intervalHours: _asInt(map['intervalHours'], 8),
      weeklyMask: _asInt(map['weeklyMask'], 0),
      monthlyDay: _asInt(map['monthlyDay'], 1),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'note': note,
      'timesPerDay': timesPerDay,

      // legacy
      'days': days,

      'timezone': timezone,
      'timesJson': timesJson,
      'startDateMillis': startDateMillis,
      'form': form,
      'doseAmount': doseAmount,

      // new fields
      'frequencyType': frequencyType,
      'intervalHours': intervalHours,
      'weeklyMask': weeklyMask,
      'monthlyDay': monthlyDay,
    };
  }
}
