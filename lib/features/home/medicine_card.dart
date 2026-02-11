import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/medicine.dart';
import 'package:intl/intl.dart';

class MedicineCard extends StatelessWidget {
  final Medicine med;
  final VoidCallback onDelete;

  const MedicineCard({super.key, required this.med, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final times = (jsonDecode(med.timesJson) as List).cast<String>();
    final start = DateTime.fromMillisecondsSinceEpoch(med.startDateMillis);
    final df = DateFormat('dd MMM yyyy');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(med.name, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 6.h),
            if ((med.note ?? '').isNotEmpty)
              Text(med.note!, style: TextStyle(fontSize: 14.sp, color: Colors.black54)),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 8.h,
              children: [
                _chip('Times/day: ${med.timesPerDay}'),
                _chip('Days: ${med.days}'),
                _chip('TZ: ${med.timezone}'),
                _chip('Start: ${df.format(start)}'),
              ],
            ),
            SizedBox(height: 10.h),
            Text('Times: ${times.join(', ')}', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 10.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2FF),
      borderRadius: BorderRadius.circular(30.r),
    ),
    child: Text(t, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
  );
}
