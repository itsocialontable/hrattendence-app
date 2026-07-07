import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/auth_provider.dart';
import '../services/review_service.dart';
import '../models/review_models.dart';
import '../models/auth_models.dart';

/// Employee "Reports" tab (bottom nav) — shows the signed-in employee's own
/// review & attendance performance, backed by:
///   GET /api/reviews/employee/:userId
///   GET /api/reviews/avg-rating/:userId
///   GET /api/reviews/attendance-rate/:userId
///   GET /api/reviews/graph/:userId
///   GET /api/reviews/monthly-summary/:userId
class TeamReportsScreen extends StatefulWidget {
  const TeamReportsScreen({super.key});

  @override
  State<TeamReportsScreen> createState() => _TeamReportsScreenState();
}

class _TeamReportsScreenState extends State<TeamReportsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  EmployeeReportsBundle? _bundle;

  late final AnimationController _entrance;
  late final Animation<double> _fade;

  String get _userId => context.read<AuthProvider>().user?.id ?? '';
  String get _userName => context.read<AuthProvider>().user?.name ?? 'Employee';
  String? get _token => context.read<AuthProvider>().token;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    final userId = _userId;
    if (userId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please login again to view your reports.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ReviewService(token: _token);
      final bundle = await service.getReportsBundle(userId);
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
      });
      _entrance.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Could not load your reports. Pull to refresh.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 20),
            if (_loading) _buildLoadingState(),
            if (!_loading && _error != null)
              ErrorStateCard(message: _error!, onRetry: _fetchAll),
            if (!_loading && _error == null && _bundle != null)
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(_fade),
                  child: _buildContent(_bundle!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Reports',
                style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            Text(_userName, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid)),
          ],
        ),
        GestureDetector(
          onTap: _loading ? null : _fetchAll,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(child: ShimmerStatCard()),
            SizedBox(width: 12),
            Expanded(child: ShimmerStatCard()),
          ],
        ),
        const SizedBox(height: 20),
        const ShimmerBox(height: 220, borderRadius: BorderRadius.all(Radius.circular(24))),
        const SizedBox(height: 20),
        const ShimmerBox(height: 220, borderRadius: BorderRadius.all(Radius.circular(24))),
      ],
    );
  }

  Widget _buildContent(EmployeeReportsBundle bundle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingAndAttendanceRow(bundle),
        const SizedBox(height: 20),
        _buildTrendCard(bundle.graph),
        const SizedBox(height: 20),
        _buildMonthlySummaryCard(bundle.graph),
        const SizedBox(height: 24),
        SectionHeader(title: 'Recent Reviews', action: bundle.reviews.isEmpty ? null : '${bundle.reviews.length} total'),
        const SizedBox(height: 16),
        _buildReviewsList(bundle.reviews),
      ],
    );
  }

  // ── Avg Rating + Attendance Rate (circular, animated) ─────────────────────
  Widget _buildRatingAndAttendanceRow(EmployeeReportsBundle bundle) {
    final avg = bundle.avgRating;
    final att = bundle.attendanceRate;

    return Row(
      children: [
        Expanded(
          child: PremiumCard(
            gradient: AppColors.darkGradient,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
            child: Column(
              children: [
                CircularPercentIndicator(
                  radius: 46,
                  lineWidth: 8,
                  percent: (avg.avgRating / 5).clamp(0.0, 1.0),
                  animation: true,
                  animationDuration: 900,
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: AppColors.accentLight,
                  backgroundColor: Colors.white.withOpacity(0.12),
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(avg.avgRating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('/ 5', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Avg Rating', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  avg.totalReviews > 0 ? '${avg.totalReviews} reviews' : 'No reviews yet',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumCard(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
            child: Column(
              children: [
                CircularPercentIndicator(
                  radius: 46,
                  lineWidth: 8,
                  percent: (att.attendanceRate / 100).clamp(0.0, 1.0),
                  animation: true,
                  animationDuration: 900,
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: AppColors.success,
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${att.attendanceRate.toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Attendance', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(
                  att.totalDays > 0 ? '${att.presentDays}/${att.totalDays} days' : 'No data yet',
                  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Trend card — rating pulse line with live delta chip ───────────────────
  Widget _buildTrendCard(GraphData graph) {
    final points = graph.points;
    final rated = points.where((p) => p.avgRating > 0).toList();
    final latest = rated.isNotEmpty ? rated.last.avgRating : 0.0;
    final double? delta = rated.length >= 2
        ? rated.last.avgRating - rated[rated.length - 2].avgRating
        : null;

    return PremiumCard(
      gradient: AppColors.darkGradient,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Performance Trend',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('Rating over the last ${points.length} months',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                ],
              ),
              if (rated.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(latest.toStringAsFixed(1),
                            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 2),
                          child: Text('/5', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                        ),
                      ],
                    ),
                    if (delta != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (delta >= 0 ? AppColors.successLight : AppColors.errorLight).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              delta >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: 11,
                              color: delta >= 0 ? AppColors.successLight : AppColors.errorLight,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              delta.abs().toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: delta >= 0 ? AppColors.successLight : AppColors.errorLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: points.length < 2
                ? Center(
              child: Text('Not enough data yet',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.5))),
            )
                : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.white.withOpacity(0.06), strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (val, _) {
                        final i = val.round();
                        if (val != i.toDouble()) return const SizedBox();
                        if (i < 0 || i >= points.length) return const SizedBox();
                        final isLast = i == points.length - 1;
                        final skip = (points.length / 6).ceil();
                        if (!isLast && i % skip != 0) return const SizedBox();
                        final shortLabel = points[i].label.split(' ').first;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            shortLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: isLast ? FontWeight.w700 : FontWeight.w400,
                              color: isLast ? Colors.white : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].avgRating),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    gradient: LinearGradient(colors: [AppColors.accentLight, Colors.white.withOpacity(0.9)]),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final isLast = index == points.length - 1;
                        final hasData = points[index].avgRating > 0;
                        return FlDotCirclePainter(
                          radius: isLast ? 5 : (hasData ? 2.5 : 0),
                          color: isLast ? Colors.white : AppColors.accentLight,
                          strokeWidth: isLast ? 3 : 0,
                          strokeColor: Colors.white.withOpacity(0.35),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.22), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Monthly summary — scannable dual-metric progress rows ─────────────────
  Widget _buildMonthlySummaryCard(GraphData graph) {
    final months = graph.points;
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Summary',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Last ${months.length} months at a glance',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(AppColors.primary, 'Rating'),
                  const SizedBox(width: 10),
                  _legendDot(AppColors.secondary, 'Attendance'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (months.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No monthly data yet',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < months.length; i++) ...[
                  _monthSummaryRow(months[i], i),
                  if (i != months.length - 1) const SizedBox(height: 16),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _monthSummaryRow(GraphPoint point, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 550 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              child: Text(
                point.label,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMid),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metricBar(
                    fraction: (point.avgRating / 5).clamp(0.0, 1.0) * t,
                    color: AppColors.primary,
                    valueLabel: point.avgRating > 0 ? point.avgRating.toStringAsFixed(1) : '–',
                  ),
                  const SizedBox(height: 7),
                  _metricBar(
                    fraction: (point.attendanceRate / 100).clamp(0.0, 1.0) * t,
                    color: AppColors.secondary,
                    valueLabel: '${point.attendanceRate.toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metricBar({required double fraction, required Color color, required String valueLabel}) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 7,
              color: color.withOpacity(0.12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
      ],
    );
  }

  // ── Reviews list ────────────────────────────────────────────────────────────
  Widget _buildReviewsList(List<ReviewItem> reviews) {
    if (reviews.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.rate_review_outlined, color: AppColors.textLight, size: 32),
              const SizedBox(height: 10),
              Text('No reviews yet', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: reviews.map((r) {
        final initials = r.reviewerName.trim().isEmpty
            ? '?'
            : r.reviewerName.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppAvatar(initials: initials, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.reviewerName,
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          if (r.date != null)
                            Text(DateFormat('d MMM yyyy').format(r.date!),
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    _buildStars(r.rating),
                  ],
                ),
                if (r.category.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  TagBadge(label: r.category, color: AppColors.secondary),
                ],
                if (r.comment.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(r.comment, style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textMid, height: 1.4)),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (rating >= i + 1) {
          icon = Icons.star_rounded;
        } else if (rating > i && rating < i + 1) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: 14, color: AppColors.warning);
      }),
    );
  }
}