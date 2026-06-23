import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/leave_models.dart';
import '../providers/auth_provider.dart';
import '../providers/leave_provider.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});
  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  int _tabIndex = 0;

  // ── Apply form state ──────────────────────────────────────────────────
  String _selectedLeaveType = LeaveType.paid;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedSession;
  final TextEditingController _reasonController = TextEditingController();

  // ── My leaves filter state ───────────────────────────────────────────
  String _selectedFilter = 'All';
  final filters = ['All', 'Approved', 'Pending', 'Rejected'];

  final DateFormat _apiDateFmt = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFmt = DateFormat('MMM d, yyyy');

  bool _didFetch = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetch) {
      _didFetch = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadLeaves());
    }
  }

  String? get _currentUserId => context.read<AuthProvider>().user?.id;

  Future<void> _loadLeaves() async {
    final status = _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase();
    await context.read<LeaveProvider>().fetchLeaves(userId: _currentUserId, status: status);
  }

  /// Whether the leave needs a session (First Half / Second Half).
  /// True when the leave type is "Half Day", or when From/To fall on the
  /// same date (a single-day leave) — picking the date determines whether
  /// the session selector shows up.
  bool get _requiresSession {
    if (_selectedLeaveType == LeaveType.halfDay) return true;
    if (_fromDate != null && _toDate != null) {
      return _isSameDate(_fromDate!, _toDate!);
    }
    return false;
  }

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _handleSubmit() async {
    if (_fromDate == null || _toDate == null) {
      _showSnack('Please select both From and To dates', isError: true);
      return;
    }
    if (_toDate!.isBefore(_fromDate!)) {
      _showSnack('To date cannot be before From date', isError: true);
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _showSnack('Please enter a reason for leave', isError: true);
      return;
    }
    if (_requiresSession && _selectedSession == null) {
      _showSnack('Please select a session (First Half / Second Half)', isError: true);
      return;
    }

    final leaveProvider = context.read<LeaveProvider>();

    final success = await leaveProvider.applyLeave(
      from: _apiDateFmt.format(_fromDate!),
      to: _apiDateFmt.format(_toDate!),
      type: _selectedLeaveType,
      reason: _reasonController.text.trim(),
      session: _requiresSession ? _selectedSession : null,
    );

    if (!mounted) return;

    if (success) {
      _showSnack('Leave application submitted! ✅');
      setState(() {
        _fromDate = null;
        _toDate = null;
        _selectedSession = null;
        _reasonController.clear();
        _selectedLeaveType = LeaveType.paid;
        _tabIndex = 0;
      });
    } else {
      _showSnack(leaveProvider.errorMessage ?? 'Failed to submit leave application', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        _buildHeader(),
        const SizedBox(height: 20),
        _buildLeaveBalance(),
        const SizedBox(height: 20),
        _buildQuickTypes(),
        const SizedBox(height: 20),
        _buildTabs(),
        const SizedBox(height: 16),
        _tabIndex == 0 ? _buildLeaveList() : _buildApplyForm(),
      ]),
    );
  }

  Widget _buildHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('My Leaves', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        Text('Track & apply leaves', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid)),
      ]),
      GestureDetector(
        onTap: () => setState(() => _tabIndex = 1),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14), boxShadow: AppShadow.strong),
          child: Row(children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text('Apply', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ])),
      ),
    ]);
  }

  Widget _buildLeaveBalance() {
    return Consumer<LeaveProvider>(builder: (context, leaveProvider, _) {
      // Note: the backend doesn't expose a "leave quota" endpoint yet, so the
      // total is a placeholder. Used / pending are computed from the real
      // leaves fetched via GET /api/leaves.
      const totalLeaves = 24;
      final usedLeaves = leaveProvider.approvedDays;
      final pendingLeaves = leaveProvider.pendingDays;
      final remaining = totalLeaves - usedLeaves;
      final leftLeaves = remaining < 0 ? 0 : remaining;

      return PremiumCard(gradient: AppColors.darkGradient, padding: const EdgeInsets.all(24), child: Row(children: [
        CircularPercentIndicator(
          radius: 52, lineWidth: 8, percent: totalLeaves == 0 ? 0.0 : leftLeaves / totalLeaves,
          center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$leftLeaves', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('Left', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.5))),
          ]),
          progressColor: AppColors.primary, backgroundColor: Colors.white.withOpacity(0.1),
          circularStrokeCap: CircularStrokeCap.round, animation: true,
        ),
        const SizedBox(width: 24),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Leave Balance', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Year ${DateTime.now().year}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildBalanceStat('$totalLeaves', 'Total', AppColors.primary)),
            Expanded(child: _buildBalanceStat('$usedLeaves', 'Used', AppColors.accent)),
            Expanded(child: _buildBalanceStat('$pendingLeaves', 'Pending', AppColors.warning)),
            // Expanded(child: _buildBalanceStat('$leftLeaves', 'Left', AppColors.success)),
          ]),
        ])),
      ]));
    });
  }

  Widget _buildBalanceStat(String value, String label, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.4))),
    ]);
  }

  Widget _buildQuickTypes() {
    final types = [
      {'label': 'Paid', 'type': LeaveType.paid, 'color': AppColors.primary, 'icon': Icons.beach_access_rounded},
      {'label': 'Sick', 'type': LeaveType.sick, 'color': AppColors.success, 'icon': Icons.local_hospital_rounded},
      {'label': 'Casual', 'type': LeaveType.casual, 'color': AppColors.secondary, 'icon': Icons.star_rounded},
      {'label': 'Half Day', 'type': LeaveType.halfDay, 'color': AppColors.warning, 'icon': Icons.wb_sunny_rounded},
    ];
    return Row(children: types.map((t) {
      final color = t['color'] as Color;
      return Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: PremiumCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        onTap: () => setState(() {
          _selectedLeaveType = t['type'] as String;
          _tabIndex = 1;
        }),
        child: Column(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(t['icon'] as IconData, color: color, size: 18)),
          const SizedBox(height: 8),
          Text(t['label'] as String, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
      )));
    }).toList());
  }

  Widget _buildTabs() {
    return Row(children: ['My Leaves', 'Apply Leave'].asMap().entries.map((e) {
      final isActive = _tabIndex == e.key;
      return Padding(padding: const EdgeInsets.only(right: 10), child: GestureDetector(
        onTap: () => setState(() => _tabIndex = e.key),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(gradient: isActive ? AppColors.primaryGradient : null,
            color: isActive ? null : AppColors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: isActive ? AppShadow.strong : AppShadow.subtle),
          child: Text(e.value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textMid))),
      ));
    }).toList());
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _formatLeaveDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      return _displayDateFmt.format(DateTime.parse(raw)).replaceAll(', ${DateTime.now().year}', '');
    } catch (_) {
      return raw;
    }
  }

  Widget _buildLeaveList() {
    return Column(children: [
      // Filter row
      SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: filters.map((f) {
        final isActive = _selectedFilter == f;
        return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
          onTap: () {
            setState(() => _selectedFilter = f);
            _loadLeaves();
          },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: isActive ? AppColors.primary : AppColors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadow.subtle),
            child: Text(f, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.textMid))),
        ));
      }).toList())),
      const SizedBox(height: 16),
      Consumer<LeaveProvider>(builder: (context, leaveProvider, _) {
        if (leaveProvider.isLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(child: Column(children: [
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
              const SizedBox(height: 14),
              Text('Loading your leaves...', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight)),
            ])),
          );
        }

        if (leaveProvider.errorMessage != null && leaveProvider.leaves.isEmpty) {
          return PremiumCard(padding: const EdgeInsets.all(24), child: Column(children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 36),
            const SizedBox(height: 12),
            Text(leaveProvider.errorMessage!, textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid)),
            const SizedBox(height: 16),
            GradientButton(label: 'Retry', icon: Icons.refresh_rounded, height: 44, onTap: _loadLeaves),
          ]));
        }

        if (leaveProvider.leaves.isEmpty) {
          return PremiumCard(padding: const EdgeInsets.all(24), child: Column(children: [
            const Icon(Icons.event_busy_rounded, color: AppColors.textLight, size: 36),
            const SizedBox(height: 12),
            Text('No leave applications found', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid)),
          ]));
        }

        return Column(children: leaveProvider.leaves.map((l) {
          final color = _statusColor(l.status);
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.event_note_rounded, color: color, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.typeLabel, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  Text('${_formatLeaveDate(l.from)} → ${_formatLeaveDate(l.to)}  •  ${l.days} day(s)',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
                ])),
                TagBadge(label: l.statusLabel, color: color),
              ]),
              if (l.session.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: TagBadge(label: LeaveSession.label(l.session), color: AppColors.secondary)),
              ],
              const SizedBox(height: 10),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Row(children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Expanded(child: Text(l.reason.isEmpty ? '—' : l.reason, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMid))),
                ])),
                if (l.appliedOn.isNotEmpty)
                  Text('Applied: ${_formatLeaveDate(l.appliedOn)}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
              ]),
            ]),
          ));
        }).toList());
      }),
    ]);
  }

  Widget _buildApplyForm() {
    return PremiumCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Apply for Leave', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 20),
      _buildFormLabel('Leave Type'),
      const SizedBox(height: 8),
      _buildTypeSelector(),
      const SizedBox(height: 16),
      _buildDateSection(),
      if (_requiresSession) ...[
        const SizedBox(height: 16),
        _buildFormLabel('Session'),
        const SizedBox(height: 8),
        _buildSessionSelector(),
      ],
      const SizedBox(height: 16),
      _buildFormLabel('Reason'),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: TextField(
          controller: _reasonController,
          maxLines: 3,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(border: InputBorder.none, contentPadding: const EdgeInsets.all(14),
            hintText: 'Enter reason for leave...', hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight)),
        ),
      ),
      // const SizedBox(height: 16),
      // Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
      //   child: Row(children: [
      //     const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
      //     const SizedBox(width: 10),
      //     Expanded(child: Text('Apply at least 2 working days in advance. Urgent leaves need manager call.',
      //       style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warning))),
      //   ])),
      const SizedBox(height: 24),
      Consumer<LeaveProvider>(builder: (context, leaveProvider, _) => _buildSubmitButton(leaveProvider)),
    ]));
  }

  Widget _buildSubmitButton(LeaveProvider leaveProvider) {
    if (leaveProvider.isSubmitting) {
      return Container(
        height: 52,
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(AppSpacing.buttonRadius), boxShadow: AppShadow.strong),
        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white))),
          const SizedBox(width: 12),
          Text('Submitting...', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ])),
      );
    }
    return GradientButton(
      label: 'Submit Application',
      icon: Icons.send_rounded,
      gradient: AppColors.primaryGradient,
      onTap: _handleSubmit,
    );
  }

  Widget _buildFormLabel(String label) => Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMid));

  Widget _buildTypeSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _selectedLeaveType, isExpanded: true,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textLight),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _selectedLeaveType = v;
            if (v == LeaveType.halfDay && _fromDate != null) {
              _toDate = _fromDate;
            }
            if (_requiresSession && _selectedSession == null) {
              _selectedSession = LeaveSession.firstHalf;
            }
            if (!_requiresSession) {
              _selectedSession = null;
            }
          });
        },
        items: LeaveType.values.map((t) => DropdownMenuItem(value: t, child: Text(LeaveType.label(t)))).toList(),
      )),
    );
  }

  /// Half Day leaves only need a single date. Every other leave type shows
  /// a From/To pair — picking the same date for both automatically reveals
  /// the session selector below.
  Widget _buildDateSection() {
    if (_selectedLeaveType == LeaveType.halfDay) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildFormLabel('Date'),
        const SizedBox(height: 8),
        _buildDatePicker(
          _fromDate == null ? 'Select date' : _displayDateFmt.format(_fromDate!),
          () => _pickDate(isFrom: true),
        ),
      ]);
    }

    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildFormLabel('From Date'),
        const SizedBox(height: 8),
        _buildDatePicker(
          _fromDate == null ? 'From Date' : _displayDateFmt.format(_fromDate!),
          () => _pickDate(isFrom: true),
        ),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildFormLabel('To Date'),
        const SizedBox(height: 8),
        _buildDatePicker(
          _toDate == null ? 'To Date' : _displayDateFmt.format(_toDate!),
          () => _pickDate(isFrom: false),
        ),
      ])),
    ]);
  }

  Widget _buildSessionSelector() {
    return Row(children: LeaveSession.values.map((s) {
      final isActive = _selectedSession == s;
      return Expanded(child: Padding(
        padding: EdgeInsets.only(right: s == LeaveSession.firstHalf ? 10 : 0),
        child: GestureDetector(
          onTap: () => setState(() => _selectedSession = s),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.primaryGradient : null,
              color: isActive ? null : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isActive ? Colors.transparent : AppColors.border),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(s == LeaveSession.firstHalf ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                size: 16, color: isActive ? Colors.white : AppColors.textMid),
              const SizedBox(width: 8),
              Text(LeaveSession.label(s), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textMid)),
            ]),
          ),
        ),
      ));
    }).toList());
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? _fromDate ?? DateTime.now());
    final firstDate = isFrom ? DateTime.now() : (_fromDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = picked;
        // Half Day is always a single-day leave.
        if (_selectedLeaveType == LeaveType.halfDay) {
          _toDate = picked;
        } else if (_toDate == null || _toDate!.isBefore(picked)) {
          _toDate = picked;
        }
      } else {
        _toDate = picked;
      }

      // Auto-default the session once it becomes required, so the user
      // always has a valid value pre-selected.
      if (_requiresSession) {
        _selectedSession ??= LeaveSession.firstHalf;
      } else {
        _selectedSession = null;
      }
    });
  }

  Widget _buildDatePicker(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(height: 50,
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark))),
        ])),
    );
  }
}
