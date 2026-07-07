/// Attendance Provider - State Management with persistent live timer
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_models.dart';
import '../models/auth_models.dart';
import '../services/attendance_service.dart';
import '../services/biometric_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService attendanceService;
  final BiometricService biometricService;

  AttendanceProvider({
    required this.attendanceService,
    required this.biometricService,
  });

  // ── Core state ─────────────────────────────────────────────────────────────
  AttendanceState? _attendanceState;
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _canCheckBiometric = false;

  // ── Live working timer ─────────────────────────────────────────────────────
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  static const _timerKey = 'checkin_timestamp_epoch';

  // ── History ────────────────────────────────────────────────────────────────
  List<AttendanceLogEntry> _history = [];
  bool _isHistoryLoading = false;
  String? _historyError;
  int _historyFetchSeq = 0;
  String? _lastHistoryDate;
  String? _lastHistoryFromDate;
  String? _lastHistoryToDate;
  String? _lastHistoryUserId;

  // ── Getters ────────────────────────────────────────────────────────────────
  AttendanceState? get attendanceState => _attendanceState;
  bool get isLoading => _isLoading;
  bool get isBiometricLoading => _isBiometricLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get canCheckBiometric => _canCheckBiometric;
  bool get isCheckedIn => _attendanceState?.isCheckedIn ?? false;
  bool get isCheckedOut =>
      !isCheckedIn && _attendanceState?.checkOutTime != null;

  /// Live elapsed duration since check-in (ticks every second while checked in)
  Duration get elapsed => _elapsed;

  /// Formatted as  HH:MM:SS
  String get elapsedFormatted {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  List<AttendanceLogEntry> get history => _history;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyError => _historyError;

  // ══════════════════════════════════════════════════════════════════════════
  //  INITIALIZE  (call on app start / provider creation)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> initialize() async {
    try {
      _canCheckBiometric = await biometricService.canCheckBiometrics();
      _errorMessage = null;

      // Always try to get the real state from server first so
      // check-in → check-out button appears correctly after app resume.
      final serverState = await attendanceService.syncTodayFromServer();
      if (serverState != null) {
        _attendanceState = serverState;
      } else {
        // Fall back to locally cached state (handles offline case).
        _attendanceState = await attendanceService.getAttendanceState();
      }

      // Resume timer if user was checked-in before app was killed
      if (isCheckedIn) {
        await _resumeTimer();
      }
    } catch (e) {
      _errorMessage = 'Initialization error: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TIMER  helpers
  // ══════════════════════════════════════════════════════════════════════════

  /// Starts timer from NOW and persists the timestamp so it survives app kill.
  Future<void> _startTimer() async {
    final prefs = await SharedPreferences.getInstance();
    // Store epoch seconds of check-in moment
    await prefs.setInt(_timerKey, DateTime.now().millisecondsSinceEpoch);
    _launchTicker();
  }

  /// Resumes timer using the stored timestamp (called on app restart).
  Future<void> _resumeTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final epoch = prefs.getInt(_timerKey);
    if (epoch != null) {
      final checkInMoment = DateTime.fromMillisecondsSinceEpoch(epoch);
      _elapsed = DateTime.now().difference(checkInMoment);
    } else if (_attendanceState?.checkInTime != null) {
      // Fallback: parse "HH:mm" string from AttendanceState
      _elapsed = DateTime.now().difference(
        AttendanceService.parseTimeString(_attendanceState!.checkInTime!),
      );
    }
    _launchTicker();
  }

  /// Creates a periodic ticker that increments [_elapsed] every second.
  void _launchTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  /// Stops the timer and removes the persisted timestamp.
  Future<void> _stopTimer() async {
    _timer?.cancel();
    _timer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerKey);
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CHECK IN
  // ══════════════════════════════════════════════════════════════════════════
  Future<bool> checkIn({String? location}) async {
    try {
      // Block same-day re-check-in
      if (isCheckedIn || isCheckedOut) {
        _errorMessage = isCheckedOut
            ? 'You have already completed attendance for today.'
            : 'You are already checked in.';
        notifyListeners();
        return false;
      }

      // Step 1 – Biometric
      _isBiometricLoading = true;
      _errorMessage = null;
      notifyListeners();

      final reason = await biometricService.getAuthenticationReason(
        action: 'punch in',
      );
      final result = await biometricService.authenticateStrict(reason: reason);
      _isBiometricLoading = false;

      if (!_handleBiometricResult(result)) return false;

      // Step 2 – API
      _isLoading = true;
      notifyListeners();

      final response = await attendanceService.checkIn(location: location);

      _attendanceState = AttendanceState(
        isCheckedIn: true,
        checkInTime: response.checkIn,
        isLate: response.isLate,
        isHalfDay: response.isHalfDay,
        warningCount: response.warningCount,
        maxWarnings: response.maxWarnings,
        checkInId: response.id,
        date: DateTime.now(),
      );

      _successMessage = 'Check-in successful at ${response.checkIn}';
      _errorMessage = null;

      // Step 3 – Start persistent timer
      _elapsed = Duration.zero;
      await _startTimer();

      // Step 4 – Sync real state from server to ensure isCheckedIn is correct
      // and checkout button appears immediately.
      try {
        final serverState = await attendanceService.syncTodayFromServer();
        if (serverState != null) {
          _attendanceState = AttendanceState(
            isCheckedIn: serverState.isCheckedIn,
            checkInTime: serverState.checkInTime ?? response.checkIn?.toString(),
            checkOutTime: serverState.checkOutTime,
            netMins: serverState.netMins,
            isLate: serverState.isLate ?? response.isLate,
            isHalfDay: serverState.isHalfDay ?? response.isHalfDay,
            warningCount: serverState.warningCount ?? response.warningCount as int?,
            maxWarnings: serverState.maxWarnings ?? response.maxWarnings as int?,
            checkInId: _attendanceState?.checkInId,
            date: serverState.date,
          );
        }
      } catch (_) {
        // Server sync failed — keep optimistic local state
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _successMessage = null;
      // The service may have just healed local storage (e.g. backend said
      // "already checked in today" and handed back the real state) — pull
      // it back in so the dashboard reflects it immediately, not just
      // after the next app restart.
      try {
        _attendanceState = await attendanceService.getAttendanceState();
      } catch (_) {}
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      _isBiometricLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CHECK OUT
  // ══════════════════════════════════════════════════════════════════════════
  Future<bool> checkOut({String? location}) async {
    try {
      if (!isCheckedIn) {
        _errorMessage = 'You have not checked in yet.';
        notifyListeners();
        return false;
      }

      // Step 1 – Biometric
      _isBiometricLoading = true;
      _errorMessage = null;
      notifyListeners();

      final reason = await biometricService.getAuthenticationReason(
        action: 'punch out',
      );
      final result = await biometricService.authenticateStrict(reason: reason);
      _isBiometricLoading = false;

      if (!_handleBiometricResult(result)) return false;

      // Step 2 – API
      _isLoading = true;
      notifyListeners();

      final response = await attendanceService.checkOut(location: location);

      if (_attendanceState != null) {
        _attendanceState = AttendanceState(
          isCheckedIn: false,
          checkInTime: _attendanceState!.checkInTime,
          checkOutTime: response.checkOut,
          netMins: response.netMins,
          isLate: _attendanceState!.isLate,
          isHalfDay: _attendanceState!.isHalfDay,
          warningCount: _attendanceState!.warningCount,
          maxWarnings: _attendanceState!.maxWarnings,
          checkInId: _attendanceState!.checkInId,
          date: DateTime.now(),
        );
      }

      _successMessage =
      'Check-out successful at ${response.checkOut}.\nWorked: ${AttendanceService.formatNetMinutes(response.netMins)}';
      _errorMessage = null;

      // Step 3 – Stop timer
      await _stopTimer();

      // Step 4 – Sync real state from server to confirm checkout is recorded.
      try {
        final serverState = await attendanceService.syncTodayFromServer();
        if (serverState != null) {
          _attendanceState = AttendanceState(
            isCheckedIn: serverState.isCheckedIn,
            checkInTime: serverState.checkInTime ?? _attendanceState?.checkInTime,
            checkOutTime: serverState.checkOutTime ?? response.checkOut,
            netMins: serverState.netMins ?? response.netMins,
            isLate: serverState.isLate ?? _attendanceState?.isLate,
            isHalfDay: serverState.isHalfDay ?? _attendanceState?.isHalfDay,
            warningCount: serverState.warningCount ?? _attendanceState?.warningCount,
            maxWarnings: serverState.maxWarnings ?? _attendanceState?.maxWarnings,
            checkInId: _attendanceState?.checkInId,
            date: serverState.date,
          );
        }
      } catch (_) {
        // Server sync failed — keep optimistic local state
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _successMessage = null;
      // The service may have just healed local storage (e.g. backend said
      // "already checked in today" and handed back the real state) — pull
      // it back in so the dashboard reflects it immediately, not just
      // after the next app restart.
      try {
        _attendanceState = await attendanceService.getAttendanceState();
      } catch (_) {}
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      _isBiometricLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HISTORY
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> fetchAttendanceHistory({
    String? userId,
    String? date,
    String? fromDate,
    String? toDate,
  }) async {
    final seq = ++_historyFetchSeq;
    _lastHistoryDate = date;
    _lastHistoryFromDate = fromDate;
    _lastHistoryToDate = toDate;
    _lastHistoryUserId = userId;

    _isHistoryLoading = true;
    _historyError = null;
    notifyListeners();

    try {
      final result = await attendanceService.getAttendanceHistory(
        userId: userId,
        date: date,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (seq != _historyFetchSeq) return;

      _history = result;
      _historyError = null;
    } catch (e) {
      if (seq != _historyFetchSeq) return;
      _historyError = e is ApiException
          ? e.message
          : 'Failed to load attendance. Please try again.';
    } finally {
      if (seq == _historyFetchSeq) {
        _isHistoryLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshHistory() => fetchAttendanceHistory(
    userId: _lastHistoryUserId,
    date: _lastHistoryDate,
    fromDate: _lastHistoryFromDate,
    toDate: _lastHistoryToDate,
  );

  /// Force-sync today's attendance state from the server.
  /// Useful when navigating back to the dashboard or pulling to refresh.
  Future<void> syncFromServer() async {
    try {
      final serverState = await attendanceService.syncTodayFromServer();
      if (serverState != null) {
        _attendanceState = serverState;
        if (isCheckedIn && (_timer == null || !(_timer?.isActive ?? false))) {
          await _resumeTimer();
        } else if (!isCheckedIn) {
          await _stopTimer();
        }
      }
    } catch (e) {
      debugPrint('syncFromServer error: $e');
    } finally {
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  bool _handleBiometricResult(BiometricResult result) {
    switch (result) {
      case BiometricResult.success:
        return true;
      case BiometricResult.cancelled:
        _errorMessage = 'Authentication cancelled.';
        break;
      case BiometricResult.failed:
        _errorMessage =
        '❌ Fingerprint not recognized.\nOnly your registered finger works.';
        break;
      case BiometricResult.notAvailable:
      // Emulators / test devices usually have no fingerprint enrolled.
      // In debug builds only, skip biometric so check-in/out can still
      // be tested end-to-end. Release builds keep enforcing it.
        if (kDebugMode) {
          debugPrint(
              '⚠️ [DEBUG] No biometric enrolled — skipping check (debug build only).');
          return true;
        }
        _errorMessage =
        'No fingerprint enrolled.\nPlease set up fingerprint in device Settings.';
        break;
      case BiometricResult.notSupported:
        if (kDebugMode) {
          debugPrint(
              '⚠️ [DEBUG] Biometric not supported on this device — skipping check (debug build only).');
          return true;
        }
        _errorMessage = 'This device does not support fingerprint authentication.';
        break;
      case BiometricResult.lockedOut:
        _errorMessage =
        '🔒 Too many failed attempts.\nDevice is locked. Try again later.';
        break;
    }
    notifyListeners();
    return false;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ── Text helpers used by other screens ────────────────────────────────────
  String getStatusText() {
    if (isCheckedIn) return 'Checked In at ${_attendanceState?.checkInTime}';
    if (isCheckedOut) return 'Checked Out at ${_attendanceState?.checkOutTime}';
    return 'Not checked in';
  }

  String getLateStatusText() {
    if (_attendanceState?.isLate ?? false) return '⚠️ Late Check-in';
    if (isCheckedIn || isCheckedOut) return '✓ On Time';
    return '';
  }

  String getHalfDayStatusText() {
    if (_attendanceState?.isHalfDay ?? false) return '⏱️ Half Day';
    return '';
  }

  String getWorkingDurationText() {
    if (isCheckedOut && _attendanceState?.netMins != null) {
      return 'Working Duration: ${AttendanceService.formatNetMinutes(_attendanceState!.netMins!)}';
    }
    return '';
  }

  String getWarningText() {
    final warnings = _attendanceState?.warningCount ?? 0;
    final maxWarnings = _attendanceState?.maxWarnings ?? 3;
    if (warnings > 0) return '⚠️ Warnings: $warnings/$maxWarnings';
    return '';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}