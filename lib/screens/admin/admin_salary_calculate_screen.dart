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
                child: Text('Calculate Salary',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
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
                          value: _selectedEmployee,
                          hint: Text(
                            empProv.isLoading ? 'Loading employees...' : 'Select an employee',
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textLight),
                          items: empProv.employees.map((e) {
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
                r.employeeName.isNotEmpty ? r.employeeName[0] : '?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              )),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.employeeName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(r.department, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.6))),
            ])),
          ]),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(children: [
            _mini('Present', '${r.presentDays}', AppColors.primary),
            Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
            _mini('Leave', '${r.leaveDays}', AppColors.accent),
            Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
            _mini('Deductions', _fmtAmt(r.deductions.toDouble()), AppColors.error),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Net Salary', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85))),
          Text(_fmtAmt(r.netSalary.toDouble()), style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
      ),
    ]);
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
