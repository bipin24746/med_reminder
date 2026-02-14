import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/models/medicine.dart';
import '../data/repos/mdecine_repo.dart';
import '../data/repos/onboarding_repo.dart';
import '../data/repos/user_repo.dart';
import '../data/repos/session_repo.dart';

final onboardingRepoProvider = Provider((ref) => OnboardingRepo());
final userRepoProvider = Provider((ref) => UserRepo());
final medicineRepoProvider = Provider((ref) => MedicineRepo());
final sessionRepoProvider = Provider((ref) => SessionRepo());

final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  return ref.read(onboardingRepoProvider).isDone();
});

// ----------------- AUTH -----------------

class AuthState {
  final bool isLoggedIn;
  final String? email;
  const AuthState({required this.isLoggedIn, this.email});
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._userRepo, this._sessionRepo)
      : super(const AuthState(isLoggedIn: false));

  final UserRepo _userRepo;
  final SessionRepo _sessionRepo;

  /// ✅ restore login state from SharedPreferences
  Future<void> loadSession() async {
    final (loggedIn, email) = await _sessionRepo.readSession();
    if (loggedIn) {
      state = AuthState(isLoggedIn: true, email: email);
    }
  }

  Future<bool> signIn(String email, String password) async {
    final user = await _userRepo.signIn(email, password);
    if (user == null) return false;

    state = AuthState(isLoggedIn: true, email: user.email);
    await _sessionRepo.saveSession(email: user.email);
    return true;
  }

  Future<bool> signUp(String email, String password) async {
    final ok = await _userRepo.signUp(email, password);
    return ok;
  }

  Future<void> signOut() async {
    state = const AuthState(isLoggedIn: false);
    await _sessionRepo.clearSession();
  }
}

final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(
    ref.read(userRepoProvider),
    ref.read(sessionRepoProvider),
  );

  // ✅ auto-load saved session immediately
  Future.microtask(() => controller.loadSession());

  return controller;
});

// ----------------- MEDS -----------------

final medicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  return ref.read(medicineRepoProvider).all();
});
