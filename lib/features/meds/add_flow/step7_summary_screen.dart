import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/medicine.dart';
import '../../../providers/providers.dart';
import '../../../services/native_alarm_service.dart';
import 'add_med_flow_controller.dart';
import 'add_med_flow_state.dart';

class Step7SummaryScreen extends ConsumerStatefulWidget {
  const Step7SummaryScreen({super.key});

  @override
  ConsumerState<Step7SummaryScreen> createState() => _Step7SummaryScreenState();
}

class _Step7SummaryScreenState extends ConsumerState<Step7SummaryScreen> {
  bool _saving = false;

  // Mon bit0 ... Sun bit6
  int _weeklyMask(Set<int> days) {
    int mask = 0;
    for (final d in days) {
      if (d < 1 || d > 7) continue;
      mask |= (1 << (d - 1));
    }
    return mask;
  }

  DateTime _computeFirstTriggerLocal(AddMedFlowState flow, TimeOfDay t) {
    final now = DateTime.now();

    DateTime candidate = DateTime(
      flow.startDate.year,
      flow.startDate.month,
      flow.startDate.day,
      t.hour,
      t.minute,
    );

    if (candidate.isBefore(now)) {
      switch (flow.frequencyType) {
        case MedFrequencyType.daily:
          candidate = candidate.add(const Duration(days: 1));
          break;

        case MedFrequencyType.intervalHours:
          candidate = now.add(Duration(hours: flow.intervalHours.clamp(1, 24)));
          break;

        case MedFrequencyType.weekly:
        case MedFrequencyType.monthly:
        // native scheduleNext() will find correct next slot based on mask/day
          candidate = now.add(const Duration(minutes: 2));
          break;
      }
    }

    return candidate;
  }

  /// ✅ FIX: unique alarm ids per slotIndex (NOT minuteOfDay)
  Future<void> _scheduleNativeAlarmsForFlow(AddMedFlowState flow, int medId) async {
    const slotSize = 10000;

    for (int slotIndex = 0; slotIndex < flow.times.length; slotIndex++) {
      final t = flow.times[slotIndex];

      // ✅ Unique always: medicineId * 10000 + slotIndex
      final alarmId = medId * slotSize + slotIndex;
      final firstLocal = _computeFirstTriggerLocal(flow, t);

      await NativeAlarmService.schedule(
        id: alarmId,
        triggerAt: firstLocal,
        title: "Time for ${flow.name}",
        body: flow.note.trim().isNotEmpty ? flow.note.trim() : "Take your medicine",
        extras: {
          "freqType": flow.frequencyType.index,
          "hour": t.hour,
          "minute": t.minute,
          "intervalHours": flow.intervalHours,
          "weeklyMask": _weeklyMask(flow.weeklyDays),
          "monthlyDay": flow.monthlyDay,

          // ✅ critical: stable streamId
          "streamId": alarmId,
        },
      );

      // intervalHours uses only one stream
      if (flow.frequencyType == MedFrequencyType.intervalHours) break;
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  String _prettyForm(String form) {
    switch (form) {
      case 'pill':
        return 'Tablet / Pill';
      case 'liquid':
        return 'Liquid';
      case 'injection':
        return 'Injection';
      case 'drops':
        return 'Drops';
      case 'inhaler':
        return 'Inhaler';
      default:
        return form;
    }
  }

  String _prettyFrequency(AddMedFlowState flow) {
    switch (flow.frequencyType) {
      case MedFrequencyType.daily:
        return 'Daily';
      case MedFrequencyType.intervalHours:
        return 'Every ${flow.intervalHours} hours';
      case MedFrequencyType.weekly:
        return 'Weekly';
      case MedFrequencyType.monthly:
        return 'Monthly (day ${flow.monthlyDay})';
    }
  }

  String _prettyWeeklyDays(Set<int> days) {
    const names = <int, String>{
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final sorted = days.toList()..sort();
    if (sorted.isEmpty) return '-';
    return sorted.map((d) => names[d] ?? '$d').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(addMedFlowProvider);
    final isEdit = flow.editingId != null;

    final timesText = flow.times.map(_formatTime).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${isEdit ? "Edit" : "Add"} Medication (6/6)'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Confirm details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            _sectionCard(
              title: 'Medicine',
              child: Column(
                children: [
                  _row('Name', flow.name.isEmpty ? '-' : flow.name),
                  const Divider(height: 20),
                  _row('Form', _prettyForm(flow.form)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _sectionCard(
              title: 'Dose',
              child: _row('Amount', flow.doseAmount.isEmpty ? '-' : flow.doseAmount),
            ),
            const SizedBox(height: 12),

            _sectionCard(
              title: 'Schedule',
              child: Column(
                children: [
                  _row('Frequency', _prettyFrequency(flow)),
                  if (flow.frequencyType == MedFrequencyType.weekly) ...[
                    const Divider(height: 20),
                    _row('Days', _prettyWeeklyDays(flow.weeklyDays)),
                  ],
                  const Divider(height: 20),
                  _row(
                    'Start date',
                    '${flow.startDate.year}-${flow.startDate.month.toString().padLeft(2, '0')}-${flow.startDate.day.toString().padLeft(2, '0')}',
                  ),
                  const Divider(height: 20),
                  _row('Timezone', flow.timezone),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _sectionCard(
              title: 'Times',
              child: Column(
                children: [
                  for (int i = 0; i < timesText.length; i++) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        'Time ${i + 1}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        timesText[i],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (i != timesText.length - 1) const Divider(height: 10),
                  ],
                ],
              ),
            ),

            if (flow.note.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Note',
                child: Text(
                  flow.note.trim(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _saving ? null : () => _save(context, flow),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _saving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Save & Schedule'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _row(String left, String right) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.65),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            right,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, AddMedFlowState flow) async {
    if (flow.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine name is missing')),
      );
      return;
    }

    if (_saving) return;
    setState(() => _saving = true);

    try {
      final timesStr = flow.times
          .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList();

      final startMidnight = DateTime(flow.startDate.year, flow.startDate.month, flow.startDate.day);

      final med = Medicine(
        id: flow.editingId,
        name: flow.name.trim(),
        note: flow.note.trim().isEmpty ? null : flow.note.trim(),
        timesPerDay: flow.timesPerDay,
        timezone: flow.timezone,
        timesJson: jsonEncode(timesStr),
        startDateMillis: startMidnight.millisecondsSinceEpoch,
        form: flow.form,
        doseAmount: flow.doseAmount.trim().isEmpty ? '1' : flow.doseAmount.trim(),

        frequencyType: flow.frequencyType.index,
        intervalHours: flow.intervalHours,
        weeklyMask: _weeklyMask(flow.weeklyDays),
        monthlyDay: flow.monthlyDay,
      );

      if (flow.editingId != null) {
        await NativeAlarmService.cancelForMedicine(flow.editingId!);
        await ref.read(medicineRepoProvider).update(med);
        await _scheduleNativeAlarmsForFlow(flow, flow.editingId!);
      } else {
        final id = await ref.read(medicineRepoProvider).insert(med);
        await _scheduleNativeAlarmsForFlow(flow, id);
      }

      ref.invalidate(medicinesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(flow.editingId != null ? 'Updated & rescheduled' : 'Saved & scheduled')),
        );
        context.go('/meds');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}