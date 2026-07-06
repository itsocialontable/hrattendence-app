import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_providers.dart';
import '../../theme/app_theme.dart';
import 'admin_attendance_screen.dart';
import 'admin_salary_screen.dart';
import 'admin_salary_calculate_screen.dart';
import 'admin_attendance_rules_screen.dart';
import 'admin_setting_screen.dart';
import 'admin_employee_screen.dart';
import 'admin_leave_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_review_screen.dart';
import 'change_password_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Bottom nav layout (as requested):
  //   Left  → 0: Salary  | 1: Reviews
  //   Center→ 2: Dashboard  (elevated dock)
  //   Right → 3: Employees | 4: Attendance
  int _currentIndex = 2; // start on Dashboard

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardProvider>().fetchStats();
      context.read<AdminNotificationsProvider>().fetchNotifications();
    });
  }

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0:
        return const AdminEmployeeScreen();
      case 1:
        return const AdminAttendanceScreen();
      case 2:
        return _buildHome(context.watch<AuthProvider>().user);
      case 3:
        return const AdminReviewScreen();
      case 4:
        return const AdminSalaryScreen();
      default:
        return _buildHome(context.watch<AuthProvider>().user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildScreen(),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  // ── Home / Dashboard ─────────────────────────────────────────────────────────

  Widget _buildHome(dynamic user) {
    final dp = context.watch<AdminDashboardProvider>();
    final stats = dp.stats;

    final statItems = [
      _StatItem('Total Employees', stats?.totalEmployees.toString() ?? '—',
          Icons.people_alt_outlined, AppColors.secondary, AppColors.secondaryBg),
      _StatItem('Present Today', stats?.presentToday.toString() ?? '—',
          Icons.check_circle_outline, AppColors.success, AppColors.successBg),
      _StatItem('On Leave', stats?.onLeave.toString() ?? '—',
          Icons.event_busy_outlined, AppColors.warning, AppColors.warningBg),
      _StatItem('Absent', stats?.absent.toString() ?? '—',
          Icons.cancel_outlined, AppColors.error, AppColors.errorBg),
    ];

    return RefreshIndicator(
      onRefresh: () => context.read<AdminDashboardProvider>().fetchStats(),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary]),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4))),
                    child: const Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin Panel',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12)),
                            Text(user?.name ?? 'Admin',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ])),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const AdminNotificationsScreen())),
                    child: Stack(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white, size: 22),
                      ),
                      Consumer<AdminNotificationsProvider>(
                        builder: (context, notifProvider, _) {
                          if (notifProvider.unreadCount == 0)
                            return const SizedBox.shrink();
                          return Positioned(
                            right: 8, top: 8,
                            child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle)),
                          );
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => _buildSettingsTab())),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.settings_outlined,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border:
                    Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Today',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(_todayDate(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ]),
                ),
              ]),
            ),
          ),

          // Error banner
          if (dp.hasError)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(dp.error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 12))),
                    TextButton(
                      onPressed: () =>
                          context.read<AdminDashboardProvider>().fetchStats(),
                      child: const Text('Retry',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ]),
                ),
              ),
            ),

          // Stats grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overview',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    const SizedBox(height:5),
                    dp.isLoading
                        ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)))
                        : GridView.count(
                      padding: EdgeInsets.zero,
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: statItems
                          .map((s) => _StatCard(stat: s))
                          .toList(),
                    ),
                  ]),
            ),
          ),

          // Quick actions
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: _QuickActionCard(
                              icon: Icons.person_add_outlined,
                              label: 'Add Employee',
                              color: AppColors.secondary,
                              onTap: () =>
                                  setState(() => _currentIndex = 0))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _QuickActionCard(
                              icon: Icons.assignment_outlined,
                              label: 'Leave Requests',
                              color: AppColors.warning,
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const AdminLeaveScreen())))),
                      const SizedBox(width: 12),
                      // Expanded(
                      //     child: _QuickActionCard(
                      //         icon: Icons.rate_review_outlined,
                      //         label: 'Add Review',
                      //         color: AppColors.accent,
                      //         onTap: () =>
                      //             setState(() => _currentIndex = 1))),
                    ]),
                    const SizedBox(height: 14),
                  ]),
            ),
          ),

          // Today attendance
          // SliverPadding(
          //   padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          //   sliver: SliverToBoxAdapter(
          //     child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Row(
          //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //               children: [
          //                 const Text("Today's Attendance",
          //                     style: TextStyle(
          //                         fontSize: 18,
          //                         fontWeight: FontWeight.bold,
          //                         color: AppColors.textDark)),
          //                 TextButton(
          //                   onPressed: () =>
          //                       setState(() => _currentIndex = 4),
          //                   child: const Text('View All',
          //                       style: TextStyle(
          //                           color: AppColors.secondary,
          //                           fontWeight: FontWeight.w600)),
          //                 ),
          //               ]),
          //           const SizedBox(height: 12),
          //           dp.isLoading
          //               ? const Center(
          //               child: CircularProgressIndicator(
          //                   color: AppColors.primary))
          //               : stats != null
          //               ? _LiveAttendanceSummary(stats: stats)
          //               : _PlaceholderAttendance(),
          //         ]),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    final adminUser = context.watch<AuthProvider>().user;
    final adminName = (adminUser?.name.isNotEmpty ?? false)
        ? adminUser!.name
        : 'Administrator';
    final adminEmail =
    (adminUser?.email.isNotEmpty ?? false) ? adminUser!.email : '—';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Administrator',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          color: Colors.white,
          child: Row(children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(adminName,
                          style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(adminEmail,
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 14)),
                    ])),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            children: [
              // _SettingsTile(Icons.business_rounded, 'Company Settings',
              //     AppColors.secondaryBg, AppColors.secondary, () {
              //       Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //               builder: (_) =>
              //                   AdminCompanySettingsScreen()));
              //     }),
              _SettingsTile(Icons.people_alt_rounded, 'Salary Calculate',
                  AppColors.secondaryBg, AppColors.secondary, () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminSalaryCalculateScreen()));
                  }),
              _SettingsTile(
                  Icons.notifications_rounded,
                  'Notifications',
                  AppColors.warningBg,
                  AppColors.warning, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const AdminNotificationsScreen()));
              }),
              _SettingsTile(Icons.lock_rounded, 'Change Password',
                  AppColors.successBg, AppColors.success, () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen()));
                  }),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  context.read<AuthProvider>().logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 14),
                    const Text('Sign Out',
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  String _todayDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

// ── Custom Bottom Nav with docked center button ───────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Layout: Salary | Reviews | [Dashboard dock] | Employees | Attendance
    // const items = [
    //   _NavItem(Icons.payments_outlined, Icons.payments, 'Salary', 0),
    //   _NavItem(Icons.star_outline_rounded, Icons.star_rounded, 'Reviews', 1),
    //   _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 2),
    //   _NavItem(Icons.people_outline, Icons.people, 'Employees', 3),
    //   _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Attendance', 4),
    // ];
    const items = [
      _NavItem(Icons.people_outline, Icons.people, 'Employees', 0),
      _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Attendance', 1),
      _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 2),
      _NavItem(Icons.star_outline_rounded, Icons.star_rounded, 'Reviews', 3),

      _NavItem(Icons.payments_outlined, Icons.payments, 'Salary', 4),



    ];

    return SafeArea(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final isActive = currentIndex == item.index;
            final isCenter = item.index == 2;

            if (isCenter) {
              // Elevated dock button
              return GestureDetector(
                onTap: () => onTap(item.index),
                child: Transform.translate(
                  offset: const Offset(0, -14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? AppColors.primaryGradient
                              : const LinearGradient(
                            colors: [
                              AppColors.primaryLight,
                              AppColors.secondary
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Regular tab
            return GestureDetector(
              onTap: () => onTap(item.index),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 68,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textLight,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  const _NavItem(this.icon, this.activeIcon, this.label, this.index);
}

// ── Attendance summary widgets ────────────────────────────────────────────────

class _LiveAttendanceSummary extends StatelessWidget {
  final dynamic stats;
  const _LiveAttendanceSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadow.card),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _SummaryRow('Present', stats.presentToday.toString(),
              AppColors.success),
          const Divider(height: 16, color: AppColors.border),
          _SummaryRow(
              'On Leave', stats.onLeave.toString(), AppColors.warning),
          const Divider(height: 16, color: AppColors.border),
          _SummaryRow('Absent', stats.absent.toString(), AppColors.error),
          if (stats.lateToday != null && stats.lateToday > 0) ...[
            const Divider(height: 16, color: AppColors.border),
            _SummaryRow(
                'Late', stats.lateToday.toString(), AppColors.warning),
          ],
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
        width: 10,
        height: 10,
        decoration:
        BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 10),
    Text(label,
        style: const TextStyle(
            fontSize: 14, color: AppColors.textMid)),
    const Spacer(),
    Text(value,
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color)),
  ]);
}

class _PlaceholderAttendance extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.card),
    padding: const EdgeInsets.all(20),
    child: const Center(
        child: Text('Pull to refresh to load live data',
            style: TextStyle(
                color: AppColors.textLight, fontSize: 13))),
  );
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _StatItem(this.label, this.value, this.icon, this.color, this.bg);
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.card),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: stat.bg,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(stat.icon, color: stat.color, size: 18)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stat.value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: stat.color)),
            Text(stat.label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textLight)),
          ]),
        ]),
  );
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding:
      const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadow.card),
      child: Column(children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
      ]),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  const _SettingsTile(
      this.icon, this.label, this.iconBg, this.iconColor, this.onTap);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.subtle),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark))),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight),
          ]),
        ),
      ),
    ),
  );
}