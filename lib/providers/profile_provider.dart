import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiService apiService;

  ProfileProvider({required this.apiService});

  // ── State ──────────────────────────────────────────────────────────────────
  UserProfile? _profile;
  List<UserProfile> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────
  UserProfile? get profile => _profile;
  List<UserProfile> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Fetch single user by ID ────────────────────────────────────────────────
  Future<void> fetchUserById(String userId) async {
    log('▶ [ProfileProvider] fetchUserById($userId)');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await apiService.getUserById(userId);
      _errorMessage = null;
      log('✅ [ProfileProvider] profile loaded: ${_profile?.name}');
    } on ApiException catch (e) {
      _errorMessage = e.message;
      log('❌ [ProfileProvider] ApiException: ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      log('❌ [ProfileProvider] Unexpected error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Refresh profile ────────────────────────────────────────────────────────
  Future<void> refreshProfile(String userId) async {
    log('🔄 [ProfileProvider] refreshProfile($userId)');
    await fetchUserById(userId);
  }

  // ── Fetch all users (kept for backward compat) ─────────────────────────────
  Future<void> fetchUsers() async {
    log('▶ [ProfileProvider] fetchUsers()');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.getUsers();
      _users = response.users;
      _errorMessage = null;
      log('✅ [ProfileProvider] ${_users.length} users loaded');
    } on ApiException catch (e) {
      _errorMessage = e.message;
      log('❌ [ProfileProvider] ApiException: ${e.message}');
    } catch (e) {
      _errorMessage = 'Failed to fetch users: ${e.toString()}';
      log('❌ [ProfileProvider] Unexpected error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUsers() async => await fetchUsers();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}