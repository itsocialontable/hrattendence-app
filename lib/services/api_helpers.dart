/// API Interceptor and Helper utilities for managing API calls with token
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';

/// Extension for adding common headers and token to requests
extension HttpRequestExtension on http.Client {
  /// Create headers with authentication token
  Future<Map<String, String>> getAuthHeaders(String? token) async {
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

/// Utility class for handling API responses
class ApiResponseHandler {
  /// Parse API response and handle common errors
  static Future<T> handleResponse<T>(
    http.Response response, {
    required T Function(dynamic) parser,
    void Function(int statusCode)? onUnauthorized,
  }) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parser(response.body);
    } else if (response.statusCode == 401) {
      onUnauthorized?.call(response.statusCode);
      throw ApiException(
        message: 'Unauthorized. Please login again.',
        statusCode: 401,
      );
    } else if (response.statusCode == 403) {
      throw ApiException(
        message: 'Access forbidden.',
        statusCode: 403,
      );
    } else if (response.statusCode == 404) {
      throw ApiException(
        message: 'Resource not found.',
        statusCode: 404,
      );
    } else if (response.statusCode >= 500) {
      throw ApiException(
        message: 'Server error. Please try again later.',
        statusCode: response.statusCode,
      );
    } else {
      throw ApiException(
        message: 'Error: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }
}

/// Best Practices for API Integration:
/// 
/// 1. Always use token from AuthProvider:
///    ```dart
///    final token = await apiService.getToken();
///    ```
///
/// 2. Handle 401 errors by triggering re-authentication:
///    ```dart
///    try {
///      await apiService.getUsers();
///    } on ApiException catch (e) {
///      if (e.statusCode == 401) {
///        context.read<AuthProvider>().logout();
///      }
///    }
///    ```
///
/// 3. Use Provider for state management:
///    ```dart
///    Provider<ApiService>(create: (_) => ApiService())
///    ChangeNotifierProvider<AuthProvider>(...)
///    ```
///
/// 4. Always show loading state during API calls:
///    ```dart
///    if (authProvider.isLoading) {
///      return CircularProgressIndicator();
///    }
///    ```
///
/// 5. Handle errors gracefully with proper UI feedback:
///    ```dart
///    if (authProvider.errorMessage != null) {
///      ScaffoldMessenger.of(context).showSnackBar(
///        SnackBar(content: Text(authProvider.errorMessage))
///      );
///    }
///    ```
