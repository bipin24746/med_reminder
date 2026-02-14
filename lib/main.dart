import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:med_reminder_fixed/services/notification_services.dart';

import 'core/app_theme.dart';
import 'core/router.dart';
import 'services/timezone_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await TimezoneService.init();
  await NotificationService.init(); // ✅ MUST

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme(),
          routerConfig: router,

          // ✅ Elders: make text bigger everywhere safely (no TextTheme.apply crash)
          builder: (context, appChild) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: const TextScaler.linear(1.25), // 25% bigger
              ),
              child: appChild ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
