import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';
import '../services/admin_api_service.dart';
import '../models/auth_models.dart';

// ── Base Admin Provider ────────────────────────────────────────────────────────

abstract class _BaseAdminProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  void _setLoading(bool v) {
    debugPrint('[AdminProvider] _setLoading($v)');
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    debugPrint('[AdminProvider] _setError($msg)');
    _error = msg;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<T?> _run<T>(Future<T> Function() action,
      {String fallback = 'Something went wrong.',
        void Function(Object error)? onException}) async {
    _setLoading(true);
    _setError(null);
    try {
      final result = await action();
      return result;
    } on ApiException catch (e) {
      _setError(e.message);
      onException?.call(e);
      return null;
    } catch (e) {
      _setError(fallback);
      debugPrint('[AdminProvider] Unexpected: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
}

// ── Admin Auth Provider ───────────────────────────────────────────────────────
// Handles: /api/register, /api/forgot-password, /api/verify-otp,
//          /api/resend-otp, /api/reset-password

class AdminAuthProvider extends _BaseAdminProvider {
  final AdminApiService _api;

  AdminAuthProvider(this._api);

  // Forgot-password flow state
  bool _otpSent = false;
  bool _otpVerified = false;
  String? _pendingEmail;
  bool _isDuplicateEmail = false;

  bool get otpSent => _otpSent;
  bool get otpVerified => _otpVerified;
  String? get pendingEmail => _pendingEmail;
  /// True when the last registerAdmin() call failed because the email was
  /// already registered — UI should offer "Go to Login" rather than retry.
  bool get isDuplicateEmail => _isDuplicateEmail;

  // ── Register (one-time admin setup) ─────────────────────────────────────────
  Future<bool> registerAdmin({
    required String fullName,
    String? lName,
    required String email,
    String? phoneNo,
    String? companyName,
    required String password,
    required String confirmPassword,
    required String secret,
  }) async {
    _isDuplicateEmail = false;
    final result = await _run(
          () => _api.registerAdmin(
        fullName: fullName,
        lName: lName,
        email: email,
        phoneNo: phoneNo,
        companyName: companyName,
        password: password,
        confirmPassword: confirmPassword,
        secret: secret,
      ),
      fallback: 'Registration failed. Please try again.',
      onException: (e) {
        if (e is DuplicateRegistrationException) {
          _isDuplicateEmail = true;
        }
      },
    );
    return result != null;
  }


  // ── Verify Registration OTP ──────────────────────────────────────────────────
  Future<bool> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _run(
          () async {
        await _api.verifyRegistrationOtp(email: email, otp: otp);
        return true;
      },
      fallback: 'OTP verification failed.',
    );
    return result == true;
  }

  // ── Resend Registration OTP ──────────────────────────────────────────────────
  Future<bool> resendRegistrationOtp({required String email}) async {
    final result = await _run(
          () async {
        await _api.resendRegistrationOtp(email: email);
        return true;
      },
      fallback: 'Failed to resend OTP.',
    );
    return result == true;
  }

  // ── Forgot Password ──────────────────────────────────────────────────────────
  Future<bool> sendForgotPasswordOtp({required String email}) async {
    final result = await _run(
          () async {
        await _api.forgotPassword(email: email);
        return true;
      },
      fallback: 'Failed to send OTP.',
    );
    if (result == true) {
      _otpSent = true;
      _pendingEmail = email;
      notifyListeners();
      return true;
    }
    return false;
  }

  // ── Verify OTP ───────────────────────────────────────────────────────────────
  Future<bool> verifyOtp({required String otp}) async {
    if (_pendingEmail == null) {
      _setError('Please request an OTP first.');
      return false;
    }
    final result = await _run(
          () async {
        await _api.verifyOtp(email: _pendingEmail!, otp: otp);
        return true;
      },
      fallback: 'OTP verification failed.',
    );
    if (result == true) {
      _otpVerified = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // ── Resend OTP ───────────────────────────────────────────────────────────────
  Future<bool> resendOtp() async {
    if (_pendingEmail == null) {
      _setError('Email not set. Please restart password reset.');
      return false;
    }
    final result = await _run(
          () async {
        await _api.resendOtp(email: _pendingEmail!);
        return true;
      },
      fallback: 'Failed to resend OTP.',
    );
    return result == true;
  }

  // ── Reset Password ───────────────────────────────────────────────────────────
  Future<bool> resetPassword({
    required String otp,
    required String newPassword,
  }) async {
    if (_pendingEmail == null) {
      _setError('Session expired. Please restart the reset flow.');
      return false;
    }
    final result = await _run(
          () async {
        await _api.resetPassword(
            email: _pendingEmail!, otp: otp, newPassword: newPassword);
        return true;
      },
      fallback: 'Password reset failed.',
    );
    if (result == true) {
      _resetForgotFlow();
      return true;
    }
    return false;
  }

  void _resetForgotFlow() {
    _otpSent = false;
    _otpVerified = false;
    _pendingEmail = null;
    notifyListeners();
  }

  void resetForgotFlow() => _resetForgotFlow();
}

// ── Admin Dashboard Provider ──────────────────────────────────────────────────

class AdminDashboardProvider extends _BaseAdminProvider {
  final AdminApiService _api;

  AdminDashboardProvider(this._api);

  AdminDashboardStats? _stats;
  AdminDashboardStats? get stats => _stats;

  Future<void> fetchStats() async {
    final result = await _run(
          () => _api.getAdminStats(),
      fallback: 'Failed to load dashboard stats.',
    );
    if (result != null) {
      _stats = result;
      notifyListeners();
    }
  }

  void setFallbackStats(AdminDashboardStats s) {
    _stats = s;
    notifyListeners();
  }
}

// ── Admin Employee Provider ───────────────────────────────────────────────────

class AdminEmployeeProvider extends _BaseAdminProvider {
  final AdminApiService _api;

  AdminEmployeeProvider(this._api);

  List<AdminEmployee> _employees = [];
  List<AdminEmployee> get employees => List.unmodifiable(_employees);

  String _searchQuery = '';
  String _filterDept = 'All';
  String _filterRole = 'All';

  String get searchQuery => _searchQuery;
  String get filterDept => _filterDept;
  String get filterRole => _filterRole;

  List<AdminEmployee> get filtered {
    return _employees.where((e) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.email.toLowerCase().contains(q) ||
          e.username.toLowerCase().contains(q) ||
          e.designation.toLowerCase().contains(q);
      final matchDept = _filterDept == 'All' || e.dept == _filterDept;
      final matchRole = _filterRole == 'All' || e.role == _filterRole;
      return matchSearch && matchDept && matchRole;
    }).toList();
  }

  List<String> get departments {
    final depts = _employees.map((e) => e.dept).toSet().toList()..sort();
    return ['All', ...depts];
  }

  int get activeCount => _employees.where((e) => e.isActive).length;
  int get inactiveCount => _employees.where((e) => !e.isActive).length;
  int get deptCount => _employees.map((e) => e.dept).toSet().length;

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilterDept(String dept) {
    _filterDept = dept;
    notifyListeners();
  }

  void setFilterRole(String role) {
    _filterRole = role;
    notifyListeners();
  }

  AdminEmployee? _selectedEmployee;
  AdminEmployee? get selectedEmployee => _selectedEmployee;

  /// GET /api/users/:id — fetch a single employee's full profile
  /// (used e.g. when opening an employee's detail view from the list).
  Future<AdminEmployee?> fetchEmployeeById(String id) async {
    final result = await _run(
          () => _api.getEmployee(id),
      fallback: 'Failed to load employee details.',
    );
    _selectedEmployee = result;
    notifyListeners();
    return result;
  }

  Future<void> fetchEmployees({bool silent = false}) async {
    // silent=true (background refresh) — don't show spinner if list already loaded
    if (silent || _employees.isNotEmpty) {
      _setError(null);
      try {
        final result = await _api.getEmployees();
        _employees = result;
        notifyListeners();
      } on ApiException catch (e) {
        _setError(e.message);
      } catch (_) {
        // silently ignore background refresh errors
      }
      return;
    }
    // First load — show spinner normally
    final result = await _run(
          () => _api.getEmployees(),
      fallback: 'Failed to load employees.',
    );
    if (result != null) {
      _employees = result;
      notifyListeners();
    }
  }

  Future<bool> createEmployee(AdminEmployeeInput input) async {
    final result = await _run(
          () => _api.createEmployee(input),
      fallback: 'Failed to create employee.',
    );
    if (result != null) {
      _employees.add(result);
      notifyListeners();
      fetchEmployees(silent: true);
      return true;
    }
    return false;
  }

  Future<bool> updateEmployee(String id, AdminEmployeeInput input) async {
    // Optimistic update — instantly reflect changes in UI
    final idx = _employees.indexWhere((e) => e.id == id);
    AdminEmployee? backup;
    if (idx != -1) {
      backup = _employees[idx];
      _employees[idx] = AdminEmployee(
        id: id,
        name: '${input.fullName} ${input.lName}'.trim(),
        username: input.username,
        email: input.email,
        role: backup!.role,
        dept: input.dept,
        designation: input.designation,
        salary: input.salary,
        joinDate: input.joinDate,
        phone: input.phone,
        gender: input.gender,
        bloodGroup: input.bloodGroup,
        address: input.address,
        emergencyContact: input.emergencyContact,
        shiftType: input.shiftType,
        isActive: backup.isActive,
        bankAccountNo: backup.bankAccountNo,
        bankName: backup.bankName,
        bankBranch: backup.bankBranch,
        bankIfsc: backup.bankIfsc,
        aadharNo: backup.aadharNo,
        panNo: backup.panNo,
      );
      notifyListeners();
    }
    // Call API
    try {
      final result = await _api.updateEmployee(id, input);
      // Confirm with server response if id matches
      final i = _employees.indexWhere((e) => e.id == id);
      if (i != -1 && result.id.isNotEmpty) _employees[i] = result;
      notifyListeners();
      // Server response to PUT can be partial (e.g. missing bank/aadhar/pan
      // fields it didn't echo back) — do a silent full refetch so the list
      // (and any subsequent GET-driven screen) always shows the true, complete
      // saved record instead of a stale/partial one.
      fetchEmployees(silent: true);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      // Rollback on failure
      if (idx != -1 && backup != null) {
        _employees[idx] = backup;
        notifyListeners();
      }
      return false;
    } catch (_) {
      // API returned bad response but update likely saved — keep optimistic update
      // and do a silent refresh to confirm
      fetchEmployees(silent: true);
      return true;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    final result = await _run(
          () async {
        await _api.deleteEmployee(id);
        return true;
      },
      fallback: 'Failed to delete employee.',
    );
    if (result == true) {
      _employees.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }
}

// ── Admin Attendance Provider ─────────────────────────────────────────────────

class AdminAttendanceProvider extends _BaseAdminProvider {
  final AdminApiService _api;

  AdminAttendanceProvider(this._api);

  List<AdminAttendanceRecord> _records = [];
  AdminAttendanceSummary _summary = AdminAttendanceSummary(all: 0, present: 0, absent: 0, halfDay: 0, late: 0);
  String _selectedDate = '';
  String _searchQuery = '';
  String _filterStatus = 'All';

  List<AdminAttendanceRecord> get records => List.unmodifiable(_records);
  AdminAttendanceSummary get summary => _summary;
  String get selectedDate => _selectedDate;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;

  List<AdminAttendanceRecord> get filtered {
    return _records.where((r) {
      final q = _searchQuery.trim().toLowerCase();
      final matchSearch = q.isEmpty ||
          r.employeeName.toLowerCase().contains(q) ||
          r.userId.toLowerCase().contains(q);
      // "Late" / "Half Day" are flags (is_late / is_half_day) on top of
      // status, not their own status strings — filterCategory accounts for
      // that so all 4 chips match the right rows.
      final matchStatus = _filterStatus == 'All' ||
          r.filterCategory.trim().toLowerCase() == _filterStatus.trim().toLowerCase();
      return matchSearch && matchStatus;
    }).toList();
  }

  Map<String, int> get statusCounts {
    final m = <String, int>{};
    for (final r in _records) {
      m[r.status] = (m[r.status] ?? 0) + 1;
    }
    return m;
  }

  void setDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilterStatus(String s) {
    _filterStatus = s;
    notifyListeners();
  }

  Future<void> fetchAttendance({String? date, String? userId, String? month}) async {
    if (date != null) _selectedDate = date;
    final result = await _run(
          () => _api.getAttendance(date: date, userId: userId, month: month),
      fallback: 'Failed to load attendance.',
    );
    // Always update + notify, even when the API returns an empty list,
    // so the UI (loading -> empty/list state) reliably reflects the
    // latest fetch instead of silently keeping stale data on refresh.
    _records = result?.records ?? [];
    _summary = result?.summary ??
        AdminAttendanceSummary.fromRecords(_records);
    notifyListeners();
  }

  Future<bool> addManualAttendance(AdminAttendanceInput input) async {
    final result = await _run(
          () => _api.addManualAttendance(input),
      fallback: 'Failed to add attendance.',
    );
    if (result != null) {
      // Re-fetch instead of just splicing the new record into the local
      // list — guarantees the list AND the summary counts are in sync
      // with the server immediately, without the user needing to
      // pull-to-refresh to see it.
      await fetchAttendance(date: _selectedDate);
      return true;
    }
    return false;
  }

  Future<bool> updateAttendance(String id, AdminAttendanceInput input) async {
    final result = await _run(
          () => _api.updateAttendance(id, input),
      fallback: 'Failed to update attendance.',
    );
    if (result != null) {
      // Same reasoning as addManualAttendance: refresh from the server so
      // the edited row and the summary counts update right away.
      await fetchAttendance(date: _selectedDate);
      return true;
    }
    return false;
  }

  Future<bool> deleteAttendance(String id) async {
    final ok = await _run(
          () async {
        await _api.deleteAttendance(id);
        return true;
      },
      fallback: 'Failed to delete attendance.',
    );
    if (ok == true) {
      // Refresh from the server so the list and summary counts drop the
      // deleted row immediately, same as add/update.
      await fetchAttendance(date: _selectedDate);
      return true;
    }
    return false;
  }
}

// ── Admin Leave Provider ──────────────────────────────────────────────────────

class AdminLeaveProvider extends _BaseAdminProvider {
  final AdminApiService _api;

  AdminLeaveProvider(this._api);

  List<AdminLeaveRequest> _leaves = [];

  List<AdminLeaveRequest> get leaves => List.unmodifiable(_leaves);
  List<AdminLeaveRequest> get pending =>
      _leaves.where((l) => l.status == 'pending').toList();
  List<AdminLeaveRequest> get approved =>
      _leaves.where((l) => l.status == 'approved').toList();
  List<AdminLeaveRequest> get rejected =>
      _leaves.where((l) => l.status == 'rejected').toList();

  Future<void> fetchLeaves({String? status}) async {
    final result = await _run(
          () => _api.getAllLeaves(status: status),
      fallback: 'Failed to load leave requests.',
    );
    if (result != null) {
      _leaves = result;
      notifyListeners();
    }
  }

  Future<bool> approveLeave(String id, {String? remark, String? approvedBy}) async {
    final result = await _run(
          () async {
        await _api.approveLeave(id);
        return true;
      },
      fallback: 'Failed to approve leave.',
    );
    if (result == true) {
      final idx = _leaves.indexWhere((l) => l.id == id);
      if (idx != -1) {
        _leaves[idx] = _leaves[idx].copyWith(
          status: 'approved',
          managerRemark: remark,
          approvedBy: approvedBy,
        );
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> rejectLeave(String id, {String? remark, String? approvedBy}) async {
    final result = await _run(
          () async {
        await _api.rejectLeave(id);
        return true;
      },
      fallback: 'Failed to reject leave.',
    );
    if (result == true) {
      final idx = _leaves.indexWhere((l) => l.id == id);
      if (idx != -1) {
        _leaves[idx] = _leaves[idx].copyWith(
          status: 'rejected',
          managerRemark: remark,
          approvedBy: approvedBy,
        );
        notifyListeners();
      }
      return true;
    }
    return false;
  }
}

// ── Admin Salary Provider ─────────────────────────────────────────────────────

class AdminSalaryProvider extends _BaseAdminProvider {
  final AdminApiService _api;

  AdminSalaryProvider(this._api);

  List<AdminSalaryRecord> _salaries = [];
  String _selectedMonth = '';
  bool _isGenerating = false;
  String? _generateMessage;

  List<AdminSalaryRecord> get salaries => List.unmodifiable(_salaries);
  String get selectedMonth => _selectedMonth;
  bool get isGenerating => _isGenerating;
  String? get generateMessage => _generateMessage;

  int get totalNetSalary =>
      _salaries.fold(0, (sum, s) => sum + s.netSalary);
  int get paidCount => _salaries.where((s) => s.status == 'paid').length;
  int get pendingCount => _salaries.where((s) => s.status == 'pending').length;

  void setMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  Future<void> fetchSalaries({String? month, String? userId}) async {
    final result = await _run(
          () => _api.getSalaryList(month: month, userId: userId),
      fallback: 'Failed to load salary data.',
    );
    if (result != null) {
      _salaries = result;
      notifyListeners();
    }
  }

  Future<bool> generatePayroll({required String month}) async {
    _isGenerating = true;
    _generateMessage = null;
    notifyListeners();
    try {
      final result = await _api.generatePayroll(month: month);
      _generateMessage = result.message;
      await fetchSalaries(month: month);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to generate payroll.');
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  AdminSalaryRecord? _calculatedResult;
  AdminSalaryRecord? get calculatedResult => _calculatedResult;
  bool _isCalculating = false;
  bool get isCalculating => _isCalculating;

  Future<bool> calculateSalary({
    required String userId,
    required String fromDate,
    required String toDate,
  }) async {
    _isCalculating = true;
    _calculatedResult = null;
    _setError(null);
    notifyListeners();
    try {
      final result = await _api.calculateSalary(
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
      );
      _calculatedResult = result;
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to calculate salary.');
      return false;
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  void clearCalculatedResult() {
    _calculatedResult = null;
    notifyListeners();
  }
}

// ── Admin Settings Provider ───────────────────────────────────────────────────

class AdminSettingsProvider extends _BaseAdminProvider {
  final AdminApiService _api;

  AdminSettingsProvider(this._api);

  AdminAttendanceRules? _attendanceRules;
  AdminGlobalSettings? _globalSettings;

  AdminAttendanceRules? get attendanceRules => _attendanceRules;
  AdminGlobalSettings? get globalSettings => _globalSettings;

  // ── Attendance Rules ─────────────────────────────────────────────────────────

  Future<void> fetchAttendanceRules() async {
    final result = await _run(
          () => _api.getAttendanceRules(),
      fallback: 'Failed to load attendance rules.',
    );
    if (result != null) {
      _attendanceRules = result;
      notifyListeners();
    }
  }

  Future<bool> saveAttendanceRules(AdminAttendanceRules rules) async {
    final result = await _run(
          () => _api.updateAttendanceRules(rules),
      fallback: 'Failed to save attendance rules.',
    );
    if (result != null) {
      _attendanceRules = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  // ── Global Settings ──────────────────────────────────────────────────────────

  Future<void> fetchGlobalSettings() async {
    final result = await _run(
          () => _api.getSettings(),
      fallback: 'Failed to load settings.',
    );
    if (result != null) {
      _globalSettings = result;
      notifyListeners();
    }
  }

  Future<bool> saveGlobalSettings(AdminGlobalSettings settings) async {
    final result = await _run(
          () => _api.updateSettings(settings),
      fallback: 'Failed to save settings.',
    );
    if (result != null) {
      _globalSettings = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> fetchAll() async {
    await Future.wait([
      fetchAttendanceRules(),
      fetchGlobalSettings(),
    ]);
  }
}

// ── Admin Notifications Provider ──────────────────────────────────────────────

class AdminNotificationsProvider extends _BaseAdminProvider {
  final AdminApiService _api;

  AdminNotificationsProvider(this._api);

  List<AdminNotification> _notifications = [];

  List<AdminNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// GET /api/notifications
  Future<void> fetchNotifications() async {
    final result = await _run(
          () => _api.getNotifications(),
      fallback: 'Failed to load notifications.',
    );
    if (result != null) {
      _notifications = result;
      notifyListeners();
    }
  }

  /// DELETE /api/notifications/:id
  /// Removes the item optimistically so the UI feels instant; if the
  /// request fails, the item is put back and an error is surfaced.
  Future<bool> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return false;

    final removed = _notifications[index];
    _notifications = List.of(_notifications)..removeAt(index);
    notifyListeners();

    final result = await _run(
          () async {
        await _api.deleteNotification(id);
        return true;
      },
      fallback: 'Failed to delete notification.',
    );

    if (result == true) {
      return true;
    }

    // Roll back on failure.
    _notifications = List.of(_notifications)..insert(index, removed);
    notifyListeners();
    return false;
  }
}