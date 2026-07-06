import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Centralized HTTP logging wrapper.
///
/// Every single API call made through this helper is printed to the
/// terminal/console (via `debugPrint`, which shows up in `flutter run`,
/// the IDE console and `adb logcat`) — both the outgoing request AND the
/// incoming response (or the failure if the request never got a response).
///
/// This exists so that *every* API hit in the app is observable, which is
/// required for debugging "Failed to Network" / timeout issues against the
/// Render backend (which cold-starts and can be slow to respond).
class HttpLogger {
  static int _counter = 0;

  static String _shortBody(String? body, {int max = 2000}) {
    if (body == null || body.isEmpty) return '(empty)';
    if (body.length <= max) return body;
    return '${body.substring(0, max)}... [truncated ${body.length - max} chars]';
  }

  static Map<String, String> _redactHeaders(Map<String, String>? headers) {
    if (headers == null) return {};
    final redacted = Map<String, String>.from(headers);
    if (redacted.containsKey('Authorization')) {
      redacted['Authorization'] = 'Bearer ***redacted***';
    }
    return redacted;
  }

  static Future<http.Response> request(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final id = ++_counter;
    final stopwatch = Stopwatch()..start();

    debugPrint('┌─── API HIT #$id ───────────────────────────────────────');
    debugPrint('│ ➤ $method $url');
    debugPrint('│ Headers: ${jsonEncode(_redactHeaders(headers))}');
    if (body != null) {
      debugPrint('│ Body: ${_shortBody(body is String ? body : jsonEncode(body))}');
    }

    try {
      http.Response response;
      final encodedBody = body == null
          ? null
          : (body is String ? body : jsonEncode(body));

      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers).timeout(timeout);
          break;
        case 'POST':
          response = await http
              .post(url, headers: headers, body: encodedBody)
              .timeout(timeout);
          break;
        case 'PUT':
          response = await http
              .put(url, headers: headers, body: encodedBody)
              .timeout(timeout);
          break;
        case 'PATCH':
          response = await http
              .patch(url, headers: headers, body: encodedBody)
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers).timeout(timeout);
          break;
        default:
          throw ArgumentError('Unsupported method: $method');
      }

      stopwatch.stop();
      debugPrint('│ ✅ STATUS: ${response.statusCode}  (${stopwatch.elapsedMilliseconds}ms)');
      debugPrint('│ Response: ${_shortBody(response.body)}');
      debugPrint('└────────────────────────────────────────────────────────');
      return response;
    } catch (e) {
      stopwatch.stop();
      debugPrint('│ ❌ FAILED after ${stopwatch.elapsedMilliseconds}ms: $e');
      debugPrint('└────────────────────────────────────────────────────────');
      rethrow;
    }
  }
}
