import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:rescueeats/core/model/userModel.dart';
import 'package:rescueeats/screens/auth/provider/authstate.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:rescueeats/screens/restaurant/provider/restaurant_provider.dart';
import 'package:rescueeats/screens/order/orderLogic.dart';

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
      
      // Invalidate order provider to ensure fresh data for new user
      _ref.invalidate(orderControllerProvider);
      
      state = state.copyWith(status: AuthStatus.authenticated, user: user);

      // Register FCM Token
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _apiService.registerFcmToken(fcmToken);
        }
      } catch (e) {
        print('FCM Token Error: $e');
      }

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

      // Invalidate order provider to ensure fresh data for new user
      _ref.invalidate(orderControllerProvider);

      state = state.copyWith(status: AuthStatus.authenticated, user: user);

      // Register FCM Token
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _apiService.registerFcmToken(fcmToken);
        }
      } catch (e) {
        print('FCM Token Error: $e');
      }

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

  // Google Sign-In is currently not supported by the backend
  // The backend uses OAuth 2.0 web flow which is incompatible with mobile
  // Uncomment and implement when backend adds mobile Google Auth support
  /*
  Future<void> signInWithGoogle({UserRole role = UserRole.user}) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // This would need a backend endpoint that accepts ID tokens
      // final user = await _apiService.googleAuth(googleAuth.idToken!, role);
      // state = state.copyWith(status: AuthStatus.authenticated, user: user);
      
      throw Exception('Google Sign-In not supported yet');
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Google Sign-In not supported: ${e.toString()}',
      );
    }
  }
  */

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _apiService.logout();
      await _googleSignIn.signOut();

      // Clear restaurant data on logout
      _ref.read(restaurantOwnerProvider.notifier).clear();
      
      // Invalidate all providers to clear cached data
      _ref.invalidate(orderControllerProvider);

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
