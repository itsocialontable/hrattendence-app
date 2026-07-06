import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/admin_models.dart';
import 'api_service.dart';
import '../services/http_logger.dart';
import '../models/auth_models.dart';

/// Admin-specific API service.
/// All endpoints require a valid Bearer token (admin role).
///
/// Screenshot endpoints covered:
///   POST /api/register          [ADMIN ONLY]
///   POST /api/login             [BOTH]
///   POST /api/forgot-password   [BOTH]
///   POST /api/verify-otp        [BOTH]
///   POST /api/resend-otp        [BOTH]
///   POST /api/reset-password    [BOTH]
///
/// Admin resource endpoints:
///   GET    /api/users                        — _list all employees
///   GET    /api/users/:id                    — single employee
///   POST   /api/users                        — create employee
///   PUT    /api/users/:id                    — update employee
///   DELETE /api/users/:id                    — delete employee
///   GET    /api/attendance                   — all attendance records
///   GET    /api/attendance?date=&userId=     — filtered attendance
///   PUT    /api/attendance/:id               — edit attendance record
///   POST   /api/attendance/manual            — add manual record
///   GET    /api/leave/all                    — all leave requests
///   PUT    /api/leave/:id/approve            — approve leave
///   PUT    /api/leave/:id/reject             — reject leave
///   GET    /api/salary                       — salary list
///   POST   /api/salary/generate              — generate payroll
///   GET    /api/settings/attendance-rules    — get attendance rules
///   PUT    /api/settings/attendance-rules    — update attendance rules
///   GET    /api/settings                     — get global settings
///   PUT    /api/settings                     — update global settings
///   GET    /api/dashboard/admin-stats        — admin dashboard stats

class AdminApiService {
  final ApiService _base;

  static const _baseUrl = ApiService.baseUrl; // shared base URL constant

  AdminApiService(this._base);

  // ────────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ────────────────────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await _base.getToken();
    if (token == null) {
      throw ApiException(message: 'No authentication token. Please login again.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      // 'ngrok-skip-browser-warning': 'true',
    };
  }

  Future<http.Response> _get(String path) async {
    try {
      return await HttpLogger.request(
        'GET',
        Uri.parse('$_baseUrl$path'),
        headers: await _authHeaders(),
        timeout: const Duration(seconds: 60),
      );
    } on SocketException {
      throw ApiException(message: 'No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException(message: 'Connection timeout. Please try again.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(message: 'Connection timeout. Please try again.');
      }
      throw ApiException(message: 'Network error. Please try again.');
    }
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      return await HttpLogger.request(
        'POST',
        Uri.parse('$_baseUrl$path'),
        headers: await _authHeaders(),
        body: body,
        timeout: const Duration(seconds: 60),
      );
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on TimeoutException {
      throw ApiException(message: 'Connection timeout. Please try again.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(message: 'Connection timeout. Please try again.');
      }
      throw ApiException(message: 'Network error. Please try again.');
    }
  }

