import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:med_reminder_fixed/data/repos/mdecine_repo.dart';
import '../data/repos/onboarding_repo.dart';
import '../data/repos/user_repo.dart';
import '../data/models/medicine.dart';

final onboardingRepoProvider = Provider((ref) => OnboardingRepo());
final userRepoProvider = Provider((ref) => UserRepo());
final medicineRepoProvider = Provider((ref) => MedicineRepo());

final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  return ref.read(onboardingRepoProvider).isDone();
});

class AuthState {
  final bool isLoggedIn;
  final String? email;
  const AuthState({required this.isLoggedIn, this.email});
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._userRepo) : super(const AuthState(isLoggedIn: false));
  final UserRepo _userRepo;

  Future<bool> signIn(String email, String password) async {
    final user = await _userRepo.signIn(email, password);
    if (user == null) return false;
    state = AuthState(isLoggedIn: true, email: user.email);
    return true;
  }

  Future<bool> signUp(String email, String password) async {
    final ok = await _userRepo.signUp(email, password);
    return ok;
  }

  void signOut() {
    state = const AuthState(isLoggedIn: false);
  }
}

final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(userRepoProvider));
});

final medicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  return ref.read(medicineRepoProvider).all();
});
