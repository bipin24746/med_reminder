import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import '../../../../providers/providers.dart';

class Step5ReviewTimesScreen extends ConsumerWidget {
  const Step5ReviewTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(addMedFlowProvider);
    final isEdit = flow.editingId != null;

    final times = List<TimeOfDay>.from(flow.times);

    return Scaffold(
      appBar: AppBar(title: Text('${isEdit ? "Edit" : "Add"} Medication (5/7)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Review your times',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                itemCount: times.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        times[i].format(context),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 28),
                        onPressed: () {
                          if (times.length <= 1) return; // keep at least 1
                          times.removeAt(i);
                          ref.read(addMedFlowProvider.notifier).setTimes(times);
                          ref.read(addMedFlowProvider.notifier).setTimesPerDay(times.length);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Times per day: ${times.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 12),
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
