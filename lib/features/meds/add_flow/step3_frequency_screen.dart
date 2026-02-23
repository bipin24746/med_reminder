import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import 'add_med_flow_state.dart';
import '../../../../providers/providers.dart';

class Step3FrequencyScreen extends ConsumerWidget {
  const Step3FrequencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(addMedFlowProvider);
    final isEdit = flow.editingId != null;

    return Scaffold(
      appBar: AppBar(title: Text('${isEdit ? "Edit" : "Add"} Medication (3/6)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How often do you take it?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Frequency type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<MedFrequencyType>(
                    value: flow.frequencyType,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: MedFrequencyType.daily, child: Text('Daily')),
                      DropdownMenuItem(value: MedFrequencyType.intervalHours, child: Text('Every X hours')),
                      DropdownMenuItem(value: MedFrequencyType.weekly, child: Text('Weekly')),
                      DropdownMenuItem(value: MedFrequencyType.monthly, child: Text('Monthly')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(addMedFlowProvider.notifier).setFrequencyType(v);
                    },
                  ),

                  const SizedBox(height: 14),

                  if (flow.frequencyType == MedFrequencyType.intervalHours) ...[
                    const Text('Interval (hours)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: flow.intervalHours.clamp(1, 24),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: List.generate(24, (i) => i + 1)
                          .map((h) => DropdownMenuItem(value: h, child: Text('Every $h hour(s)')))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        ref.read(addMedFlowProvider.notifier).setIntervalHours(v);
                      },
                    ),
                  ],

                  if (flow.frequencyType == MedFrequencyType.weekly) ...[
                    const SizedBox(height: 10),
                    const Text('Select weekdays', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (i) {
                        final day = i + 1; // 1..7
                        final label = const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i];
                        final selected = flow.weeklyDays.contains(day);
                        return FilterChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (on) {
                            final next = {...flow.weeklyDays};
                            if (on) next.add(day); else next.remove(day);
                            if (next.isEmpty) return; // keep at least 1
                            ref.read(addMedFlowProvider.notifier).setWeeklyDays(next);
                          },
                        );
                      }),
                    ),
                  ],

                  if (flow.frequencyType == MedFrequencyType.monthly) ...[
                    const SizedBox(height: 10),
                    const Text('Day of month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: flow.monthlyDay.clamp(1, 31),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: List.generate(31, (i) => i + 1)
                          .map((d) => DropdownMenuItem(value: d, child: Text('Day $d')))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        ref.read(addMedFlowProvider.notifier).setMonthlyDay(v);
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Start date stays
            ListTile(
              contentPadding: EdgeInsets.zero,
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
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
                Expanded(child: OutlinedButton(onPressed: () => context.pop(), child: const Text('Back'))),
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

  Widget _card({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}
