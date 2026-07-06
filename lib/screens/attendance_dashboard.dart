import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/dashboard_models.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/attendance_provider.dart';
import 'salary_screen.dart';
import 'hr_policy_screen.dart';
import 'leave_management_screen.dart';
import 'notifications_screen.dart';

class AttendanceDashboard extends StatefulWidget {
  const AttendanceDashboard({super.key});

  @override
  State<AttendanceDashboard> createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<AttendanceDashboard>
    with TickerProviderStateMixin {
  // ── Pulse animation for the clock button ─────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Press-and-hold animation (ring fills up) ──────────────────────────
  late AnimationController _holdController;
  late Animation<double> _holdAnimation;

  bool _isHolding = false;

  @override
  void initState() {
    super.initState();

    // Idle pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Hold-progress ring (2 seconds to fill)
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _holdAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _holdController, curve: Curves.easeInOut),
    );

    // When hold completes → trigger check-in / check-out
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onHoldComplete();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
      context.read<AttendanceProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────
  void _loadStats() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) return;
    context.read<EmployeeStatsProvider>().fetchEmployeeStats(userId);
  }

  Future<void> _onRefresh() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) return;
    await context.read<EmployeeStatsProvider>().fetchEmployeeStats(userId);
    await context.read<AttendanceProvider>().syncFromServer();
  }

  // ── Hold gesture handlers ─────────────────────────────────────────────
  void _onHoldStart() {
    final provider = context.read<AttendanceProvider>();
    // Already both checked-in and checked-out → nothing to do
    if (provider.isCheckedOut) return;
    // API call in progress → ignore
    if (provider.isLoading || provider.isBiometricLoading) return;

    setState(() => _isHolding = true);
    _pulseController.stop();
    _holdController.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _onHoldCancel() {
    if (!_isHolding) return;
    setState(() => _isHolding = false);
    _holdController.reverse();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _onHoldComplete() async {
    setState(() => _isHolding = false);
    HapticFeedback.heavyImpact();

    final provider = context.read<AttendanceProvider>();
    bool success;

    if (!provider.isCheckedIn) {
      success = await provider.checkIn();
    } else {
      success = await provider.checkOut();
    }

    _holdController.reset();
    _pulseController.repeat(reverse: true);

    if (!mounted) return;

    // Always refresh employee stats after checkin/checkout
    // so presentDays / workingHours counters update too.
    _loadStats();

    if (success) {
      HapticFeedback.mediumImpact();
      _showResultSheet(success: true);
    } else {
      HapticFeedback.vibrate();
      _showResultSheet(success: false);
    }
  }

  // ── Result bottom sheet ───────────────────────────────────────────────
  void _showResultSheet({required bool success}) {
    final provider = context.read<AttendanceProvider>();
    final msg = success
        ? (provider.successMessage ?? 'Done!')
        : (provider.errorMessage ?? 'Something went wrong.');

    // Determine if this was check-in or check-out from the message content
    final isCheckIn = msg.toLowerCase().contains('check-in') ||
        msg.toLowerCase().contains('checkin');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultSheet(
        success: success,
        message: msg,
        isCheckIn: isCheckIn,
      ),
    ).then((_) => provider.clearMessages());
  }

  // ── Navigation helper ─────────────────────────────────────────────────
  void _navigate(BuildContext context, Widget screen, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(title,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(child: screen),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Consumer2<EmployeeStatsProvider, AttendanceProvider>(
      builder: (context, statsProvider, attendanceProvider, _) {
        final stats = statsProvider.stats;
        final isLoading = statsProvider.isLoading;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildTopBar(context),
                const SizedBox(height: 28),
                _buildClockInHero(attendanceProvider),
                const SizedBox(height: 24),
                _buildTimeStatsRow(attendanceProvider),
                _buildTodayStatusBadges(attendanceProvider),
                const SizedBox(height: 24),
                // _buildLunchCard(),
                // _buildQuickActionRow(context),
                const SizedBox(height: 24),
                _buildLatePolicyCard(stats, isLoading),
                const SizedBox(height: 24),
                _buildMonthStatsRow(stats, isLoading),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final initials = _initialsFor(auth.user?.name);
        final firstName = auth.user?.name?.trim().split(' ').first ?? 'there';

        final hour = DateTime.now().hour;
        final String greeting;
        final IconData greetIcon;
        final Color greetColor;
        if (hour < 12) {
          greeting = 'Good Morning';
          greetIcon = Icons.wb_sunny_rounded;
          greetColor = AppColors.warning;
        } else if (hour < 17) {
          greeting = 'Good Afternoon';
          greetIcon = Icons.light_mode_rounded;
          greetColor = AppColors.warningLight;
        } else if (hour < 21) {
          greeting = 'Good Evening';
          greetIcon = Icons.nights_stay_rounded;
          greetColor = AppColors.secondary;
        } else {
          greeting = 'Good Night';
          greetIcon = Icons.bedtime_rounded;
          greetColor = AppColors.textDark;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Greeting + name
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: greetColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(greetIcon, color: greetColor, size: 22),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  greeting,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  firstName,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    height: 1.1,
                  ),
                ),
              ]),
            ]),

            // Notification bell + Avatar
            Row(children: [
              GestureDetector(
                onTap: () => _navigate(
                    context, const NotificationsScreen(), 'Notifications'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadow.subtle,
                  ),
                  child: Stack(children: [
                    const Center(
                        child: Icon(Icons.notifications_none_rounded,
                            color: AppColors.textDark, size: 20)),
                    Positioned(
                      top: 9, right: 9,
                      child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              AppAvatar(initials: initials, size: 40, showBadge: true),
            ]),
          ],
        );
      },
    );
  }

  String _initialsFor(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // ── Clock-In Hero ─────────────────────────────────────────────────────
  Widget _buildClockInHero(AttendanceProvider ap) {
    // Determine button state
    final bool alreadyDone = ap.isCheckedOut;
    final bool checkedIn   = ap.isCheckedIn;
    final bool loading     = ap.isLoading || ap.isBiometricLoading;

    final Color buttonColor = alreadyDone
        ? AppColors.textLight
        : checkedIn
        ? AppColors.error
        : AppColors.primary;

    final String buttonLabel = alreadyDone
        ? 'DONE'
        : checkedIn
        ? 'CLOCK OUT'
        : 'CLOCK IN';

    final IconData buttonIcon = alreadyDone
        ? Icons.check_rounded
        : checkedIn
        ? Icons.logout_rounded
        : Icons.touch_app_rounded;

    final String hintText = alreadyDone
        ? 'You have checked out today'
        : loading
        ? checkedIn
        ? 'Verifying biometric...'
        : 'Verifying biometric...'
        : _isHolding
        ? 'Keep holding...'
        : checkedIn
        ? 'Hold to Clock Out'
        : 'Hold to Clock In';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadow.card,
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          // Live time & date
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (c, _) {
              final now = DateTime.now();
              const d = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
              const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
              final t = TimeOfDay.now();
              final h  = t.hourOfPeriod.toString().padLeft(2, '0');
              final mn = t.minute.toString().padLeft(2, '0');
              final ap2 = t.period == DayPeriod.am ? 'AM' : 'PM';
              return Column(children: [
                Text(
                  '${d[now.weekday - 1]}, ${m[now.month - 1]} ${now.day}',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '$h:$mn $ap2',
                  style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      letterSpacing: -1.5),
                ),
              ]);
            },
          ),

          const SizedBox(height: 28),

          // ── Press-and-hold button ────────────────────────────────────
          GestureDetector(
            onLongPressStart: (_) => _onHoldStart(),
            onLongPressEnd: (_) => _onHoldCancel(),
            onLongPressCancel: _onHoldCancel,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _holdAnimation]),
              builder: (context, child) {
                final pulse = _isHolding ? 1.0 : _pulseAnimation.value;
                return Transform.scale(
                  scale: pulse,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              buttonColor.withOpacity(
                                  0.12 + 0.12 * _holdAnimation.value),
                              buttonColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      // Progress ring (fills as user holds)
                      SizedBox(
                        width: 148,
                        height: 148,
                        child: CircularProgressIndicator(
                          value: loading ? null : _holdAnimation.value,
                          strokeWidth: 3.5,
                          backgroundColor: buttonColor.withOpacity(0.15),
                          valueColor:
                          AlwaysStoppedAnimation<Color>(buttonColor),
                        ),
                      ),
                      // Inner filled circle
                      Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: alreadyDone
                              ? const LinearGradient(
                            colors: [
                              AppColors.neutralGreyLight,
                              AppColors.neutralGrey
                            ],
                          )
                              : checkedIn
                              ? const LinearGradient(
                            colors: [
                              AppColors.error,
                              AppColors.errorLight
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : AppColors.primaryGradient,
                          boxShadow: alreadyDone
                              ? []
                              : [
                            BoxShadow(
                              color: buttonColor.withOpacity(
                                  0.35 + 0.2 * _holdAnimation.value),
                              blurRadius:
                              28 + 16 * _holdAnimation.value,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: loading
                            ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(buttonIcon,
                                color: Colors.white, size: 34),
                            const SizedBox(height: 4),
                            Text(
                              buttonLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Live working timer (only shown when checked in)
          if (ap.isCheckedIn) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  ap.elapsedFormatted,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Working',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.primary.withOpacity(0.7)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Hint text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              hintText,
              key: ValueKey(hintText),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _isHolding ? buttonColor : AppColors.textLight,
                fontWeight: _isHolding ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Location tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.primary, size: 14),
              const SizedBox(width: 6),
              Text(
                'You are not in Office reach',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textMid),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.restaurant,
                color: AppColors.warning,
              ),
              SizedBox(width: 5,),
              Text(
                'Lunch time(fixed) 01:15PM-02:00PM',
                style: GoogleFonts.poppins(
                    fontSize: 12,  color: AppColors.warning,),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Clock-in / Clock-out time stats ───────────────────────────────────
  Widget _buildTimeStatsRow(AttendanceProvider ap) {
    final state = ap.attendanceState;
    String _orPlaceholder(String? v) =>
        (v == null || v.trim().isEmpty) ? '--:--' : v;
    final clockIn  = _orPlaceholder(state?.checkInTime);
    final clockOut = _orPlaceholder(state?.checkOutTime);
    final netMins  = state?.netMins;
    final hoursStr = netMins != null
        ? AttendanceService.formatNetMinutes(netMins)
        : '--:--';

    return Row(children: [
      Expanded(child: _buildTimeCard(
          'Clock In', clockIn, Icons.login_rounded, AppColors.success)),
      const SizedBox(width: 12),
      Expanded(child: _buildTimeCard(
          'Clock Out', clockOut, Icons.logout_rounded, AppColors.error)),
      const SizedBox(width: 12),
      Expanded(child: _buildTimeCard(
          'Hours', hoursStr, Icons.timer_rounded, AppColors.primary)),
    ]);
  }

  Widget _buildTimeCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadow.subtle,
      ),
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textLight)),
      ]),
    );
  }

  // ── Today's late / half-day status badges ─────────────────────────────
  Widget _buildTodayStatusBadges(AttendanceProvider ap) {
    final state = ap.attendanceState;
    final isLate = state?.isLate ?? false;
    final isHalfDay = state?.isHalfDay ?? false;
    final warningCount = state?.warningCount ?? 0;
    final maxWarnings = (state?.maxWarnings ?? 0) > 0 ? state!.maxWarnings! : 3;

    if (!isLate && !isHalfDay) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (isHalfDay)
            _statusChip('Half Day Marked', Icons.timer_off_rounded, AppColors.error)
          else if (isLate)
            _statusChip('Late Check-in', Icons.warning_amber_rounded, AppColors.warning),
          if (isLate && !isHalfDay && warningCount > 0)
            _statusChip(
              'Warning $warningCount/$maxWarnings',
              Icons.report_gmailerrorred_rounded,
              AppColors.warning,
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // ── Late Arrival Policy card (3 warnings before 11 AM → then Half Day) ─
  Widget _buildLatePolicyCard(EmployeeStats? stats, bool isLoading) {
    if (stats == null) return const SizedBox.shrink();

    final used = stats.warnings;
    final maxW = stats.maxWarnings > 0 ? stats.maxWarnings : 3;
    final left = stats.warningsLeft;
    final atRisk = stats.nextLateIsHalfDay;

    final Color accent = atRisk
        ? AppColors.error
        : used > 0
        ? AppColors.warning
        : AppColors.success;

    final String message = atRisk
        ? 'You\'ve used all $maxW warnings — your next late check-in (after the cut-off, within 11:00 AM) will be marked as a Half Day.'
        : used > 0
        ? 'You have $left warning${left == 1 ? '' : 's'} left. Check in before 11:00 AM — after that, late check-ins start counting as a Half Day.'
        : 'Check in on time. If you\'re late but still arrive before 11:00 AM, you get a warning — up to $maxW per month. After that, a late check-in counts as a Half Day.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadow.subtle,
        border: Border.all(color: accent.withOpacity(0.18), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.schedule_rounded, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Late Arrival Policy',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
          ),
          Text('$used/$maxW',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
        ]),
        const SizedBox(height: 12),
        // Dots showing warnings used out of the monthly max
        Row(
          children: List.generate(maxW, (i) {
            final filled = i < used;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                height: 8,
                decoration: BoxDecoration(
                  color: filled ? accent : AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                  border: filled ? null : Border.all(color: AppColors.border),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(message,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textMid, height: 1.4)),
      ]),
    );
  }
  Widget _buildLunchCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.warningBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lunch Time (Fixed)",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "01:00 PM - 02:00 PM",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Divider(
                  color: AppColors.warning.withOpacity(0.15),
                  height: 1,
                ),

                const SizedBox(height: 12),

                const Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Lunch Not Started",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.lunch_dining,
              size: 40,
              color: AppColors.warningLight,
            ),
          ),
        ],
      ),
    );
  }
  // ── Quick Actions ─────────────────────────────────────────────────────
  // Widget _buildQuickActionRow(BuildContext context) {
  //   final actions = [
  //     {'label': 'Salary',     'icon': Icons.account_balance_wallet_rounded, 'color': AppColors.success, 'screen': const SalaryScreen()},
  //     {'label': 'HR Policy',  'icon': Icons.policy_rounded,                 'color': AppColors.primary, 'screen': const HRPolicyScreen()},
  //     {'label': 'Apply Leave','icon': Icons.event_note_rounded,             'color': AppColors.secondary,  'screen': const LeaveManagementScreen()},
  //     {'label': 'Break',      'icon': Icons.coffee_rounded,                 'color': AppColors.accent,    'screen': null},
  //   ];
  //   return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //     Text('Quick Actions',
  //         style: GoogleFonts.poppins(
  //             fontSize: 16,
  //             fontWeight: FontWeight.w700,
  //             color: AppColors.textDark)),
  //     const SizedBox(height: 12),
  //     Row(
  //       children: actions.map((a) {
  //         final color = a['color'] as Color;
  //         return Expanded(
  //           child: Padding(
  //             padding: const EdgeInsets.only(right: 8),
  //             child: GestureDetector(
  //               onTap: () {
  //                 if (a['screen'] != null) {
  //                   _navigate(context, a['screen'] as Widget,
  //                       a['label'] as String);
  //                 }
  //               },
  //               child: Container(
  //                 padding: const EdgeInsets.symmetric(vertical: 14),
  //                 decoration: BoxDecoration(
  //                   color: color.withOpacity(0.08),
  //                   borderRadius: BorderRadius.circular(16),
  //                   border: Border.all(
  //                       color: color.withOpacity(0.18), width: 1),
  //                 ),
  //                 child: Column(children: [
  //                   Icon(a['icon'] as IconData, color: color, size: 22),
  //                   const SizedBox(height: 6),
  //                   Text(a['label'] as String,
  //                       style: GoogleFonts.poppins(
  //                           fontSize: 10,
  //                           fontWeight: FontWeight.w600,
  //                           color: color)),
  //                 ]),
  //               ),
  //             ),
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   ]);
  // }

  // ── Monthly stats (present / absent / leave / late / half-day / warnings)
  Widget _buildMonthStatsRow(EmployeeStats? stats, bool isLoading) {
    if (isLoading && stats == null) {
      return Column(children: [
        Row(children: const [
          Expanded(child: ShimmerStatCard()),
          SizedBox(width: 12),
          Expanded(child: ShimmerStatCard()),
          SizedBox(width: 12),
          Expanded(child: ShimmerStatCard()),
        ]),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(child: ShimmerStatCard()),
          SizedBox(width: 12),
          Expanded(child: ShimmerStatCard()),
          SizedBox(width: 12),
          Expanded(child: ShimmerStatCard()),
        ]),
      ]);
    }

    final present   = stats?.presentDays    ?? 0;
    final absent    = stats?.absentDays     ?? 0;
    final leave     = stats?.approvedLeaves ?? 0;
    final lateCount = stats?.lateDays       ?? 0;
    final halfDay   = stats?.halfDays       ?? 0;
    final warnings  = stats?.warnings       ?? 0;
    final maxWarn   = (stats?.maxWarnings ?? 0) > 0 ? stats!.maxWarnings : 3;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('This Month',
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildStatCard('Present', present.toString().padLeft(2,'0'), AppColors.success, Icons.check_circle_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Absent',  absent.toString().padLeft(2,'0'),  AppColors.error,   Icons.cancel_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Leave',   leave.toString().padLeft(2,'0'),   AppColors.warning, Icons.event_rounded)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildStatCard('Late',     lateCount.toString().padLeft(2,'0'), AppColors.primary, Icons.schedule_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Half Day', halfDay.toString().padLeft(2,'0'),   AppColors.accent,    Icons.timer_off_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Warnings', '$warnings/$maxWarn',                AppColors.error,  Icons.report_problem_rounded)),
      ]),
    ]);
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadow.subtle,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 10),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textLight)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Result Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════
class _ResultSheet extends StatelessWidget {
  final bool success;
  final String message;
  final bool isCheckIn;

  const _ResultSheet({
    required this.success,
    required this.message,
    required this.isCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final color  = success ? AppColors.success : AppColors.error;
    final icon   = success
        ? (isCheckIn ? Icons.login_rounded : Icons.logout_rounded)
        : Icons.error_outline_rounded;
    final title  = success
        ? (isCheckIn ? 'Checked In! 🎉' : 'Checked Out! 👋')
        : 'Oops!';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 36),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppColors.textMid),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text('Done',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}