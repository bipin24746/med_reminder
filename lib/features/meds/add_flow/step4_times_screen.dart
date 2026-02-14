import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import '../../../../providers/providers.dart';

class Step4TimesScreen extends ConsumerWidget {
  const Step4TimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(addMedFlowProvider);
    final isEdit = flow.editingId != null;

    final times = List<TimeOfDay>.from(flow.times);

    return Scaffold(
      appBar: AppBar(title: Text('${isEdit ? "Edit" : "Add"} Medication (4/7)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Set reminder times',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),

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
                      trailing: const Icon(Icons.access_time, size: 30),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: t);
                        if (picked != null) {
                          times[i] = picked;
                          ref.read(addMedFlowProvider.notifier).setTimes(times);
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
                    onPressed: () => context.push('/meds/add/review'),
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
