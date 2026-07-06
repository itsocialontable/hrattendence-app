import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/admin_review_models.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';
import '../services/http_logger.dart';

/// Handles:
///   POST   /api/reviews              — submit / upsert review
///   PUT    /api/reviews/:id          — update review
///   DELETE /api/reviews/:id          — delete review
///   GET    /api/reviews/admin/all    — get all reviews by this admin
class AdminReviewService {
  final ApiService _base;
  static const _baseUrl = ApiService.baseUrl;

  AdminReviewService(this._base);

  // ── Auth headers ─────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await _base.getToken();
    if (token == null) {
      throw ApiException(message: 'No authentication token. Please login again.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── HTTP helpers ─────────────────────────────────────────────────────────────

  Future<http.Response> _get(String path) async {
    try {
      return await HttpLogger.request(
        'GET',
        Uri.parse('$_baseUrl$path'),
        headers: await _authHeaders(),
        timeout: const Duration(seconds: 30),
      );
    } on SocketException {
      throw ApiException(message: 'No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException(message: 'Connection timeout. Please try again.');
    } catch (e) {
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
        timeout: const Duration(seconds: 30),
      );
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on TimeoutException {
      throw ApiException(message: 'Connection timeout. Please try again.');
    } catch (e) {
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
        timeout: const Duration(seconds: 30),
      );
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on TimeoutException {
      throw ApiException(message: 'Connection timeout. Please try again.');
    } catch (e) {
      throw ApiException(message: 'Network error. Please try again.');
    }
  }

  Future<http.Response> _delete(String path) async {
    try {
      return await HttpLogger.request(
        'DELETE',
        Uri.parse('$_baseUrl$path'),
        headers: await _authHeaders(),
        timeout: const Duration(seconds: 30),
      );
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    } on TimeoutException {
      throw ApiException(message: 'Connection timeout. Please try again.');
    } catch (e) {
      throw ApiException(message: 'Network error. Please try again.');
    }
  }

  // ── Response decoder ─────────────────────────────────────────────────────────

  dynamic _decode(http.Response res, String what) {
    debugPrint('📝 [ReviewService] ${res.request?.method} ${res.request?.url} -> ${res.statusCode}');
    if (res.statusCode == 401) {
      throw ApiException(message: 'Session expired. Please login again.', statusCode: 401);
    }
    if (res.statusCode == 403) {
      throw ApiException(message: 'You do not have permission to perform this action.', statusCode: 403);
    }
    if (res.statusCode == 404) {
      throw ApiException(message: 'Review not found.', statusCode: 404);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // Try to get server error message
      String msg = 'Failed to $what (${res.statusCode}).';
      try {
        final body = jsonDecode(res.body);
        if (body is Map) {
          final serverMsg = body['message'] ?? body['error'] ?? body['msg'];
          if (serverMsg is String && serverMsg.isNotEmpty) msg = serverMsg;
        }
      } catch (_) {}
      throw ApiException(message: msg, statusCode: res.statusCode);
    }
    try {
      return jsonDecode(res.body);
    } catch (_) {
      throw ApiException(message: 'Invalid response while loading $what.');
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// POST /api/reviews
  /// Creates or upserts a review for the given employee + month + category.
  Future<AdminReview> submitReview(AdminReviewInput input) async {
    final res = await _post('/api/reviews', input.toJson());
    final body = _decode(res, 'submit review');
    return AdminReview.fromJson(
      body is Map<String, dynamic> ? body : {'_id': '', ...{}},
    );
  }

  /// PUT /api/reviews/:id
  /// Only the admin who created the review can edit it.
  Future<AdminReview> updateReview(String id, AdminReviewUpdateInput input) async {
    final res = await _put('/api/reviews/$id', input.toJson());
    final body = _decode(res, 'update review');
    return AdminReview.fromJson(
      body is Map<String, dynamic> ? body : <String, dynamic>{},
    );
  }

  /// DELETE /api/reviews/:id
  /// Only the admin who created the review can delete it.
  Future<void> deleteReview(String id) async {
    final res = await _delete('/api/reviews/$id');
    _decode(res, 'delete review');
  }

  /// GET /api/reviews/admin/all
  /// Optional query params: userId, month (YYYY-MM)
  Future<List<AdminReview>> getAllMyReviews({String? userId, String? month}) async {
    final params = <String, String>{};
    if (userId != null && userId.isNotEmpty) params['userId'] = userId;
    if (month != null && month.isNotEmpty) params['month'] = month;

    final uri = Uri.parse('$_baseUrl/api/reviews/admin/all')
        .replace(queryParameters: params.isEmpty ? null : params);

    http.Response res;
    try {
      res = await HttpLogger.request(
        'GET',
        uri,
        headers: await _authHeaders(),
        timeout: const Duration(seconds: 30),
      );
    } on SocketException {
      throw ApiException(message: 'No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException(message: 'Connection timeout. Please try again.');
    } catch (e) {
      throw ApiException(message: 'Network error. Please try again.');
    }

    final body = _decode(res, 'fetch reviews');
    return AdminReview.listFromJson(body);
  }
}
