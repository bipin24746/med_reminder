import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import '../../providers/providers.dart';
import '../../services/native_alarm_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:med_reminder_fixed/services/native_alarm_service.dart';


class MedsScreen extends ConsumerWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              return Card(
                child: ListTile(
                  title: Text(m.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  subtitle: Text('${m.form} • Dose: ${m.doseAmount}\nTimes/day: ${m.timesPerDay}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          if (m.id == null) return;

                          // decode timesJson -> TimeOfDay list
                          final times = (jsonDecode(m.timesJson) as List).cast<String>().map((s) {
                            final p = s.split(':');
                            return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
                          }).toList();

                          ref.read(addMedFlowProvider.notifier).loadForEdit(
                            id: m.id!,
                            name: m.name,
                            form: m.form,
                            days: m.days,
                            timesPerDay: m.timesPerDay,
                            times: times,
                            doseAmount: m.doseAmount,
                            note: m.note ?? '',
                            timezone: m.timezone,
                            startDate: DateTime.fromMillisecondsSinceEpoch(m.startDateMillis),
                          );

                          context.go('/meds/add/name');
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (m.id == null) return;
                          await NativeAlarmService.cancel(m.id!); // optional: if you track per alarm id(s)
                          await ref.read(medicineRepoProvider).delete(m.id!);
                          ref.invalidate(medicinesProvider);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
