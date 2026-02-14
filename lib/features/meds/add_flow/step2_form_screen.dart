import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import '../../../../providers/providers.dart';

class Step2FormScreen extends ConsumerWidget {
  const Step2FormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(addMedFlowProvider);

    final items = const [
      ('pill', Icons.local_hospital, 'Pill / Tablet'),
      ('capsule', Icons.medication_outlined, 'Capsule'),
      ('liquid', Icons.water_drop, 'Liquid / Syrup'),
      ('injection', Icons.vaccines, 'Injection'),
      ('inhaler', Icons.air, 'Inhaler'),
      ('drops', Icons.opacity, 'Drops'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Medication Type (2/7)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select the form',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final (key, icon, label) = items[i];
                  final selected = flow.form == key;
                  return Card(
                    child: ListTile(
                      leading: Icon(icon, size: 34),
                      title: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      trailing: selected ? const Icon(Icons.check_circle) : null,
                      onTap: () => ref.read(addMedFlowProvider.notifier).setForm(key),
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
                    onPressed: () => context.push('/meds/add/frequency'),
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
