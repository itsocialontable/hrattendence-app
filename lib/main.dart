import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm_attendance_app/screens/admin/admin_attendance_screen.dart';
import 'package:hrm_attendance_app/screens/admin/admin_employee_screen.dart';
import 'package:hrm_attendance_app/screens/admin/admin_leave_screen.dart';
import 'package:hrm_attendance_app/services/leave_service.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';
import 'screens/attendance_dashboard.dart';
import 'screens/team_reports_screen.dart';
import 'screens/employee_profile_screen.dart';
import 'screens/attendance_history_screen.dart';
import 'screens/leave_management_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'services/api_service.dart';
import 'services/attendance_service.dart';
import 'services/biometric_service.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/leave_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const HRMApp());
}

class HRMApp extends StatelessWidget {
  const HRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Core Services ──
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<BiometricService>(
          create: (_) => BiometricService(),
        ),
        Provider<AttendanceService>(
          create: (ctx) => AttendanceService(
            apiService: ctx.read<ApiService>(),
          ),
        ),

        // ── Auth ──
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(
            apiService: ctx.read<ApiService>(),
          )..initialize(),
        ),

        // ── Profile ──
        ChangeNotifierProvider<ProfileProvider>(
          create: (ctx) => ProfileProvider(
            apiService: ctx.read<ApiService>(),
          ),
        ),

        // ── Dashboard / Employee Stats ──
        ChangeNotifierProvider<EmployeeStatsProvider>(
          create: (ctx) => EmployeeStatsProvider(
            apiService: ctx.read<ApiService>(),
          ),
        ),

        // ── Attendance ──
        ChangeNotifierProvider<AttendanceProvider>(
          create: (ctx) => AttendanceProvider(
            attendanceService: ctx.read<AttendanceService>(),
            biometricService: ctx.read<BiometricService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              ProfileProvider(apiService: ctx.read<ApiService>()),
        ),

        // ── Leave ──
        Provider<LeaveService>(
          create: (context) => LeaveService(
            apiService: context.read<ApiService>(),
          ),
        ),
        ChangeNotifierProvider<LeaveProvider>(
          create: (context) => LeaveProvider(
            leaveService: context.read<LeaveService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'HRM Attendance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const MainShell(),
          '/login': (context) => const LoginScreen(),
          '/splash': (context) => const SplashScreen(),
          '/admin-login': (context) => const AdminLoginScreen(),
          '/admin-home': (context) => const AdminDashboard(),
          '/employee-attendence': (context) => const AdminAttendanceScreen(),
          '/add-employee': (context) => const AdminEmployeeScreen(),
          '/leave': (context) => const AdminLeaveScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading && !authProvider.isLoggedIn) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }
        if (authProvider.isLoggedIn) {
          // Route to admin dashboard if role is admin
          if (authProvider.user?.role == 'admin') {
            return const AdminDashboard();
          }
          return const MainShell();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AttendanceDashboard(),
    const AttendanceHistoryScreen(),
    const LeaveManagementScreen(),
    const TeamReportsScreen(),
    const EmployeeProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: SafeArea(
        child: AppBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}
