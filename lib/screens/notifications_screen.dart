import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
          _buildPinnedAlert(),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Today'),
          const SizedBox(height: 12),
          ..._buildTodayNotifs(),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Earlier'),
          const SizedBox(height: 12),
          ..._buildEarlierNotifs(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Notifications',
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('Mark all read',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildPinnedAlert() {
    return PremiumCard(
      gradient: AppColors.darkGradient,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_rounded, color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3 Feb 2019 – Closed for Renovation',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Office will be closed for maintenance. Plan accordingly.',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTodayNotifs() {
    final notifs = [
      {
        'name': 'Ferdinand Karl',
        'action': 'Applied for Annual Leave',
        'detail': 'From 10 Dec – 12 Dec',
        'type': 'leave',
        'time': '2m ago',
        'unread': true,
        'actions': true,
      },
      {
        'name': 'Jennifer',
        'action': 'Applied Time Update Request',
        'detail': 'To Dec: 10th Feb 2018',
        'type': 'time',
        'time': '15m ago',
        'unread': true,
        'actions': true,
      },
      {
        'name': 'Eva Istry',
        'action': 'Applied for Casual Leave',
        'detail': 'To 16 February 2018',
        'type': 'leave',
        'time': '1h ago',
        'unread': true,
        'actions': false,
      },
    ];

    return notifs.map((n) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _buildNotifCard(n),
    )).toList();
  }

  List<Widget> _buildEarlierNotifs() {
    final notifs = [
      {
        'name': 'alana janti',
        'action': 'Applied for Casual Leave',
        'detail': 'To 16 February 2018',
        'type': 'leave',
        'time': 'Yesterday',
        'unread': false,
        'actions': false,
      },
      {
        'name': 'Ferdinand Karl',
        'action': 'Applied for Annual Leave',
        'detail': '9th March – 15th March',
        'type': 'leave',
        'time': 'Dec 12',
        'unread': false,
        'actions': false,
      },
      {
        'name': 'Ferdinand Karl',
        'action': 'Applied for Annual Leave',
        'detail': 'Dec 13 – Dec 20',
        'type': 'leave',
        'time': 'Dec 10',
        'unread': false,
        'actions': false,
      },
    ];

    return notifs.map((n) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _buildNotifCard(n),
    )).toList();
  }

  Widget _buildNotifCard(Map<String, dynamic> notif) {
    final isUnread = notif['unread'] as bool;
    final hasActions = notif['actions'] as bool;
    final type = notif['type'] as String;
    final color = type == 'leave' ? AppColors.primary : AppColors.secondary;
    final name = notif['name'] as String;
    final initials = name.split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return PremiumCard(
      padding: const EdgeInsets.all(14),
      color: isUnread ? AppColors.white : AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AppAvatar(
                    initials: initials,
                    size: 42,
                    gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  ),
                  if (isUnread)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: name,
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                          TextSpan(
                            text: ' ${notif['action']}',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textMid),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(notif['detail'] as String,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
              Text(notif['time'] as String,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
          if (hasActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.successGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('APPROVE',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text('REJECT',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
