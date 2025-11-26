import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rescueeats/core/model/userModel.dart';
import 'package:rescueeats/screens/auth/provider/authstate.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:rescueeats/screens/restaurant/provider/restaurant_provider.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Ref _ref;

  AuthNotifier(this._apiService, this._ref) : super(const AuthState());

  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    // 1. Validation Guard
    if (emailOrPhone.trim().isEmpty || password.trim().isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Please fill in all fields',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final user = await _apiService.login(emailOrPhone, password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);

      // Auto-fetch restaurant for restaurant owners
      if (user.role == UserRole.restaurant) {
        _ref.read(restaurantOwnerProvider.notifier).fetchMyRestaurant();
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
  }) async {
    if (name.isEmpty ||
        email.isEmpty ||
        phoneNumber.isEmpty ||
        password.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Please fill in all fields',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final user = await _apiService.register(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        role: role,
      );

      state = state.copyWith(status: AuthStatus.authenticated, user: user);

      // Auto-fetch restaurant for restaurant owners
      if (user.role == UserRole.restaurant) {
        _ref.read(restaurantOwnerProvider.notifier).fetchMyRestaurant();
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> signInWithGoogle({UserRole role = UserRole.user}) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Send idToken to backend for verification
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      final user = await _apiService.googleAuth(googleAuth.idToken!, role);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Google Sign-In failed: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _apiService.logout();
      await _googleSignIn.signOut();

      // Clear restaurant data on logout
      _ref.read(restaurantOwnerProvider.notifier).clear();

      await Future.delayed(const Duration(seconds: 1));
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiService(), ref);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});
