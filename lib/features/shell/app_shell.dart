import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  String _loc(BuildContext context) {
    // ✅ go_router v17: this is reliable inside ShellRoute
    return GoRouterState.of(context).uri.toString();
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/meds')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  String _locationForIndex(int index) {
    switch (index) {
      case 1:
        return '/meds';
      case 2:
        return '/settings';
      default:
        return '/';
    }
  }

  bool _isAddFlow(String location) => location.startsWith('/meds/add/');

  Future<bool> _confirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String yesText,
    required String noText,
    IconData icon = Icons.logout_rounded,
  }) async {
    final theme = Theme.of(context);

    final res = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Icon bubble
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 34, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 14),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 18),

                // ✅ Buttons row (full width, same height)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(false),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.35)),
                          ),
                          child: Text(
                            noText,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(true),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            yesText,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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

    return res ?? false;
  }


  Future<bool> _handleBack(BuildContext context) async {
    final location = _loc(context);

    // 1) Add-med flow => normal back
    if (_isAddFlow(location)) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/meds');
      }
      return true; // handled
    }

    // 2) Home => Logout dialog
    if (location == '/' || location.startsWith('/?')) {
      final logout = await _confirmDialog(
        context: context,
        title: 'Logout?',
        message: 'Do you want to logout?',
        yesText: 'Yes',
        noText: 'No',
      );

      if (logout) {
        ref.read(authControllerProvider.notifier).signOut();
        if (mounted) context.go('/signin');
      }
      return true; // handled (even if user said No)
    }

    // 3) Meds / Settings => Exit dialog
    if (location == '/meds' || location == '/settings') {
      final exit = await _confirmDialog(
        context: context,
        title: 'Exit App?',
        message: 'Do you want to close the application?',
        yesText: 'Yes',
        noText: 'No',
      );

      if (exit) {
        SystemNavigator.pop(); // ✅ closes app fully (alarms/db stay)
      }
      return true;
    }

    // 4) Fallback
    if (context.canPop()) {
      context.pop();
      return true;
    }

    context.go('/');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final location = _loc(context);
    final currentIndex = _indexFromLocation(location);

    return BackButtonListener(
      onBackButtonPressed: () async {
        await _handleBack(context);
        return true; // ✅ prevents direct exit always
      },
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          await _handleBack(context);
        },
        child: Scaffold(
          body: widget.child,
          bottomNavigationBar: NavigationBar(
            height: 78,
            selectedIndex: currentIndex,
            onDestinationSelected: (i) {
              final dest = _locationForIndex(i);
              if (_loc(context) != dest) context.go(dest);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.medication_outlined),
                selectedIcon: Icon(Icons.medication),
                label: 'Meds',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
