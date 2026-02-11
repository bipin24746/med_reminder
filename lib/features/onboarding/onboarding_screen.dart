import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../data/repos/onboarding_repo.dart';
import 'widgets/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const OnboardingPage(
        title: 'Never miss your medicine',
        subtitle: 'Simple reminders with big text, clear actions, and calm design.',
        icon: Icons.medication_outlined,
      ),
      const OnboardingPage(
        title: 'Timezone-based reminders',
        subtitle: 'Select your timezone so reminders work even when traveling.',
        icon: Icons.public,
      ),
      const OnboardingPage(
        title: 'Easy for elders',
        subtitle: 'Large buttons, high contrast, and minimal steps.',
        icon: Icons.accessibility_new,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (v) => setState(() => _index = v),
                children: pages,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                            (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: i == _index ? 22.w : 8.w,
                          height: 8.w,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            color: i == _index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary.withOpacity(0.25),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                    onPressed: () async {
                      if (_index < pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                        return;
                      }
                      await ref.read(onboardingRepoProvider).setDone();
                      ref.invalidate(onboardingDoneProvider);
                      if (context.mounted) context.go('/signin');

                    },
                    child: Text(_index < pages.length - 1 ? 'Next' : 'Get Started',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
