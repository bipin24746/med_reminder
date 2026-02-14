import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import '../../../../providers/providers.dart';

class Step6DoseScreen extends ConsumerStatefulWidget {
  const Step6DoseScreen({super.key});
  @override
  ConsumerState<Step6DoseScreen> createState() => _Step6DoseScreenState();
}

class _Step6DoseScreenState extends ConsumerState<Step6DoseScreen> {
  late final TextEditingController _dose;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final flow = ref.read(addMedFlowProvider);
    _dose = TextEditingController(text: flow.doseAmount);
    _note = TextEditingController(text: flow.note);
  }

  @override
  void dispose() {
    _dose.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(addMedFlowProvider);
    final isEdit = flow.editingId != null;

    final quick = _quickDose(flow.form);

    return Scaffold(
      appBar: AppBar(title: Text('${isEdit ? "Edit" : "Add"} Medication (6/7)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Dose information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: quick.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  onPressed: () => setState(() => _dose.text = s),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),
            TextField(
              controller: _dose,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Dose amount',
                hintText: 'e.g. 1 tablet, 5 ml',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. after food',
              ),
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
                    onPressed: () {
                      ref.read(addMedFlowProvider.notifier).setDose(_dose.text.trim().isEmpty ? '1' : _dose.text.trim());
                      ref.read(addMedFlowProvider.notifier).setNote(_note.text.trim());
                      context.push('/meds/add/summary');
                    },
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

  List<String> _quickDose(String form) {
    switch (form) {
      case 'liquid':
        return const ['5 ml', '10 ml', '15 ml'];
      case 'injection':
        return const ['1 dose', '2 doses'];
      case 'drops':
        return const ['1 drop', '2 drops', '3 drops'];
      case 'inhaler':
        return const ['1 puff', '2 puffs'];
      default:
        return const ['1 tablet', '2 tablets', '½ tablet'];
    }
  }
}
