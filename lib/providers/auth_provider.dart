import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/services/apple_auth_service.dart';
import '../core/services/google_auth_service.dart';
import '../core/services/storage_service.dart';
import '../data/models/author_model.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storageService;
  final ApiClient _apiClient;

  String? _token;
  AuthorModel? _author;
  AuthorStatsModel? _stats;
  List<ActivityLogModel> _activityLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._storageService, {ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient() {
    _initFromStorage();
  }

  // Getters
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get token => _token;
  AuthorModel? get author => _author;
  AuthorStatsModel get stats => _stats ?? const AuthorStatsModel();
  List<ActivityLogModel> get activityLogs => List.unmodifiable(_activityLogs);
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _initFromStorage() {
    _token = _storageService.getAuthToken();
    final cached = _storageService.getAuthorData();
    if (cached != null) {
      try {
        final data = AuthorDashboardData.fromJson(cached);
        _author = data.author;
        _stats = data.stats;
        _activityLogs = data.activityLogs;
      } catch (e) {
        debugPrint('[AuthProvider] Error restoring cached author data: $e');
      }
    }

    if (isAuthenticated) {
      loadDashboard(silent: true);
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        body: {
          'email': email.trim(),
          'password': password,
        },
      );

      if (response is Map<String, dynamic> && response['error'] == false) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final token = data['token']?.toString();

        if (token != null && token.isNotEmpty) {
          _token = token;
          await _storageService.setAuthToken(token);

          // Now fetch the real dashboard metrics & activity logs
          await loadDashboard(silent: true);

          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        }
      }

      final msg = response is Map && response['message'] != null
          ? response['message'].toString()
          : 'Login failed. Please check your credentials.';
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle({GoogleAuthResult? mockAuthResult}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = mockAuthResult ?? await GoogleAuthService.signIn();
      if (result == null) {
        // User cancelled account picker
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final body = <String, dynamic>{
        'guard': 'member',
        'email': result.email,
        'name': result.name ?? result.email,
        'id': result.id,
      };

      if (result.idToken != null && result.idToken!.isNotEmpty) {
        body['identityToken'] = result.idToken;
      }
      if (result.photoUrl != null && result.photoUrl!.isNotEmpty) {
        body['avatar'] = result.photoUrl;
      }

      final response = await _apiClient.post(
        ApiEndpoints.authGoogle,
        body: body,
      );

      if (response is Map<String, dynamic> && response['error'] == false) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final token = data['token']?.toString();

        if (token != null && token.isNotEmpty) {
          _token = token;
          await _storageService.setAuthToken(token);

          // Fetch real author dashboard data
          await loadDashboard(silent: true);

          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        }
      }

      final msg = response is Map && response['message'] != null
          ? response['message'].toString()
          : 'Google sign-in failed. Please try again.';
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithApple({AppleAuthResult? mockAuthResult}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = mockAuthResult ?? await AppleAuthService.signIn();
      if (result == null) {
        // User cancelled Apple Sign In
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final body = <String, dynamic>{
        'guard': 'member',
        'identityToken': result.identityToken,
        'id': result.id,
      };

      if (result.email != null && result.email!.isNotEmpty) {
        body['email'] = result.email;
      }
      if (result.name != null && result.name!.isNotEmpty) {
        body['name'] = result.name;
      }
      if (result.authorizationCode != null && result.authorizationCode!.isNotEmpty) {
        body['authorizationCode'] = result.authorizationCode;
      }

      final response = await _apiClient.post(
        ApiEndpoints.authApple,
        body: body,
      );

      if (response is Map<String, dynamic> && response['error'] == false) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final token = data['token']?.toString();

        if (token != null && token.isNotEmpty) {
          _token = token;
          await _storageService.setAuthToken(token);

          // Fetch real author dashboard data
          await loadDashboard(silent: true);

          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        }
      }

      final msg = response is Map && response['message'] != null
          ? response['message'].toString()
          : 'Apple sign-in failed. Please try again.';
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Apple sign-in error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadDashboard({bool refresh = false, bool silent = false}) async {
    if (!isAuthenticated) return;

    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.authorDashboard,
        token: _token,
      );

      if (response is Map<String, dynamic> && response['error'] == false) {
        final dataJson = response['data'] as Map<String, dynamic>? ?? {};
        final dashboardData = AuthorDashboardData.fromJson(dataJson);

        _author = dashboardData.author;
        _stats = dashboardData.stats;
        _activityLogs = dashboardData.activityLogs;

        await _storageService.setAuthorData(dataJson);
      }
    } on ApiException catch (e) {
      debugPrint('[AuthProvider] Failed to load author dashboard: ${e.message}');
      if (e.statusCode == 401) {
        // Token expired or invalid
        await logout();
        return;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error loading author dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? fullName,
    String? displayName,
    String? phone,
    String? description,
    String? dob,
    String? gender,
    String? education,
    String? designation,
    String? experience,
    String? city,
    String? state,
    String? address,
    String? facebook,
    String? instagram,
    String? xTwitter,
    String? youtube,
    String? linkedin,
  }) async {
    if (!isAuthenticated || _token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fName = firstName?.trim() ?? '';
      final lName = lastName?.trim() ?? '';
      String derivedName = '';
      if (fullName != null && fullName.trim().isNotEmpty) {
        derivedName = fullName.trim();
      } else if (fName.isNotEmpty || lName.isNotEmpty) {
        derivedName = '$fName $lName'.trim();
      }

      final body = <String, dynamic>{
        if (fName.isNotEmpty) 'first_name': fName,
        if (lName.isNotEmpty) 'last_name': lName,
        if (derivedName.isNotEmpty) 'name': derivedName,
        if (derivedName.isNotEmpty) 'full_name': derivedName,
        if (displayName != null) 'display_name': displayName.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (description != null) 'description': description.trim(),
        if (dob != null) 'dob': dob.trim(),
        if (gender != null) 'gender': gender.trim(),
        if (education != null) 'education': education.trim(),
        if (designation != null) 'designation': designation.trim(),
        if (experience != null) 'experience': experience.trim(),
        if (city != null) 'city': city.trim(),
        if (state != null) 'state': state.trim(),
        if (address != null) 'address': address.trim(),
        if (facebook != null) 'facebook': facebook.trim(),
        if (instagram != null) 'instagram': instagram.trim(),
        if (xTwitter != null) 'x_twitter': xTwitter.trim(),
        if (youtube != null) 'youtube': youtube.trim(),
        if (linkedin != null) 'linkedin': linkedin.trim(),
      };

      dynamic response;
      try {
        response = await _apiClient.post(
          ApiEndpoints.authorUpdateProfile,
          body: body,
          token: _token,
        );
      } catch (_) {
        // Fallback to me endpoint if needed
        response = await _apiClient.put(
          ApiEndpoints.me,
          body: body,
          token: _token,
        );
      }

      if (response is Map<String, dynamic> && response['error'] == false) {
        // Immediate local cache update
        if (response['data'] is Map<String, dynamic> && response['data']['author'] is Map<String, dynamic>) {
          _author = AuthorModel.fromJson(response['data']['author'] as Map<String, dynamic>);
          await _storageService.setAuthorData({'author': _author!.toJson()});
        }
        // Refresh author data from dashboard
        await loadDashboard(refresh: true, silent: true);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final msg = response is Map && response['message'] != null
          ? response['message'].toString()
          : 'Failed to update profile.';
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred while updating profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAvatar(String filePath) async {
    if (!isAuthenticated || _token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.postMultipart(
        ApiEndpoints.authorUpdateAvatar,
        fileFieldName: 'avatar',
        filePath: filePath,
        token: _token,
      );

      if (response is Map<String, dynamic> && response['error'] == false) {
        // Refresh author data from dashboard
        await loadDashboard(refresh: true, silent: true);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final msg = response is Map && response['message'] != null
          ? response['message'].toString()
          : 'Failed to update profile photo.';
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred while uploading photo: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_token != null && _token!.isNotEmpty) {
        await _apiClient.get(ApiEndpoints.logout, token: _token);
      }
      await GoogleAuthService.signOut();
    } catch (e) {
      debugPrint('[AuthProvider] Logout API call warning: $e');
    } finally {
      _token = null;
      _author = null;
      _stats = null;
      _activityLogs = [];
      _errorMessage = null;
      await _storageService.clearAuth();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_token != null && _token!.isNotEmpty) {
        await _apiClient.delete(ApiEndpoints.authorDeleteAccount, token: _token);
      }
      await GoogleAuthService.signOut();
      _token = null;
      _author = null;
      _stats = null;
      _activityLogs = [];
      _errorMessage = null;
      await _storageService.clearAuth();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthProvider] Delete account error: $e');
      _errorMessage = 'Failed to delete account: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
