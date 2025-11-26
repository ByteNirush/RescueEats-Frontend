import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Sign in with Google and return the ID token
  Future<String?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Return the ID token to send to backend
      return googleAuth.idToken;
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_failed' ||
          e.message?.contains('DEVELOPER_ERROR') == true) {
        throw Exception(
          'Google Sign-In is not configured. Please contact support.',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user info from Google account
  Future<Map<String, String?>> getUserInfo() async {
    final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;

    if (currentUser == null) {
      return {};
    }

    return {
      'name': currentUser.displayName,
      'email': currentUser.email,
      'photoUrl': currentUser.photoUrl,
    };
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } on PlatformException catch (_) {
      // Ignore platform exceptions when Google Sign-In is not configured
    } catch (_) {
      // Don't rethrow - allow logout to continue even if Google sign-out fails
    }
  }

  /// Check if user is currently signed in with Google
  bool get isSignedIn => _googleSignIn.currentUser != null;
}
