import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import '../../../../providers/providers.dart';

class Step3FrequencyScreen extends ConsumerWidget {
  const Step3FrequencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(addMedFlowProvider);
    final isEdit = flow.editingId != null;

    return Scaffold(
      appBar: AppBar(title: Text('${isEdit ? "Edit" : "Add"} Medication (3/7)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'How often do you take it?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),

            _bigStepperCard(
              title: 'Times per day',
              value: flow.timesPerDay,
              onMinus: () => _setTimesPerDay(ref, (flow.timesPerDay - 1).clamp(1, 6)),
              onPlus: () => _setTimesPerDay(ref, (flow.timesPerDay + 1).clamp(1, 6)),
            ),
            const SizedBox(height: 12),

            _bigStepperCard(
              title: 'For how many days',
              value: flow.days,
              onMinus: () => ref.read(addMedFlowProvider.notifier).setDays((flow.days - 1).clamp(1, 365)),
              onPlus: () => ref.read(addMedFlowProvider.notifier).setDays((flow.days + 1).clamp(1, 365)),
            ),

            const SizedBox(height: 12),
            ListTile(
              title: const Text('Start date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              subtitle: Text(
                '${flow.startDate.year}-${flow.startDate.month.toString().padLeft(2, '0')}-${flow.startDate.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18),
              ),
              trailing: const Icon(Icons.date_range),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  initialDate: flow.startDate,
                );
                if (picked != null) {
                  ref.read(addMedFlowProvider.notifier).setStartDate(picked);
                }
              },
            ),

            const Spacer(),
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
                    onPressed: () => context.push('/meds/add/times'),
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

  void _setTimesPerDay(WidgetRef ref, int v) {
    ref.read(addMedFlowProvider.notifier).setTimesPerDay(v);

    // ensure times list length matches
    final flow = ref.read(addMedFlowProvider);
    final times = List<TimeOfDay>.from(flow.times);

    while (times.length < v) {
      times.add(const TimeOfDay(hour: 12, minute: 0));
    }
    while (times.length > v) {
      times.removeLast();
    }
    ref.read(addMedFlowProvider.notifier).setTimes(times);
  }

  Widget _bigStepperCard({
    required String title,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline, size: 30)),
            Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline, size: 30)),
          ],
        ),
      ),
    );
  }
}
