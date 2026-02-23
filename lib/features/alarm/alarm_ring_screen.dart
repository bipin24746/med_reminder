// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../services/notification_services.dart';
//
// class AlarmRingScreen extends StatelessWidget {
//   final int alarmId;
//   final String title;
//   final String body;
//
//   const AlarmRingScreen({
//     super.key,
//     required this.alarmId,
//     required this.title,
//     required this.body,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Reminder')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
//             const SizedBox(height: 8),
//             Text(body, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
//             const Spacer(),
//
//             ElevatedButton.icon(
//               icon: const Icon(Icons.check_circle_outline),
//               label: const Text('Mark as taken'),
//               onPressed: () async {
//                 // ✅ dismiss ONLY this notification / alarm
//                 await NotificationService.cancel(alarmId);
//
//                 // ✅ DO NOT cancel medicine streams here
//                 if (context.mounted) context.pop();
//               },
//             ),
//             const SizedBox(height: 12),
//             OutlinedButton(
//               onPressed: () => context.pop(),
//               child: const Text('Close'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }