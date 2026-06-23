import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

enum LeaveStatus { pending, approved, rejected }

class LeaveRequestModel {
  final String id;
  final String employeeName;
  final String employeeId;
  final String department;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final int totalDays;
  final String reason;
  final String appliedOn;
  final LeaveStatus status;
  final String? managerRemark;
  final String? approvedBy;

  const LeaveRequestModel({
    required this.id,
    required this.employeeName,
    required this.employeeId,
    required this.department,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.reason,
    required this.appliedOn,
    this.status = LeaveStatus.pending,
    this.managerRemark,
    this.approvedBy,
  });

  LeaveRequestModel copyWith({LeaveStatus? status, String? managerRemark, String? approvedBy}) =>
      LeaveRequestModel(
        id: id, employeeName: employeeName, employeeId: employeeId,
        department: department, leaveType: leaveType, fromDate: fromDate,
        toDate: toDate, totalDays: totalDays, reason: reason, appliedOn: appliedOn,
        status: status ?? this.status,
        managerRemark: managerRemark ?? this.managerRemark,
        approvedBy: approvedBy ?? this.approvedBy,
      );
}

// ── Sample Data ───────────────────────────────────────────────────────────────

final List<LeaveRequestModel> _sampleLeaves = [
  const LeaveRequestModel(
    id: 'L001', employeeName: 'Arjun Sharma', employeeId: 'GC-001',
    department: 'Engineering', leaveType: 'Sick Leave',
    fromDate: '23 Jun 2026', toDate: '24 Jun 2026', totalDays: 2,
    reason: 'Having fever and doctor advised rest for 2 days.',
    appliedOn: '22 Jun 2026', status: LeaveStatus.pending,
  ),
  const LeaveRequestModel(
    id: 'L002', employeeName: 'Priya Patel', employeeId: 'GC-002',
    department: 'HR', leaveType: 'Casual Leave',
    fromDate: '25 Jun 2026', toDate: '26 Jun 2026', totalDays: 2,
    reason: 'Family function — sister\'s engagement ceremony.',
    appliedOn: '20 Jun 2026', status: LeaveStatus.pending,
  ),
  const LeaveRequestModel(
    id: 'L003', employeeName: 'Rahul Meena', employeeId: 'GC-003',
    department: 'Sales', leaveType: 'Annual Leave',
    fromDate: '01 Jul 2026', toDate: '05 Jul 2026', totalDays: 5,
    reason: 'Planned vacation with family.',
    appliedOn: '15 Jun 2026', status: LeaveStatus.approved,
    managerRemark: 'Approved. Enjoy your vacation!', approvedBy: 'Admin',
  ),
  const LeaveRequestModel(
    id: 'L004', employeeName: 'Neha Singh', employeeId: 'GC-004',
    department: 'Finance', leaveType: 'Maternity Leave',
    fromDate: '10 Jul 2026', toDate: '07 Oct 2026', totalDays: 90,
    reason: 'Maternity leave as per company policy.',
    appliedOn: '01 Jun 2026', status: LeaveStatus.approved,
    managerRemark: 'Approved as per HR policy.', approvedBy: 'Admin',
  ),
  const LeaveRequestModel(
    id: 'L005', employeeName: 'Vijay Kumar', employeeId: 'GC-005',
    department: 'Operations', leaveType: 'Casual Leave',
    fromDate: '22 Jun 2026', toDate: '22 Jun 2026', totalDays: 1,
    reason: 'Personal work.',
    appliedOn: '21 Jun 2026', status: LeaveStatus.rejected,
    managerRemark: 'Cannot approve — critical project deadline.', approvedBy: 'Admin',
  ),
];

// ── Main Screen ───────────────────────────────────────────────────────────────

class AdminLeaveScreen extends StatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  State<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends State<AdminLeaveScreen>
    with SingleTickerProviderStateMixin {
  List<LeaveRequestModel> _leaves = List.from(_sampleLeaves);
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<LeaveRequestModel> _byStatus(LeaveStatus s) =>
      _leaves.where((l) => l.status == s).toList();

  void _openDetail(LeaveRequestModel leave) async {
    final result = await showModalBottomSheet<LeaveRequestModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeaveDetailSheet(leave: leave),
    );
    if (result != null) {
      setState(() {
        final idx = _leaves.indexWhere((l) => l.id == leave.id);
        if (idx != -1) _leaves[idx] = result;
      });
      if (mounted) {
        final approved = result.status == LeaveStatus.approved;
        _showSnack(
          approved ? '✓ Leave approved for ${leave.employeeName}' : '✗ Leave rejected for ${leave.employeeName}',
          approved ? AppColors.success : AppColors.error,
        );
        if (approved || result.status == LeaveStatus.rejected) {
          _tabCtrl.animateTo(approved ? 1 : 2);
        }
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: AppColors.white, fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pending = _byStatus(LeaveStatus.pending);
    final approved = _byStatus(LeaveStatus.approved);
    final rejected = _byStatus(LeaveStatus.rejected);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Leave Requests',
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white)),
                    const SizedBox(height: 18),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: _HeaderStat(
                    //         label: 'Pending',
                    //         count: pending.length,
                    //         color: AppColors.warning,
                    //       ),
                    //     ),
                    //     Expanded(
                    //       child: _HeaderStat(
                    //         label: 'Approved',
                    //         count: approved.length,
                    //         color: AppColors.successLight,
                    //       ),
                    //     ),
                    //     Expanded(
                    //       child: _HeaderStat(
                    //         label: 'Rejected',
                    //         count: rejected.length,
                    //         color: AppColors.errorLight,
                    //       ),
                    //     ),
                    //   ],
                    // )
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.white,
              indicatorWeight: 3,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withOpacity(0.55),
              labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
              tabs: [
                Tab(text: 'Pending (${pending.length})'),
                Tab(text: 'Approved (${approved.length})'),
                Tab(text: 'Rejected (${rejected.length})'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _LeaveList(leaves: pending, onTap: _openDetail, showActions: true),
            _LeaveList(leaves: approved, onTap: _openDetail, showActions: false),
            _LeaveList(leaves: rejected, onTap: _openDetail, showActions: false),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _HeaderStat({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
      child: Text('$count', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ),
    const SizedBox(width: 5),
    Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.white.withOpacity(0.75))),
  ]);
}

// ── Leave List ────────────────────────────────────────────────────────────────

class _LeaveList extends StatelessWidget {
  final List<LeaveRequestModel> leaves;
  final ValueChanged<LeaveRequestModel> onTap;
  final bool showActions;
  const _LeaveList({required this.leaves, required this.onTap, required this.showActions});

  @override
  Widget build(BuildContext context) {
    if (leaves.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event_available_outlined, size: 56, color: AppColors.neutralGrey),
        const SizedBox(height: 12),
        Text('No requests here', style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 15)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: leaves.length,
      itemBuilder: (_, i) => _LeaveCard(leave: leaves[i], onTap: () => onTap(leaves[i]), showActions: showActions),
    );
  }
}

// ── Leave Card ────────────────────────────────────────────────────────────────

class _LeaveCard extends StatelessWidget {
  final LeaveRequestModel leave;
  final VoidCallback onTap;
  final bool showActions;
  const _LeaveCard({required this.leave, required this.onTap, required this.showActions});

  Color get _statusColor => switch (leave.status) {
    LeaveStatus.pending => AppColors.warning,
    LeaveStatus.approved => AppColors.success,
    LeaveStatus.rejected => AppColors.error,
  };

  String get _statusLabel => switch (leave.status) {
    LeaveStatus.pending => 'Pending',
    LeaveStatus.approved => 'Approved',
    LeaveStatus.rejected => 'Rejected',
  };

  IconData get _leaveIcon => switch (leave.leaveType) {
    'Sick Leave' => Icons.local_hospital_outlined,
    'Annual Leave' => Icons.beach_access_outlined,
    'Maternity Leave' => Icons.child_care_outlined,
    _ => Icons.event_note_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final initials = leave.employeeName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadow.subtle,
          border: Border.all(color: _statusColor.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(initials,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(leave.employeeName,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text('${leave.employeeId} · ${leave.department}',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusLabel,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor)),
              ),
            ]),
          ),

          Divider(color: AppColors.border, height: 1),

          // Details grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              Icon(_leaveIcon, size: 14, color: AppColors.secondary),
              const SizedBox(width: 5),
              Text(leave.leaveType,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary)),
              const Spacer(),
              Icon(Icons.calendar_month_outlined, size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text('${leave.fromDate} → ${leave.toDate}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMid)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(6)),
                child: Text('${leave.totalDays}d',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ]),
          ),

          // Reason
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              leave.reason,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMid, height: 1.4),
            ),
          ),

          // Applied on / action row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(children: [
              Text('Applied: ${leave.appliedOn}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
              const Spacer(),
              if (showActions) ...[
                _QuickBtn(label: 'Reject', color: AppColors.error, onTap: onTap),
                const SizedBox(width: 8),
                _QuickBtn(label: 'Approve', color: AppColors.success, onTap: onTap),
              ] else
                Text('Tap to view details',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight,
                        decoration: TextDecoration.underline)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ),
  );
}

// ── Leave Detail Sheet ────────────────────────────────────────────────────────

class _LeaveDetailSheet extends StatefulWidget {
  final LeaveRequestModel leave;
  const _LeaveDetailSheet({required this.leave});

  @override
  State<_LeaveDetailSheet> createState() => _LeaveDetailSheetState();
}

class _LeaveDetailSheetState extends State<_LeaveDetailSheet> {
  final _remarkCtrl = TextEditingController();
  bool _submitting = false;

  bool get _isPending => widget.leave.status == LeaveStatus.pending;

  @override
  void initState() {
    super.initState();
    _remarkCtrl.text = widget.leave.managerRemark ?? '';
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _action(LeaveStatus status) async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.pop(context, widget.leave.copyWith(
        status: status,
        managerRemark: _remarkCtrl.text.trim().isEmpty
            ? (status == LeaveStatus.approved ? 'Approved by manager.' : 'Rejected by manager.')
            : _remarkCtrl.text.trim(),
        approvedBy: 'Admin',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.leave;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.neutralGreyLight, borderRadius: BorderRadius.circular(2))),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: AppColors.secondaryGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                child: Center(child: Text(
                  l.employeeName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white),
                )),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.employeeName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                Text('${l.employeeId} · ${l.department}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.white.withOpacity(0.75))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text(l.leaveType, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)),
              ),
            ]),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Duration card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primaryBg, AppColors.secondaryBg]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    _DateBlock(label: 'From', date: l.fromDate),
                    Expanded(child: Column(children: [
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.textLight, size: 18),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                        child: Text('${l.totalDays} Days', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
                      ),
                    ])),
                    _DateBlock(label: 'To', date: l.toDate),
                  ]),
                ),
                const SizedBox(height: 16),

                // Info rows
                _DetailRow(icon: Icons.event_note_outlined, label: 'Leave Type', value: l.leaveType),
                _DetailRow(icon: Icons.calendar_today_outlined, label: 'Applied On', value: l.appliedOn),
                _DetailRow(icon: Icons.info_outline_rounded, label: 'Status',
                    valueWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: l.status == LeaveStatus.pending ? AppColors.warningBg
                            : l.status == LeaveStatus.approved ? AppColors.successBg : AppColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l.status == LeaveStatus.pending ? 'Pending' : l.status == LeaveStatus.approved ? 'Approved' : 'Rejected',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                            color: l.status == LeaveStatus.pending ? AppColors.warning
                                : l.status == LeaveStatus.approved ? AppColors.success : AppColors.error),
                      ),
                    )),
                const SizedBox(height: 4),

                // Reason
                Text('Reason', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(l.reason, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark, height: 1.5)),
                ),
                const SizedBox(height: 16),

                // Manager Remark
                Text('Manager Remark ${_isPending ? "(Optional)" : ""}',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _remarkCtrl,
                  maxLines: 3,
                  readOnly: !_isPending,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Add a remark for the employee…',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
                    filled: true,
                    fillColor: _isPending ? AppColors.background : AppColors.neutralGreyLight.withOpacity(0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary, width: 1.5)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ]),
            ),
          ),

          // Action buttons
          if (_isPending)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: _submitting
                  ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                  : Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => _action(LeaveStatus.rejected),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text('Reject', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () => _action(LeaveStatus.approved),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text('Approve', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )),
                    ]),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Text(
                l.status == LeaveStatus.approved
                    ? '✓ Approved by ${l.approvedBy}'
                    : '✗ Rejected by ${l.approvedBy}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: l.status == LeaveStatus.approved ? AppColors.success : AppColors.error),
              ),
            ),
        ]),
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  final String label, date;
  const _DateBlock({required this.label, required this.date});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
    const SizedBox(height: 4),
    Text(date, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
  ]);
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Widget? valueWidget;
  const _DetailRow({required this.icon, required this.label, this.value = '', this.valueWidget});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.textLight),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid)),
      const Spacer(),
      valueWidget ?? Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
    ]),
  );
}
