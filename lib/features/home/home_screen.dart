import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import 'package:med_reminder_fixed/services/native_alarm_service.dart';
import 'package:med_reminder_fixed/services/notification_services.dart';

import '../../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Convert "HH:mm" -> minutes since midnight (for sorting)
  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  /// Format "HH:mm" -> "8:00 AM"
  String _prettyTime(BuildContext context, String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: h, minute: m);
    return tod.format(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicinesProvider);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi ${auth.email ?? ''}'),
        actions: [
          // ✅ Logout icon (you said you want logout here instead of settings)
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              // If you already show logout dialog in AppShell back,
              // this is optional. If you want dialog here too, tell me.
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

          // ✅ Build schedule map: time -> medicines
          final Map<String, List<dynamic>> schedule = {};
          for (final med in meds) {
            final times = (jsonDecode(med.timesJson) as List).cast<String>();

            for (final t in times) {
              schedule.putIfAbsent(t, () => []);
              schedule[t]!.add(med);
            }
          }

          // ✅ Sort times
          final timesSorted = schedule.keys.toList()
            ..sort((a, b) => _toMinutes(a).compareTo(_toMinutes(b)));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 6),
              Text(
                'Today’s Schedule',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),

              ...timesSorted.map((timeKey) {
                final list = schedule[timeKey] ?? [];

                return _TimeGroupCard(
                  timeLabel: _prettyTime(context, timeKey),
                  meds: list,
                  onDelete: (med) async {
                    if (med.id == null) return;
                    final medId = med.id!;

                    // cancel native alarms (safe upper bound)
                    const slotSize = 10000;
                    const maxSlots = 3000;
                    for (int i = 0; i < maxSlots; i++) {
                      await NativeAlarmService.cancel(medId * slotSize + i);
                    }

                    // cancel notifications (if any)
                    await NotificationService.cancelForMedicine(medId);

                    // delete from DB
                    await ref.read(medicineRepoProvider).delete(medId);

                    // refresh
                    ref.invalidate(medicinesProvider);
                  },
                );
              }),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _TimeGroupCard extends StatelessWidget {
  final String timeLabel;
  final List<dynamic> meds;
  final Future<void> Function(dynamic med) onDelete;

  const _TimeGroupCard({
    required this.timeLabel,
    required this.meds,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: time + count
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  '${meds.length} meds',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Medicines list inside the time card
            ...meds.map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
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

                    // Name + dose/form
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
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
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => onDelete(m),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
