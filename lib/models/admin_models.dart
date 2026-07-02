/// Complete admin data models.
/// Mirrors every field seen in the screenshot API spec and codebase.

// ── Auth ──────────────────────────────────────────────────────────────────────

class AdminRegisterResponse {
  final String message;
  final String? adminId;

  AdminRegisterResponse({required this.message, this.adminId});

  factory AdminRegisterResponse.fromJson(Map<String, dynamic> j) =>
      AdminRegisterResponse(
        message: j['message'] ?? 'Admin registered successfully.',
        // adminId: j['adminId'] ?? j['id'],
      );
}

// ── Dashboard Stats ───────────────────────────────────────────────────────────

class AdminDashboardStats {
  final int totalEmployees;
  final int presentToday;
  final int onLeave;
  final int absent;
  final int lateToday;
  final double attendanceRate;
  final List<DeptStats> departmentBreakdown;

  AdminDashboardStats({
    required this.totalEmployees,
    required this.presentToday,
    required this.onLeave,
    required this.absent,
    required this.lateToday,
    required this.attendanceRate,
    required this.departmentBreakdown,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> j) =>
      AdminDashboardStats(
        totalEmployees: _int(j['totalEmployees'] ?? j['total_employees'] ?? 0),
        presentToday: _int(j['presentToday'] ?? j['present_today'] ?? 0),
        onLeave: _int(j['onLeave'] ?? j['on_leave'] ?? 0),
        absent: _int(j['absentToday'] ?? 0),
        lateToday: _int(j['lateToday'] ?? j['late_today'] ?? 0),
        attendanceRate: _double(j['attendanceRate'] ?? j['attendance_rate'] ?? 0),
        departmentBreakdown: ((j['departmentBreakdown'] ??
            j['department_breakdown'] ??
            []) as List)
            .map((e) => DeptStats.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Fallback when API is unavailable — keeps UI renderable.
  factory AdminDashboardStats.empty() => AdminDashboardStats(
    totalEmployees: 0,
    presentToday: 0,
    onLeave: 0,
    absent: 0,
    lateToday: 0,
    attendanceRate: 0,
    departmentBreakdown: [],
  );
}

class DeptStats {
  final String department;
  final int total;
  final int present;

  DeptStats({required this.department, required this.total, required this.present});

  factory DeptStats.fromJson(Map<String, dynamic> j) => DeptStats(
    department: j['department'] ?? j['dept'] ?? '',
    total: _int(j['total'] ?? 0),
    present: _int(j['present'] ?? 0),
  );
}

// ── Employee ──────────────────────────────────────────────────────────────────

class AdminEmployee {
  final String id;
  final String name;
  final String? fullName;
  final String? lName;
  final String username;
  final String email;
  final String role; // 'employee' | 'admin'
  final String? adminId;
  final String dept;
  final String designation;
  final int salary;
  final String joinDate;
  final String? phone;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? empId;
  final String? emergencyContact;
  final String? shiftType;
  final bool isActive;
  // Bank & ID fields
  final String? bankAccountNo;
  final String? bankName;
  final String? bankBranch;
  final String? bankIfsc;
  final String? aadharNo;
  final String? panNo;

  AdminEmployee({
    required this.id,
    required this.name,
    this.fullName,
    this.lName,
    required this.username,
    required this.email,
    required this.role,
    this.adminId,
    required this.dept,
    required this.designation,
    required this.salary,
    required this.joinDate,
    this.phone,
    this.gender,
    this.bloodGroup,
    this.address,
    this.empId,
    this.emergencyContact,
    this.shiftType,
    this.isActive = true,
    this.bankAccountNo,
    this.bankName,
    this.bankBranch,
    this.bankIfsc,
    this.aadharNo,
    this.panNo,
  });

  factory AdminEmployee.fromJson(Map<String, dynamic> j) => AdminEmployee(
    id: j['id'] ?? j['_id'] ?? '',
    name: j['name'] ?? '',
    fullName: j['fullName'] ?? j['full_name'],
    lName: j['lName'] ?? j['l_name'] ?? j['lastName'],
    username: j['username'] ?? '',
    email: j['email'] ?? '',
    role: j['role'] ?? 'employee',
    adminId: j['admin_id'] ?? j['adminId'],
    dept: j['dept'] ?? j['department'] ?? '',
    designation: j['designation'] ?? '',
    salary: _int(j['salary'] ?? 0),
    joinDate: j['joinDate'] ?? j['join_date'] ?? '',
    phone: j['phone'] ?? j['phoneNo'],
    gender: j['gender'],
    bloodGroup: j['bloodGroup'] ?? j['blood_group'],
    address: j['address'],
    empId: j['emp_id'] ?? j['empId'],
    emergencyContact: j['emergencyContact'] ?? j['emergency_contact'],
    shiftType: j['shiftType'] ?? j['shift_type'],
    isActive: j['isActive'] ?? j['is_active'] ?? true,
    bankAccountNo: j['bank_ac_no'] ?? j['bankAccountNo'],
    bankName: j['bank_name'] ?? j['bankName'],
    bankBranch: j['bank_branch'] ?? j['bankBranch'],
    bankIfsc: j['bank_ifsc'] ?? j['bankIfsc'],
    aadharNo: j['aadhar_no'] ?? j['aadharNo'],
    panNo: j['pan_no'] ?? j['panNo'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (fullName != null) 'fullName': fullName,
    if (lName != null) 'lName': lName,
    'username': username,
    'email': email,
    'role': role,
    if (adminId != null) 'admin_id': adminId,
    'dept': dept,
    'designation': designation,
    'salary': salary,
    'joinDate': joinDate,
    if (phone != null) 'phone': phone,
    if (gender != null) 'gender': gender,
    if (bloodGroup != null) 'bloodGroup': bloodGroup,
    if (address != null) 'address': address,
    if (empId != null) 'emp_id': empId,
    if (emergencyContact != null) 'emergencyContact': emergencyContact,
    if (shiftType != null) 'shiftType': shiftType,
    'isActive': isActive,
    if (bankAccountNo != null) 'bank_ac_no': bankAccountNo,
    if (bankName != null) 'bank_name': bankName,
    if (bankBranch != null) 'bank_branch': bankBranch,
    if (bankIfsc != null) 'bank_ifsc': bankIfsc,
    if (aadharNo != null) 'aadhar_no': aadharNo,
    if (panNo != null) 'pan_no': panNo,
  };
}

class AdminEmployeeInput {
  final String fullName;
  final String lName;
  final String username;
  final String email;
  final String password;
  final String role;
  final String dept;
  final String designation;
  final int salary;
  final String joinDate;
  final String? phone;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? emergencyContact;
  final String? shiftType;
  final String? bankAccountNo;
  final String? bankName;
  final String? bankBranch;
  final String? bankIfsc;
  final String? aadharNo;
  final String? panNo;

  AdminEmployeeInput({
    required this.fullName,
    required this.lName,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.dept,
    required this.designation,
    required this.salary,
    required this.joinDate,
    this.phone,
    this.gender,
    this.bloodGroup,
    this.address,
    this.emergencyContact,
    this.shiftType,
    this.bankAccountNo,
    this.bankName,
    this.bankBranch,
    this.bankIfsc,
    this.aadharNo,
    this.panNo,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'lName': lName,
    'username': username,
    'email': email,
    'password': password,
    'role': role,
    'dept': dept,
    'designation': designation,
    'salary': salary,
    'join_date': joinDate,
    if (phone != null) 'phone': phone,
    if (gender != null) 'gender': gender,
    if (bloodGroup != null) 'bloodGroup': bloodGroup,
    if (address != null) 'address': address,
    if (emergencyContact != null) 'emergency_contact': emergencyContact,
    if (shiftType != null) 'shiftType': shiftType,
    if (bankAccountNo != null) 'bank_ac_no': bankAccountNo,
    if (bankName != null) 'bank_name': bankName,
    if (bankBranch != null) 'bank_branch': bankBranch,
    if (bankIfsc != null) 'bank_ifsc': bankIfsc,
    if (aadharNo != null) 'aadhar_no': aadharNo,
    if (panNo != null) 'pan_no': panNo,
  };
}

// ── Attendance ────────────────────────────────────────────────────────────────

class AdminAttendanceRecord {
  final String id;
  final String userId;
  final String employeeName;
  final String department;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String? workingHours;
  final String status; // Present | Absent | Late | Half Day | Holiday
  final bool isManual;
  final String? note;

  AdminAttendanceRecord({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.department,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.workingHours,
    required this.status,
    this.isManual = false,
    this.note,
  });

  factory AdminAttendanceRecord.fromJson(Map<String, dynamic> j) =>
      AdminAttendanceRecord(
        id: j['id'] ?? j['_id'] ?? '',
        userId: j['userId'] ?? j['user_id'] ?? j['employeeId'] ?? '',
        employeeName: j['employeeName'] ?? j['employee_name'] ?? j['name'] ?? '',
        department: j['department'] ?? j['dept'] ?? '',
        date: j['date'] ?? '',
        checkIn: j['checkIn'] ?? j['check_in'],
        checkOut: j['checkOut'] ?? j['check_out'],
        workingHours: j['workingHours'] ?? j['working_hours'],
        status: j['status'] ?? 'Unknown',
        isManual: j['isManual'] ?? j['is_manual'] ?? false,
        note: j['note'],
      );
}

class AdminAttendanceInput {
  final String userId;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String? note;

  AdminAttendanceInput({
    required this.userId,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'date': date,
    if (checkIn != null) 'checkIn': checkIn,
    if (checkOut != null) 'checkOut': checkOut,
    'status': status,
    if (note != null) 'note': note,
  };
}

// ── Leave ─────────────────────────────────────────────────────────────────────

class AdminLeaveRequest {
  final String id;
  final String userId;
  final String employeeName;
  final String department;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final int totalDays;
  final String reason;
  final String appliedOn;
  final String status; // pending | approved | rejected
  final String? managerRemark;
  final String? approvedBy;

  AdminLeaveRequest({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.department,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.reason,
    required this.appliedOn,
    required this.status,
    this.managerRemark,
    this.approvedBy,
  });

  factory AdminLeaveRequest.fromJson(Map<String, dynamic> j) =>
      AdminLeaveRequest(
        id: j['id'] ?? j['_id'] ?? '',
        userId: j['userId'] ?? j['user_id'] ?? '',
        employeeName: j['employeeName'] ?? j['employee_name'] ?? j['name'] ?? '',
        department: j['department'] ?? j['dept'] ?? '',
        leaveType: j['type'] ?? '',
        fromDate: j['fromDate'] ?? j['from_date'] ?? '',
        toDate: j['toDate'] ?? j['to_date'] ?? '',
        totalDays: _int(j['totalDays'] ?? j['days'] ?? 0),
        reason: j['reason'] ?? '',
        appliedOn: j['appliedOn'] ?? j['applied_on'] ?? '',
        status: j['status'] ?? 'pending',
        managerRemark: j['managerRemark'] ?? j['manager_remark'] ?? j['remark'],
        approvedBy: j['approvedBy'] ?? j['approved_by'],
      );

  AdminLeaveRequest copyWith({String? status, String? managerRemark, String? approvedBy}) =>
      AdminLeaveRequest(
        id: id,
        userId: userId,
        employeeName: employeeName,
        department: department,
        leaveType: leaveType,
        fromDate: fromDate,
        toDate: toDate,
        totalDays: totalDays,
        reason: reason,
        appliedOn: appliedOn,
        status: status ?? this.status,
        managerRemark: managerRemark ?? this.managerRemark,
        approvedBy: approvedBy ?? this.approvedBy,
      );
}

// ── Salary ────────────────────────────────────────────────────────────────────

class AdminSalaryRecord {
  final String id;
  final String userId;
  final String employeeName;
  final String department;
  final String month;
  final int basicSalary;
  final int allowances;
  final int deductions;
  final int netSalary;
  final int presentDays;
  final int leaveDays;
  final String status; // paid | pending | processing

  // Attendance summary (mirrors employee-facing SalaryResponse fields)
  final int totalWorkingDays;
  final int offDays;
  final double absentDays;
  final double halfDays;
  final int lateDays;

  AdminSalaryRecord({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.department,
    required this.month,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.netSalary,
    required this.presentDays,
    required this.leaveDays,
    required this.status,
    this.totalWorkingDays = 0,
    this.offDays = 0,
    this.absentDays = 0,
    this.halfDays = 0,
    this.lateDays = 0,
  });

  factory AdminSalaryRecord.fromJson(Map<String, dynamic> j) =>
      AdminSalaryRecord(
        id: j['id'] ?? j['_id'] ?? '',
        userId: j['userId'] ?? j['user_id'] ?? '',
        employeeName: j['employeeName'] ?? j['employee_name'] ?? j['name'] ?? '',
        department: j['department'] ?? j['dept'] ?? '',
        month: j['month'] ?? '',
        basicSalary: _int(j['basicSalary'] ?? j['basic_salary'] ?? j['monthlySalary'] ?? j['salary'] ?? 0),
        allowances: _int(j['allowances'] ?? 0),
        deductions: _int(j['deductions'] ?? j['deduction'] ?? 0),
        netSalary: _int(j['netSalary'] ?? j['net_salary'] ?? 0),
        presentDays: _int(j['presentDays'] ?? j['present_days'] ?? 0),
        leaveDays: _int(j['leaveDays'] ?? j['leave_days'] ?? j['approvedLeaveDays'] ?? 0),
        status: j['status'] ?? 'pending',
        totalWorkingDays: _int(j['totalWorkingDays'] ?? j['total_working_days'] ?? j['workingDays'] ?? 0),
        offDays: _int(j['offDays'] ?? j['off_days'] ??
            ((j['sundays'] ?? j['satOffDays']) != null
                ? _int(j['sundays'] ?? 0) + _int(j['satOffDays'] ?? 0)
                : 0)),
        absentDays: _dbl(j['absentDays'] ?? j['absent_days'] ?? 0),
        halfDays: _dbl(j['halfDays'] ?? j['half_days'] ?? 0),
        lateDays: _int(j['lateDays'] ?? j['late_days'] ?? 0),
      );
}

class AdminPayrollResult {
  final String message;
  final int processed;
  final String month;

  AdminPayrollResult(
      {required this.message, required this.processed, required this.month});

  factory AdminPayrollResult.fromJson(Map<String, dynamic> j) =>
      AdminPayrollResult(
        message: j['message'] ?? 'Payroll generated.',
        processed: _int(j['processed'] ?? j['count'] ?? 0),
        month: j['month'] ?? '',
      );
}

// ── Settings — Attendance Rules ───────────────────────────────────────────────

class AdminAttendanceRules {
  final String officeStartTime;   // e.g. "09:00"
  final String officeEndTime;     // e.g. "18:00"
  final int lateGracePeriodMins;
  final int halfDayThresholdHours;
  final int minWorkingHours;
  final bool allowWeekendWork;
  final List<String> workingDays; // ["Mon","Tue","Wed","Thu","Fri"]
  final int casualLeaveQuota;
  final int sickLeaveQuota;
  final int annualLeaveQuota;

  AdminAttendanceRules({
    required this.officeStartTime,
    required this.officeEndTime,
    required this.lateGracePeriodMins,
    required this.halfDayThresholdHours,
    required this.minWorkingHours,
    required this.allowWeekendWork,
    required this.workingDays,
    required this.casualLeaveQuota,
    required this.sickLeaveQuota,
    required this.annualLeaveQuota,
  });

  factory AdminAttendanceRules.fromJson(Map<String, dynamic> j) {
    final rules = (j['rules'] ?? j) as Map<String, dynamic>;
    return AdminAttendanceRules(
      officeStartTime: rules['officeStartTime'] ?? rules['office_start_time'] ?? '09:00',
      officeEndTime: rules['officeEndTime'] ?? rules['office_end_time'] ?? '18:00',
      lateGracePeriodMins: _int(rules['lateGracePeriodMins'] ?? rules['late_grace_period_mins'] ?? 15),
      halfDayThresholdHours: _int(rules['halfDayThresholdHours'] ?? rules['half_day_threshold_hours'] ?? 4),
      minWorkingHours: _int(rules['minWorkingHours'] ?? rules['min_working_hours'] ?? 8),
      allowWeekendWork: rules['allowWeekendWork'] ?? rules['allow_weekend_work'] ?? false,
      workingDays: List<String>.from(
          rules['workingDays'] ?? rules['working_days'] ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']),
      casualLeaveQuota: _int(rules['casualLeaveQuota'] ?? rules['casual_leave_quota'] ?? 12),
      sickLeaveQuota: _int(rules['sickLeaveQuota'] ?? rules['sick_leave_quota'] ?? 12),
      annualLeaveQuota: _int(rules['annualLeaveQuota'] ?? rules['annual_leave_quota'] ?? 15),
    );
  }

  factory AdminAttendanceRules.defaults() => AdminAttendanceRules(
    officeStartTime: '09:00',
    officeEndTime: '18:00',
    lateGracePeriodMins: 15,
    halfDayThresholdHours: 4,
    minWorkingHours: 8,
    allowWeekendWork: false,
    workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    casualLeaveQuota: 12,
    sickLeaveQuota: 12,
    annualLeaveQuota: 15,
  );

  AdminAttendanceRules copyWith({
    String? officeStartTime,
    String? officeEndTime,
    int? lateGracePeriodMins,
    int? halfDayThresholdHours,
    int? minWorkingHours,
    bool? allowWeekendWork,
    List<String>? workingDays,
    int? casualLeaveQuota,
    int? sickLeaveQuota,
    int? annualLeaveQuota,
  }) =>
      AdminAttendanceRules(
        officeStartTime: officeStartTime ?? this.officeStartTime,
        officeEndTime: officeEndTime ?? this.officeEndTime,
        lateGracePeriodMins: lateGracePeriodMins ?? this.lateGracePeriodMins,
        halfDayThresholdHours: halfDayThresholdHours ?? this.halfDayThresholdHours,
        minWorkingHours: minWorkingHours ?? this.minWorkingHours,
        allowWeekendWork: allowWeekendWork ?? this.allowWeekendWork,
        workingDays: workingDays ?? this.workingDays,
        casualLeaveQuota: casualLeaveQuota ?? this.casualLeaveQuota,
        sickLeaveQuota: sickLeaveQuota ?? this.sickLeaveQuota,
        annualLeaveQuota: annualLeaveQuota ?? this.annualLeaveQuota,
      );

  Map<String, dynamic> toJson() => {
    'officeStartTime': officeStartTime,
    'officeEndTime': officeEndTime,
    'lateGracePeriodMins': lateGracePeriodMins,
    'halfDayThresholdHours': halfDayThresholdHours,
    'minWorkingHours': minWorkingHours,
    'allowWeekendWork': allowWeekendWork,
    'workingDays': workingDays,
    'casualLeaveQuota': casualLeaveQuota,
    'sickLeaveQuota': sickLeaveQuota,
    'annualLeaveQuota': annualLeaveQuota,
  };
}

// ── Settings — Global ─────────────────────────────────────────────────────────

class AdminGlobalSettings {
  final String companyName;
  final String companyEmail;
  final String? companyPhone;
  final String? companyAddress;
  final String currency;
  final String timezone;
  final bool emailNotifications;
  final bool autoPayroll;

  AdminGlobalSettings({
    required this.companyName,
    required this.companyEmail,
    this.companyPhone,
    this.companyAddress,
    required this.currency,
    required this.timezone,
    required this.emailNotifications,
    required this.autoPayroll,
  });

  factory AdminGlobalSettings.fromJson(Map<String, dynamic> j) {
    final s = (j['settings'] ?? j) as Map<String, dynamic>;
    return AdminGlobalSettings(
      companyName: s['companyName'] ?? s['company_name'] ?? '',
      companyEmail: s['companyEmail'] ?? s['company_email'] ?? '',
      companyPhone: s['companyPhone'] ?? s['company_phone'],
      companyAddress: s['companyAddress'] ?? s['company_address'],
      currency: s['currency'] ?? 'INR',
      timezone: s['timezone'] ?? 'Asia/Kolkata',
      emailNotifications: s['emailNotifications'] ?? s['email_notifications'] ?? true,
      autoPayroll: s['autoPayroll'] ?? s['auto_payroll'] ?? false,
    );
  }

  AdminGlobalSettings copyWith({
    String? companyName,
    String? companyEmail,
    String? companyPhone,
    String? companyAddress,
    String? currency,
    String? timezone,
    bool? emailNotifications,
    bool? autoPayroll,
  }) =>
      AdminGlobalSettings(
        companyName: companyName ?? this.companyName,
        companyEmail: companyEmail ?? this.companyEmail,
        companyPhone: companyPhone ?? this.companyPhone,
        companyAddress: companyAddress ?? this.companyAddress,
        currency: currency ?? this.currency,
        timezone: timezone ?? this.timezone,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        autoPayroll: autoPayroll ?? this.autoPayroll,
      );

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'companyEmail': companyEmail,
    if (companyPhone != null) 'companyPhone': companyPhone,
    if (companyAddress != null) 'companyAddress': companyAddress,
    'currency': currency,
    'timezone': timezone,
    'emailNotifications': emailNotifications,
    'autoPayroll': autoPayroll,
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

int _int(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _dbl(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

double _double(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}