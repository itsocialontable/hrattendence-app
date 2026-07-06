import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../models/review_models.dart';
import 'api_service.dart';

/// Talks to the employee Reviews & Reports endpoints:
///   GET /api/reviews/employee/:userId
///   GET /api/reviews/avg-rating/:userId
///   GET /api/reviews/attendance-rate/:userId
///   GET /api/reviews/graph/:userId
///   GET /api/reviews/monthly-summary/:userId
class ReviewService {
  final String? token;

  ReviewService({required this.token});

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<http.Response> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}$path'), headers: _headers)
          .timeout(const Duration(seconds: 30));
      debugPrint('📈 [ReviewService] GET $path -> ${res.statusCode}');
      debugPrint('📈 [ReviewService] BODY: ${res.body}');
      return res;
    } on SocketException {
      throw ApiException(message: 'No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException(message: 'Could not reach the server. Please try again.');
    } on FormatException {
      throw ApiException(message: 'Invalid response from server. Please try again later.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(message: 'Connection timeout. Please try again.');
      }
      rethrow;
    }
  }

  dynamic _decodeOrThrow(http.Response res, String what) {
    if (res.statusCode == 401) {
      throw ApiException(message: 'Session expired. Please login again.', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        message: 'Failed to load $what (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
    try {
      return jsonDecode(res.body);
    } catch (_) {
      throw ApiException(message: 'Invalid response while loading $what.');
    }
  }

  Future<List<ReviewItem>> getEmployeeReviews(String userId) async {
    final res = await _get('/api/reviews/employee/$userId');
    final body = _decodeOrThrow(res, 'reviews');
    return ReviewItem.listFromJson(body);
  }

  Future<AvgRatingData> getAvgRating(String userId) async {
    final res = await _get('/api/reviews/avg-rating/$userId');
    final body = _decodeOrThrow(res, 'average rating');
    return AvgRatingData.fromJson(body);
  }

  Future<AttendanceRateData> getAttendanceRate(String userId) async {
    final res = await _get('/api/reviews/attendance-rate/$userId');
    final body = _decodeOrThrow(res, 'attendance rate');
    return AttendanceRateData.fromJson(body);
  }

  Future<GraphData> getGraph(String userId) async {
    final res = await _get('/api/reviews/graph/$userId');
    final body = _decodeOrThrow(res, 'performance graph');
    return GraphData.fromJson(body);
  }

  Future<MonthlySummaryData> getMonthlySummary(String userId) async {
    final res = await _get('/api/reviews/monthly-summary/$userId');
    final body = _decodeOrThrow(res, 'monthly summary');
    return MonthlySummaryData.fromJson(body);
  }

  /// Fetches everything the Reports screen needs in parallel.
  /// If one call fails, the whole bundle fails (caller shows a retry state) —
  /// but any endpoint that *is* reachable still gets logged for debugging.
  Future<EmployeeReportsBundle> getReportsBundle(String userId) async {
    final results = await Future.wait([
      getEmployeeReviews(userId),
      getAvgRating(userId),
      getAttendanceRate(userId),
      getGraph(userId),
      getMonthlySummary(userId),
    ]);

    return EmployeeReportsBundle(
      reviews: results[0] as List<ReviewItem>,
      avgRating: results[1] as AvgRatingData,
      attendanceRate: results[2] as AttendanceRateData,
      graph: results[3] as GraphData,
      monthlySummary: results[4] as MonthlySummaryData,
    );
  }
}