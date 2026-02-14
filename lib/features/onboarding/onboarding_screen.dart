import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      OnboardingPage(
        title: 'Never miss your medicine',
        subtitle: 'Simple Medicine Reminder Application.',
        icon: Icons.medication_outlined,
      ),
      OnboardingPage(
        title: 'Timezone-based reminders',
        subtitle: 'Select your timezone so reminders work even when traveling.',
        icon: Icons.public,
      ),
      OnboardingPage(
        title: 'Easy for elders',
        subtitle: 'Large buttons, high contrast, and minimal steps.',
        icon: Icons.accessibility_new,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false, // ✅ bottom handled by bottomNavigationBar
        child: PageView(
          controller: _controller,
          onPageChanged: (v) => setState(() => _index = v),
          children: pages,
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 14.h),
          child: LayoutBuilder(
            builder: (context, c) {
              // ✅ make sure button width is always finite
              final buttonWidth = (c.maxWidth * 0.38).clamp(140.0, 190.0);

              return Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                            (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: i == _index ? 26.w : 10.w,
                          height: 10.w,
                          margin: EdgeInsets.symmetric(horizontal: 5.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.r),
                            color: i == _index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary.withOpacity(0.25),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // ✅ fixed width + fixed height => never Infinity
                  SizedBox(
                    width: buttonWidth,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_index < pages.length - 1) {
                          await _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                          return;
                        }

                        await ref.read(onboardingRepoProvider).setDone();
                        ref.invalidate(onboardingDoneProvider);

                        if (context.mounted) context.go('/signin');
                      },
                      child: Text(
                        _index < pages.length - 1 ? 'Next' : 'Get Started',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),

    );
  }
}

