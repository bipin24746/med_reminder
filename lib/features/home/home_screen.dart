import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import '../../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  String _prettyTime(BuildContext context, String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m).format(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          /// ✅ Build map: time -> list of medicines
          /// ✅ DEDUPE: if same medicine name repeats in the same time, show only one
          final Map<String, List<dynamic>> schedule = {};
          final Map<String, Set<String>> seenNamesByTime = {}; // time -> set of med names

          for (final med in meds) {
            final times = (jsonDecode(med.timesJson) as List).cast<String>();

            for (final t in times) {
              schedule.putIfAbsent(t, () => []);
              seenNamesByTime.putIfAbsent(t, () => <String>{});

              final nameKey = (med.name).trim().toLowerCase();

              // ✅ if same name already added for this time, skip
              if (seenNamesByTime[t]!.contains(nameKey)) continue;

              seenNamesByTime[t]!.add(nameKey);
              schedule[t]!.add(med);
            }
          }

          /// ✅ Sort times
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
                  meds: list,
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
  final List<dynamic> meds;

  const _TimeSlotCard({
    required this.timeLabel,
    required this.meds,
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
            // ✅ Header: Time + count
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
                      Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
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

            // ✅ Medicines list under same time
            ...meds.map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.035),
                  borderRadius: BorderRadius.circular(16),
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
                      child: Icon(
                        Icons.medication_rounded,
                        color: theme.colorScheme.primary,
                      ),
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
                          if ((m.note ?? '').toString().trim().isNotEmpty) ...[
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
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}