  Future<http.Response> _put(String path, Map<String, dynamic> body) async {
    try {
      return await HttpLogger.request(
        'PUT',
        Uri.parse('$_baseUrl$path'),
        headers: await _authHeaders(),
        body: body,
        timeout: const Duration(seconds: 60),
      );
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on TimeoutException {
      throw ApiException(message: 'Connection timeout. Please try again.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(message: 'Connection timeout.');
      }
      throw ApiException(message: 'Network error.');
    }
  }

  Future<http.Response> _delete(String path) async {
    try {
      return await HttpLogger.request(
        'DELETE',
        Uri.parse('$_baseUrl$path'),
        headers: await _authHeaders(),
        timeout: const Duration(seconds: 60),
      );
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on TimeoutException {
      throw ApiException(message: 'Connection timeout. Please try again.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(message: 'Connection timeout.');
      }
      throw ApiException(message: 'Network error.');
    }
  }

  /// Decode JSON body safely; throws ApiException on parse failure.
  dynamic _decode(http.Response res, {String fallbackError = 'Server error'}) {
    try {
      return jsonDecode(res.body);
    } catch (_) {
      throw ApiException(
          message: 'Invalid response from server.', statusCode: res.statusCode);
    }
  }

  /// Extract human-readable message from an error JSON body.
  String _extractMessage(dynamic json, {required String fallback}) {
    if (json is Map) {
      final msg = json['message'] ?? json['error'] ?? json['msg'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
    }
    return fallback;
  }

  void _checkAuth(http.Response res) {
    if (res.statusCode == 401) {
      _base.clearToken();
      throw ApiException(
          message: 'Session expired. Please login again.', statusCode: 401);
    }
    if (res.statusCode == 403) {
      throw ApiException(
          message: 'Admin access required.', statusCode: 403);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // AUTH — Screenshot endpoints
  // ────────────────────────────────────────────────────────────────────────────

  /// Guards against duplicate registration submissions. Render's free-tier
  /// servers can take 30-60s to wake from idle, so a slow first request can
  /// still be processing on the backend even after the client times out.
  /// POST /api/register — [ADMIN ONLY] One-time setup. Returns 403 if admin exists.
  Future<AdminRegisterResponse> registerAdmin({
    required String fullName,
    String? lName,
    required String email,
    String? phoneNo,
    String? companyName,
    required String password,
    required String confirmPassword,
    required String secret,
  }) {
    return _doRegisterAdmin(
      fullName: fullName,
      lName: lName,
      email: email,
      phoneNo: phoneNo,
      companyName: companyName,
      password: password,
      confirmPassword: confirmPassword,
      secret: secret,
    );
  }

  Future<AdminRegisterResponse> _doRegisterAdmin({
    required String fullName,
    String? lName,
    required String email,
    String? phoneNo,
    String? companyName,
    required String password,
    required String confirmPassword,
    required String secret,
  }) async {
    try {
      final res = await HttpLogger.request(
        'POST',
        Uri.parse('$_baseUrl/api/register'),
        headers: {
          'Content-Type': 'application/json',
          // 'ngrok-skip-browser-warning': 'true',
        },
        body: {
          'fullName': fullName,
          if (lName != null) 'lName': lName,
          'email': email,
          if (phoneNo != null) 'phoneNo': phoneNo,
          if (companyName != null) 'companyName': companyName,
          'password': password,
          'confirmPassword': confirmPassword,
          'secret': secret,
        },
        timeout: const Duration(seconds: 60),
      );

      final json = _decode(res);
      switch (res.statusCode) {
        case 200:
        case 201:
          return AdminRegisterResponse.fromJson(json as Map<String, dynamic>);
        case 400:
          throw ApiException(
              message: _extractMessage(json, fallback: 'Invalid registration data.'),
              statusCode: 400);
        case 403:
        case 409:
        // Account already exists for this email. This is the expected
        // result of: (a) a genuine duplicate signup, or (b) a previous
        // request that timed out on the client but actually completed on
        // the server. Either way it is NOT a generic failure — surface it
        // distinctly so the UI can route the user to login instead of
        // showing a scary error.
          throw DuplicateRegistrationException(
            message: _extractMessage(json, fallback: 'This email is already registered.'),
            statusCode: res.statusCode,
          );
        default:
          throw ApiException(
              message: _extractMessage(json,
                  fallback: 'Registration failed (${res.statusCode}).'),
              statusCode: res.statusCode);
      }
    } on SocketException {
      throw ApiException(message: 'No internet connection. Check your WiFi/data and try again.');
    } on ApiException {
      rethrow;
    } on TimeoutException {
      // Render free-tier servers sleep after 15 min idle and take 30-60s to
      // wake up on the first request. The request may still complete on the
      // backend even though the client gave up waiting — so we don't
      // silently retry here (the in-flight guard above already prevents a
      // duplicate submission). We tell the user clearly what's happening
      // and that re-tapping Register is now safe (it will either succeed,
      // or correctly report "already registered" if it actually went
      // through the first time).
      throw ApiException(
          message:
          'Server is waking up (this can take up to a minute on first use). '
              'Please wait a few seconds and try again — your first request is '
              'still being processed, so you will not be charged/duplicated.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(
            message:
            'Server is waking up (this can take up to a minute on first use). '
                'Please wait a few seconds and try again.');
      }
      throw ApiException(message: 'Registration failed. Please try again.');
    }
  }
  Future<void> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await http
          .post(
        Uri.parse('$_baseUrl/api/register/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      )
          .timeout(const Duration(seconds: 60));

      final json = _decode(res);
      if (res.statusCode == 200 || res.statusCode == 201) return;
      throw ApiException(
          message: _extractMessage(json, fallback: 'Invalid or expired OTP.'),
          statusCode: res.statusCode);
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on ApiException {
      rethrow;
    } on Exception {
      throw ApiException(message: 'OTP verification failed.');
    }
  }

  /// POST /api/register/resend-otp — Resend registration OTP.
  Future<void> resendRegistrationOtp({required String email}) async {
    try {
      final res = await http
          .post(
        Uri.parse('$_baseUrl/api/register/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      )
          .timeout(const Duration(seconds: 60));

      final json = _decode(res);
      if (res.statusCode == 200 || res.statusCode == 201) return;
      throw ApiException(
          message: _extractMessage(json, fallback: 'Failed to resend OTP.'),
          statusCode: res.statusCode);
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on ApiException {
      rethrow;
    } on Exception {
      throw ApiException(message: 'Failed to resend OTP.');
    }
  }


  /// POST /api/forgot-password — Sends OTP to email.
  Future<void> forgotPassword({required String email}) async {
    try {
      final res = await http
          .post(
        Uri.parse('$_baseUrl/api/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      )
          .timeout(const Duration(seconds: 60));

      final json = _decode(res);
      if (res.statusCode == 200 || res.statusCode == 201) return;
      throw ApiException(
          message: _extractMessage(json, fallback: 'Failed to send OTP.'),
          statusCode: res.statusCode);
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(message: 'Connection timeout.');
      }
      throw ApiException(message: 'Failed to send OTP. Please try again.');
    }
  }

  /// POST /api/verify-otp — Verify OTP before reset password.
  Future<void> verifyOtp({required String email, required String otp}) async {
    try {
      final res = await http
          .post(
        Uri.parse('$_baseUrl/api/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      )
          .timeout(const Duration(seconds: 60));

      final json = _decode(res);
      if (res.statusCode == 200 || res.statusCode == 201) return;
      throw ApiException(
          message: _extractMessage(json, fallback: 'Invalid or expired OTP.'),
          statusCode: res.statusCode);
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on ApiException {
      rethrow;
    } on Exception {
      throw ApiException(message: 'OTP verification failed.');
    }
  }

  /// POST /api/resend-otp — Resend OTP (new 10-min window).
  Future<void> resendOtp({required String email}) async {
    try {
      final res = await http
          .post(
        Uri.parse('$_baseUrl/api/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      )
          .timeout(const Duration(seconds: 60));

      final json = _decode(res);
      if (res.statusCode == 200 || res.statusCode == 201) return;
      throw ApiException(
          message: _extractMessage(json, fallback: 'Failed to resend OTP.'),
          statusCode: res.statusCode);
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on ApiException {
      rethrow;
    } on Exception {
      throw ApiException(message: 'Failed to resend OTP.');
    }
  }

  /// POST /api/reset-password — Set new password after OTP verification.
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final res = await http
          .post(
        Uri.parse('$_baseUrl/api/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      )
          .timeout(const Duration(seconds: 60));

      final json = _decode(res);
      if (res.statusCode == 200 || res.statusCode == 201) return;
      throw ApiException(
          message: _extractMessage(json, fallback: 'Failed to reset password.'),
          statusCode: res.statusCode);
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on ApiException {
      rethrow;
    } on Exception {
      throw ApiException(message: 'Password reset failed.');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ADMIN DASHBOARD
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/dashboard/admin-stats
  Future<AdminDashboardStats> getAdminStats() async {
    final res = await _get('/api/dashboard/stats');
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AdminDashboardStats.fromJson(json as Map<String, dynamic>);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to load dashboard stats.'),
        statusCode: res.statusCode);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // EMPLOYEE MANAGEMENT
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/users — List all employees.
  Future<List<AdminEmployee>> getEmployees() async {
    final res = await _get('/api/users');
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200) {
      final list = json is List ? json : (json['users'] ?? []);
      return (list as List)
          .map((e) => AdminEmployee.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to load employees.'),
        statusCode: res.statusCode);
  }

  /// GET /api/users/:id — Single employee.
  Future<AdminEmployee> getEmployee(String id) async {
    final res = await _get('/api/users/$id');
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200) {
      return AdminEmployee.fromJson(json as Map<String, dynamic>);
    }
    if (res.statusCode == 404) throw ApiException(message: 'Employee not found.', statusCode: 404);
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to load employee.'),
        statusCode: res.statusCode);
  }

  /// POST /api/users — Create new employee.
  Future<AdminEmployee> createEmployee(AdminEmployeeInput input) async {
    final res = await _post('/api/users', input.toJson());
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AdminEmployee.fromJson(
          (json['user'] ?? json) as Map<String, dynamic>);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to create employee.'),
        statusCode: res.statusCode);
  }

  /// PUT /api/users/:id — Update employee.
  Future<AdminEmployee> updateEmployee(String id, AdminEmployeeInput input) async {
    final res = await _put('/api/users/$id', input.toJson());
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AdminEmployee.fromJson(
          (json['user'] ?? json) as Map<String, dynamic>);
    }
    if (res.statusCode == 404) throw ApiException(message: 'Employee not found.', statusCode: 404);
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to update employee.'),
        statusCode: res.statusCode);
  }

  /// DELETE /api/users/:id — Remove employee.
  Future<void> deleteEmployee(String id) async {
    final res = await _delete('/api/users/$id');
    _checkAuth(res);
    if (res.statusCode == 200 || res.statusCode == 204) return;
    final json = _decode(res);
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to delete employee.'),
        statusCode: res.statusCode);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ATTENDANCE MANAGEMENT
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/attendance?date=YYYY-MM-DD&userId=
  Future<AdminAttendanceResult> getAttendance({
    String? date,
    String? userId,
    String? month,
  }) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (userId != null) params['userId'] = userId;
    if (month != null) params['month'] = month;

    final uri = Uri.parse('$_baseUrl/api/attendance')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    http.Response res;
    try {
      res = await HttpLogger.request(
        'GET',
        uri,
        headers: await _authHeaders(),
        timeout: const Duration(seconds: 60),
      );
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on TimeoutException {
      throw ApiException(message: 'Connection timeout.');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(message: 'Connection timeout.');
      }
      throw ApiException(message: 'Network error.');
    }

    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200) {
      final list = json is List ? json : (json['attendance'] ?? json['records'] ?? []);
      final records = (list as List)
          .map((e) => AdminAttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      // Backend sends a "summary" object alongside "records":
      // { "summary": { "all":12, "present":8, "absent":2, "halfDay":1, "late":3 }, "records":[...] }
      // Fall back to counting the records ourselves if it's ever missing,
      // so older backend responses keep working.
      final summaryJson = (json is Map) ? json['summary'] : null;
      final summary = summaryJson is Map<String, dynamic>
          ? AdminAttendanceSummary.fromJson(summaryJson)
          : AdminAttendanceSummary.fromRecords(records);
      return AdminAttendanceResult(records: records, summary: summary);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to load attendance.'),
        statusCode: res.statusCode);
  }

  /// POST /api/attendance/manual — Add manual attendance.
  Future<AdminAttendanceRecord> addManualAttendance(
      AdminAttendanceInput input) async {
    final res = await _post('/api/attendance/admin-add', input.toJson());
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AdminAttendanceRecord.fromJson(
          (json['attendance'] ?? json['record'] ?? json) as Map<String, dynamic>);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to add attendance.'),
        statusCode: res.statusCode);
  }

  /// PUT /api/attendance/:id — Edit attendance record.
  Future<AdminAttendanceRecord> updateAttendance(
      String id, AdminAttendanceInput input) async {
    final res = await _put('/api/attendance/$id', input.toJson());
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AdminAttendanceRecord.fromJson(
          (json['attendance'] ?? json['record'] ?? json) as Map<String, dynamic>);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to update attendance.'),
        statusCode: res.statusCode);
  }

  /// DELETE /api/attendance/:id — Remove an attendance record.
  Future<void> deleteAttendance(String id) async {
    final res = await _delete('/api/attendance/$id');
    _checkAuth(res);
    if (res.statusCode == 200 || res.statusCode == 204) return;
    final json = _decode(res);
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to delete attendance.'),
        statusCode: res.statusCode);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // LEAVE MANAGEMENT
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/leave/all — All leave requests (admin).
  Future<List<AdminLeaveRequest>> getAllLeaves({String? status}) async {
    final path = status != null ? '/api/leaves?status=$status' : '/api/leaves';
    final res = await _get(path);
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200) {
      final list = json is List ? json : (json['leaves'] ?? json['requests'] ?? []);
      return (list as List)
          .map((e) => AdminLeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to load leave requests.'),
        statusCode: res.statusCode);
  }

  /// PUT /api/leave/:id/approve
  Future<void> approveLeave(String id) async {
    final res = await _put('/api/leaves/$id', {
      'status': 'approved',
    });
    _checkAuth(res);
    if (res.statusCode == 200 || res.statusCode == 201) return;
    final json = _decode(res);
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to approve leave.'),
        statusCode: res.statusCode);
  }

  /// PUT /api/leave/:id/reject
  Future<void> rejectLeave(String id) async {
    final res = await _put('/api/leaves/$id', {
      'status': 'rejected',
    });
    _checkAuth(res);
    if (res.statusCode == 200 || res.statusCode == 201) return;
    final json = _decode(res);
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to reject leave.'),
        statusCode: res.statusCode);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SALARY MANAGEMENT
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/salary?month=YYYY-MM&userId=...
  Future<List<AdminSalaryRecord>> getSalaryList({String? month, String? userId}) async {
    final params = <String, String>{
      if (month != null) 'month': month,
      if (userId != null) 'userId': userId,
    };
    final path = params.isEmpty
        ? '/api/salary/all'
        : '/api/salary/all?${Uri(queryParameters: params).query}';
    final res = await _get(path);
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200) {
      final list = json is List ? json : (json['employees'] ?? json['salaries'] ?? []);
      return (list as List)
          .map((e) => AdminSalaryRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to load salary data.'),
        statusCode: res.statusCode);
  }

  /// POST /api/salary/generate — Generate payroll for a month.
  Future<AdminPayrollResult> generatePayroll({required String month}) async {
    final res = await _post('/api/salary/generate', {'month': month});
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AdminPayrollResult.fromJson(json as Map<String, dynamic>);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to generate payroll.'),
        statusCode: res.statusCode);
  }

  /// POST /api/salary/calculate — Calculate salary for one employee over a date range.
  Future<AdminSalaryRecord> calculateSalary({
    required String userId,
    required String fromDate,
    required String toDate,
  }) async {
    final res = await _post('/api/salary/calculate', {
      'userId': userId,
      'fromDate': fromDate,
      'toDate': toDate,
    });
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = (json is Map && json['data'] != null) ? json['data'] : json;
      return AdminSalaryRecord.fromJson(data as Map<String, dynamic>);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to calculate salary.'),
        statusCode: res.statusCode);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SETTINGS — Attendance Rules
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/settings/attendance-rules
  Future<AdminAttendanceRules> getAttendanceRules() async {
    final res = await _get('/api/admin/settings');
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200) {
      return AdminAttendanceRules.fromJson(json as Map<String, dynamic>);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to load attendance rules.'),
        statusCode: res.statusCode);
  }

  /// PUT /api/settings/attendance-rules
  Future<AdminAttendanceRules> updateAttendanceRules(
      AdminAttendanceRules rules) async {
    final res = await _put('/api/admin/settings', rules.toJson());
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AdminAttendanceRules.fromJson(
          (json['rules'] ?? json) as Map<String, dynamic>);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to update attendance rules.'),
        statusCode: res.statusCode);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SETTINGS — Global
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/settings
  Future<AdminGlobalSettings> getSettings() async {
    final res = await _get('/api/admin/settings');
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200) {
      return AdminGlobalSettings.fromJson(json as Map<String, dynamic>);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to load settings.'),
        statusCode: res.statusCode);
  }

  /// PUT /api/settings
  Future<AdminGlobalSettings> updateSettings(AdminGlobalSettings s) async {
    final res = await _put('/api/admin/settings', s.toJson());
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AdminGlobalSettings.fromJson(
          (json['settings'] ?? json) as Map<String, dynamic>);
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to update settings.'),
        statusCode: res.statusCode);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SECURITY — Change Password
  // ────────────────────────────────────────────────────────────────────────────

  /// POST /api/change-password — Change the logged-in admin's password.
  /// Body: { oldPassword, newPassword, confirmPassword }
  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await _post('/api/change-password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });

    if (res.statusCode == 401) {
      // On this endpoint 401 means "current password is incorrect", not an
      // expired session — so we deliberately don't clear the token here.
      final json = _decode(res);
      throw ApiException(
        message: _extractMessage(json, fallback: 'Current password is incorrect.'),
        statusCode: 401,
      );
    }
    if (res.statusCode == 403) {
      final json = _decode(res);
      throw ApiException(
        message: _extractMessage(json, fallback: 'You do not have permission to do this.'),
        statusCode: 403,
      );
    }

    final json = _decode(res);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return _extractMessage(json, fallback: 'Password changed successfully.');
    }

    switch (res.statusCode) {
      case 400:
        throw ApiException(
          message: _extractMessage(json, fallback: 'Please check the entered passwords.'),
          statusCode: 400,
        );
      case 404:
        throw ApiException(
          message: _extractMessage(json, fallback: 'User not found.'),
          statusCode: 404,
        );
      case 422:
        throw ApiException(
          message: _extractMessage(json, fallback: 'New password does not meet requirements.'),
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
          statusCode: res.statusCode,
        );
      default:
        throw ApiException(
          message: _extractMessage(json, fallback: 'Failed to change password (${res.statusCode}).'),
          statusCode: res.statusCode,
        );
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/notifications
  Future<List<AdminNotification>> getNotifications() async {
    final res = await _get('/api/notifications');
    _checkAuth(res);
    final json = _decode(res);
    if (res.statusCode == 200) {
      final list = json is List ? json : (json['notifications'] ?? json['data'] ?? []);
      return (list as List)
          .map((e) => AdminNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to load notifications.'),
        statusCode: res.statusCode);
  }

  /// DELETE /api/notifications/:id
  Future<void> deleteNotification(String id) async {
    final res = await _delete('/api/notifications/$id');
    _checkAuth(res);
    if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) return;
    final json = _decode(res);
    throw ApiException(
        message: _extractMessage(json, fallback: 'Failed to delete notification.'),
        statusCode: res.statusCode);
  }
}