import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/home/medicine_card.dart';
import 'package:med_reminder_fixed/services/alarm_id.dart';
import 'package:med_reminder_fixed/services/native_alarm_service.dart';
import 'package:med_reminder_fixed/services/notification_services.dart';
import '../../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicinesProvider);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi ${auth.email ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],

      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      body: medsAsync.when(
        data: (meds) {
          if (meds.isEmpty) {
            return const Center(
              child: Text('No medicines yet.\nTap "Add Medicine".', textAlign: TextAlign.center),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meds.length,
            itemBuilder: (_, i) {
              final med = meds[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MedicineCard(
                  med: med,
                  onDelete: () async {
                    if (med.id == null) return;
                    final medId = med.id!;

                    // cancel native alarms (safe upper bound)
                    const slotSize = 10000;
                    const maxSlots = 3000; // enough for 365 days * 6 times = 2190
                    for (int i = 0; i < maxSlots; i++) {
                      await NativeAlarmService.cancel(medId * slotSize + i);
                    }

                    // cancel notifications (if any)
                    await NotificationService.cancelForMedicine(medId);

                    // delete from DB
                    await ref.read(medicineRepoProvider).delete(medId);

                    // refresh list
                    ref.invalidate(medicinesProvider);
                  },


                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
