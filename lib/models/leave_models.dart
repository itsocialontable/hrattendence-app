/// Leave Models - Request & Response models for /api/leaves

/// Leave type constants matching the backend contract:
/// paid / unpaid / sick / casual / half_day
class LeaveType {
  static const String paid = 'paid';
  static const String unpaid = 'unpaid';
  static const String sick = 'sick';
  static const String casual = 'casual';
  static const String halfDay = 'half_day';

  static const List<String> values = [paid, unpaid, sick, casual, halfDay];

  static String label(String type) {
    switch (type) {
      case paid:
        return 'Paid Leave';
      case unpaid:
        return 'Unpaid Leave';
      case sick:
        return 'Sick Leave';
      case casual:
        return 'Casual Leave';
      case halfDay:
        return 'Half Day';
      default:
        return type;
    }
  }
}

/// Session constants — used when a leave is for a single day (from == to)
/// or when the type is Half Day, the user must pick which half of the day.
class LeaveSession {
  static const String firstHalf = 'first_half';
  static const String secondHalf = 'second_half';

  static const List<String> values = [firstHalf, secondHalf];

  static String label(String session) {
    switch (session) {
      case firstHalf:
        return 'First Half';
      case secondHalf:
        return 'Second Half';
      default:
        return session;
    }
  }
}

/// Request body for POST /api/leaves
/// { "from":"", "to":"", "type":"", "reason":"", "session":"" }
class LeaveRequest {
  final String from;
  final String to;
  final String type;
  final String reason;
  final String? session;

  LeaveRequest({
    required this.from,
    required this.to,
    required this.type,
    required this.reason,
    this.session,
  });

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'type': type,
      'reason': reason,
      'session': session ?? '',
    };
  }
}

/// A single leave record, as returned by the API
/// (used both for the POST response and items inside the GET list).
class LeaveModel {
  final String id;
  final String userId;
  final String from;
  final String to;
  final String type;
  final String reason;
  final String session;
  final String status;
  final String appliedOn;
  final int days;

  LeaveModel({
    required this.id,
    required this.userId,
    required this.from,
    required this.to,
    required this.type,
    required this.reason,
    required this.session,
    required this.status,
    required this.appliedOn,
    required this.days,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    // Some backends nest the created/returned record under "leave" / "data"
    final src = (json['leave'] is Map)
        ? json['leave'] as Map<String, dynamic>
        : (json['data'] is Map ? json['data'] as Map<String, dynamic> : json);

    return LeaveModel(
      id: (src['id'] ?? src['_id'] ?? '').toString(),
      userId: (src['userId'] ?? src['user_id'] ?? '').toString(),
      from: (src['from'] ?? src['fromDate'] ?? src['from_date'] ?? '').toString(),
      to: (src['to'] ?? src['toDate'] ?? src['to_date'] ?? '').toString(),
      type: (src['type'] ?? src['leaveType'] ?? src['leave_type'] ?? '').toString(),
      reason: (src['reason'] ?? '').toString(),
      session: (src['session'] ?? '').toString(),
      status: (src['status'] ?? 'pending').toString(),
      appliedOn: (src['appliedOn'] ??
              src['applied_on'] ??
              src['createdAt'] ??
              src['created_at'] ??
              '')
          .toString(),
      days: src['days'] is int
          ? src['days'] as int
          : int.tryParse('${src['days']}') ?? _computeDays(src),
    );
  }

  static int _computeDays(Map<String, dynamic> src) {
    final from = src['from'] ?? src['fromDate'] ?? src['from_date'];
    final to = src['to'] ?? src['toDate'] ?? src['to_date'];
    if (from == null || to == null) return 1;
    return daysBetween(from.toString(), to.toString());
  }

  /// Inclusive day count between two ISO (yyyy-MM-dd) date strings.
  /// Falls back to 1 if either string can't be parsed.
  static int daysBetween(String from, String to) {
    try {
      final fromDt = DateTime.parse(from);
      final toDt = DateTime.parse(to);
      final diff = toDt.difference(fromDt).inDays + 1;
      return diff > 0 ? diff : 1;
    } catch (_) {
      return 1;
    }
  }

  /// Pretty status used for badges, with the first letter capitalized.
  String get statusLabel {
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String get typeLabel => LeaveType.label(type);

  /// Returns a copy with any blank fields filled in from the given
  /// fallback values. Used right after a successful POST so the card we
  /// show immediately always reflects what the user actually submitted,
  /// even if the server's response echoes back an incomplete record.
  LeaveModel fillBlanksFrom({
    required String from,
    required String to,
    required String type,
    required String reason,
    String? session,
  }) {
    final resolvedFrom = this.from.isNotEmpty ? this.from : from;
    final resolvedTo = this.to.isNotEmpty ? this.to : to;
    return LeaveModel(
      id: id.isNotEmpty ? id : 'local_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      from: resolvedFrom,
      to: resolvedTo,
      type: this.type.isNotEmpty ? this.type : type,
      reason: this.reason.isNotEmpty ? this.reason : reason,
      session: this.session.isNotEmpty ? this.session : (session ?? ''),
      status: status.isNotEmpty ? status : 'pending',
      appliedOn: appliedOn.isNotEmpty ? appliedOn : DateTime.now().toIso8601String(),
      // Always recompute from the dates we know are correct, instead of
      // trusting a possibly-default "1" coming back from an incomplete response.
      days: daysBetween(resolvedFrom, resolvedTo),
    );
  }
}
