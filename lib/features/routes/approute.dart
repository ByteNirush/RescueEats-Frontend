import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescueeats/features/routes/routeconstants.dart';
import 'package:rescueeats/screens/admin/createRestaurantScreen.dart';
import 'package:rescueeats/screens/restaurant/createMyRestaurantScreen.dart';
import 'package:rescueeats/screens/auth/forgotPs.dart';
import 'package:rescueeats/screens/auth/login.dart';
import 'package:rescueeats/screens/auth/provider/authprovider.dart';
import 'package:rescueeats/screens/auth/provider/authstate.dart';
import 'package:rescueeats/screens/auth/signup.dart';
import 'package:rescueeats/screens/home/homescreen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStatusProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: RouteConstants.login,
    redirect: (BuildContext context, GoRouterState state) {
      final currentLocation = state.uri.toString();
      final bool loggingIn =
          currentLocation == RouteConstants.login ||
          currentLocation == RouteConstants.register ||
          currentLocation ==
              RouteConstants.forgotPassword; // Allow forgot password access

      if (authStatus == AuthStatus.authenticated) {
        if (loggingIn) {
          return RouteConstants.home;
        }
        return null;
      }

      if (authStatus == AuthStatus.unauthenticated) {
        if (!loggingIn) {
          return RouteConstants.login;
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteConstants.login,
        name: RouteConstants.loginName,
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: RouteConstants.register,
        name: RouteConstants.registerName,
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const RegisterScreen()),
      ),
      // Add Forgot Password Route
      GoRoute(
        path: RouteConstants.forgotPassword,
        name: RouteConstants.forgotPasswordName,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: RouteConstants.home,
        name: RouteConstants.homeName,
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const HomeScreen()),
      ),
      GoRoute(
        path: RouteConstants.createRestaurant,
        name: RouteConstants.createRestaurantName,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const CreateRestaurantScreen(),
        ),
      ),
      GoRoute(
        path: RouteConstants.createMyRestaurant,
        name: RouteConstants.createMyRestaurantName,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const CreateMyRestaurantScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});
