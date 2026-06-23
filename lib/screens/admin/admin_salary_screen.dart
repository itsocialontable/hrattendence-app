import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'admin_salary_settings_screen.dart';

// ─── Models ────────────────────────────────────────────────────────────────────
class EmployeeSalaryRecord {
  final String id;
  final String name;
  final String department;
  final double monthlySalary;
  final double perDaySalary;
  final int totalWorkingDays;
  final int presentDays;
  final double halfDays; // includes late-arrival half days
  final int absentDays;
  final int approvedLeaveDays;
  final int lateDaysAfter11;    // late arrivals after 11 AM (each = 0.5 day)
  final int lateDaysAfter2PM;   // late arrivals after 2 PM (every 3 = 0.5 day)
  final double halfDayDeduction;
  final double absentDeduction;
  final double totalDeduction;
  final double netSalary;

  const EmployeeSalaryRecord({
    required this.id,
    required this.name,
    required this.department,
    required this.monthlySalary,
    required this.perDaySalary,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.halfDays,
    required this.absentDays,
    required this.approvedLeaveDays,
    required this.lateDaysAfter11,
    required this.lateDaysAfter2PM,
    required this.halfDayDeduction,
    required this.absentDeduction,
    required this.totalDeduction,
    required this.netSalary,
  });
}

// ─── Sample Data ────────────────────────────────────────────────────────────────
List<EmployeeSalaryRecord> _buildSampleData() {
  EmployeeSalaryRecord make({
    required String id,
    required String name,
    required String dept,
    required double monthly,
    required int present,
    required double halfDays,
    required int absent,
    required int leave,
    required int late11,
    required int late2pm,
  }) {
    const workingDays = 26;
    final perDay = monthly / workingDays;
    final halfDayDed = halfDays * perDay * 0.5;
    final absentDed = absent * perDay;
    final totalDed = halfDayDed + absentDed;
    final net = monthly - totalDed;
    return EmployeeSalaryRecord(
      id: id, name: name, department: dept,
      monthlySalary: monthly, perDaySalary: perDay,
      totalWorkingDays: workingDays, presentDays: present,
      halfDays: halfDays, absentDays: absent, approvedLeaveDays: leave,
      lateDaysAfter11: late11, lateDaysAfter2PM: late2pm,
      halfDayDeduction: halfDayDed, absentDeduction: absentDed,
      totalDeduction: totalDed, netSalary: net,
    );
  }

  return [
    make(id: 'GC-001', name: 'Arjun Sharma',  dept: 'Engineering', monthly: 55000, present: 24, halfDays: 0,   absent: 0, leave: 2, late11: 0, late2pm: 0),
    make(id: 'GC-002', name: 'Priya Patel',   dept: 'HR',          monthly: 42000, present: 23, halfDays: 1.0, absent: 0, leave: 2, late11: 2, late2pm: 1),
    make(id: 'GC-003', name: 'Rahul Meena',   dept: 'Sales',       monthly: 38000, present: 20, halfDays: 0.5, absent: 3, leave: 0, late11: 1, late2pm: 3),
    make(id: 'GC-004', name: 'Neha Singh',    dept: 'Finance',     monthly: 48000, present: 25, halfDays: 0,   absent: 1, leave: 0, late11: 0, late2pm: 0),
    make(id: 'GC-005', name: 'Vijay Kumar',   dept: 'Operations',  monthly: 35000, present: 22, halfDays: 1.5, absent: 2, leave: 0, late11: 3, late2pm: 4),
    make(id: 'GC-006', name: 'Sunita Verma',  dept: 'Marketing',   monthly: 44000, present: 26, halfDays: 0,   absent: 0, leave: 0, late11: 0, late2pm: 0),
    make(id: 'GC-007', name: 'Amit Joshi',    dept: 'Engineering', monthly: 62000, present: 21, halfDays: 1.0, absent: 2, leave: 2, late11: 2, late2pm: 2),
    make(id: 'GC-008', name: 'Kavita Rao',    dept: 'Design',      monthly: 40000, present: 24, halfDays: 0.5, absent: 1, leave: 0, late11: 1, late2pm: 0),
  ];
}

// ─── Screen ────────────────────────────────────────────────────────────────────
class AdminSalaryScreen extends StatefulWidget {
  const AdminSalaryScreen({super.key});

  @override
  State<AdminSalaryScreen> createState() => _AdminSalaryScreenState();
}

class _AdminSalaryScreenState extends State<AdminSalaryScreen> {
  final List<EmployeeSalaryRecord> _allRecords = _buildSampleData();
  String _search = '';
  String _selectedMonth = 'Jun 2026';
  String _filterDept = 'All';
  EmployeeSalaryRecord? _selectedEmployee;

  static const _months = [
    'Jun 2026', 'May 2026', 'Apr 2026', 'Mar 2026',
  ];

