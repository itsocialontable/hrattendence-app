import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/admin_providers.dart';
import '../../models/admin_models.dart';

class AdminSalaryCalculateScreen extends StatefulWidget {
  const AdminSalaryCalculateScreen({super.key});

  @override
  State<AdminSalaryCalculateScreen> createState() => _AdminSalaryCalculateScreenState();
}

class _AdminSalaryCalculateScreenState extends State<AdminSalaryCalculateScreen> {
  AdminEmployee? _selectedEmployee;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminEmployeeProvider>().fetchEmployees();
      context.read<AdminSalaryProvider>().clearCalculatedResult();
    });
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Select date';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtAmt(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _fromDate : _toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _calculate() async {
    if (_selectedEmployee == null || _fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select employee, from date and to date.')),
      );
      return;
    }
    if (_toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To date cannot be before from date.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final ok = await context.read<AdminSalaryProvider>().calculateSalary(
      userId: _selectedEmployee!.id,
      fromDate: _apiDate(_fromDate!),
      toDate: _apiDate(_toDate!),
    );
    if (!ok && mounted) {
      final err = context.read<AdminSalaryProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Failed to calculate salary.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final empProv = context.watch<AdminEmployeeProvider>();
    final salaryProv = context.watch<AdminSalaryProvider>();
    final result = salaryProv.calculatedResult;

    // Safety net alongside the id-based == on AdminEmployee: if the
    // selected employee was deleted (or the list simply hasn't loaded
    // yet), don't pass a value that has zero matches in `items`.
    final dropdownValue = (_selectedEmployee != null &&
        empProv.employees.contains(_selectedEmployee))
        ? _selectedEmployee
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 44, 20, 24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child:    Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0,vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text('Calculate Salary',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                PremiumCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Employee', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AdminEmployee>(
                          isExpanded: true,
                          value: dropdownValue,
                          hint: Text(
                            empProv.isLoading ? 'Loading employees...' : 'Select an employee',
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textLight),
                          // De-duplicated by id: if the backend ever returns
                          // the same employee twice, two DropdownMenuItems
                          // would both equal `value` (since == is by id) and
                          // trip the "2 or more" branch of the same assertion.
                          items: {for (final e in empProv.employees) e.id: e}
                              .values
                              .map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text('${e.name}  •  ${e.dept}',
                                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark)),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedEmployee = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Date Range', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _DateBox(label: 'From', value: _fmtDate(_fromDate), onTap: () => _pickDate(isFrom: true))),
                      const SizedBox(width: 12),
                      Expanded(child: _DateBox(label: 'To', value: _fmtDate(_toDate), onTap: () => _pickDate(isFrom: false))),
                    ]),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: salaryProv.isCalculating ? 'Calculating...' : 'Calculate',
                      icon: salaryProv.isCalculating ? null : Icons.calculate_outlined,
                      onTap: salaryProv.isCalculating ? null : _calculate,
                    ),
                  ]),
                ),
                if (result != null) ...[
                  const SizedBox(height: 20),
                  _buildResultCard(result),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(AdminSalaryRecord r) {
    return Column(children: [
      // ── Employee header + top attendance snapshot ──────────────────────
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.darkGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(
                r.employeeName.isNotEmpty ? r.employeeName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              )),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.employeeName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(
                [r.department, r.designation].where((s) => s.isNotEmpty).join(' • '),
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.6)),
              ),
              if (r.fromDate.isNotEmpty && r.toDate.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('${r.fromDate}  →  ${r.toDate}',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.5))),
              ],
            ])),
          ]),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(children: [
            _mini('Present', '${r.presentDays}', AppColors.success),
            Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
            _mini('Half Day', '${r.halfDays}', AppColors.accent),
            Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
            _mini('Late', '${r.lateDays}', AppColors.warning),
            Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
            _mini('Absent', '${r.absentDays}', AppColors.error),
          ]),
        ]),
      ),
      const SizedBox(height: 14),

      // ── Full attendance + deduction breakdown ───────────────────────────
      PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Attendance Breakdown',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 10),
          _infoRow('Days in Month', '${r.daysInMonth}'),
          _infoRow('Sundays', '${r.sundays}'),
          _infoRow('Total Working Days', '${r.totalWorkingDays}'),
          _infoRow('Present Days', '${r.presentDays}'),
          _infoRow('Half Days', '${r.halfDays}'),
          _infoRow('Late Days', '${r.lateDays}'),
          _infoRow('Approved Leave Days', '${r.approvedLeaveDays}'),
          _infoRow('Unpaid Leave Days', '${r.unpaidLeaveDays}'),
          _infoRow('Absent Days', '${r.absentDays}'),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Text('Deductions',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 10),
          _infoRow('Half Day Deduction', _fmtAmt(r.halfDayDeduction)),
          _infoRow('Absent Deduction', _fmtAmt(r.absentDeduction)),
          _infoRow('Unpaid Leave Deduction', _fmtAmt(r.unpaidLeaveDeduction)),
          _infoRow('Total Auto Deduction', _fmtAmt(r.totalAutoDeduction), highlight: true),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Text('Salary',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 10),
          _infoRow('Basic Salary', _fmtAmt(r.basicSalary.toDouble())),
          _infoRow('Per Day Salary', _fmtAmt(r.perDaySalary)),
        ]),
      ),
      const SizedBox(height: 14),

      // ── Net salary ───────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Net Salary', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85))),
          Text(_fmtAmt(r.baseNetSalary != 0 ? r.baseNetSalary : r.netSalary.toDouble()),
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
      ),
      if (r.message.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(r.message, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
      ],
    ]);
  }

  Widget _infoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textMid)),
        Text(value, style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          color: highlight ? AppColors.error : AppColors.textDark,
        )),
      ]),
    );
  }

  Widget _mini(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.5))),
    ]));
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateBox({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
          const SizedBox(height: 2),
          Row(children: [
            Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark))),
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textLight),
          ]),
        ]),
      ),
    );
  }
}