import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/admin_providers.dart';
import '../../models/admin_models.dart';
import 'admin_salary_settings_screen.dart';

class AdminSalaryScreen extends StatefulWidget {
  const AdminSalaryScreen({super.key});

  @override
  State<AdminSalaryScreen> createState() => _AdminSalaryScreenState();
}

class _AdminSalaryScreenState extends State<AdminSalaryScreen> {
  String _search = '';
  String _filterDept = 'All';
  String _selectedMonth = '';
  AdminSalaryRecord? _selectedRecord;

  // Month list — current + 3 previous
  late final List<String> _months;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _months = List.generate(4, (i) {
      final d = DateTime(now.year, now.month - i);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[d.month - 1]} ${d.year}';
    });
    _selectedMonth = _months[0];

    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  String get _apiMonth {
    // Convert "Jun 2026" → "2026-06"
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final parts = _selectedMonth.split(' ');
    final m = (months.indexOf(parts[0]) + 1).toString().padLeft(2, '0');
    return '${parts[1]}-$m';
  }

  void _fetch() => context.read<AdminSalaryProvider>().fetchSalaries(month: _apiMonth);

  // Format helper — divides into L/K units and trims trailing ".0"
  // so amounts read as ₹20K, ₹1L instead of the old ₹20000.0K style.
  String _fmt(double amount) {
    String trim(double v) {
      final s = v.toStringAsFixed(1);
      return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    }
    if (amount >= 100000) return '₹${trim(amount / 100000)}L';
    if (amount >= 1000)   return '₹${trim(amount / 1000)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  // Formats day counts (int or half-day double) — e.g. 20, 0.5, 1
  String _fmtDays(num v) {
    if (v is int) return v.toString();
    final d = v.toDouble();
    return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
  }

  List<AdminSalaryRecord> get _filtered {
    final prov = context.read<AdminSalaryProvider>();
    return prov.salaries.where((r) {
      final matchSearch = r.employeeName.toLowerCase().contains(_search.toLowerCase()) ||
          r.userId.toLowerCase().contains(_search.toLowerCase());
      final matchDept = _filterDept == 'All' || r.department == _filterDept;
      return matchSearch && matchDept;
    }).toList();
  }

  List<String> get _departments {
    final prov = context.read<AdminSalaryProvider>();
    final depts = prov.salaries.map((r) => r.department).toSet().toList()..sort();
    return ['All', ...depts];
  }

  double get _totalPayroll   => _filtered.fold(0.0, (s, r) => s + r.netSalary);
  double get _totalDeductions => _filtered.fold(0.0, (s, r) => s + r.deductions);

  @override
  Widget build(BuildContext context) {
    if (_selectedRecord != null) return _buildDetailView(_selectedRecord!);
    return _buildListView();
  }

  // ── List View ───────────────────────────────────────────────────────────────
  Widget _buildListView() {
    final prov = context.watch<AdminSalaryProvider>();
    final filtered = prov.isLoading ? <AdminSalaryRecord>[] : _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header — exact same gradient as original
        Container(
          padding: const EdgeInsets.fromLTRB(20, 44, 20, 20),
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text('Salary Management',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
                Text(_selectedMonth,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.7))),
              ])),
              // Generate payroll button
              GestureDetector(
                onTap: prov.isGenerating ? null : () => _generate(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: prov.isGenerating
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 20),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Summary row
            Row(children: [
              _headerStat('Total Payroll', _fmt(_totalPayroll), Icons.account_balance_wallet_outlined),
              Container(width: 1, height: 36, color: Colors.white.withOpacity(0.2)),
              _headerStat('Total Deductions', _fmt(_totalDeductions), Icons.remove_circle_outline),
              Container(width: 1, height: 36, color: Colors.white.withOpacity(0.2)),
              _headerStat('Employees', '${filtered.length}', Icons.people_outline),
            ]),
          ]),
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
                onTap: () {
                  setState(() => _selectedMonth = _months[i]);
                  context.read<AdminSalaryProvider>().fetchSalaries(month: _apiMonth);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: active ? AppColors.primaryGradient : null,
                    color: active ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: active ? AppShadow.strong : AppShadow.subtle,
                  ),
                  child: Text(_months[i],
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.textMid)),
                ),
              );
            },
          ),
        ),

        // Search + Dept filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadow.subtle),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Search employee...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadow.subtle),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterDept,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMid),
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500),
                  items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => _filterDept = v ?? 'All'),
                ),
              ),
            ),
          ]),
        ),

        // Error Banner
        if (prov.hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.errorBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(prov.error!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                TextButton(
                  onPressed: _fetch,
                  child: const Text('Retry', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ]),
            ),
          ),

        // Loading
        if (prov.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),

        // Empty
        if (!prov.isLoading && filtered.isEmpty && !prov.hasError)
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.neutralGrey),
            const SizedBox(height: 12),
            Text('No salary records for $_selectedMonth',
                style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: prov.isGenerating ? null : () => _generate(context),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: Text('Generate Payroll', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
              ),
            ),
          ]))),

        // List
        if (!prov.isLoading && filtered.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _employeeSalaryCard(filtered[i]),
            ),
          ),
      ]),
    );
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Expanded(child: Column(children: [
      Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.6)), textAlign: TextAlign.center),
    ]));
  }

  Widget _employeeSalaryCard(AdminSalaryRecord r) {
    final hasDeduction = r.deductions > 0;
    return GestureDetector(
      onTap: () => setState(() => _selectedRecord = r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadow.card,
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(
                r.employeeName.isNotEmpty ? r.employeeName[0] : '?',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.employeeName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              Text('${r.userId} • ${r.department}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmt(r.netSalary.toDouble()),
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text('Net Salary', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
            ]),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _miniChip('Present',    '${r.presentDays}d',  AppColors.success),
              _miniChip('Leave',      '${r.leaveDays}d',    AppColors.secondary),
              _miniChip('Basic',      _fmt(r.basicSalary.toDouble()), AppColors.primary),
              _miniChip('Allowances', '+${_fmt(r.allowances.toDouble())}', AppColors.success),
            ]),
          ),
          if (hasDeduction) ...[
            const SizedBox(height: 8),
            Row(children: [
              _StatusBadge(r.status),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(20)),
                child: Text('−${_fmt(r.deductions.toDouble())}',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error)),
              ),
            ]),
          ] else ...[
            const SizedBox(height: 8),
            Row(children: [
              _StatusBadge(r.status),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                child: Text('No deductions 🎉',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _miniChip(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textLight)),
    ]));
  }

  Future<void> _generate(BuildContext ctx) async {
    final ok = await ctx.read<AdminSalaryProvider>().generatePayroll(month: _apiMonth);
    if (ctx.mounted) {
      final prov = ctx.read<AdminSalaryProvider>();
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(ok ? prov.generateMessage ?? 'Payroll generated!' : prov.error ?? 'Generation failed',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── Detail View — exact same as original ────────────────────────────────────
  Widget _buildDetailView(AdminSalaryRecord r) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textDark),
          onPressed: () => setState(() => _selectedRecord = null),
        ),
        title: Text('Salary Details',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(20)),
              child: Text(_selectedMonth,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          _detailHeroCard(r),
          const SizedBox(height: 16),
          _detailAttendanceCard(r),
          const SizedBox(height: 16),
          _detailDeductionCard(r),
          const SizedBox(height: 16),
          _detailNetCard(r),
        ],
      ),
    );
  }

  Widget _detailHeroCard(AdminSalaryRecord r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(
              r.employeeName.isNotEmpty ? r.employeeName[0] : '?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            )),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.employeeName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('${r.userId} • ${r.department}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.6))),
          ])),
        ]),
        const SizedBox(height: 20),
        Container(height: 1, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 16),
        Row(children: [
          _detailMini('Basic Salary', _fmt(r.basicSalary.toDouble()), AppColors.primary),
          Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
          _detailMini('Deduction', _fmt(r.deductions.toDouble()), AppColors.accent),
          Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1)),
          _detailMini('Net Salary', _fmt(r.netSalary.toDouble()), AppColors.success),
        ]),
      ]),
    );
  }

  Widget _detailMini(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.45))),
    ]));
  }

  Widget _detailAttendanceCard(AdminSalaryRecord r) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle('Attendance Summary', ''),
        const SizedBox(height: 16),
        Row(children: [
          _attBadge('Working Days', r.totalWorkingDays, AppColors.primary, Icons.calendar_month_rounded),
          const SizedBox(width: 8),
          _attBadge('Present', r.presentDays, AppColors.success, Icons.check_circle_rounded),
          const SizedBox(width: 8),
          _attBadge('Off Days', r.offDays, AppColors.neutralGrey, Icons.weekend_rounded),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _attBadge('Absent', r.absentDays, AppColors.error, Icons.cancel_rounded),
          const SizedBox(width: 8),
          _attBadge('Half Day', r.halfDays, AppColors.warning, Icons.timer_off_rounded),
          const SizedBox(width: 8),
          _attBadge('Late', r.lateDays, AppColors.accent, Icons.watch_later_rounded),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _attBadge('Leave', r.leaveDays, AppColors.secondary, Icons.beach_access_rounded),
          const SizedBox(width: 8),
          _attBadge('Allowances', r.allowances, AppColors.warning, Icons.add_circle_outline_rounded),
        ]),
      ]),
    );
  }

  Widget _detailDeductionCard(AdminSalaryRecord r) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle('Salary Breakdown', ''),
        const SizedBox(height: 14),
        _deductRow('Basic Salary', _fmt(r.basicSalary.toDouble()), AppColors.primary, Icons.payments_rounded, isEarning: true),
        if (r.allowances > 0)
          _deductRow('Allowances', _fmt(r.allowances.toDouble()), AppColors.success, Icons.add_circle_outline, isEarning: true),
        const Divider(height: 20, color: AppColors.border),
        if (r.deductions > 0)
          _deductRow('Total Deductions', _fmt(r.deductions.toDouble()), AppColors.error, Icons.remove_circle_outline)
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.thumb_up_rounded, color: AppColors.success, size: 18),
              const SizedBox(width: 10),
              Text('No deductions this month! 🎉',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
            ]),
          ),
      ]),
    );
  }

  Widget _deductRow(String label, String amount, Color color, IconData icon, {bool isEarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500))),
        Text('${isEarning ? '+' : '-'}$amount',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700,
                color: isEarning ? AppColors.success : color)),
      ]),
    );
  }

  Widget _detailNetCard(AdminSalaryRecord r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Net Salary',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
          Text(_fmt(r.netSalary.toDouble()),
              style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
        const SizedBox(height: 14),
        Container(height: 1, color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${_fmt(r.basicSalary.toDouble())} + ${_fmt(r.allowances.toDouble())} − ${_fmt(r.deductions.toDouble())}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.6))),
          Text('= ${_fmt(r.netSalary.toDouble())}',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      ]),
    );
  }

  Widget _cardTitle(String title, String sub) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      if (sub.isNotEmpty)
        Text(sub, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
    ]);
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
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(_fmtDays(value), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: color.withOpacity(0.7)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  Color get _color => switch (status) {
    'paid'       => AppColors.success,
    'pending'    => AppColors.warning,
    'processing' => AppColors.secondary,
    _            => AppColors.textLight,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(status.toUpperCase(),
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _color)),
  );
}
