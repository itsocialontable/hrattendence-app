import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

import 'package:http/http.dart' as http;


// ─────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────
class SalaryResponse {
  final String userId;
  final String userName;
  final String dept;
  final String month;
  final double monthlySalary;
  final double perDaySalary;
  final int daysInMonth;
  final int sundays;
  final int satOffDays;
  final int totalWorkingDays;
  final int presentDays;
  final double halfDays;
  final int lateDays;
  final int approvedLeaveDays;
  final double effectivePresent;
  final double absentDays;
  final double halfDayDeduction;
  final double absentDeduction;
  final double totalDeduction;
  final double netSalary;
  final String? note;

  SalaryResponse({
    required this.userId,
    required this.userName,
    required this.dept,
    required this.month,
    required this.monthlySalary,
    required this.perDaySalary,
    required this.daysInMonth,
    required this.sundays,
    required this.satOffDays,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.halfDays,
    required this.lateDays,
    required this.approvedLeaveDays,
    required this.effectivePresent,
    required this.absentDays,
    required this.halfDayDeduction,
    required this.absentDeduction,
    required this.totalDeduction,
    required this.netSalary,
    this.note,
  });

  factory SalaryResponse.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int i(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    // Support nested salary object as a fallback, otherwise use flat root.
    final s = json['salary'] is Map
        ? json['salary'] as Map<String, dynamic>
        : json;

    return SalaryResponse(
      userId: s['userId']?.toString() ?? '',
      userName: s['userName']?.toString() ?? '',
      dept: s['dept']?.toString() ?? '',
      month: s['month']?.toString() ?? '',
      monthlySalary: d(s['monthlySalary']),
      perDaySalary: d(s['perDaySalary']),
      daysInMonth: i(s['daysInMonth']),
      sundays: i(s['sundays']),
      satOffDays: i(s['satOffDays']),
      totalWorkingDays: i(s['totalWorkingDays']),
      presentDays: i(s['presentDays']),
      halfDays: d(s['halfDays']),
      lateDays: i(s['lateDays']),
      approvedLeaveDays: i(s['approvedLeaveDays']),
      effectivePresent: d(s['effectivePresent']),
      absentDays: d(s['absentDays']),
      halfDayDeduction: d(s['halfDayDeduction']),
      absentDeduction: d(s['absentDeduction']),
      totalDeduction: d(s['totalDeduction']),
      netSalary: d(s['netSalary']),
      note: s['note']?.toString(),
    );
  }
}

