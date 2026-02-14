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
  void setDays(int v) => state = state.copyWith(days: v);
  void setTimesPerDay(int v) => state = state.copyWith(timesPerDay: v);
  void setTimes(List<TimeOfDay> v) => state = state.copyWith(times: v);

  void setDose(String v) => state = state.copyWith(doseAmount: v);
  void setNote(String v) => state = state.copyWith(note: v);

  void setTimezone(String v) => state = state.copyWith(timezone: v);
  void setStartDate(DateTime v) => state = state.copyWith(startDate: v);

  /// ✅ for editing an existing medicine
  void loadForEdit({
    required int id,
    required String name,
    required String form,
    required int days,
    required int timesPerDay,
    required List<TimeOfDay> times,
    required String doseAmount,
    required String note,
    required String timezone,
    required DateTime startDate,
  }) {
    state = AddMedFlowState(
      editingId: id,
      name: name,
      form: form,
      days: days,
      timesPerDay: timesPerDay,
      times: times,
      doseAmount: doseAmount,
      note: note,
      timezone: timezone,
      startDate: startDate,
    );
  }
}
