/// Dashboard Models
/// Maps the response of GET /api/dashboard/employee-stats/:userId

class EmployeeStats {
  final String userId;
  final String month;
  final int presentDays;
  final int halfDays;
  final int lateDays;
  final int totalWorkMins;
  final int absentDays;
  final int pendingLeaves;
  final int approvedLeaves;
  final int saturdayOffs;
  final int saturdayOffsAllowed;
  final int saturdayOffsLeft;
  final int warnings;
  final int maxWarnings;
  final int warningsLeft;
  final bool nextLateIsHalfDay;
  final int daysInMonth;
  final int sundays;
  final int totalWorkingDays;

  EmployeeStats({
    required this.userId,
    required this.month,
    required this.presentDays,
    required this.halfDays,
    required this.lateDays,
    required this.totalWorkMins,
    required this.absentDays,
    required this.pendingLeaves,
    required this.approvedLeaves,
    required this.saturdayOffs,
    required this.saturdayOffsAllowed,
    required this.saturdayOffsLeft,
    required this.warnings,
    required this.maxWarnings,
    required this.warningsLeft,
    required this.nextLateIsHalfDay,
    required this.daysInMonth,
    required this.sundays,
    required this.totalWorkingDays,
  });

  /// Total leaves = pending + approved (handy derived getter for UI)
  int get totalLeaves => pendingLeaves + approvedLeaves;

  /// Work hours/mins split, formatted as e.g. "12h 30m"
  String get formattedWorkTime {
    final hours = totalWorkMins ~/ 60;
    final mins = totalWorkMins % 60;
    return '${hours}h ${mins}m';
  }

  /// Human friendly month label e.g. "June 2026" from "2026-06"
  String get formattedMonth {
    try {
      final parts = month.split('-');
      const names = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final monthIndex = int.parse(parts[1]) - 1;
      return '${names[monthIndex]} ${parts[0]}';
    } catch (_) {
      return month;
    }
  }

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    bool _b(dynamic v) {
      if (v is bool) return v;
      return v?.toString().toLowerCase() == 'true';
    }

    return EmployeeStats(
      userId: json['userId']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      presentDays: _i(json['presentDays']),
      halfDays: _i(json['halfDays']),
      lateDays: _i(json['lateDays']),
      totalWorkMins: _i(json['totalWorkMins']),
      absentDays: _i(json['absentDays']),
      pendingLeaves: _i(json['pendingLeaves']),
      approvedLeaves: _i(json['approvedLeaves']),
      saturdayOffs: _i(json['saturdayOffs']),
      saturdayOffsAllowed: _i(json['saturdayOffsAllowed']),
      saturdayOffsLeft: _i(json['saturdayOffsLeft']),
      warnings: _i(json['warnings']),
      maxWarnings: _i(json['maxWarnings']),
      warningsLeft: _i(json['warningsLeft']),
      nextLateIsHalfDay: _b(json['nextLateIsHalfDay']),
      daysInMonth: _i(json['daysInMonth']),
      sundays: _i(json['sundays']),
      totalWorkingDays: _i(json['totalWorkingDays']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'month': month,
      'presentDays': presentDays,
      'halfDays': halfDays,
      'lateDays': lateDays,
      'totalWorkMins': totalWorkMins,
      'absentDays': absentDays,
      'pendingLeaves': pendingLeaves,
      'approvedLeaves': approvedLeaves,
      'saturdayOffs': saturdayOffs,
      'saturdayOffsAllowed': saturdayOffsAllowed,
      'saturdayOffsLeft': saturdayOffsLeft,
      'warnings': warnings,
      'maxWarnings': maxWarnings,
      'warningsLeft': warningsLeft,
      'nextLateIsHalfDay': nextLateIsHalfDay,
      'daysInMonth': daysInMonth,
      'sundays': sundays,
      'totalWorkingDays': totalWorkingDays,
    };
  }
}