// ─────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────
class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  // Available months (last 6 months)
  late List<Map<String, dynamic>> _months;
  int _selectedIndex = 0;

  bool _isLoading = false;
  String? _errorMessage;
  SalaryResponse? _salary;

  @override
  void initState() {
    super.initState();
    _months = _buildMonthList();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSalary());
  }

  List<Map<String, dynamic>> _buildMonthList() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> list = [];
    for (int i = 0; i < 6; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      list.add({
        'label': _monthLabel(d),
        'month': d.month,
        'year': d.year,
      });
    }
    return list;
  }

  String _monthLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }


  Future<void> _fetchSalary() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? '';

    final selected = _months[_selectedIndex];
    final monthStr =
        '${selected['year']}-${selected['month'].toString().padLeft(2, '0')}';

    debugPrint('📡 Fetching salary: userId=$userId month=$monthStr');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _salary = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final token = await apiService.getToken();

      final uri = Uri.parse(
        '${ApiService.baseUrl}/api/salary/calculate'
            '?userId=$userId&month=$monthStr',
      );

      debugPrint('🌐 GET $uri');
      debugPrint('🔑 Token: $token');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          _salary = SalaryResponse.fromJson(json);
          _isLoading = false;
        });

        log('✅ Salary loaded: net=${_salary?.netSalary}');
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage =
          'No salary record found for ${selected['label']}.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
          'Server error (${response.statusCode}). Try again.';
          _isLoading = false;
        });

        log('❌ Error ${response.statusCode}: ${response.body}');
      }
    } on SocketException catch (e) {
      log('❌ SocketException: $e');

      setState(() {
        _errorMessage =
        'No internet connection. Please check your network.';
        _isLoading = false;
      });
    } on TimeoutException catch (e) {
      log('❌ Timeout: $e');

      setState(() {
        _errorMessage = 'Request timed out. Please try again.';
        _isLoading = false;
      });
    } catch (e) {
      log('❌ Unexpected error: $e');

      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMonthPicker(),
          const SizedBox(height: 20),
          if (_isLoading) _buildLoader(),
          if (_errorMessage != null && !_isLoading) _buildError(),
          if (_salary != null && !_isLoading) ...[
            _buildSalaryHero(),
            const SizedBox(height: 20),
            _buildAttendanceSummary(),
            const SizedBox(height: 20),
            _buildDeductionBreakdown(),
            const SizedBox(height: 20),
            _buildNetSalaryCard(),
          ],
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    final net = _salary?.netSalary ?? 0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Salary',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Breakdown & Deductions',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMid,
                ),
              ),
            ],
          ),
        ),
        if (_salary != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '₹${(net / 1000).toStringAsFixed(1)}K',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Month Picker ──
  Widget _buildMonthPicker() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        itemBuilder: (_, i) {
          final isActive = _selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = i);
                _fetchSalary();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  color: isActive ? null : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow:
                      isActive ? AppShadow.strong : AppShadow.subtle,
                ),
                child: Text(
                  _months[i]['label'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textMid,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Loader ──
  Widget _buildLoader() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Calculating salary...',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textMid),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Error ──
  Widget _buildError() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.error,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _fetchSalary,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Salary Hero Card ──
  Widget _buildSalaryHero() {
    final s = _salary!;
    return PremiumCard(
      gradient: AppColors.darkGradient,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Salary',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatAmount(s.netSalary),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.dept.isNotEmpty ? s.dept : s.userName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _miniStat('Monthly Salary',
                      _formatAmount(s.monthlySalary), AppColors.primary)),
              Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.1)),
              Expanded(
                  child: _miniStat('Total Deduction',
                      _formatAmount(s.totalDeduction), AppColors.accent)),
              Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.1)),
              Expanded(
                  child: _miniStat(
                      'Per Day',
                      _formatAmount(s.perDaySalary),
                      AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  // ── Attendance Summary (present / half-day / absent / late / leave days) ──
  Widget _buildAttendanceSummary() {
    final s = _salary!;
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Summary',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${s.totalWorkingDays} working days',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _dayBadge('Present', s.presentDays,
                      AppColors.success, Icons.check_circle_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _dayBadge('Half Day', s.halfDays,
                      AppColors.warning, Icons.brightness_4_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _dayBadge('Absent', s.absentDays,
                      AppColors.error, Icons.cancel_rounded)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _dayBadge('Late', s.lateDays, AppColors.secondary,
                      Icons.schedule_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _dayBadge('Approved Leave', s.approvedLeaveDays,
                      AppColors.secondary, Icons.beach_access_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _dayBadge('Effective Present', s.effectivePresent,
                      AppColors.primary, Icons.fact_check_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDays(num days) {
    return days == days.roundToDouble()
        ? days.toInt().toString()
        : days.toStringAsFixed(1);
  }

  Widget _dayBadge(
      String label, num days, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            _formatDays(days),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Deduction Breakdown ──
  Widget _buildDeductionBreakdown() {
    final s = _salary!;
    final hasHalfDay = s.halfDayDeduction > 0;
    final hasAbsent = s.absentDeduction > 0;

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deduction Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How deductions are calculated from your monthly salary',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),

          // Monthly Salary row
          _deductionRow('Monthly Salary', s.monthlySalary,
              AppColors.primary, Icons.payments_rounded,
              isEarning: true),
          const Divider(height: 24),

          // Half day deduction
          if (hasHalfDay) ...[
            _deductionRow(
              'Half Day Deduction (${_formatDays(s.halfDays)} ${s.halfDays == 1 ? 'day' : 'days'})',
              s.halfDayDeduction,
              AppColors.warning,
              Icons.brightness_4_rounded,
            ),
          ],

          // Absent deduction
          if (hasAbsent) ...[
            _deductionRow(
              'Absent Deduction (${_formatDays(s.absentDays)} days)',
              s.absentDeduction,
              AppColors.error,
              Icons.cancel_rounded,
            ),
          ],

          if (!hasHalfDay && !hasAbsent) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up_rounded,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No half-day/absent deductions this month! 🎉',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (s.note != null && s.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.note!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _deductionRow(
    String label,
    double amount,
    Color color,
    IconData icon, {
    bool isEarning = false,
    String? note,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textLight),
                  ),
              ],
            ),
          ),
          Text(
            '${isEarning ? '+' : '-'}${_formatAmount(amount)}',
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

  // ── Net Salary Card ──
  Widget _buildNetSalaryCard() {
    final s = _salary!;
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
                _formatAmount(s.netSalary),
                style: GoogleFonts.poppins(
                  fontSize: 24,
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
                '${_formatAmount(s.monthlySalary)} − ${_formatAmount(s.totalDeduction)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              Text(
                '= ${_formatAmount(s.netSalary)}',
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
}

// Simple TimeoutException if not imported elsewhere
class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);
  @override
  String toString() => message;
}
