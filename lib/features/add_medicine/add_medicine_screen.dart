import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:med_reminder_fixed/services/native_alarm_service.dart';
import 'package:med_reminder_fixed/services/notification_services.dart';

import '../../data/models/medicine.dart';
import '../../providers/providers.dart';
import '../../services/timezone_service.dart';

class AddMedicineScreen extends ConsumerStatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  ConsumerState<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends ConsumerState<AddMedicineScreen> {
  final _name = TextEditingController();
  final _note = TextEditingController();

  int _timesPerDay = 2;
  int _days = 7;
  DateTime _startDate = DateTime.now();
  String _timezone = 'Asia/Kathmandu';

  final List<TimeOfDay> _times = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 20, minute: 0),
  ];

  bool _saving = false;

  final _tzOptions = const [
    'Asia/Kathmandu',
    'Asia/Kolkata',
    'Asia/Dubai',
    'Europe/London',
    'America/New_York',
    'UTC',
  ];

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Medicine"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () async {
              // Opens AlarmActivity NOW (for testing)
              await NativeAlarmService.openNow(
                title: "Test Alarm",
                body: "If you hear sound, AlarmActivity works",
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Medicine name'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            SizedBox(height: 16.h),

            _numberRow(
              title: 'Times per day',
              value: _timesPerDay,
              onMinus: () => setState(() {
                if (_timesPerDay > 1) _timesPerDay--;
                _syncTimesList();
              }),
              onPlus: () => setState(() {
                if (_timesPerDay < 6) _timesPerDay++;
                _syncTimesList();
              }),
            ),
            SizedBox(height: 10.h),

            _numberRow(
              title: 'How many days',
              value: _days,
              onMinus: () => setState(() {
                if (_days > 1) _days--;
              }),
              onPlus: () => setState(() {
                if (_days < 365) _days++;
              }),
            ),
            SizedBox(height: 12.h),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text('${_startDate.year}-${_startDate.month}-${_startDate.day}'),
              trailing: const Icon(Icons.date_range),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  initialDate: _startDate,
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),

            SizedBox(height: 6.h),
            DropdownButtonFormField<String>(
              value: _timezone,
              items: _tzOptions
                  .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                  .toList(),
              onChanged: (v) => setState(() => _timezone = v ?? 'UTC'),
              decoration: const InputDecoration(labelText: 'Timezone (for reminders)'),
            ),

            SizedBox(height: 16.h),
            Text(
              'Reminder times',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 10.h),

            ...List.generate(_times.length, (i) {
              final t = _times[i];
              return Card(
                child: ListTile(
                  title: Text(
                    'Time ${i + 1}',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(t.format(context), style: TextStyle(fontSize: 16.sp)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: t);
                    if (picked != null) setState(() => _times[i] = picked);
                  },
                ),
              );
            }),

            SizedBox(height: 18.h),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Text(
                _saving ? 'Saving...' : 'Save & Schedule',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberRow({
    required String title,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
            ),
            IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline)),
            Text('$value', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
            IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
      ),
    );
  }

  void _syncTimesList() {
    while (_times.length < _timesPerDay) {
      _times.add(const TimeOfDay(hour: 12, minute: 0));
    }
    while (_times.length > _timesPerDay) {
      _times.removeLast();
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter medicine name')),
      );
      return;
    }

    if (_saving) return;
    setState(() => _saving = true);

    try {
      final timesStr = _times
          .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList();

      final med = Medicine(
        name: name,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        timesPerDay: _timesPerDay,
        days: _days,
        timezone: _timezone,
        timesJson: jsonEncode(timesStr),
        startDateMillis: DateTime(_startDate.year, _startDate.month, _startDate.day)
            .millisecondsSinceEpoch,
      );

      // 1) Save to DB (now we get an id)
      final id = await ref.read(medicineRepoProvider).insert(med);
      final saved = med.copyWith(id: id);

      // 2) Optional: notification bar reminder
      // await NotificationService.scheduleMedicine(saved);

      // 3) Native AlarmManager: auto-open AlarmActivity and ring
      await _scheduleNativeAlarms(saved);

      // refresh list
      ref.invalidate(medicinesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved & scheduled')),
        );
        context.go('/');
      }
    } catch (e, st) {
      debugPrint('Save/schedule failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule failed: $e')),
        );
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

        const slotSize = 10000; // enough for 365*6 = 2190 alarms
        final alarmId = saved.id! * slotSize + idx;


        await NativeAlarmService.schedule(
          id: alarmId,
          triggerAt: tzDate.toLocal(),
          title: "Time for ${saved.name}",
          body: saved.note?.isNotEmpty == true ? saved.note! : "Take your medicine",
        );

        idx++;
      }
    }
  }
}
