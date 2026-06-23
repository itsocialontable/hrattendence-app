/// Attendance UI Widgets
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Attendance Status Card
class AttendanceStatusCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final bool isLate;
  final bool isHalfDay;
  final int? warningCount;
  final int? maxWarnings;

  const AttendanceStatusCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.isLate = false,
    this.isHalfDay = false,
    this.warningCount,
    this.maxWarnings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundColor, backgroundColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (isLate || isHalfDay || (warningCount ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (isLate)
                      _buildBadge('⚠️ Late', Colors.orange),
                    if (isHalfDay)
                      _buildBadge('⏱️ Half Day', Colors.amber),
                    if ((warningCount ?? 0) > 0)
                      _buildBadge(
                        '⚠️ ${warningCount}/${maxWarnings}',
                        Colors.red,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Real-time Clock Widget
class RealTimeClockWidget extends StatefulWidget {
  final TextStyle? textStyle;
  final TextStyle? labelStyle;

  const RealTimeClockWidget({
    Key? key,
    this.textStyle,
    this.labelStyle,
  }) : super(key: key);

  @override
  State<RealTimeClockWidget> createState() => _RealTimeClockWidgetState();
}

class _RealTimeClockWidgetState extends State<RealTimeClockWidget> {
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _updateTime();
  }

  void _updateTime() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
        _updateTime();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          DateFormat('HH:mm:ss').format(_currentTime),
          style: widget.textStyle ??
              const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
        ),
        Text(
          DateFormat('EEEE, MMMM dd, yyyy').format(_currentTime),
          style: widget.labelStyle ??
              TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

/// Working Duration Timer
class WorkingDurationWidget extends StatefulWidget {
  final String checkInTime;
  final Duration updateInterval;

  const WorkingDurationWidget({
    Key? key,
    required this.checkInTime,
    this.updateInterval = const Duration(seconds: 1),
  }) : super(key: key);

  @override
  State<WorkingDurationWidget> createState() => _WorkingDurationWidgetState();
}

class _WorkingDurationWidgetState extends State<WorkingDurationWidget> {
  late Duration _workingDuration;

  @override
  void initState() {
    super.initState();
    _updateDuration();
  }

  void _updateDuration() {
    _calculateWorkingDuration();
    Future.delayed(widget.updateInterval, () {
      if (mounted) {
        _updateDuration();
      }
    });
  }

  void _calculateWorkingDuration() {
    try {
      final parts = widget.checkInTime.split(':');
      final now = DateTime.now();
      final checkInTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      _workingDuration = now.difference(checkInTime);
    } catch (e) {
      _workingDuration = Duration.zero;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatDuration(_workingDuration),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const Text(
          'Working Duration',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

/// Attendance Button
class AttendanceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? textColor;

  const AttendanceButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: (isLoading || isDisabled) ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Colors.white,
                  ),
                ),
              )
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.secondary,
          foregroundColor: textColor ?? Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Attendance Info Row
class AttendanceInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const AttendanceInfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(icon, size: 20, color: Colors.grey[600]),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
