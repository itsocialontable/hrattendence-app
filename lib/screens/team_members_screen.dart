import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  String _selectedTeam = 'All';
  final teams = ['All', 'Design', 'Engineering', 'Marketing', 'Sales'];

  final List<Map<String, dynamic>> members = [
    {'name': 'Natasha Kirovska', 'role': 'Creative Director', 'team': 'Design', 'status': 'Online', 'hours': '8h 20m', 'in': '09:00', 'color': AppColors.primary, 'perf': 0.94},
    {'name': 'Jennifer Liu', 'role': 'UI Designer', 'team': 'Design', 'status': 'Online', 'hours': '7h 45m', 'in': '09:02', 'color': AppColors.secondary, 'perf': 0.88},
    {'name': 'Jun Cho', 'role': 'Sales Executive', 'team': 'Sales', 'status': 'Online', 'hours': '9h 00m', 'in': '08:55', 'color': AppColors.accent, 'perf': 0.91},
    {'name': 'Ida Nikkanen', 'role': 'Sales Manager', 'team': 'Sales', 'status': 'Away', 'hours': '6h 10m', 'in': '10:15', 'color': AppColors.warning, 'perf': 0.76},
    {'name': 'Violanna Kiser', 'role': 'Marketing Lead', 'team': 'Marketing', 'status': 'Online', 'hours': '8h 50m', 'in': '09:05', 'color': AppColors.success, 'perf': 0.92},
    {'name': 'Jonathan Hunz', 'role': 'Backend Engineer', 'team': 'Engineering', 'status': 'Online', 'hours': '9h 20m', 'in': '08:45', 'color': AppColors.primary, 'perf': 0.97},
    {'name': 'Marie Palmer', 'role': 'Product Designer', 'team': 'Design', 'status': 'Offline', 'hours': '–', 'in': '–', 'color': AppColors.error, 'perf': 0.0},
    {'name': 'Elizabeth Olsen', 'role': 'Content Writer', 'team': 'Marketing', 'status': 'Online', 'hours': '7h 30m', 'in': '09:20', 'color': AppColors.secondary, 'perf': 0.85},
    {'name': 'J. Scaife', 'role': 'Frontend Engineer', 'team': 'Engineering', 'status': 'Away', 'hours': '5h 15m', 'in': '10:40', 'color': AppColors.warning, 'perf': 0.72},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedTeam == 'All'
        ? members
        : members.where((m) => m['team'] == _selectedTeam).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildTeamStats(),
              const SizedBox(height: 20),
              _buildTeamFilter(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: filtered.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildMemberCard(filtered[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Teams',
                style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            Text('${members.length} members total',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid)),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.subtle,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: AppColors.textLight, size: 22),
          const SizedBox(width: 10),
          Text('Search members...',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildTeamStats() {
    final online = members.where((m) => m['status'] == 'Online').length;
    final away = members.where((m) => m['status'] == 'Away').length;
    final offline = members.where((m) => m['status'] == 'Offline').length;

    return Row(
      children: [
        Expanded(child: _buildMiniStatCard('$online', 'Online', AppColors.success)),
        const SizedBox(width: 10),
        Expanded(child: _buildMiniStatCard('$away', 'Away', AppColors.warning)),
        const SizedBox(width: 10),
        Expanded(child: _buildMiniStatCard('$offline', 'Offline', AppColors.error)),
      ],
    );
  }

  Widget _buildMiniStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamFilter() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: teams.map((t) {
          final isSelected = _selectedTeam == t;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTeam = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? AppShadow.strong : AppShadow.subtle,
                ),
                child: Text(t,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textMid,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final color = member['color'] as Color;
    final status = member['status'] as String;
    Color statusColor;
    switch (status) {
      case 'Online': statusColor = AppColors.success; break;
      case 'Away': statusColor = AppColors.warning; break;
      default: statusColor = AppColors.error;
    }
    final name = member['name'] as String;
    final initials = name.split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    final perf = member['perf'] as double;

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AppAvatar(
            initials: initials,
            size: 48,
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            showBadge: true,
            badgeColor: statusColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                Text(member['role'] as String,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
                if (perf > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: perf,
                            backgroundColor: color.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(perf * 100).toInt()}%',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TagBadge(label: status, color: statusColor),
              const SizedBox(height: 6),
              Text(member['in'] as String,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid)),
              Text('Check In', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }
}
