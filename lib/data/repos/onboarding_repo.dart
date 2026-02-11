import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepo {
  static const _kDone = 'onboarding_done';

  Future<bool> isDone() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kDone) ?? false;
  }

  Future<void> setDone() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kDone, true);
  }
}
