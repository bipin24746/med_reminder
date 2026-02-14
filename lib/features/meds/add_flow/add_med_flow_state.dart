import 'package:flutter/material.dart';

class AddMedFlowState {
  final int? editingId;

  final String name;
  final String form;
  final int days;
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
    this.days = 7,
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
    int? days,
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
      days: days ?? this.days,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      times: times ?? this.times,
      doseAmount: doseAmount ?? this.doseAmount,
      note: note ?? this.note,
      timezone: timezone ?? this.timezone,
      startDate: startDate ?? this.startDate,
    );
  }
}
