import 'dart:convert';
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
  static const String appleClientId = 'com.cineflixmedia.app.service';
  static const String appleRedirectUri = 'https://cineflixmedia.in/api/v1/auth/apple/callback';

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
      WebAuthenticationOptions? webOptions;
      if (defaultTargetPlatform == TargetPlatform.android) {
        webOptions = WebAuthenticationOptions(
          clientId: appleClientId,
          redirectUri: Uri.parse(appleRedirectUri),
        );
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: webOptions,
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

      // If userIdentifier or email is missing (e.g. on Android or subsequent logins), extract from JWT claims
      String userId = credential.userIdentifier ?? '';
      String? userEmail = credential.email;
      if (userId.isEmpty || userEmail == null || userEmail.isEmpty) {
        final claims = _extractJwtClaims(identityToken);
        if (userId.isEmpty && claims['sub'] != null) {
          userId = claims['sub'].toString();
        }
        if ((userEmail == null || userEmail.isEmpty) && claims['email'] != null) {
          userEmail = claims['email'].toString();
        }
      }

      return AppleAuthResult(
        id: userId,
        identityToken: identityToken,
        email: userEmail,
        name: fullName,
        authorizationCode: credential.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[AppleAuthService] Sign-in canceled by user');
        return null;
      }
      debugPrint('[AppleAuthService] AuthorizationException: ${e.code} ${e.message}');
      if (e.code == AuthorizationErrorCode.unknown || e.message.contains('1000')) {
        throw Exception(
          'Apple Sign-In is unavailable (Code 1000). On iOS/iPad Simulator, please ensure you are signed in to an Apple ID in device Settings, and that "Sign in with Apple" is enabled on com.cineflixmedia.app.',
        );
      }
      throw Exception('Apple Sign-In failed: ${e.message}');
    } catch (e) {
      debugPrint('[AppleAuthService] Sign-in error: $e');
      final str = e.toString();
      if (str.contains('1000')) {
        throw Exception(
          'Apple Sign-In is unavailable (Code 1000). On iOS/iPad Simulator, please ensure you are signed in to an Apple ID in device Settings, and that "Sign in with Apple" is enabled on com.cineflixmedia.app.',
        );
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _extractJwtClaims(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length >= 2) {
        final normalized = base64Url.normalize(parts[1]);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final payload = jsonDecode(decoded);
        if (payload is Map<String, dynamic>) {
          return payload;
        }
      }
    } catch (e) {
      debugPrint('[AppleAuthService] Error extracting JWT claims: $e');
    }
    return {};
  }
}
