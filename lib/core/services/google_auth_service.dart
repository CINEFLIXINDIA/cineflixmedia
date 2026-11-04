import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/app_constants.dart';

class GoogleAuthResult {
  final String email;
  final String? name;
  final String id;
  final String? idToken;
  final String? photoUrl;

  const GoogleAuthResult({
    required this.email,
    required this.id,
    this.name,
    this.idToken,
    this.photoUrl,
  });
}

class GoogleAuthService {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConstants.googleServerClientId,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[GoogleAuthService] Initialize warning: $e');
    }
  }

  static Future<GoogleAuthResult?> signIn() async {
    await ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      return GoogleAuthResult(
        email: account.email,
        id: account.id,
        name: account.displayName,
        idToken: idToken,
        photoUrl: account.photoUrl,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('[GoogleAuthService] Sign-in canceled by user');
        return null;
      }
      debugPrint('[GoogleAuthService] GoogleSignInException: ${e.code} ${e.description}');
      rethrow;
    } catch (e) {
      debugPrint('[GoogleAuthService] Sign-in error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('[GoogleAuthService] Sign-out warning: $e');
    }
  }
}

