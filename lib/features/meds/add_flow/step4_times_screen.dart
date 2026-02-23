import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'add_med_flow_controller.dart';
import 'add_med_flow_state.dart';
import 'wheel_time_picker.dart'; // adjust path if needed

class Step4TimesScreen extends ConsumerWidget {
  const Step4TimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(addMedFlowProvider);
    final ctrl = ref.read(addMedFlowProvider.notifier);

    final isEdit = flow.editingId != null;
    final isInterval = flow.frequencyType == MedFrequencyType.intervalHours;

    final times = flow.times;

    return Scaffold(
      appBar: AppBar(
        title: Text('${isEdit ? "Edit" : "Add"} Medication (4/6)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Set reminder times',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            if (!isInterval)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: times.length >= 12 ? null : ctrl.addTime,
                      icon: const Icon(Icons.add),
                      label: const Text('Add time'),
                    ),
                  ),
                ],
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Every X hours uses only one time stream.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: times.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final t = times[i];

                  return Card(
                    child: ListTile(
                      title: Text(
                        'Time ${i + 1}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        t.format(context),
                        style: const TextStyle(fontSize: 20),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 28),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: (isInterval || times.length <= 1)
                                ? null
                                : () => ctrl.removeTimeAt(i),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final picked = await showWheelTimePicker(context, initial: t);
                        if (picked != null) {
                          final updated = List<TimeOfDay>.from(times);
                          updated[i] = picked;
                          ctrl.setTimes(updated);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/meds/add/dose'),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
