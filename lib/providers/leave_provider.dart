/// Leave Provider - State Management for /api/leaves
import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../models/leave_models.dart';
import '../services/leave_service.dart';

class LeaveProvider extends ChangeNotifier {
  final LeaveService leaveService;

  LeaveProvider({required this.leaveService});

  // ── State ──────────────────────────────────────────────────────────────
  List<LeaveModel> _leaves = [];
  bool _isLoading = false; // GET /api/leaves
  bool _isSubmitting = false; // POST /api/leaves
  String? _errorMessage;
  String? _successMessage;

  // Guards against out-of-order responses: if the user taps filters quickly,
  // an older (slower) request can resolve *after* a newer one. Without this,
  // the stale result would overwrite the freshly-loaded, correct one.
  int _fetchSeq = 0;
  String? _lastUserId;
  String? _lastStatus;

  // ── Getters ────────────────────────────────────────────────────────────
  List<LeaveModel> get leaves => _leaves;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  int get totalDays => _leaves.fold(0, (s, l) => s + l.days);
  int get approvedDays => _leaves
      .where((l) => l.status.toLowerCase() == 'approved')
      .fold(0, (s, l) => s + l.days);
  int get pendingDays => _leaves
      .where((l) => l.status.toLowerCase() == 'pending')
      .fold(0, (s, l) => s + l.days);
  int get rejectedDays => _leaves
      .where((l) => l.status.toLowerCase() == 'rejected')
      .fold(0, (s, l) => s + l.days);

  /// GET /api/leaves?userId=&status=
  Future<void> fetchLeaves({String? userId, String? status}) async {
    final seq = ++_fetchSeq;
    _lastUserId = userId;
    _lastStatus = status;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await leaveService.getLeaves(userId: userId, status: status);

      // A newer fetchLeaves() call has started since this one began — drop
      // this result, it's stale, so it can't clobber the latest data.
      if (seq != _fetchSeq) {
        // ignore: avoid_print
        print('LeaveProvider: discarding stale GET result (seq=$seq, current=$_fetchSeq)');
        return;
      }

      _leaves = result;
      // ignore: avoid_print
      print('LeaveProvider: fetched ${_leaves.length} leave(s) for userId=$userId status=$status');
      _errorMessage = null;
    } catch (e) {
      if (seq != _fetchSeq) return;
      _errorMessage = e is ApiException ? e.message : 'Failed to load leaves. Please try again.';
      // ignore: avoid_print
      print('LeaveProvider: fetchLeaves error -> $_errorMessage');
    } finally {
      if (seq == _fetchSeq) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Re-runs the most recent fetchLeaves() query (same userId/status).
  /// Useful right after a POST, to reconcile with whatever the server
  /// ends up persisting once it's done processing the new leave.
  Future<void> refresh() => fetchLeaves(userId: _lastUserId, status: _lastStatus);

  /// POST /api/leaves
  Future<bool> applyLeave({
    required String from,
    required String to,
    required String type,
    required String reason,
    String? session,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final request = LeaveRequest(
        from: from,
        to: to,
        type: type,
        reason: reason,
        session: session,
      );

      final created = await leaveService.applyLeave(request);

      // The server's response is sometimes incomplete right after creation
      // (e.g. missing from/to/type), so fill any blanks with what the user
      // actually submitted — this is what we show immediately, and it's
      // guaranteed correct regardless of what the API echoes back.
      final display = created.fillBlanksFrom(
        from: from,
        to: to,
        type: type,
        reason: reason,
        session: session,
      );

      _leaves.insert(0, display);
      _successMessage = 'Leave application submitted successfully';
      _errorMessage = null;
      // ignore: avoid_print
      print('LeaveProvider: leave applied successfully -> id=${display.id}, status=${display.status}');

      notifyListeners();

      // Reconcile with the server shortly after, in case it needed a moment
      // to fully persist the record (this won't clobber a newer manual
      // fetch, thanks to the sequence guard above).
      Future.delayed(const Duration(milliseconds: 1200), refresh);

      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : 'Failed to submit leave application. Please try again.';
      _successMessage = null;
      // ignore: avoid_print
      print('LeaveProvider: applyLeave error -> $_errorMessage');

      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
