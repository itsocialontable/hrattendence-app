/// Attendance Models
import 'dart:convert';

class CheckInResponse {
  final dynamic success;
  final dynamic id;
  final dynamic checkIn;
  final dynamic isLate;
  final dynamic isHalfDay;
  final dynamic autoHalfDay;
  final dynamic warningCount;
  final dynamic maxWarnings;
  final dynamic halfDayAmount;

  CheckInResponse({
    required this.success,
    required this.id,
    required this.checkIn,
    required this.isLate,
    required this.isHalfDay,
    required this.autoHalfDay,
    required this.warningCount,
    required this.maxWarnings,
    required this.halfDayAmount,
  });

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    // Some backends nest the actual record under "attendance" / "data" / "record"
    // (same shape as the GET /api/attendance list endpoint).
    final src = (json['attendance'] is Map)
        ? json['attendance'] as Map<String, dynamic>
        : (json['data'] is Map)
        ? json['data'] as Map<String, dynamic>
        : (json['record'] is Map ? json['record'] as Map<String, dynamic> : json);

    bool b(dynamic v) {
      if (v is bool) return v;
      return v?.toString().toLowerCase() == 'true';
    }

    int i(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    String s(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    return CheckInResponse(
      success: json['success'] ?? true,
      id: s(src['id'] ?? src['_id'] ?? src['attendanceId'] ?? json['id']),
      checkIn: s(src['checkIn'] ??
          src['clockIn'] ??
          src['check_in'] ??
          src['punchIn'] ??
          src['time'] ??
          src['checkInTime']),
      isLate: b(src['isLate'] ?? src['late']),
      isHalfDay: b(src['isHalfDay'] ?? src['halfDay']),
      autoHalfDay: b(src['autoHalfDay']),
      warningCount: i(src['warningCount'] ?? src['warnings']),
      maxWarnings: i(src['maxWarnings']) > 0 ? i(src['maxWarnings']) : 3,
      halfDayAmount: src['halfDayAmount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'id': id,
      'checkIn': checkIn,
      'isLate': isLate,
      'isHalfDay': isHalfDay,
      'autoHalfDay': autoHalfDay,
      'warningCount': warningCount,
      'maxWarnings': maxWarnings,
      'halfDayAmount': halfDayAmount,
    };
  }
}

class CheckOutResponse {
  final bool success;
  final String checkOut;
  final int netMins;

  CheckOutResponse({
    required this.success,
    required this.checkOut,
    required this.netMins,
  });

  factory CheckOutResponse.fromJson(Map<String, dynamic> json) {
    // Same nested-shape tolerance as CheckInResponse.
    final src = (json['attendance'] is Map)
        ? json['attendance'] as Map<String, dynamic>
        : (json['data'] is Map)
        ? json['data'] as Map<String, dynamic>
        : (json['record'] is Map ? json['record'] as Map<String, dynamic> : json);

    bool b(dynamic v) {
      if (v is bool) return v;
      return v?.toString().toLowerCase() == 'true';
    }

    int i(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    String s(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    return CheckOutResponse(
      success: b(json['success'] ?? true),
      checkOut: s(src['checkOut'] ??
          src['clockOut'] ??
          src['check_out'] ??
          src['punchOut'] ??
          src['time'] ??
          src['checkOutTime']),
      netMins: i(src['netMins'] ??
          src['workingMins'] ??
          src['working_minutes'] ??
          src['netMinutes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'checkOut': checkOut,
      'netMins': netMins,
    };
  }
}

/// Local Attendance State - Saved to SharedPreferences
class AttendanceState {
  final bool isCheckedIn;
  final String? checkInTime;
  final String? checkOutTime;
  final int? netMins;
  final bool? isLate;
  final bool? isHalfDay;
  final int? warningCount;
  final int? maxWarnings;
  final String? checkInId;
  final DateTime date;

  AttendanceState({
    required this.isCheckedIn,
    this.checkInTime,
    this.checkOutTime,
    this.netMins,
    this.isLate,
    this.isHalfDay,
    this.warningCount,
    this.maxWarnings,
    this.checkInId,
    required this.date,
  });

  factory AttendanceState.fromJson(Map<String, dynamic> json) {
    return AttendanceState(
      isCheckedIn: json['isCheckedIn'] ?? false,
      checkInTime: json['checkIn'],
      checkOutTime: json['checkOutTime'],
      netMins: json['netMins'],
      isLate: json['isLate'],
      isHalfDay: json['isHalfDay'],
      warningCount: json['warningCount'],
      maxWarnings: json['maxWarnings'],
      checkInId: json['checkInId'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCheckedIn': isCheckedIn,
      'checkIn': checkInTime,
      'checkOutTime': checkOutTime,
      'netMins': netMins,
      'isLate': isLate,
      'isHalfDay': isHalfDay,
      'warningCount': warningCount,
      'maxWarnings': maxWarnings,
      'checkInId': checkInId,
      'date': date.toIso8601String(),
    };
  }

  static String get storageKey => 'attendance_${DateTime.now().toIso8601String().split('T')[0]}';
}

/// A single row of the attendance history list — one calendar day's
/// punch data, as returned by GET /api/attendance.
///
/// Parsing is intentionally permissive (multiple key fallbacks, like the
/// other models in this app) since the exact backend field names for this
/// endpoint haven't been confirmed yet. Once a real sample response is
/// available, tighten this up to match it exactly.
class AttendanceLogEntry {
  final DateTime date;
  final String? checkIn;
  final String? checkOut;
  final int? workingMinutes;
  final String? workingHoursLabel;
  final String status; // present / absent / leave / half_day / weekend / holiday / pending
  final String? leaveType;
  final bool isLate;
  final bool isHalfDay;
  final String? location;

  AttendanceLogEntry({
    required this.date,
    this.checkIn,
    this.checkOut,
    this.workingMinutes,
    this.workingHoursLabel,
    required this.status,
    this.leaveType,
    this.isLate = false,
    this.isHalfDay = false,
    this.location,
  });

  bool get isWeekendDay =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  bool get isLeave => status == 'leave';
  bool get isWeekend => status == 'weekend' || status == 'holiday';
  bool get isAbsent => status == 'absent';
  bool get isPending => status == 'pending';

  static const _dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  String get dayAbbrev => _dayNames[date.weekday - 1];

  /// "09h 02m" — uses the API's own label if it sent one, otherwise
  /// derives it from minutes, otherwise shows a placeholder.
  String get formattedWorkingHours {
    if (workingHoursLabel != null && workingHoursLabel!.isNotEmpty) {
      return workingHoursLabel!;
    }
    if (workingMinutes != null) {
      final h = workingMinutes! ~/ 60;
      final m = workingMinutes! % 60;
      return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m';
    }
    return '--';
  }

  factory AttendanceLogEntry.fromJson(Map<String, dynamic> json) {
    // Some backends nest the actual record under "attendance" / "record".
    final src = (json['attendance'] is Map)
        ? json['attendance'] as Map<String, dynamic>
        : (json['record'] is Map ? json['record'] as Map<String, dynamic> : json);

    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    bool b(dynamic v) {
      if (v is bool) return v;
      return v?.toString().toLowerCase() == 'true';
    }

    int? iOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    final rawDate = src['date'] ?? src['day'] ?? src['attendanceDate'];
    DateTime parsedDate;
    try {
      parsedDate = rawDate != null ? DateTime.parse(rawDate.toString()) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final checkIn = str(src['checkIn'] ?? src['clockIn'] ?? src['check_in'] ?? src['punchIn']);
    final checkOut = str(src['checkOut'] ?? src['clockOut'] ?? src['check_out'] ?? src['punchOut']);

    final workingMinutes = iOrNull(
      src['netMins'] ?? src['net_mins'] ?? src['workingMins'] ?? src['working_minutes'] ?? src['netMinutes'],
    );
    final workingHoursLabel = str(
      src['workingHours'] ?? src['workingHrs'] ?? src['working_hours'],
    );

    final leaveType = str(src['leaveType'] ?? src['leave_type']);
    String status = (str(src['status']) ?? '').toLowerCase();

    // No explicit status from the API — make a reasonable guess from
    // whatever fields *are* present, so the UI still renders sensibly.
    if (status.isEmpty) {
      if (leaveType != null) {
        status = 'leave';
      } else if (checkIn == null && checkOut == null) {
        status = (parsedDate.weekday == DateTime.saturday || parsedDate.weekday == DateTime.sunday)
            ? 'weekend'
            : 'absent';
      } else if (checkIn != null && checkOut == null) {
        status = 'pending';
      } else {
        status = 'present';
      }
    }

    return AttendanceLogEntry(
      date: parsedDate,
      checkIn: checkIn,
      checkOut: checkOut,
      workingMinutes: workingMinutes,
      workingHoursLabel: workingHoursLabel,
      status: status,
      leaveType: leaveType,
      isLate: b(src['isLate'] ?? src['is_late']),
      isHalfDay: b(src['isHalfDay'] ?? src['is_half_day']),
      location: str(src['location'] ?? src['checkin_location']),
    );
  }
}