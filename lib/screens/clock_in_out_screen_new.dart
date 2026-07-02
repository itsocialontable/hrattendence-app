import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/attendance_widgets.dart';

class ClockInOutScreen extends StatefulWidget {
  const ClockInOutScreen({super.key});

  @override
  State<ClockInOutScreen> createState() => _ClockInOutScreenState();
}

class _ClockInOutScreenState extends State<ClockInOutScreen> {
  String _selectedLocation = 'Office Jaipur';

  @override
  void initState() {
    super.initState();
    // Initialize attendance state on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().initialize();
    });
  }

  void _handleCheckIn() async {
    final provider = context.read<AttendanceProvider>();
    
    if (provider.isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already checked in today'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await provider.checkIn(
      location: _selectedLocation,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.successMessage ?? 'Check-in successful'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        provider.clearMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Check-in failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _handleCheckOut() async {
    final provider = context.read<AttendanceProvider>();
    
    if (!provider.isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check-in first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await provider.checkOut(
      location: _selectedLocation,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.successMessage ?? 'Check-out successful'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        provider.clearMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Check-out failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Consumer<AttendanceProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // Real-time Clock
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: RealTimeClockWidget(),
                  ),
                ),
                const SizedBox(height: 32),

                // Attendance Status Cards
                if (provider.isCheckedIn)
                  AttendanceStatusCard(
                    title: 'Checked In',
                    subtitle: 'At ${provider.attendanceState?.checkInTime}',
                    icon: Icons.login_rounded,
                    backgroundColor: Colors.green,
                    iconColor: Colors.white,
                    isLate: provider.attendanceState?.isLate ?? false,
                    isHalfDay: provider.attendanceState?.isHalfDay ?? false,
                    warningCount: provider.attendanceState?.warningCount,
                    maxWarnings: provider.attendanceState?.maxWarnings,
                  )
                else if (provider.isCheckedOut)
                  AttendanceStatusCard(
                    title: 'Checked Out',
                    subtitle: 'At ${provider.attendanceState?.checkOutTime}',
                    icon: Icons.logout_rounded,
                    backgroundColor: Colors.blue,
                    iconColor: Colors.white,
                    isLate: provider.attendanceState?.isLate ?? false,
                    isHalfDay: provider.attendanceState?.isHalfDay ?? false,
                    warningCount: provider.attendanceState?.warningCount,
                    maxWarnings: provider.attendanceState?.maxWarnings,
                  )
                else
                  AttendanceStatusCard(
                    title: 'Not Checked In',
                    subtitle: 'Tap the button below to check in',
                    icon: Icons.schedule_rounded,
                    backgroundColor: Colors.grey,
                    iconColor: Colors.white,
                  ),

                const SizedBox(height: 24),

                // Location Selection
                _buildLocationSelector(),
                const SizedBox(height: 24),

                // Working Duration (if checked in)
                if (provider.isCheckedIn)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        WorkingDurationWidget(
                          checkInTime: provider.attendanceState?.checkInTime ?? '09:00',
                        ),
                      ],
                    ),
                  ),

                if (provider.isCheckedIn) const SizedBox(height: 24),

                // Check In / Check Out Buttons
                Row(
                  children: [
                    Expanded(
                      child: AttendanceButton(
                        label: 'Check In',
                        icon: Icons.login_rounded,
                        onPressed: _handleCheckIn,
                        isLoading: provider.isBiometricLoading || (provider.isLoading && !provider.isCheckedIn),
                        isDisabled: provider.isCheckedIn,
                        backgroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AttendanceButton(
                        label: 'Check Out',
                        icon: Icons.logout_rounded,
                        onPressed: _handleCheckOut,
                        isLoading: provider.isBiometricLoading || (provider.isLoading && provider.isCheckedIn),
                        isDisabled: !provider.isCheckedIn || provider.isCheckedOut,
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Biometric Status
                _buildBiometricStatus(provider),

                const SizedBox(height: 24),

                // Attendance Details
                if (provider.attendanceState != null)
                  _buildAttendanceDetails(provider),
              ],
            );
          },
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
            const Text(
              'Attendance',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              DateTime.now().toString().split(' ')[0],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Online',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedLocation,
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          'Office Jaipur',
          'Office Delhi',
          'Office Bangalore',
          'Work from Home',
        ].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedLocation = newValue;
            });
          }
        },
      ),
    );
  }

  Widget _buildBiometricStatus(AttendanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: provider.canCheckBiometric ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: provider.canCheckBiometric ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            provider.canCheckBiometric ? Icons.verified_user_rounded : Icons.warning_rounded,
            color: provider.canCheckBiometric ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.canCheckBiometric ? 'Biometric Enabled' : 'Biometric Unavailable',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: provider.canCheckBiometric ? Colors.green : Colors.orange,
                  ),
                ),
                Text(
                  provider.canCheckBiometric
                      ? 'Fingerprint/Face ID required for attendance'
                      : 'Device does not support biometric authentication',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDetails(AttendanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          AttendanceInfoRow(
            label: 'Check-In Time',
            value: provider.attendanceState?.checkInTime ?? '--:--',
            icon: Icons.login_rounded,
            valueColor: Colors.green,
          ),
          if (provider.attendanceState?.checkOutTime != null)
            AttendanceInfoRow(
              label: 'Check-Out Time',
              value: provider.attendanceState!.checkOutTime!,
              icon: Icons.logout_rounded,
              valueColor: Colors.blue,
            ),
          if (provider.attendanceState?.netMins != null)
            AttendanceInfoRow(
              label: 'Working Duration',
              value: AttendanceService.formatNetMinutes(
                provider.attendanceState!.netMins!,
              ),
              icon: Icons.schedule_rounded,
            ),
          if (provider.attendanceState?.isLate ?? false)
            AttendanceInfoRow(
              label: 'Status',
              value: '⚠️ Late Check-in',
              valueColor: Colors.orange,
            ),
          if (provider.attendanceState?.isHalfDay ?? false)
            AttendanceInfoRow(
              label: 'Marking',
              value: '⏱️ Half Day',
              valueColor: Colors.amber,
            ),
          if ((provider.attendanceState?.warningCount ?? 0) > 0)
            AttendanceInfoRow(
              label: 'Warnings',
              value: '${provider.attendanceState?.warningCount}/${provider.attendanceState?.maxWarnings}',
              icon: Icons.warning_rounded,
              valueColor: Colors.red,
            ),
        ],
      ),
    );
  }
}