  List<String> get _departments {
    final depts = _allRecords.map((e) => e.department).toSet().toList()..sort();
    return ['All', ...depts];
  }

  List<EmployeeSalaryRecord> get _filtered => _allRecords.where((r) {
    final matchSearch = r.name.toLowerCase().contains(_search.toLowerCase()) ||
        r.id.toLowerCase().contains(_search.toLowerCase());
    final matchDept = _filterDept == 'All' || r.department == _filterDept;
    return matchSearch && matchDept;
  }).toList();

  String _fmt(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  double get _totalPayroll =>
      _filtered.fold(0.0, (sum, r) => sum + r.netSalary);
  double get _totalDeductions =>
      _filtered.fold(0.0, (sum, r) => sum + r.totalDeduction);

  @override
  Widget build(BuildContext context) {
    if (_selectedEmployee != null) {
      return _buildDetailView(_selectedEmployee!);
    }
    return _buildListView();
  }

  // ── List View ───────────────────────────────────────────────────────────────
  Widget _buildListView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 44, 20, 20),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Salary Management',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _selectedMonth,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Settings shortcut
                    // GestureDetector(
                    //   onTap: () => Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (_) =>
                    //           const AdminSalarySettingsScreen(),
                    //     ),
                    //   ),
                    //   child: Container(
                    //     padding: const EdgeInsets.all(10),
                    //     decoration: BoxDecoration(
                    //       color: Colors.white.withOpacity(0.15),
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //     child: const Icon(Icons.tune_rounded,
                    //         color: Colors.white, size: 20),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 16),
                // Summary row
                Row(
                  children: [
                    _headerStat('Total Payroll', _fmt(_totalPayroll),
                        Icons.account_balance_wallet_outlined),
                    Container(
                        width: 1,
                        height: 36,
                        color: Colors.white.withOpacity(0.2)),
                    _headerStat('Total Deductions', _fmt(_totalDeductions),
                        Icons.remove_circle_outline),
                    Container(
                        width: 1,
                        height: 36,
                        color: Colors.white.withOpacity(0.2)),
                    _headerStat('Employees',
                        '${_filtered.length}', Icons.people_outline),
                  ],
                ),
              ],
            ),
          ),

          // Month Picker
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _months.length,
              itemBuilder: (_, i) {
                final active = _months[i] == _selectedMonth;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMonth = _months[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: active ? AppColors.primaryGradient : null,
                      color: active ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: active ? AppShadow.strong : AppShadow.subtle,
                    ),
                    child: Text(
                      _months[i],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.textMid,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Search + Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadow.subtle,
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Search employee...',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textLight),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColors.textLight),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Dept filter
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadow.subtle,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterDept,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: AppColors.textMid),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500),
                      items: _departments
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _filterDept = v ?? 'All'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _employeeSalaryCard(_filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _employeeSalaryCard(EmployeeSalaryRecord r) {
    final hasDeduction = r.totalDeduction > 0;
    return GestureDetector(
      onTap: () => setState(() => _selectedEmployee = r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadow.card,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      r.name[0],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${r.id} • ${r.department}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmt(r.netSalary),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Net Salary',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.textLight),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _miniChip('Present', '${r.presentDays}d',
                      AppColors.success),
                  _miniChip('Half Day', '${r.halfDays}',
                      AppColors.warning),
                  _miniChip('Absent', '${r.absentDays}d',
                      AppColors.error),
                  _miniChip('Leave', '${r.approvedLeaveDays}d',
                      AppColors.secondary),
                ],
              ),
            ),

            // Deduction badge
            if (hasDeduction) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  // Half day detail
                  if (r.lateDaysAfter11 > 0)
                    _deductBadge(
                      '${r.lateDaysAfter11}× late >11AM',
                      AppColors.warning,
                    ),
                  if (r.lateDaysAfter2PM > 0)
                    _deductBadge(
                      '${r.lateDaysAfter2PM}× late >2PM',
                      AppColors.accent,
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '−${_fmt(r.totalDeduction)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 9, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _deductBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ── Detail View ─────────────────────────────────────────────────────────────
  Widget _buildDetailView(EmployeeSalaryRecord r) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textDark),
          onPressed: () => setState(() => _selectedEmployee = null),
        ),
        title: Text(
          'Salary Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _selectedMonth,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Hero card
          _detailHeroCard(r),
          const SizedBox(height: 16),

          // Attendance summary
          _detailAttendanceCard(r),
          const SizedBox(height: 16),

          // Half Day Rule Breakdown
          if (r.lateDaysAfter11 > 0 || r.lateDaysAfter2PM > 0)
            _halfDayBreakdownCard(r),
          if (r.lateDaysAfter11 > 0 || r.lateDaysAfter2PM > 0)
            const SizedBox(height: 16),

          // Deduction Breakdown
          _detailDeductionCard(r),
          const SizedBox(height: 16),

          // Net Salary
          _detailNetCard(r),
        ],
      ),
    );
  }

  Widget _detailHeroCard(EmployeeSalaryRecord r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    r.name[0],
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${r.id} • ${r.department}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            children: [
              _detailMini('Monthly', _fmt(r.monthlySalary), AppColors.primary),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.1)),
              _detailMini('Deduction', _fmt(r.totalDeduction), AppColors.accent),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.1)),
              _detailMini('Net Salary', _fmt(r.netSalary), AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailMini(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailAttendanceCard(EmployeeSalaryRecord r) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Attendance Summary', '${r.totalWorkingDays} working days'),
          const SizedBox(height: 16),
          Row(
            children: [
              _attBadge('Present', r.presentDays, AppColors.success,
                  Icons.check_circle_rounded),
              const SizedBox(width: 8),
              _attBadge('Half Day', r.halfDays, AppColors.warning,
                  Icons.brightness_4_rounded),
              const SizedBox(width: 8),
              _attBadge('Absent', r.absentDays, AppColors.error,
                  Icons.cancel_rounded),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _attBadge('Leave', r.approvedLeaveDays, AppColors.secondary,
                  Icons.beach_access_rounded),
              const SizedBox(width: 8),
              _attBadge('Late >11AM', r.lateDaysAfter11, AppColors.warning,
                  Icons.schedule_rounded),
              const SizedBox(width: 8),
              _attBadge('Late >2PM', r.lateDaysAfter2PM, AppColors.accent,
                  Icons.watch_later_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _halfDayBreakdownCard(EmployeeSalaryRecord r) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Half Day Rule Breakdown', 'Why half days were applied'),
          const SizedBox(height: 14),
          if (r.lateDaysAfter11 > 0)
            _ruleBreakdownRow(
              icon: Icons.schedule_rounded,
              color: AppColors.warning,
              title: 'Late Arrival after 11:00 AM',
              detail:
                  '${r.lateDaysAfter11} occurrences × 0.5 day each = ${(r.lateDaysAfter11 * 0.5).toStringAsFixed(1)} half days',
              deduction: _fmt(r.lateDaysAfter11 * 0.5 * r.perDaySalary * 0.5),
            ),
          if (r.lateDaysAfter11 > 0 && r.lateDaysAfter2PM > 0)
            const Divider(height: 16, color: AppColors.border),
          if (r.lateDaysAfter2PM > 0)
            _ruleBreakdownRow(
              icon: Icons.watch_later_outlined,
              color: AppColors.accent,
              title: 'Late Arrival after 2:00 PM',
              detail:
                  '${r.lateDaysAfter2PM} occurrences ÷ 3 = ${(r.lateDaysAfter2PM / 3).toStringAsFixed(1)} half days',
              deduction:
                  _fmt((r.lateDaysAfter2PM / 3) * r.perDaySalary * 0.5),
            ),
        ],
      ),
    );
  }

  Widget _ruleBreakdownRow({
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
    required String deduction,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                detail,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textLight, height: 1.4),
              ),
            ],
          ),
        ),
        Text(
          '−$deduction',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _detailDeductionCard(EmployeeSalaryRecord r) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Deduction Breakdown', ''),
          const SizedBox(height: 14),
          _deductRow('Monthly Salary', _fmt(r.monthlySalary),
              AppColors.primary, Icons.payments_rounded,
              isEarning: true),
          const Divider(height: 20, color: AppColors.border),
          if (r.halfDayDeduction > 0)
            _deductRow(
              'Half Day Deduction (${r.halfDays} days)',
              _fmt(r.halfDayDeduction),
              AppColors.warning,
              Icons.brightness_4_rounded,
            ),
          if (r.absentDeduction > 0)
            _deductRow(
              'Absent Deduction (${r.absentDays} days)',
              _fmt(r.absentDeduction),
              AppColors.error,
              Icons.cancel_rounded,
            ),
          if (r.totalDeduction == 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up_rounded,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'No deductions this month! 🎉',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _deductRow(String label, String amount, Color color, IconData icon,
      {bool isEarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${isEarning ? '+' : '-'}$amount',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isEarning ? AppColors.success : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailNetCard(EmployeeSalaryRecord r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Salary',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                _fmt(r.netSalary),
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_fmt(r.monthlySalary)} − ${_fmt(r.totalDeduction)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              Text(
                '= ${_fmt(r.netSalary)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardTitle(String title, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        if (sub.isNotEmpty)
          Text(
            sub,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textLight),
          ),
      ],
    );
  }

  Widget _attBadge(String label, num value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value is double && value != value.roundToDouble()
                  ? value.toStringAsFixed(1)
                  : value.toInt().toString(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
