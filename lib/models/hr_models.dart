class AttendanceRecord {
  final DateTime date;
  final String punchIn;
  final String punchOut;
  final String status;
  final double workingHours;
  bool salaryDeducted;
  AttendanceRecord({required this.date, required this.punchIn, required this.punchOut, required this.status, required this.workingHours, this.salaryDeducted = false});
}

class LeaveApplication {
  final String id;
  final String type;
  final String fromDate;
  final String toDate;
  final int days;
  String status;
  final String reason;
  final DateTime appliedOn;
  LeaveApplication({required this.id, required this.type, required this.fromDate, required this.toDate, required this.days, required this.status, required this.reason, required this.appliedOn});
}

class SalarySlip {
  final String month;
  final double basicSalary;
  final double hra;
  final double conveyance;
  final double medical;
  final double deductions;
  final double lateDeductions;
  final double netSalary;
  final String status;
  SalarySlip({required this.month, required this.basicSalary, required this.hra, required this.conveyance, required this.medical, required this.deductions, required this.lateDeductions, required this.netSalary, required this.status});
}
