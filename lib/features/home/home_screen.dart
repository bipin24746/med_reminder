import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import '../../providers/providers.dart';
import '../../services/native_alarm_service.dart';
import '../../services/timezone_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _ticker;

  static const MethodChannel _alarmNative = MethodChannel('alarm_native');
  static const int _slotSize = 10000;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int _toMinutes(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    return h * 60 + m;
  }

  String _prettyTime(BuildContext context, String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m).format(context);
  }

  tz.TZDateTime _todayStart(tz.Location loc) {
    final now = tz.TZDateTime.now(loc);
    return tz.TZDateTime(loc, now.year, now.month, now.day);
  }

  int? _computeAlarmIdForToday({
    required dynamic med,
    required String hhmm,
  }) {
    final medId = med.id as int?;
    if (medId == null) return null;

    final times = (jsonDecode(med.timesJson) as List).cast<String>();
    final timeIndex = times.indexOf(hhmm);
    if (timeIndex < 0) return null;

    final loc = TimezoneService.locationFromName(med.timezone);

    final start = tz.TZDateTime.fromMillisecondsSinceEpoch(loc, med.startDateMillis);
    final startDay = tz.TZDateTime(loc, start.year, start.month, start.day);
    final today = _todayStart(loc);

    final dayOffset = today.difference(startDay).inDays;
    if (dayOffset < 0) return null;
    if (dayOffset >= (med.days as int)) return null;

    final stableIndex = dayOffset * times.length + timeIndex; // ✅ deterministic
    return medId * _slotSize + stableIndex;
  }

  tz.TZDateTime? _scheduledAtForToday({
    required dynamic med,
    required String hhmm,
  }) {
    final loc = TimezoneService.locationFromName(med.timezone);
    final now = tz.TZDateTime.now(loc);

    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;

    return tz.TZDateTime(loc, now.year, now.month, now.day, h, m);
  }

  bool _shouldShowCardActions({
    required dynamic med,
    required String hhmm,
  }) {
    final loc = TimezoneService.locationFromName(med.timezone);
    final now = tz.TZDateTime.now(loc);
    final sched = _scheduledAtForToday(med: med, hhmm: hhmm);
    if (sched == null) return false;

    final diffSec = sched.difference(now).inSeconds;
    return diffSec <= 300 && diffSec >= 0; // ✅ 1 minute before
  }

  String _titleFor(dynamic med) => 'Time for ${med.name}';
  String _bodyFor(dynamic med) {
    final note = (med.note ?? '').toString().trim();
    return note.isNotEmpty ? note : 'Take your medicine';
  }

  Future<void> _markAndCancel({
    required int alarmId,
    required String action, // TAKEN | SKIP_NOW
    required String reason,
    required String title,
    required String body,
    required int scheduledAtMillis,
  }) async {
    // ✅ tell native: mark handled + cancel native AlarmManager inside native too
    try {
      await _alarmNative.invokeMethod('markDoseHandled', {
        'id': alarmId,
        'action': action,
        'reason': reason,
        'title': title,
        'body': body,
        'scheduledAt': scheduledAtMillis,
      });
    } catch (_) {}

    // ✅ also cancel from Flutter side
    await NativeAlarmService.cancel(id: alarmId);
  }

  Future<void> _handleTaken({
    required dynamic med,
    required String hhmm,
  }) async {
    final alarmId = _computeAlarmIdForToday(med: med, hhmm: hhmm);
    if (alarmId == null) return;

    final sched = _scheduledAtForToday(med: med, hhmm: hhmm);
    final scheduledAtMillis = sched?.millisecondsSinceEpoch ?? 0;

    await _markAndCancel(
      alarmId: alarmId,
      action: 'TAKEN',
      reason: '',
      title: _titleFor(med),
      body: _bodyFor(med),
      scheduledAtMillis: scheduledAtMillis,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked taken: ${med.name}')),
      );
      setState(() {});
    }
  }

  Future<void> _handleSkip({
    required dynamic med,
    required String hhmm,
  }) async {
    final alarmId = _computeAlarmIdForToday(med: med, hhmm: hhmm);
    if (alarmId == null) return;

    final sched = _scheduledAtForToday(med: med, hhmm: hhmm);
    final scheduledAtMillis = sched?.millisecondsSinceEpoch ?? 0;

    final reasons = [
      "Already took it",
      "Not feeling well",
      "No medicine available",
      "Doctor told to pause",
      "Other",
    ];

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Why are you skipping this dose?'),
        children: reasons
            .map(
              (r) => SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, r),
            child: Text(r),
          ),
        )
            .toList(),
      ),
    );

    if (reason == null) return;

    await _markAndCancel(
      alarmId: alarmId,
      action: 'SKIP_NOW',
      reason: reason,
      title: _titleFor(med),
      body: _bodyFor(med),
      scheduledAtMillis: scheduledAtMillis,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Skipped: ${med.name} ($reason)')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(medicinesProvider);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi ${auth.email ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              ref.read(authControllerProvider.notifier).signOut();
              context.go('/signin');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(addMedFlowProvider.notifier).reset();
          context.push('/meds/add/name');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Medicines'),
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (meds) {
          if (meds.isEmpty) {
            return const Center(
              child: Text(
                'No medicines yet.\nTap "Add Medicines".',
                textAlign: TextAlign.center,
              ),
            );
          }

          final Map<String, List<dynamic>> schedule = {};
          final Map<String, Set<String>> seenNamesByTime = {};

          for (final med in meds) {
            final times = (jsonDecode(med.timesJson) as List).cast<String>();
            for (final t in times) {
              schedule.putIfAbsent(t, () => []);
              seenNamesByTime.putIfAbsent(t, () => <String>{});

              final nameKey = (med.name).trim().toLowerCase();
              if (seenNamesByTime[t]!.contains(nameKey)) continue;

              seenNamesByTime[t]!.add(nameKey);
              schedule[t]!.add(med);
            }
          }

          final timeKeys = schedule.keys.toList()
            ..sort((a, b) => _toMinutes(a).compareTo(_toMinutes(b)));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 6),
              Text(
                "Today’s Schedule",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ...timeKeys.map((timeKey) {
                final list = schedule[timeKey] ?? [];
                return _TimeSlotCard(
                  timeLabel: _prettyTime(context, timeKey),
                  hhmm: timeKey,
                  meds: list,
                  shouldShowActions: (med) =>
                      _shouldShowCardActions(med: med, hhmm: timeKey),
                  onTaken: (med) => _handleTaken(med: med, hhmm: timeKey),
                  onSkip: (med) => _handleSkip(med: med, hhmm: timeKey),
                );
              }),
              const SizedBox(height: 90),
            ],
          );
        },
      ),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final String timeLabel;
  final String hhmm;
  final List<dynamic> meds;

  final bool Function(dynamic med) shouldShowActions;
  final Future<void> Function(dynamic med) onTaken;
  final Future<void> Function(dynamic med) onSkip;

  const _TimeSlotCard({
    required this.timeLabel,
    required this.hhmm,
    required this.meds,
    required this.shouldShowActions,
    required this.onTaken,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${meds.length} med${meds.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...meds.map((m) {
              final showActions = shouldShowActions(m);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.035),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.medication_rounded,
                              color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${m.form} • Dose: ${m.doseAmount}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                ),
                              ),
                              if ((m.note ?? '').toString().trim().isNotEmpty)
                                ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    (m.note ?? '').toString().trim(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (showActions) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onSkip(m),
                              icon: const Icon(Icons.not_interested),
                              label: const Text('Skip'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => onTaken(m),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Taken'),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}