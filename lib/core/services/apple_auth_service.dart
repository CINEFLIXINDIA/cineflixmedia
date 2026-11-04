import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthResult {
  final String id;
  final String identityToken;
  final String? email;
  final String? name;
  final String? authorizationCode;

  const AppleAuthResult({
    required this.id,
    required this.identityToken,
    this.email,
    this.name,
    this.authorizationCode,
  });
}

class AppleAuthService {
  static Future<bool> isAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      debugPrint('[AppleAuthService] isAvailable check error: $e');
      return false;
    }
  }

  static Future<AppleAuthResult?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Apple authorization did not return an identity token');
      }

      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        final parts = [credential.givenName, credential.familyName]
            .where((p) => p != null && p.trim().isNotEmpty)
            .join(' ');
        if (parts.isNotEmpty) {
          fullName = parts;
        }
      }

      return AppleAuthResult(
        id: credential.userIdentifier ?? '',
        identityToken: identityToken,
        email: credential.email,
        name: fullName,
        authorizationCode: credential.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[AppleAuthService] Sign-in canceled by user');
        return null;
      }
      debugPrint('[AppleAuthService] AuthorizationException: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AppleAuthService] Sign-in error: $e');
      rethrow;
    }
  }
}

