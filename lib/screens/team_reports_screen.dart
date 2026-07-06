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
        _buildMonthlySummaryCard(bundle.monthlySummary),
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

  // ── Trend line chart (animated) ────────────────────────────────────────────
  Widget _buildTrendCard(GraphData graph) {
    return PremiumCard(
      gradient: AppColors.darkGradient,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Trend',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: graph.points.length < 2
                ? Center(
              child: Text('Not enough data yet',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.5))),
            )
                : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.white.withOpacity(0.08), strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i >= 0 && i < graph.points.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(graph.points[i].label,
                                style: GoogleFonts.poppins(fontSize: 9, color: Colors.white.withOpacity(0.4))),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (graph.points.length - 1).toDouble(),
                minY: 0,
                maxY: _niceMaxY(graph.points.map((p) => p.value).toList()),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < graph.points.length; i++)
                        FlSpot(i.toDouble(), graph.points[i].value),
                    ],
                    isCurved: true,
                    gradient: AppColors.primaryGradient,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.25), Colors.transparent],
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

  double _niceMaxY(List<double> values) {
    if (values.isEmpty) return 100;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 5) return 5; // looks like a 0-5 rating trend
    if (maxVal <= 10) return 10;
    return 100;
  }

  // ── Monthly summary grouped bar chart (animated) ──────────────────────────
  Widget _buildMonthlySummaryCard(MonthlySummaryData summary) {
    final months = summary.months;
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Summary',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              Row(
                children: [
                  _legendDot(AppColors.primary, 'Rating'),
                  const SizedBox(width:3),
                  _legendDot(AppColors.secondary, 'Attendance'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: months.isEmpty
                ? Center(
              child: Text('No monthly data yet',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
            )
                : BarChart(
              BarChartData(
                maxY: 100,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i >= 0 && i < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(months[i].month,
                                style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textLight)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < months.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (months[i].avgRating * 20).clamp(0, 100),
                          color: AppColors.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: months[i].attendanceRate.clamp(0, 100),
                          color: AppColors.secondary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      barsSpace: 6,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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