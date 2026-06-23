import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;

  AuthProvider({required this.apiService});

  // State variables
  UserData? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  // Getters
  UserData? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  /// Initialize - check if user was previously logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await apiService.isLoggedIn();
      if (_isLoggedIn) {
        _token = await apiService.getToken();
        _user = await apiService.getStoredUser();
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Initialization failed: ${e.toString()}';
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with credentials
  Future<bool> login({
    required String username,
    required String password,
    String role = 'employee',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.login(
        username: username,
        password: password,
        role: role,
      );

      _token = response.token;
      _user = response.user;
      _isLoggedIn = true;
      _errorMessage = null;

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoggedIn = false;
      _token = null;
      _user = null;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected error: ${e.toString()}';
      _isLoggedIn = false;
      _token = null;
      _user = null;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiService.logout();
      _user = null;
      _token = null;
      _isLoggedIn = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
