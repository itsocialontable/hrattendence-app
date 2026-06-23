import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ClockInOutScreen extends StatefulWidget {
  const ClockInOutScreen({super.key});
  @override
  State<ClockInOutScreen> createState() => _ClockInOutScreenState();
}

class _ClockInOutScreenState extends State<ClockInOutScreen> with SingleTickerProviderStateMixin {
  bool isClockedIn = false;
  String? punchInTime;
  String? punchOutTime;
  bool isLunchBreak = false;
  bool lunchTaken = false;
  int lateCountThisMonth = 3; // demo: 3 lates already
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // HR POLICY CONSTANTS
  static const String GRACE_TIME = "10:15 AM";
  static const String LATE_CUTOFF = "11:00 AM";
  static const String LUNCH_START = "1:15 PM";
  static const String LUNCH_END = "2:00 PM";
  static const int LATE_FOR_HALF_DAY = 3; // 3 lates = half day

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  String _getStatusMessage() {
    final now = TimeOfDay.now();
    final totalMin = now.hour * 60 + now.minute;
    if (totalMin < 10 * 60 + 15) return "On Time — Grace till 10:15 AM";
    if (totalMin < 11 * 60) return "⚠️ Late — Marked as Late Entry";
    if (totalMin >= 13 * 60 + 15 && totalMin < 14 * 60) return "🍽 Lunch Break (1:15 - 2:00 PM)";
    return "❌ After 11:00 AM — Counts as Late ($lateCountThisMonth/3 this month)";
  }

  Color _getStatusColor() {
    final now = TimeOfDay.now();
    final totalMin = now.hour * 60 + now.minute;
    if (totalMin < 10 * 60 + 15) return AppColors.success;
    if (totalMin < 11 * 60) return AppColors.warning;
    return AppColors.error;
  }

  void _handleClockAction() {
    final now = TimeOfDay.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour < 12 ? 'AM' : 'PM';
    final displayH = now.hour > 12 ? now.hour - 12 : now.hour;
    final timeStr = '${displayH.toString().padLeft(2, '0')}:$m $ampm';

    if (!isClockedIn) {
      // Check if after 11:00 AM
      final totalMin = now.hour * 60 + now.minute;
      if (totalMin >= 11 * 60) {
        _showLateWarning(timeStr, totalMin);
        return;
      }
      setState(() { isClockedIn = true; punchInTime = timeStr; });
      _showSnack("✅ Punched In at $timeStr", AppColors.success);
    } else {
      setState(() { isClockedIn = false; punchOutTime = timeStr; });
      _showSnack("👋 Punched Out at $timeStr", AppColors.primary);
    }
  }

