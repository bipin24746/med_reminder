import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
            ),
            child: Icon(icon, size: 60.w, color: Theme.of(context).colorScheme.primary),
          ),
          SizedBox(height: 28.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp, height: 1.4),
          ),
        ],
      ),
    );
  }
}
