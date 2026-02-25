import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'add_med_flow_controller.dart';

class Step2FormScreen extends ConsumerWidget {
  const Step2FormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(addMedFlowProvider);

    final items = const <_FormItem>[
      _FormItem(
        keyName: 'pill',
        assetPath: 'lib/assets/images/pills-tablets.png',
        label: 'Pill / Tablet',
      ),
      _FormItem(
        keyName: 'capsule',
        assetPath: 'lib/assets/images/capsules.png',
        label: 'Capsule',
      ),
      _FormItem(
        keyName: 'liquid',
        assetPath: 'lib/assets/images/syrup.png',
        label: 'Liquid / Syrup',
      ),
      _FormItem(
        keyName: 'injection',
        assetPath: 'lib/assets/images/syringe.png',
        label: 'Injection',
      ),
      _FormItem(
        keyName: 'inhaler',
        assetPath: 'lib/assets/images/inhaler.png',
        label: 'Inhaler',
      ),
      _FormItem(
        keyName: 'drops',
        assetPath: 'lib/assets/images/eye-dropper.png',
        label: 'Drops',
      ),
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
                  final item = items[i];
                  final selected = flow.form == item.keyName;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: selected
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.35)
                            : Colors.black.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            item.assetPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      title: Text(
                        item.label,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),

                      trailing: selected
                          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                          : const Icon(Icons.chevron_right),

                      onTap: () => ref.read(addMedFlowProvider.notifier).setForm(item.keyName),
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
                    onPressed: flow.form.isEmpty
                        ? null
                        : () => context.push('/meds/add/frequency'),
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

class _FormItem {
  final String keyName;
  final String assetPath;
  final String label;

  const _FormItem({
    required this.keyName,
    required this.assetPath,
    required this.label,
  });
}