import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import '../../../../providers/providers.dart';

class Step1NameScreen extends ConsumerStatefulWidget {
  const Step1NameScreen({super.key});
  @override
  ConsumerState<Step1NameScreen> createState() => _Step1NameScreenState();
}

class _Step1NameScreenState extends ConsumerState<Step1NameScreen> {
  final _c = TextEditingController();

  final _suggestions = const [
    'Paracetamol',
    'Aspirin',
    'Metformin',
    'Vitamin D',
    'Amoxicillin',
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(addMedFlowProvider);

    if (_c.text.isEmpty && flow.name.isNotEmpty) _c.text = flow.name;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Medication"),
        automaticallyImplyLeading: true, // ✅ allow back arrow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'What medicine are you taking?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _c,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Medicine name',
                hintText: 'Type or choose below',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  onPressed: () => setState(() => _c.text = s),
                );
              }).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                final name = _c.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter medicine name')),
                  );
                  return;
                }
                ref.read(addMedFlowProvider.notifier).setName(name);
                context.push('/meds/add/form');
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