  void _showLateWarning(String timeStr, int totalMin) {
    final newLateCount = lateCountThisMonth + 1;
    final isHalfDay = newLateCount % LATE_FOR_HALF_DAY == 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28)),
            const SizedBox(height: 16),
            Text('Late Entry Alert', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('You are punching in after 11:00 AM.\nThis will be counted as a Late entry.\n\nLate this month: $newLateCount/3${isHalfDay ? "\n\n⚠️ 3rd Late = Half Day Salary Deducted!" : ""}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMid, height: 1.6)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () { Navigator.pop(context); },
                child: Container(height: 48, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textMid)))),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() { isClockedIn = true; punchInTime = timeStr; lateCountThisMonth = newLateCount; });
                  _showSnack("⚠️ Late Punch In at $timeStr", AppColors.warning);
                },
                child: Container(height: 48, decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text('Punch In Anyway', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)))),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(children: [
        const SizedBox(height: 16),
        _buildTopBar(),
        const SizedBox(height: 16),
        _buildHRPolicyBanner(),
        const SizedBox(height: 24),
        _buildClockDisplay(),
        const SizedBox(height: 32),
        _buildClockButton(),
        const SizedBox(height: 24),
        _buildLateTracker(),
        const SizedBox(height: 20),
        _buildTodayStats(),
        const SizedBox(height: 20),
        _buildLunchBanner(),
        const SizedBox(height: 20),
        _buildLocationCard(),
        const SizedBox(height: 20),
        _buildRecentActivity(),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Attendance', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        StreamBuilder(stream: Stream.periodic(const Duration(seconds: 30)), builder: (c, _) {
          final now = DateTime.now();
          const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
          const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          return Text('${days[now.weekday-1]}, ${months[now.month-1]} ${now.day}',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid));
        }),
      ]),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('Online', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
        ])),
    ]);
  }

  Widget _buildHRPolicyBanner() {
    final statusMsg = _getStatusMessage();
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Icon(Icons.schedule_rounded, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(statusMsg, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
      ]),
    );
  }

  Widget _buildClockDisplay() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = TimeOfDay.now();
        final h = now.hourOfPeriod.toString().padLeft(2, '0');
        final m = now.minute.toString().padLeft(2, '0');
        final s = DateTime.now().second.toString().padLeft(2, '0');
        final ampm = now.period == DayPeriod.am ? 'AM' : 'PM';
        return Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$h:$m', style: GoogleFonts.poppins(fontSize: 60, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -2)),
            Padding(padding: const EdgeInsets.only(bottom: 10, left: 4),
              child: Text(':$s $ampm', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w400, color: AppColors.textLight))),
          ]),
        ]);
      },
    );
  }

  Widget _buildClockButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(scale: isClockedIn ? _pulseAnimation.value : 1.0, child: child),
      child: GestureDetector(
        onTap: _handleClockAction,
        child: Stack(alignment: Alignment.center, children: [
          Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [(isClockedIn ? AppColors.accent : AppColors.primary).withOpacity(0.15), Colors.transparent]))),
          Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: (isClockedIn ? AppColors.accent : AppColors.primary).withOpacity(0.2), width: 2))),
          Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: isClockedIn ? AppColors.accentGradient : AppColors.primaryGradient,
            boxShadow: [BoxShadow(color: (isClockedIn ? AppColors.accent : AppColors.primary).withOpacity(0.45), blurRadius: 36, offset: const Offset(0, 12))]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(isClockedIn ? Icons.pan_tool_rounded : Icons.fingerprint_rounded, color: Colors.white, size: 36),
              const SizedBox(height: 6),
              Text(isClockedIn ? 'PUNCH OUT' : 'PUNCH IN',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
            ])),
        ]),
      ),
    );
  }

  Widget _buildLateTracker() {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Text('Late Punch-In Tracker', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const Spacer(),
          Text('This Month', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
        ]),
        const SizedBox(height: 14),
        Row(children: List.generate(3, (i) {
          final filled = i < lateCountThisMonth % 3 || (lateCountThisMonth > 0 && lateCountThisMonth % 3 == 0);
          final isLast = i == 2;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: Container(height: 8, decoration: BoxDecoration(
              color: i < (lateCountThisMonth % 3 == 0 && lateCountThisMonth > 0 ? 3 : lateCountThisMonth % 3) ? AppColors.error : AppColors.border,
              borderRadius: BorderRadius.circular(4))),
          ));
        })),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$lateCountThisMonth late this month', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMid)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('3 = Half Day Deducted', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error))),
        ]),
        if (lateCountThisMonth % 3 == 0 && lateCountThisMonth > 0) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.money_off_rounded, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Text('Half Day Deducted from Salary!', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
            ])),
        ],
      ]),
    );
  }

  Widget _buildTodayStats() {
    return Row(children: [
      Expanded(child: _buildStatItem('Punch In', punchInTime ?? '--:--', AppColors.success, Icons.login_rounded)),
      const SizedBox(width: 12),
      Expanded(child: _buildStatItem('Punch Out', punchOutTime ?? '--:--', AppColors.primary, Icons.logout_rounded)),
      const SizedBox(width: 12),
      Expanded(child: _buildStatItem('Duration', punchInTime != null ? '9h 10m' : '--', AppColors.secondary, Icons.timer_rounded)),
    ]);
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return PremiumCard(padding: const EdgeInsets.all(14), child: Column(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(height: 8),
      Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
    ]));
  }

  Widget _buildLunchBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.warningBg, AppColors.warningLight.withOpacity(0.35)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Text('🍱', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Lunch Break', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warning)),
          Text('Fixed: 1:15 PM – 2:00 PM (45 min)', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warningLight)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Text('Fixed', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning))),
      ]),
    );
  }

  Widget _buildLocationCard() {
    return PremiumCard(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Office Location', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        Text('Central Building Office, Floor 4', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Text('Verified', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success))),
    ]));
  }

  Widget _buildRecentActivity() {
    final activities = [
      {'label': 'Punch In', 'time': '09:10 AM', 'date': 'Today', 'color': AppColors.success, 'status': 'On Time'},
      {'label': 'Punch Out', 'time': '06:20 PM', 'date': 'Yesterday', 'color': AppColors.primary, 'status': 'Normal'},
      {'label': 'Punch In', 'time': '10:45 AM', 'date': 'Yesterday', 'color': AppColors.warning, 'status': 'Late'},
      {'label': 'Punch Out', 'time': '05:45 PM', 'date': 'May 28', 'color': AppColors.primary, 'status': 'Normal'},
      {'label': 'Punch In', 'time': '11:20 AM', 'date': 'May 27', 'color': AppColors.error, 'status': 'Very Late'},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Recent Punch History'),
      const SizedBox(height: 14),
      ...activities.map((a) {
        final color = a['color'] as Color;
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 14),
            Expanded(child: Text(a['label'] as String, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(a['time'] as String, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              Text(a['date'] as String, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
            ]),
            const SizedBox(width: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(a['status'] as String, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color))),
          ]),
        ));
      }),
    ]);
  }
}
