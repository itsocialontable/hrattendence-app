import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TeamReportsScreen extends StatefulWidget {
  const TeamReportsScreen({super.key});

  @override
  State<TeamReportsScreen> createState() => _TeamReportsScreenState();
}

class _TeamReportsScreenState extends State<TeamReportsScreen> {
  int _selectedFilter = 0;
  final filters = ['Week', 'Month', 'Quarter', 'Year'];

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
          _buildFilterRow(),
          const SizedBox(height: 24),
          _buildPunctualityCard(),
          const SizedBox(height: 20),
          _buildWorkingHoursCard(),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Team Performance'),
          const SizedBox(height: 16),
          _buildTeamPerformanceList(),
          const SizedBox(height: 24),
          _buildSummaryCards(),
        ],
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
            Text('Team Reports', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            Text('May 2019 – May 2019', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid)),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: filters.asMap().entries.map((e) {
        final isSelected = _selectedFilter == e.key;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? AppShadow.strong : AppShadow.subtle,
              ),
              child: Text(
                e.value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textMid,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPunctualityCard() {
    return PremiumCard(
      gradient: AppColors.darkGradient,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Avg Team Punctuality',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text('+4.2%', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: LineChart(
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
                        const days = ['Day 1', 'Day 7', 'Day 14', 'Day 21', 'Day 28'];
                        if (val.toInt() >= 0 && val.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(days[val.toInt()],
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
                maxX: 4,
                minY: 60,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 82), FlSpot(1, 78), FlSpot(2, 90), FlSpot(3, 86), FlSpot(4, 92),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('19.9 Days', 'Late', Colors.white),
              _buildMiniStat('2 Days', 'Absent', Colors.white),
              _buildMiniStat('Over 31 Days', 'Total', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildWorkingHoursCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Working Hours & Timings',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 16),
          ..._buildHoursBars(),
        ],
      ),
    );
  }

  List<Widget> _buildHoursBars() {
    final data = [
      {'name': 'JL', 'label': 'Jennifer Liu', 'hours': 0.92, 'color': AppColors.primary},
      {'name': 'MW', 'label': 'Marcus Webb', 'hours': 0.75, 'color': AppColors.secondary},
      {'name': 'AS', 'label': 'Aria Santos', 'hours': 0.88, 'color': AppColors.accent},
      {'name': 'TB', 'label': 'Tom Bradley', 'hours': 0.60, 'color': AppColors.warning},
    ];

    return data.map((d) {
      final color = d['color'] as Color;
      final hours = d['hours'] as double;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            AppAvatar(initials: d['name'] as String, size: 36, gradient: LinearGradient(colors: [color, color.withOpacity(0.7)])),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(d['label'] as String,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      Text('${(hours * 9).toStringAsFixed(1)}h',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: hours,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTeamPerformanceList() {
    final teams = [
      {'team': 'Other Team', 'score': 94, 'members': 8, 'color': AppColors.success},
      {'team': 'Sales & Marketing', 'score': 87, 'members': 12, 'color': AppColors.primary},
      {'team': 'Engineering', 'score': 91, 'members': 15, 'color': AppColors.secondary},
    ];

    return Column(
      children: teams.map((t) {
        final color = t['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.groups_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['team'] as String,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      Text('${t['members']} members',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${t['score']}%',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: PremiumCard(
            gradient: AppColors.primaryGradient,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.access_time_rounded, color: Colors.white70, size: 24),
                const SizedBox(height: 12),
                Text('Avg Hours/Day', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                Text('8.4 hrs', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumCard(
            gradient: AppColors.accentGradient,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.people_alt_rounded, color: Colors.white70, size: 24),
                const SizedBox(height: 12),
                Text('Attendance Rate', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                Text('92.4%', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
