import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Home'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Attendance'},
      {'icon': Icons.event_note_rounded, 'label': 'Leave'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Reports'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.asMap().entries.map((e) {
          final isActive = currentIndex == e.key;
          final color = isActive ? AppColors.primary : AppColors.textLight;
          return GestureDetector(
            onTap: () => onTap(e.key),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 60,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 40 : 0,
                  height: isActive ? 4 : 0,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 4),
                Icon(e.value['icon'] as IconData, color: color, size: 24),
                const SizedBox(height: 2),
                Text(e.value['label'] as String, style: GoogleFonts.poppins(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: color)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}
