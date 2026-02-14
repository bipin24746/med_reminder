import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/home/medicine_card.dart';
import 'package:med_reminder_fixed/features/meds/add_flow/add_med_flow_controller.dart';
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
      icon: const Icon(Icons.logout_rounded),
      onPressed: () async {
        final theme = Theme.of(context);

        final logout = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (dialogCtx) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        size: 34,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Logout?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Do you want to logout?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.72),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogCtx).pop(false),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'No',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(dialogCtx).pop(true),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (logout == true) {
          ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) context.go('/signin');
        }
      },
    ),
    ],


    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(addMedFlowProvider.notifier).reset();
          context.push('/meds/add/name');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Medicines'),
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
