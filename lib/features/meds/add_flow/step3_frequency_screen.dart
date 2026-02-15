import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
import '../../../../providers/providers.dart';

class Step3FrequencyScreen extends ConsumerStatefulWidget {
  const Step3FrequencyScreen({super.key});

  @override
  ConsumerState<Step3FrequencyScreen> createState() => _Step3FrequencyScreenState();
}

class _Step3FrequencyScreenState extends ConsumerState<Step3FrequencyScreen> {
  final _daysCtrl = TextEditingController();

  @override
  void dispose() {
    _daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(addMedFlowProvider);
    final isEdit = flow.editingId != null;

    // Keep textfield in sync (only when value changed externally)
    final flowDaysStr = flow.days.toString();
    if (_daysCtrl.text != flowDaysStr) {
      _daysCtrl.text = flowDaysStr;
      _daysCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _daysCtrl.text.length),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${isEdit ? "Edit" : "Add"} Medication (3/7)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How often do you take it?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),

            // ✅ Times per day dropdown (FULL WIDTH)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Times per day',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: flow.timesPerDay.clamp(1, 6),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    items: List.generate(6, (i) {
                      final v = i + 1;
                      return DropdownMenuItem(
                        value: v,
                        child: Text(
                          '$v times per day',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      );
                    }),
                    onChanged: (v) {
                      if (v == null) return;
                      _setTimesPerDay(v);
                    },
                  ),
                ],
              ),
            ),


            const SizedBox(height: 12),

            // ✅ Days input
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For how many days',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _daysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter no. of days (1 - 365)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (txt) {
                      final n = int.tryParse(txt);
                      if (n == null) return; // don’t update while typing invalid
                      if (n < 1 || n > 365) return;
                      ref.read(addMedFlowProvider.notifier).setDays(n);
                    },
                    onEditingComplete: () {
                      final n = int.tryParse(_daysCtrl.text.trim());
                      if (n == null || n < 1 || n > 365) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Days must be between 1 and 365')),
                        );
                        _daysCtrl.text = flow.days.toString();
                      } else {
                        ref.read(addMedFlowProvider.notifier).setDays(n);
                      }
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Start date (same as yours)
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
                    onPressed: () {
                      // final validation before next
                      final n = int.tryParse(_daysCtrl.text.trim());
                      if (n == null || n < 1 || n > 365) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Days must be between 1 and 365')),
                        );
                        return;
                      }
                      context.push('/meds/add/times');
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

  void _setTimesPerDay(int v) {
    ref.read(addMedFlowProvider.notifier).setTimesPerDay(v);

    // keep times list length == v
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
