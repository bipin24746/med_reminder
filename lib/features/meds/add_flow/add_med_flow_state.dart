import 'package:flutter/material.dart';

enum MedFrequencyType { daily, intervalHours, weekly, monthly }

class AddMedFlowState {
  final int? editingId;

  final String name;
  final String form;

  // ✅ frequency
  final MedFrequencyType frequencyType;

  // intervalHours
  final int intervalHours;

  // weekly: 1=Mon ... 7=Sun
  final Set<int> weeklyDays;

  // monthly: 1..31 (you can allow multiple, but start with single)
  final int monthlyDay;

  final int timesPerDay;
  final List<TimeOfDay> times;

  final String doseAmount;
  final String note;

  final String timezone;
  final DateTime startDate;

  const AddMedFlowState({
    this.editingId,
    this.name = '',
    this.form = 'pill',

    this.frequencyType = MedFrequencyType.daily,
    this.intervalHours = 8,
    this.weeklyDays = const {1, 3, 5},
    this.monthlyDay = 1,

    this.timesPerDay = 2,
    this.times = const [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
    ],
    this.doseAmount = '1 tablet',
    this.note = '',
    this.timezone = 'Asia/Kathmandu',
    required this.startDate,
  });

  factory AddMedFlowState.initial() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return AddMedFlowState(startDate: start);
  }

  AddMedFlowState copyWith({
    int? editingId,
    bool clearEditingId = false,
    String? name,
    String? form,

    MedFrequencyType? frequencyType,
    int? intervalHours,
    Set<int>? weeklyDays,
    int? monthlyDay,

    int? timesPerDay,
    List<TimeOfDay>? times,

    String? doseAmount,
    String? note,
    String? timezone,
    DateTime? startDate,
  }) {
    return AddMedFlowState(
      editingId: clearEditingId ? null : (editingId ?? this.editingId),
      name: name ?? this.name,
      form: form ?? this.form,

      frequencyType: frequencyType ?? this.frequencyType,
      intervalHours: intervalHours ?? this.intervalHours,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      monthlyDay: monthlyDay ?? this.monthlyDay,

      timesPerDay: timesPerDay ?? this.timesPerDay,
      times: times ?? this.times,

      doseAmount: doseAmount ?? this.doseAmount,
      note: note ?? this.note,
      timezone: timezone ?? this.timezone,
      startDate: startDate ?? this.startDate,
    );
  }
}
