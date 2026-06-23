import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';
import '../models/dashboard_models.dart';

class ApiService {
  static const String baseUrl =
      'https://whacking-dispute-agility.ngrok-free.dev';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final FlutterSecureStorage _secureStorage;

  ApiService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Login with credentials
  Future<LoginResponse> login({
    required String username,
    required String password,
    String role = 'employee',
  }) async {
    http.Response response;

    try {
      response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 30));
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');
    } on SocketException {
      throw ApiException(
        message: 'No internet connection. Please check your network.',
      );
    } on HttpException {
      throw ApiException(
        message: 'Could not reach the server. Please try again.',
      );
    } on FormatException {
      throw ApiException(
        message: 'Invalid response from server. Please try again later.',
      );
    } on Exception catch (e) {
      // TimeoutException and any other exceptions land here
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(
          message: 'Connection timeout. Please try again.',
        );
      }
      throw ApiException(
        message: 'Login failed. Please try again.',
      );
    }

    // Parse response body
    Map<String, dynamic> jsonBody;
    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        message: 'Invalid response from server. Please try again later.',
        statusCode: response.statusCode,
      );
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          final loginResponse = LoginResponse.fromJson(jsonBody);

          // Store token securely
          await _secureStorage.write(
              key: _tokenKey, value: loginResponse.token);
          // Store user data
          await _secureStorage.write(
            key: _userKey,
            value: jsonEncode(loginResponse.user.toJson()),
          );

          return loginResponse;
        } catch (_) {
          throw ApiException(
            message: 'Unexpected response from server. Please try again.',
            statusCode: response.statusCode,
          );
        }

      case 400:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'Invalid username or password.'),
          statusCode: 400,
        );

      case 401:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'Invalid username or password.'),
          statusCode: 401,
        );

      case 403:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'You do not have access to this account.'),
          statusCode: 403,
        );

      case 404:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'User not found.'),
          statusCode: 404,
        );

      case 422:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'Please check your username and password.'),
          statusCode: 422,
        );

      case 429:
        throw ApiException(
          message: 'Too many attempts. Please try again later.',
          statusCode: 429,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        throw ApiException(
          message: 'Server error. Please try again later.',
          statusCode: response.statusCode,
        );

      default:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'Login failed (${response.statusCode}).'),
          statusCode: response.statusCode,
        );
    }
  }

  /// Fetch a single user profile — GET /api/users/:id
  Future<UserProfile> getUserById(String userId) async {
    debugPrint('▶ [API] getUserById → /api/users/$userId');

    final token = await getToken();
    if (token == null) {
      throw ApiException(
          message: 'No authentication token found. Please login again.');
    }

    http.Response response;
    try {
      response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('✅ [API] getUserById STATUS : ${response.statusCode}');
      debugPrint('✅ [API] getUserById BODY   : ${response.body}');
    } on SocketException {
      throw ApiException(
          message: 'No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException(
          message: 'Could not reach the server. Please try again.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(message: 'Connection timeout. Please try again.');
      }
      debugPrint('❌ [API] getUserById ERROR: $e');
      throw ApiException(message: 'Failed to load profile. Please try again.');
    }

    Map<String, dynamic> jsonBody;
    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        message: 'Invalid response from server.',
        statusCode: response.statusCode,
      );
    }

    switch (response.statusCode) {
      case 200:
        try {
          final profile = UserProfile.fromJson(jsonBody);
          debugPrint('✅ [API] UserProfile parsed: ${profile.name} (${profile.id})');
          return profile;
        } catch (e) {
          debugPrint('❌ [API] UserProfile parse error: $e');
          throw ApiException(message: 'Failed to parse profile data.');
        }
      case 401:
        await clearToken();
        throw ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      case 403:
        throw ApiException(message: 'Access denied.', statusCode: 403);
      case 404:
        throw ApiException(message: 'Profile not found.', statusCode: 404);
      case 500:
      case 502:
      case 503:
      case 504:
        throw ApiException(
          message: 'Server error. Please try again later.',
          statusCode: response.statusCode,
        );
      default:
        throw ApiException(
          message: _extractMessage(jsonBody,
              fallback: 'Error ${response.statusCode}'),
          statusCode: response.statusCode,
        );
    }
  }
  /// Extract a human-readable message from an error response body
  String _extractMessage(Map<String, dynamic> json, {required String fallback}) {
    final msg = json['message'] ?? json['error'] ?? json['msg'];
    if (msg is String && msg.trim().isNotEmpty) return msg;
    return fallback;
  }

  /// Fetch all users profile
  Future<ProfileResponse> getUsers() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw ApiException(message: 'No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException(
          message: 'Connection timeout. Please try again.',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final users = List<Map<String, dynamic>>.from(
          jsonData is List ? jsonData : jsonData['users'] ?? [],
        );
        return ProfileResponse.fromJson(users);
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await clearToken();
        throw ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      } else {
        throw ApiException(
          message: _parseErrorMessage(response),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException(
        message: e is ApiException ? e.message : 'Failed to fetch users: ${e.toString()}',
      );
    }
  }

  /// Fetch employee dashboard stats for a given month
  /// GET /api/dashboard/employee-stats/:userId
  Future<EmployeeStats> getEmployeeStats(
    String userId, {
    String? month,
  }) async {
    debugPrint('📊 [EmployeeStats] Fetching stats for userId=$userId month=${month ?? "(current)"}');

    final token = await getToken();
    if (token == null) {
      debugPrint('📊 [EmployeeStats] ❌ No auth token found — request not sent.');
      throw ApiException(message: 'No authentication token found');
    }

    http.Response response;

    try {
      final uri = Uri.parse('$baseUrl/api/dashboard/employee-stats/$userId')
          .replace(queryParameters: month != null ? {'month': month} : null);

      debugPrint('📊 [EmployeeStats] GET $uri');

      response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      // Print loudly so it shows up in `flutter run` / logcat / IDE console,
      // not just an attached DevTools/VM observer.
      debugPrint('📊 [EmployeeStats] STATUS: ${response.statusCode}');
      debugPrint('📊 [EmployeeStats] STATUS: $token');
      debugPrint('📊 [EmployeeStats] BODY: ${response.body}');
    } on SocketException {
      debugPrint('📊 [EmployeeStats] ❌ SocketException — no internet connection.');
      throw ApiException(
        message: 'No internet connection. Please check your network.',
      );
    } on HttpException {
      debugPrint('📊 [EmployeeStats] ❌ HttpException — could not reach server.');
      throw ApiException(
        message: 'Could not reach the server. Please try again.',
      );
    } on FormatException {
      debugPrint('📊 [EmployeeStats] ❌ FormatException — invalid response format.');
      throw ApiException(
        message: 'Invalid response from server. Please try again later.',
      );
    } on Exception catch (e) {
      debugPrint('📊 [EmployeeStats] ❌ Exception: $e');
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(
          message: 'Connection timeout. Please try again.',
        );
      }
      throw ApiException(
        message: 'Failed to load employee stats. Please try again.',
      );
    }

    if (response.statusCode == 401) {
      await clearToken();
      throw ApiException(
        message: 'Session expired. Please login again.',
        statusCode: 401,
      );
    }

    // Parse response body
    Map<String, dynamic> jsonBody;
    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      debugPrint('📊 [EmployeeStats] ❌ Could not decode JSON body.');
      throw ApiException(
        message: 'Invalid response from server. Please try again later.',
        statusCode: response.statusCode,
      );
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          final stats = EmployeeStats.fromJson(jsonBody);
          debugPrint('📊 [EmployeeStats] ✅ Parsed: ${stats.toJson()}');
          return stats;
        } catch (e) {
          debugPrint('📊 [EmployeeStats] ❌ Parse error: $e');
          throw ApiException(
            message: 'Unexpected response from server. Please try again.',
            statusCode: response.statusCode,
          );
        }

      case 403:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'You do not have access to these stats.'),
          statusCode: 403,
        );

      case 404:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'Employee stats not found.'),
          statusCode: 404,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        throw ApiException(
          message: 'Server error. Please try again later.',
          statusCode: response.statusCode,
        );

      default:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'Failed to load stats (${response.statusCode}).'),
          statusCode: response.statusCode,
        );
    }
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Get stored user data
  Future<UserData?> getStoredUser() async {
    final userJson = await _secureStorage.read(key: _userKey);
    if (userJson != null) {
      return UserData.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout - clear all stored data
  Future<void> logout() async {
    await clearToken();
  }

  /// Clear token
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }

  /// Parse error message from response
  String _parseErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map) {
        return json['message'] ??
            json['error'] ??
            'Error: ${response.statusCode}';
      }
    } catch (_) {}
    return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
  }
  Future<http.Response> authenticatedGet(String url) async {
    final token = await getToken();
    if (token == null) {
      throw ApiException(message: 'No authentication token found');
    }
    return http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );
  }
}