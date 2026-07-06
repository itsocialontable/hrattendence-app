/// Leave Service - Handles POST /api/leaves and GET /api/leaves
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../models/leave_models.dart';
import 'api_service.dart';

class LeaveService {
  final ApiService apiService;

  LeaveService({required this.apiService});

  /// POST /api/leaves
  /// Payload: { "from":"", "to":"", "type":"", "reason":"", "session":"" }
  Future<LeaveModel> applyLeave(LeaveRequest request) async {
    final token = await apiService.getToken();
    http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/api/leaves'),
            headers: {
               'Content-Type': 'application/json',
              // 'ngrok-skip-browser-warning': 'true',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      _logResponse('POST /api/leaves', request.toJson(), response);
    } on SocketException {
      throw ApiException(message: 'No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException(message: 'Could not reach the server. Please try again.');
    } on FormatException {
      throw ApiException(message: 'Invalid response from server. Please try again later.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(message: 'Connection timeout. Please try again.');
      }
      throw ApiException(message: 'Failed to submit leave application. Please try again.');
    }

    Map<String, dynamic> jsonBody;
    try {
      final decoded = jsonDecode(response.body);
      jsonBody = decoded is Map<String, dynamic> ? decoded : {'data': decoded};
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
          return LeaveModel.fromJson(jsonBody);
        } catch (_) {
          throw ApiException(
            message: 'Unexpected response from server. Please try again.',
            statusCode: response.statusCode,
          );
        }

      case 400:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'Invalid leave request. Please check the details.'),
          statusCode: 400,
        );

      case 401:
        await apiService.clearToken();
        throw ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );

      case 403:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'You are not allowed to apply for this leave.'),
          statusCode: 403,
        );

      case 404:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'Leave endpoint not found.'),
          statusCode: 404,
        );

      case 422:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'Please check the leave dates, type and reason.'),
          statusCode: 422,
        );

      case 429:
        throw ApiException(message: 'Too many requests. Please try again later.', statusCode: 429);

      case 500:
      case 502:
      case 503:
      case 504:
        throw ApiException(message: 'Server error. Please try again later.', statusCode: response.statusCode);

      default:
        throw ApiException(
          message: _extractMessage(jsonBody, fallback: 'Failed to submit leave (${response.statusCode}).'),
          statusCode: response.statusCode,
        );
    }
  }

  /// GET /api/leaves
  /// Query: userId, status
  Future<List<LeaveModel>> getLeaves({String? userId, String? status}) async {
    final token = await apiService.getToken();
    http.Response response;

    final queryParams = <String, String>{
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') 'status': status,
    };

    final uri = Uri.parse('${ApiService.baseUrl}/api/leaves').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      response = await http.get(
        uri,
        headers: {
           'Content-Type': 'application/json',
          // 'ngrok-skip-browser-warning': 'true',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      _logResponse('GET $uri', queryParams, response);
    } on SocketException {
      throw ApiException(message: 'No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException(message: 'Could not reach the server. Please try again.');
    } on FormatException {
      throw ApiException(message: 'Invalid response from server. Please try again later.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(message: 'Connection timeout. Please try again.');
      }
      throw ApiException(message: 'Failed to load leaves. Please try again.');
    }

    if (response.statusCode == 200) {
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw ApiException(
          message: 'Invalid response from server. Please try again later.',
          statusCode: response.statusCode,
        );
      }

      List<dynamic> rawList;
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map) {
        rawList = (decoded['leaves'] ?? decoded['data'] ?? decoded['results'] ?? []) as List<dynamic>;
      } else {
        rawList = [];
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => LeaveModel.fromJson(e))
          .toList();
    } else if (response.statusCode == 401) {
      await apiService.clearToken();
      throw ApiException(message: 'Session expired. Please login again.', statusCode: 401);
    } else if (response.statusCode == 404) {
      throw ApiException(message: 'No leave records found.', statusCode: 404);
    } else if (response.statusCode >= 500) {
      throw ApiException(message: 'Server error. Please try again later.', statusCode: response.statusCode);
    } else {
      throw ApiException(message: _parseErrorMessage(response), statusCode: response.statusCode);
    }
  }

  String _extractMessage(Map<String, dynamic> json, {required String fallback}) {
    final msg = json['message'] ?? json['error'] ?? json['msg'];
    if (msg is String && msg.trim().isNotEmpty) return msg;
    return fallback;
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map) {
        return (json['message'] ?? json['error'] ?? 'Error: ${response.statusCode}').toString();
      }
    } catch (_) {}
    return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
  }

  /// Logs the full request/response cycle to the console so it's easy to
  /// verify the API integration is working end-to-end while testing.
  void _logResponse(String label, Object? requestPayload, http.Response response) {
    developer.log('────── $label ──────', name: 'LeaveService');
    developer.log('Request: $requestPayload', name: 'LeaveService');
    developer.log('Status: ${response.statusCode}', name: 'LeaveService');
    developer.log('Response: ${response.body}', name: 'LeaveService');

    // Also plain `print`, since `developer.log` output is sometimes filtered
    // out of the regular console depending on how the app is run.
    // ignore: avoid_print
    print('────── $label ──────');
    // ignore: avoid_print
    print('Request: $requestPayload');
    // ignore: avoid_print
    print('Status: ${response.statusCode}');
    // ignore: avoid_print
    print('Response: ${response.body}');
  }
}
