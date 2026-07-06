import 'package:flutter/foundation.dart';
import '../models/admin_review_models.dart';
import '../models/auth_models.dart';
import '../services/admin_review_service.dart';

/// State management for the Admin Reviews screen.
///
/// Responsibilities:
///   • Fetch all reviews from GET /api/reviews/admin/all (with optional filters)
///   • Submit a new review via POST /api/reviews
///   • Update an existing review via PUT /api/reviews/:id
///   • Delete a review via DELETE /api/reviews/:id
class AdminReviewProvider extends ChangeNotifier {
  final AdminReviewService _service;

  AdminReviewProvider(this._service);

  // ── State ─────────────────────────────────────────────────────────────────

  List<AdminReview> _reviews = [];
  bool _isLoading = false;
  bool _isMutating = false; // true during submit / update / delete
  String? _error;
  String? _mutationError;

  // Active filter state (mirrors what the screen last fetched)
  String? _filterUserId;
  String? _filterMonth;

  List<AdminReview> get reviews => List.unmodifiable(_reviews);
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;
  String? get mutationError => _mutationError;
  bool get hasError => _error != null;
  bool get hasMutationError => _mutationError != null;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchReviews({String? userId, String? month}) async {
    _filterUserId = userId;
    _filterMonth = month;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reviews = await _service.getAllMyReviews(userId: userId, month: month);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      debugPrint('[AdminReviewProvider] fetchReviews error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-fetch with the last used filters.
  Future<void> refresh() => fetchReviews(
        userId: _filterUserId,
        month: _filterMonth,
      );

  // ── Submit (create / upsert) ──────────────────────────────────────────────

  Future<bool> submitReview(AdminReviewInput input) async {
    _isMutating = true;
    _mutationError = null;
    notifyListeners();

    try {
      final review = await _service.submitReview(input);

      // Upsert locally — if same id already exists, replace it
      final idx = _reviews.indexWhere((r) => r.id == review.id);
      if (idx >= 0) {
        _reviews[idx] = review;
      } else {
        // Also replace any local entry with same userId + month + category
        final dupIdx = _reviews.indexWhere((r) =>
            r.userId == input.userId &&
            r.month == input.month &&
            r.category == (input.category ?? 'overall'));
        if (dupIdx >= 0) {
          _reviews[dupIdx] = review;
        } else {
          _reviews.insert(0, review);
        }
      }

      return true;
    } on ApiException catch (e) {
      _mutationError = e.message;
      return false;
    } catch (e) {
      _mutationError = 'Failed to submit review. Please try again.';
      debugPrint('[AdminReviewProvider] submitReview error: $e');
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<bool> updateReview(String id, AdminReviewUpdateInput input) async {
    _isMutating = true;
    _mutationError = null;
    notifyListeners();

    try {
      final updated = await _service.updateReview(id, input);
      final idx = _reviews.indexWhere((r) => r.id == id);
      if (idx >= 0) _reviews[idx] = updated;
      return true;
    } on ApiException catch (e) {
      _mutationError = e.message;
      return false;
    } catch (e) {
      _mutationError = 'Failed to update review. Please try again.';
      debugPrint('[AdminReviewProvider] updateReview error: $e');
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<bool> deleteReview(String id) async {
    _isMutating = true;
    _mutationError = null;
    notifyListeners();

    try {
      await _service.deleteReview(id);
      _reviews.removeWhere((r) => r.id == id);
      return true;
    } on ApiException catch (e) {
      _mutationError = e.message;
      return false;
    } catch (e) {
      _mutationError = 'Failed to delete review. Please try again.';
      debugPrint('[AdminReviewProvider] deleteReview error: $e');
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  void clearMutationError() {
    _mutationError = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
