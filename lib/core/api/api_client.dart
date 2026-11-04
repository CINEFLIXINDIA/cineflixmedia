import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiClient {
  static const Duration timeoutDuration = Duration(seconds: 15);

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _buildHeaders({String? token, Map<String, String>? extraHeaders}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-API-KEY': AppConstants.apiKey,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?extraHeaders,
    };
  }

  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParameters != null && queryParameters.isNotEmpty) {
        final currentQuery = Map<String, dynamic>.from(uri.queryParameters);
        queryParameters.forEach((key, value) {
          if (value != null) {
            currentQuery[key] = value.toString();
          }
        });
        uri = uri.replace(queryParameters: currentQuery);
      }

      if (kDebugMode) {
        debugPrint('[ApiClient] GET: $uri');
      }

      final response = await _client
          .get(uri, headers: _buildHeaders(token: token, extraHeaders: extraHeaders))
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Connection timed out. CineFlix server is taking too long to respond.');
    } on http.ClientException catch (e) {
      throw ApiException('Network request failed: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final uri = Uri.parse(url);
      if (kDebugMode) {
        debugPrint('[ApiClient] POST: $uri Body: $body');
      }

      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: extraHeaders),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Connection timed out.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> put(
    String url, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final uri = Uri.parse(url);
      if (kDebugMode) {
        debugPrint('[ApiClient] PUT: $uri Body: $body');
      }

      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: extraHeaders),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Connection timed out.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> delete(
    String url, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final uri = Uri.parse(url);
      if (kDebugMode) {
        debugPrint('[ApiClient] DELETE: $uri Body: $body');
      }

      final response = await _client
          .delete(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: extraHeaders),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Connection timed out.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> postMultipart(
    String url, {
    String? fileFieldName,
    String? filePath,
    List<http.MultipartFile>? files,
    Map<String, String>? fields,
    String? token,
    Map<String, String>? extraHeaders,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    try {
      final uri = Uri.parse(url);
      if (kDebugMode) {
        debugPrint('[ApiClient] POST Multipart: $uri');
      }

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        'X-API-KEY': AppConstants.apiKey,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        ...?extraHeaders,
      });

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (fileFieldName != null && filePath != null) {
        final file = await http.MultipartFile.fromPath(fileFieldName, filePath);
        request.files.add(file);
      }

      if (files != null && files.isNotEmpty) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Upload timed out. Please check your network connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      debugPrint('[ApiClient] Response code: ${response.statusCode}');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Request failed with status code ${response.statusCode}';

    throw ApiException(message, statusCode: response.statusCode, details: decoded);
  }
}

