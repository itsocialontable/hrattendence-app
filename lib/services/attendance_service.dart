/// Attendance Service - Handles API calls and local storage
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_models.dart';
import '../models/auth_models.dart';
import 'api_service.dart';

class AttendanceService {
  final ApiService apiService;

  AttendanceService({required this.apiService});

  /// Check In
  Future<CheckInResponse> checkIn({
    String? location,
  }) async {
    try {
      final token = await apiService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/attendance/checkin'),
        headers: {
          'Authorization': 'Bearer $token',
           'Content-Type': 'application/json',
          // 'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          if (location != null) 'location': location,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Check-in timeout'),
      );

      developer.log('────── POST /api/attendance/checkin ──────', name: 'AttendanceService');
      developer.log('Status: ${response.statusCode}', name: 'AttendanceService');
      developer.log('Response: ${response.body}', name: 'AttendanceService');
      // ignore: avoid_print
      print('────── POST /api/attendance/checkin ──────');
      // ignore: avoid_print
      print('Status: ${response.statusCode}');
      // ignore: avoid_print
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final checkInResponse = CheckInResponse.fromJson(
          jsonDecode(response.body),
        );

        // Save to local storage
        await _saveAttendanceState(
          AttendanceState(
            isCheckedIn: true,
            checkInTime: checkInResponse.checkIn,
            isLate: checkInResponse.isLate,
            isHalfDay: checkInResponse.isHalfDay,
            warningCount: checkInResponse.warningCount,
            maxWarnings: checkInResponse.maxWarnings,
            checkInId: checkInResponse.id,
            date: DateTime.now(),
          ),
        );

        return checkInResponse;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body);

        // The backend kindly includes today's real state even on the
        // "already checked in" error — use it to heal local storage so
        // the dashboard reflects reality instead of staying stuck on
        // "--:--" until the next successful call.
        if (json['checkIn'] != null) {
          await _saveAttendanceState(
            AttendanceState(
              isCheckedIn: json['checkOut'] == null,
              checkInTime: json['checkIn']?.toString(),
              checkOutTime: json['checkOut']?.toString(),
              isLate: json['isLate'] == true,
              isHalfDay: json['isHalfDay'] == true,
              date: DateTime.now(),
            ),
          );
        }

        throw Exception(
          json['error'] ?? json['message'] ?? 'Check-in failed. Already checked in today?',
        );
      } else if (response.statusCode == 401) {
        await apiService.clearToken();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Check-in failed: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception('Check-in error: ${e.toString()}');
    }
  }

  /// Check Out
  Future<CheckOutResponse> checkOut({
    String? location,
  }) async {
    try {
      final token = await apiService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/attendance/checkout'),
        headers: {
          'Authorization': 'Bearer $token',
           'Content-Type': 'application/json',
          // 'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          if (location != null) 'location': location,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Check-out timeout'),
      );

      developer.log('────── POST /api/attendance/checkout ──────', name: 'AttendanceService');
      developer.log('Status: ${response.statusCode}', name: 'AttendanceService');
      developer.log('Response: ${response.body}', name: 'AttendanceService');
      // ignore: avoid_print
      print('────── POST /api/attendance/checkout ──────');
      // ignore: avoid_print
      print('Status: ${response.statusCode}');
      // ignore: avoid_print
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final checkOutResponse = CheckOutResponse.fromJson(
          jsonDecode(response.body),
        );

        // Update local storage
        final currentState = await getAttendanceState();
        if (currentState != null) {
          await _saveAttendanceState(
            AttendanceState(
              isCheckedIn: false,
              checkInTime: currentState.checkInTime,
              checkOutTime: checkOutResponse.checkOut,
              netMins: checkOutResponse.netMins,
              isLate: currentState.isLate,
              isHalfDay: currentState.isHalfDay,
              warningCount: currentState.warningCount,
              maxWarnings: currentState.maxWarnings,
              checkInId: currentState.checkInId,
              date: DateTime.now(),
            ),
          );
        }

        return checkOutResponse;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body);

        if (json['checkIn'] != null) {
          await _saveAttendanceState(
            AttendanceState(
              isCheckedIn: json['checkOut'] == null,
              checkInTime: json['checkIn']?.toString(),
              checkOutTime: json['checkOut']?.toString(),
              isLate: json['isLate'] == true,
              isHalfDay: json['isHalfDay'] == true,
              date: DateTime.now(),
            ),
          );
        }

        throw Exception(
          json['error'] ?? json['message'] ?? 'Check-out failed. Please check-in first.',
        );
      } else if (response.statusCode == 401) {
        await apiService.clearToken();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Check-out failed: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception('Check-out error: ${e.toString()}');
    }
  }

  /// Get attendance history — GET /api/attendance
  /// Query params (all optional, send only what's needed):
  ///   date     — a single day, e.g. "2026-06-12"
  ///   fromDate — start of a range, e.g. "2026-06-01"
  ///   toDate   — end of a range, e.g. "2026-06-30"
  Future<List<AttendanceLogEntry>> getAttendanceHistory({
    String? date,
    String? fromDate,
    String? toDate,
  }) async {
    final token = await apiService.getToken();

    final queryParams = <String, String>{
      if (date != null && date.isNotEmpty) 'date': date,
      if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
    };

    final uri = Uri.parse('${ApiService.baseUrl}/api/attendance').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    http.Response response;

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
      throw ApiException(message: 'Failed to load attendance. Please try again.');
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
      return _parseAttendanceList(decoded);
    } else if (response.statusCode == 401) {
      await apiService.clearToken();
      throw ApiException(message: 'Session expired. Please login again.', statusCode: 401);
    } else if (response.statusCode == 404) {
      // No records for this range — treat as an empty list, not an error.
      return [];
    } else if (response.statusCode >= 500) {
      throw ApiException(message: 'Server error. Please try again later.', statusCode: response.statusCode);
    } else {
      throw ApiException(message: _parseErrorMessage(response), statusCode: response.statusCode);
    }
  }

  /// Normalizes whatever shape the backend sends — a raw list, or a map
  /// wrapping the list under "attendance"/"records"/"data"/"results", or
  /// even a single record object (e.g. when filtering by one `date`) —
  /// into a flat List<AttendanceLogEntry>.
  List<AttendanceLogEntry> _parseAttendanceList(dynamic decoded) {
    List<dynamic> rawList;

    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map) {
      final listCandidate = decoded['attendance'] ??
          decoded['records'] ??
          decoded['data'] ??
          decoded['results'] ??
          decoded['logs'];
      if (listCandidate is List) {
        rawList = listCandidate;
      } else if (decoded.containsKey('checkIn') ||
          decoded.containsKey('clockIn') ||
          decoded.containsKey('date')) {
        // Looks like a single record object rather than a list.
        rawList = [decoded];
      } else {
        rawList = [];
      }
    } else {
      rawList = [];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => AttendanceLogEntry.fromJson(e))
        .toList();
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
  /// verify the API integration end-to-end while testing — mirrors the
  /// exact logging used by LeaveService for GET /api/leaves.
  void _logResponse(String label, Object? requestPayload, http.Response response) {
    developer.log('────── $label ──────', name: 'AttendanceService');
    developer.log('Request: $requestPayload', name: 'AttendanceService');
    developer.log('Status: ${response.statusCode}', name: 'AttendanceService');
    developer.log('Response: ${response.body}', name: 'AttendanceService');

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

  /// Get today's attendance state from local storage
  Future<AttendanceState?> getAttendanceState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = AttendanceState.storageKey;
      final json = prefs.getString(key);

      if (json == null) return null;

      return AttendanceState.fromJson(jsonDecode(json));
    } catch (e) {
      print('Error getting attendance state: $e');
      return null;
    }
  }

  /// Save attendance state to local storage
  Future<void> _saveAttendanceState(AttendanceState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = AttendanceState.storageKey;
      await prefs.setString(key, jsonEncode(state.toJson()));
    } catch (e) {
      print('Error saving attendance state: $e');
    }
  }

  /// Clear today's attendance state
  Future<void> clearAttendanceState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = AttendanceState.storageKey;
      await prefs.remove(key);
    } catch (e) {
      print('Error clearing attendance state: $e');
    }
  }

  /// Sync today's attendance state from the server.
  /// Calls GET /api/attendance?date=<today> and updates local storage.
  /// Returns the refreshed [AttendanceState], or null if no record found.
  Future<AttendanceState?> syncTodayFromServer() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final records = await getAttendanceHistory(date: today);

      if (records.isEmpty) {
        // No attendance record for today — clear stale local state.
        await clearAttendanceState();
        return null;
      }

      final record = records.first;

      // Build a fresh AttendanceState from what the server returned.
      // Backend sends check_in / check_out (snake_case) which AttendanceLogEntry
      // already normalises into .checkIn / .checkOut for us.
      // net_mins → workingMinutes, is_late → isLate, is_half_day → isHalfDay.
      final newState = AttendanceState(
        isCheckedIn: record.checkIn != null && record.checkOut == null,
        checkInTime: record.checkIn,
        checkOutTime: record.checkOut,
        netMins: record.workingMinutes,   // parsed from net_mins by AttendanceLogEntry
        isLate: record.isLate,            // parsed from is_late
        isHalfDay: record.isHalfDay,      // parsed from is_half_day
        date: record.date,
      );

      await _saveAttendanceState(newState);
      return newState;
    } catch (e) {
      // Network / parse errors — fall back to local cache silently.
      developer.log('syncTodayFromServer error: $e', name: 'AttendanceService');
      return null;
    }
  }

  /// Check if already checked in today
  Future<bool> isCheckedInToday() async {
    final state = await getAttendanceState();
    return state?.isCheckedIn ?? false;
  }

  /// Format net minutes to HH:MM format
  static String formatNetMinutes(int minutes) {
    final m = minutes.abs();
    final hours = m ~/ 60;
    final mins = m % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }
  /// Format time string (e.g., "09:45" from API)
  static DateTime parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Calculate working duration between check-in and checkout
  static int calculateWorkingMinutes(String checkIn, String checkOut) {
    try {
      final checkInTime = parseTimeString(checkIn);
      final checkOutTime = parseTimeString(checkOut);
      return checkOutTime.difference(checkInTime).inMinutes;
    } catch (e) {
      return 0;
    }
  }
}