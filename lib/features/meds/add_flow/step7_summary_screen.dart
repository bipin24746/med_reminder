import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_state.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../data/models/medicine.dart';
import '../../../providers/providers.dart';
import '../../../services/native_alarm_service.dart';
import '../../../services/timezone_service.dart';
import 'add_med_flow_controller.dart';

class Step7SummaryScreen extends ConsumerStatefulWidget {
  const Step7SummaryScreen({super.key});

  @override
  ConsumerState<Step7SummaryScreen> createState() => _Step7SummaryScreenState();
}

class _Step7SummaryScreenState extends ConsumerState<Step7SummaryScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(addMedFlowProvider);
    final isEdit = flow.editingId != null;

    final timesText = flow.times.map((t) => _formatTime(t)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${isEdit ? "Edit" : "Add"} Medication (7/7)'),
        automaticallyImplyLeading: true, // ✅ show back arrow
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
                  _row('Times per day', '${flow.timesPerDay}'),
                  const Divider(height: 20),
                  _row('Days', '${flow.days}'),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black.withOpacity(0.65)),
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

  Future<void> _save(BuildContext context, AddMedFlowState flow) async {
    if (flow.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine name is missing')));
      return;
    }

    if (_saving) return;
    setState(() => _saving = true);

    try {
      // build times json (HH:mm)
      final timesStr = flow.times
          .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList();

      final startMidnight = DateTime(flow.startDate.year, flow.startDate.month, flow.startDate.day);

      final baseMed = Medicine(
        id: flow.editingId,
        name: flow.name.trim(),
        note: flow.note.trim().isEmpty ? null : flow.note.trim(),
        timesPerDay: flow.timesPerDay,
        days: flow.days,
        timezone: flow.timezone,
        timesJson: jsonEncode(timesStr),
        startDateMillis: startMidnight.millisecondsSinceEpoch,
        form: flow.form,
        doseAmount: flow.doseAmount.trim().isEmpty ? '1' : flow.doseAmount.trim(),
      );

      // If editing: cancel old alarms first, then update
      if (flow.editingId != null) {
        await NativeAlarmService.cancelForMedicine(flow.editingId!);
        await ref.read(medicineRepoProvider).update(baseMed);
        await _scheduleNativeAlarms(baseMed);
      } else {
        final id = await ref.read(medicineRepoProvider).insert(baseMed);
        final saved = baseMed.copyWith(id: id);
        await _scheduleNativeAlarms(saved);
      }

      ref.invalidate(medicinesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(flow.editingId != null ? 'Updated & rescheduled' : 'Saved & scheduled')),
        );
        // go to meds list
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

  Future<void> _scheduleNativeAlarms(Medicine saved) async {
    final loc = TimezoneService.locationFromName(saved.timezone);
    final times = (jsonDecode(saved.timesJson) as List).cast<String>();
    final start = DateTime.fromMillisecondsSinceEpoch(saved.startDateMillis);

    int idx = 0;
    for (int day = 0; day < saved.days; day++) {
      final date = DateTime(start.year, start.month, start.day).add(Duration(days: day));

      for (final t in times) {
        final parts = t.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final tzDate = tz.TZDateTime(loc, date.year, date.month, date.day, hour, minute);
        if (tzDate.isBefore(tz.TZDateTime.now(loc))) continue;

        const slotSize = 10000;
        final alarmId = saved.id! * slotSize + idx;

        await NativeAlarmService.schedule(
          id: alarmId,
          triggerAt: tzDate.toLocal(),
          title: "Time for ${saved.name}",
          body: (saved.note?.isNotEmpty == true) ? saved.note! : "Take your medicine",
        );

        idx++;
      }
    }
  }
}
