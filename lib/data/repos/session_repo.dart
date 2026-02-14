import 'package:shared_preferences/shared_preferences.dart';

class SessionRepo {
  static const _kLoggedIn = 'logged_in';
  static const _kEmail = 'email';

  Future<void> saveSession({required String email}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kLoggedIn, true);
    await sp.setString(_kEmail, email);
  }

  Future<void> clearSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kLoggedIn, false);
    await sp.remove(_kEmail);
  }

  Future<(bool loggedIn, String? email)> readSession() async {
    final sp = await SharedPreferences.getInstance();
    final loggedIn = sp.getBool(_kLoggedIn) ?? false;
    final email = sp.getString(_kEmail);
    return (loggedIn, email);
  }
}
