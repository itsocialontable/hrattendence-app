/// Employee Stats Provider for managing the home tab dashboard stats
import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../models/dashboard_models.dart';
import '../services/api_service.dart';

class EmployeeStatsProvider extends ChangeNotifier {
  final ApiService apiService;

  EmployeeStatsProvider({required this.apiService});

  // State variables
  EmployeeStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastUserId;
  String? _lastMonth;

  // Getters
  EmployeeStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _stats != null;

  /// Fetch employee stats for the home tab
  Future<void> fetchEmployeeStats(String userId, {String? month}) async {
    debugPrint('🏠 [EmployeeStatsProvider] fetchEmployeeStats called for userId=$userId');
    _isLoading = true;
    _errorMessage = null;
    _lastUserId = userId;
    _lastMonth = month;
    notifyListeners();

    try {
      final response = await apiService.getEmployeeStats(userId, month: month);
      _stats = response;
      _errorMessage = null;
      debugPrint('🏠 [EmployeeStatsProvider] ✅ Stats loaded into provider: ${response.toJson()}');
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('🏠 [EmployeeStatsProvider] ❌ ApiException: ${e.message}');
    } catch (e) {
      _errorMessage = 'Failed to load stats: ${e.toString()}';
      debugPrint('🏠 [EmployeeStatsProvider] ❌ Unexpected error: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retry the last request (used by error state's Retry button)
  Future<void> retry() async {
    if (_lastUserId != null) {
      await fetchEmployeeStats(_lastUserId!, month: _lastMonth);
    }
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    if (_lastUserId != null) {
      await fetchEmployeeStats(_lastUserId!, month: _lastMonth);
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
