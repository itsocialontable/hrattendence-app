/// Attendance History Screen
/// Replaces the old "Punch" tab in the bottom nav. Shows a month-by-month
/// list of attendance records (Date / Clock In / Clock Out / Working Hrs),
/// backed by GET /api/attendance (query: date, fromDate, toDate).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/attendance_models.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';

/// Display-only conversion: backend sends checkIn/checkOut as 24-hour
/// "HH:mm" (e.g. "15:38") — this only reformats what's shown on the card to
/// "hh:mm AM/PM" (e.g. "03:38 PM"); the value stored/sent anywhere else is
/// untouched. Falls back to the raw value if it isn't a plain "HH:mm"
/// string, and to a placeholder when null/empty.
String _displayTime(String? raw) {
  if (raw == null || raw.trim().isEmpty || raw == '--:--' || raw == '...') {
    return raw ?? '--:--';
  }
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
  if (m == null) return raw; // not a bare 24h "HH:mm" value — show as-is
  final h = int.parse(m.group(1)!);
  final min = m.group(2)!;
  if (h < 0 || h > 23) return raw;
  final period = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '${h12.toString().padLeft(2, '0')}:$min $period';
}

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _fullDayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  late DateTime _selectedMonth; // always day=1 of the chosen month/year
  bool _didFetch = false;
  final ScrollController _monthScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetch) {
      _didFetch = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMonth();
        _scrollToSelectedMonth();
      });
    }
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  String _apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// GET /api/attendance?userId=<current user>&fromDate=<1st of month>&toDate=<last of month>
  Future<void> _loadMonth() async {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final userId = context.read<AuthProvider>().user?.id;
    await context.read<AttendanceProvider>().fetchAttendanceHistory(
      userId: userId,
      fromDate: _apiDate(firstDay),
      toDate: _apiDate(lastDay),
    );
  }

  void _selectMonth(int monthIndex) {
    if (_selectedMonth.month - 1 == monthIndex) return;
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, monthIndex + 1, 1));
    _loadMonth();
    _scrollToSelectedMonth();
  }

  void _changeYear(int delta) {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year + delta, _selectedMonth.month, 1));
    _loadMonth();
  }

  void _scrollToSelectedMonth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_monthScrollController.hasClients) return;
      const approxTabWidth = 78.0;
      final index = _selectedMonth.month - 1;
      final target = (index * approxTabWidth) - 90;
      final maxExtent = _monthScrollController.position.maxScrollExtent;
      final clamped = target < 0 ? 0.0 : (target > maxExtent ? maxExtent : target);
      _monthScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadMonth,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMonthTabs(),
          const SizedBox(height: 20),
          Consumer<AttendanceProvider>(
            builder: (context, provider, _) => _buildBody(provider),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Attendance', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        Text('Your daily clock-in history', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid)),
      ]),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadow.subtle),
        child: Row(children: [
          GestureDetector(
            onTap: () => _changeYear(-1),
            child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.chevron_left_rounded, color: AppColors.textMid, size: 20)),
          ),
          Row(children: [
            const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 15),
            const SizedBox(width: 6),
            Text('${_selectedMonth.year}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
          GestureDetector(
            onTap: () => _changeYear(1),
            child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.chevron_right_rounded, color: AppColors.textMid, size: 20)),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildMonthTabs() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        controller: _monthScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, i) {
          final isActive = _selectedMonth.month - 1 == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _selectMonth(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  color: isActive ? null : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isActive ? AppShadow.strong : AppShadow.subtle,
                ),
                child: Text(
                  _monthNames[i],
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.textMid),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(AttendanceProvider provider) {
    if (provider.isHistoryLoading && provider.history.isEmpty) {
      return Column(children: List.generate(5, (_) => _buildShimmerRow()));
    }

    if (provider.historyError != null && provider.history.isEmpty) {
      return ErrorStateCard(message: provider.historyError!, onRetry: _loadMonth);
    }

    if (provider.history.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          const Icon(Icons.event_busy_rounded, color: AppColors.textLight, size: 36),
          const SizedBox(height: 12),
          Text(
            'No attendance records for ${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid),
          ),
        ]),
      );
    }

    return _buildAttendanceRows(provider.history);
  }

  Widget _buildShimmerRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          const ShimmerBox(width: 30, height: 30, borderRadius: BorderRadius.all(Radius.circular(8))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            ShimmerBox(width: 70, height: 12),
            SizedBox(height: 6),
            ShimmerBox(width: 110, height: 10),
          ])),
        ]),
      ),
    );
  }

  /// Renders the list newest-first, merging consecutive weekend days
  /// (no check-in, no leave, falls on Sat/Sun) into a single banner row —
  /// matching the reference design's "Weekend: 09 Sun & 08 Sat" style row.
  Widget _buildAttendanceRows(List<AttendanceLogEntry> entries) {
    final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));

    bool isWeekendish(AttendanceLogEntry e) =>
        e.isWeekend || (e.isWeekendDay && e.checkIn == null && e.checkOut == null && !e.isLeave && !e.isAbsent);

    final widgets = <Widget>[];
    var i = 0;
    while (i < sorted.length) {
      final entry = sorted[i];
      if (isWeekendish(entry)) {
        final group = <AttendanceLogEntry>[entry];
        var j = i + 1;
        while (j < sorted.length && isWeekendish(sorted[j])) {
          group.add(sorted[j]);
          j++;
        }
        widgets.add(_buildWeekendBanner(group));
        i = j;
      } else {
        widgets.add(_buildDayRow(entry));
        i++;
      }
    }
    return Column(children: widgets);
  }

  Widget _buildWeekendBanner(List<AttendanceLogEntry> group) {
    final label = group
        .map((e) => '${e.date.day.toString().padLeft(2, '0')} ${_fullDayNames[e.date.weekday - 1]}')
        .join(' & ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(children: [
          const Icon(Icons.weekend_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Weekend : $label',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDayRow(AttendanceLogEntry entry) {
    if (entry.isLeave) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            _buildDateBadge(entry, accentColor: AppColors.secondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.leaveType ?? 'On Leave',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary),
              ),
            ),
            TagBadge(label: 'Leave', color: AppColors.secondary),
          ]),
        ),
      );
    }

    if (entry.isAbsent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            _buildDateBadge(entry, accentColor: AppColors.error),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Absent', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
            ),
            TagBadge(label: 'Absent', color: AppColors.error),
          ]),
        ),
      );
    }

    final checkInColor = entry.isLate ? AppColors.error : AppColors.textDark;
    final checkOutColor = entry.checkOut == null ? AppColors.textLight : AppColors.textDark;
    final accentColor = entry.isPending
        ? AppColors.primary
        : (entry.isLate || entry.isHalfDay ? AppColors.warning : AppColors.success);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _buildDateBadge(entry, accentColor: accentColor),
          const SizedBox(width: 6),
          Expanded(child: _buildTimeColumn('Clock In', _displayTime(entry.checkIn), checkInColor)),
          Expanded(
            child: _buildTimeColumn(
              'Clock Out',
              entry.checkOut != null ? _displayTime(entry.checkOut) : (entry.isPending ? '...' : '--:--'),
              checkOutColor,
            ),
          ),
          Expanded(child: _buildTimeColumn('Working Hrs', entry.formattedWorkingHours, AppColors.textDark)),
        ]),
      ),
    );
  }

  Widget _buildDateBadge(AttendanceLogEntry entry, {required Color accentColor}) {
    return SizedBox(
      width: 40,
      child: Column(children: [
        Text(
          entry.date.day.toString().padLeft(2, '0'),
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        Text(
          entry.dayAbbrev,
          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor),
        ),
      ]),
    );
  }

  Widget _buildTimeColumn(String label, String value, Color valueColor) {
    return Column(children: [
      Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
    ]);
  }
}