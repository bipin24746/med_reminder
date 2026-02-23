import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'add_med_flow_state.dart';

final addMedFlowProvider =
StateNotifierProvider<AddMedFlowController, AddMedFlowState>((ref) {
  return AddMedFlowController();
});

class AddMedFlowController extends StateNotifier<AddMedFlowState> {
  AddMedFlowController() : super(AddMedFlowState.initial());

  void reset() => state = AddMedFlowState.initial();

  void setName(String v) => state = state.copyWith(name: v);
  void setForm(String v) => state = state.copyWith(form: v);

  void setFrequencyType(MedFrequencyType v) {
    // intervalHours = only 1 stream
    if (v == MedFrequencyType.intervalHours) {
      final updated = List<TimeOfDay>.from(state.times);
      if (updated.isEmpty) updated.add(const TimeOfDay(hour: 8, minute: 0));

      state = state.copyWith(
        frequencyType: v,
        timesPerDay: 1,
        times: [updated.first],
      );
      return;
    }

    // switching away from intervalHours
    state = state.copyWith(frequencyType: v);

    // make sure list length matches timesPerDay
    setTimesPerDay(state.timesPerDay);
  }

  void setIntervalHours(int v) =>
      state = state.copyWith(intervalHours: v.clamp(1, 24));

  void setWeeklyDays(Set<int> v) => state = state.copyWith(weeklyDays: v);

  void setMonthlyDay(int v) =>
      state = state.copyWith(monthlyDay: v.clamp(1, 31));

  void setTimesPerDay(int v) {
    final target = v.clamp(1, 12);
    final updated = List<TimeOfDay>.from(state.times);

    // grow with unique suggestions
    while (updated.length < target) {
      updated.add(_suggestNextTime(updated));
    }

    // shrink (keep first N)
    if (updated.length > target) {
      updated.removeRange(target, updated.length);
    }

    state = state.copyWith(timesPerDay: target, times: updated);
  }

  void addTime() {
    final updated = List<TimeOfDay>.from(state.times);
    if (updated.length >= 12) return;

    updated.add(_suggestNextTime(updated));
    state = state.copyWith(timesPerDay: updated.length, times: updated);
  }

  void removeTimeAt(int index) {
    final updated = List<TimeOfDay>.from(state.times);

    if (updated.length <= 1) return;
    if (index < 0 || index >= updated.length) return;

    updated.removeAt(index); // ✅ removes only that index
    state = state.copyWith(timesPerDay: updated.length, times: updated);
  }

  /// ✅ IMPORTANT: update BOTH times and timesPerDay
  void setTimes(List<TimeOfDay> v) {
    final updated = List<TimeOfDay>.from(v);
    state = state.copyWith(times: updated, timesPerDay: updated.length);
  }

  void setDose(String v) => state = state.copyWith(doseAmount: v);
  void setNote(String v) => state = state.copyWith(note: v);

  void setTimezone(String v) => state = state.copyWith(timezone: v);
  void setStartDate(DateTime v) => state = state.copyWith(startDate: v);

  /// Create a different “next” time so new slots aren’t all 08:00.
  TimeOfDay _suggestNextTime(List<TimeOfDay> existing) {
    if (existing.isEmpty) return const TimeOfDay(hour: 8, minute: 0);

    final last = existing.last;
    final baseMinutes = last.hour * 60 + last.minute;

    // add 2 hours each time
    final nextMinutes = (baseMinutes + 120) % (24 * 60);
    final h = nextMinutes ~/ 60;
    final m = nextMinutes % 60;

    TimeOfDay out = TimeOfDay(hour: h, minute: m);

    // ensure uniqueness (handle duplicates)
    for (int tries = 0; tries < 24; tries++) {
      final exists =
      existing.any((t) => t.hour == out.hour && t.minute == out.minute);
      if (!exists) break;

      final mm = ((out.hour * 60 + out.minute) + 60) % (24 * 60);
      out = TimeOfDay(hour: mm ~/ 60, minute: mm % 60);
    }

    return out;
  }

  MedFrequencyType _freqFromInt(int raw) {
    if (raw < 0 || raw >= MedFrequencyType.values.length) {
      return MedFrequencyType.daily;
    }
    return MedFrequencyType.values[raw];
  }

  void loadForEdit({
    required int id,
    required String name,
    required String form,
    required int timesPerDay,
    required List<TimeOfDay> times,
    required String doseAmount,
    required String note,
    required String timezone,
    required DateTime startDate,

    // stored in DB as int
    required int frequencyType,
    required int intervalHours,
    required Set<int> weeklyDays,
    required int monthlyDay,
  }) {
    final safeTimes = List<TimeOfDay>.from(times);

    state = AddMedFlowState(
      editingId: id,
      name: name,
      form: form,
      frequencyType: _freqFromInt(frequencyType),
      intervalHours: intervalHours.clamp(1, 24),
      weeklyDays: weeklyDays,
      monthlyDay: monthlyDay.clamp(1, 31),
      timesPerDay: safeTimes.length, // ✅ keep consistent
      times: safeTimes,
      doseAmount: doseAmount,
      note: note,
      timezone: timezone,
      startDate: startDate,
    );

    // also force correct length if something mismatch came from DB
    setTimesPerDay(state.timesPerDay);
  }
}
