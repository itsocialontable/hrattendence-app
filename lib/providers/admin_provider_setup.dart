import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'admin_providers.dart';
import '../services/admin_api_service.dart';

/// Drop-in MultiProvider wrapper.
/// Wrap your MaterialApp (or the admin route subtree) with this.
///
/// Usage:
///   runApp(AdminProviderSetup(child: MyApp()));
///
/// Or wrap only the admin navigator:
///   AdminProviderSetup(child: AdminDashboardV2())
class AdminProviderSetup extends StatelessWidget {
  final Widget child;
  const AdminProviderSetup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Grab the existing ApiService from above in the tree
    final baseApi = context.read<ApiService>();
    final adminApi = AdminApiService(baseApi);

    return MultiProvider(
      providers: [
        // Auth flows (register, forgot-pw, otp, reset-pw)
        ChangeNotifierProvider(
          create: (_) => AdminAuthProvider(adminApi),
        ),
        // Dashboard stats
        ChangeNotifierProvider(
          create: (_) => AdminDashboardProvider(adminApi),
        ),
        // Employee CRUD
        ChangeNotifierProvider(
          create: (_) => AdminEmployeeProvider(adminApi),
        ),
        // Attendance (view + manual edit)
        ChangeNotifierProvider(
          create: (_) => AdminAttendanceProvider(adminApi),
        ),
        // Leave approval / rejection
        ChangeNotifierProvider(
          create: (_) => AdminLeaveProvider(adminApi),
        ),
        // Salary & payroll generation
        ChangeNotifierProvider(
          create: (_) => AdminSalaryProvider(adminApi),
        ),
        // Attendance rules + global company settings
        ChangeNotifierProvider(
          create: (_) => AdminSettingsProvider(adminApi),
        ),
      ],
      child: child,
    );
  }
}
