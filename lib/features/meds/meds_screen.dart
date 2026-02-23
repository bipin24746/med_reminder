import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../services/native_alarm_service.dart';
import '../meds/add_flow/add_med_flow_controller.dart';

class MedsScreen extends ConsumerStatefulWidget {
  const MedsScreen({super.key});

  @override
  ConsumerState<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends ConsumerState<MedsScreen> {
  int? _deletingId;

  // Convert weeklyMask (Mon bit0 ... Sun bit6) -> Set<int> days 1..7
  Set<int> _daysFromMask(int mask) {
    final out = <int>{};
    for (int d = 1; d <= 7; d++) {
      final bit = 1 << (d - 1);
      if ((mask & bit) != 0) out.add(d);
    }
    return out;
  }

  Future<bool> _confirmDelete(BuildContext context, String medName) async {
    final res = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Delete medicine?'),
          content: Text('Delete "$medName" and cancel all its reminders?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }

  Future<void> _deleteMedicine(BuildContext context, int medId, String medName) async {
    if (_deletingId != null) return;

    final ok = await _confirmDelete(context, medName);
    if (!ok) return;

    setState(() => _deletingId = medId);

    try {
      // ✅ cancel all alarm streams for this medicine
      await NativeAlarmService.cancelForMedicine(medId);

      // ✅ delete from DB
      await ref.read(medicineRepoProvider).delete(medId);

      // ✅ refresh list
      ref.invalidate(medicinesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "$medName"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(medicinesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Medicines')),
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
                'No medicines yet.\nTap “Add Medicines”.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: meds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final m = meds[i];
              final isDeletingThis = (m.id != null && _deletingId == m.id);

              return Card(
                child: ListTile(
                  title: Text(
                    m.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${m.form} • Dose: ${m.doseAmount}\nTimes/day: ${m.timesPerDay}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: isDeletingThis
                            ? null
                            : () async {
                          if (m.id == null) return;

                          final times = (jsonDecode(m.timesJson) as List).cast<String>().map((s) {
                            final p = s.split(':');
                            return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
                          }).toList();

                          ref.read(addMedFlowProvider.notifier).loadForEdit(
                            id: m.id!,
                            name: m.name,
                            form: m.form,
                            timesPerDay: m.timesPerDay,
                            times: times,
                            doseAmount: m.doseAmount,
                            note: m.note ?? '',
                            timezone: m.timezone,
                            startDate: DateTime.fromMillisecondsSinceEpoch(m.startDateMillis),

                            // ✅ new fields (must exist in Medicine model/db)
                            frequencyType: m.frequencyType,
                            intervalHours: m.intervalHours,
                            weeklyDays: _daysFromMask(m.weeklyMask),
                            monthlyDay: m.monthlyDay,
                          );

                          context.go('/meds/add/name');
                        },
                      ),
                      IconButton(
                        icon: isDeletingThis
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.delete_outline),
                        onPressed: isDeletingThis
                            ? null
                            : () async {
                          if (m.id == null) return;
                          await _deleteMedicine(context, m.id!, m.name);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}