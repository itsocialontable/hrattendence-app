import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String? workingHours;
  final String status; // Present, Absent, Late, Half Day, Holiday
  final bool isManual;
  final String? note;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.workingHours,
    required this.status,
    this.isManual = false,
    this.note,
  });

  AttendanceRecord copyWith({
    String? checkIn, String? checkOut, String? workingHours,
    String? status, bool? isManual, String? note,
  }) => AttendanceRecord(
    id: id, employeeId: employeeId, employeeName: employeeName,
    department: department, date: date,
    checkIn: checkIn ?? this.checkIn,
    checkOut: checkOut ?? this.checkOut,
    workingHours: workingHours ?? this.workingHours,
    status: status ?? this.status,
    isManual: isManual ?? this.isManual,
    note: note ?? this.note,
  );
}

// ── Sample Data ───────────────────────────────────────────────────────────────

final List<AttendanceRecord> _sampleAttendance = [
  const AttendanceRecord(id: 'A001', employeeId: 'GC-001', employeeName: 'Arjun Sharma',
      department: 'Engineering', date: '22 Jun 2026',
      checkIn: '09:02 AM', checkOut: '06:15 PM', workingHours: '9h 13m', status: 'Present'),
  const AttendanceRecord(id: 'A002', employeeId: 'GC-002', employeeName: 'Priya Patel',
      department: 'HR', date: '22 Jun 2026',
      checkIn: '09:45 AM', checkOut: '06:00 PM', workingHours: '8h 15m', status: 'Late'),
  const AttendanceRecord(id: 'A003', employeeId: 'GC-003', employeeName: 'Rahul Meena',
      department: 'Sales', date: '22 Jun 2026',
      checkIn: null, checkOut: null, workingHours: null, status: 'Absent'),
  const AttendanceRecord(id: 'A004', employeeId: 'GC-004', employeeName: 'Neha Singh',
      department: 'Finance', date: '22 Jun 2026',
      checkIn: '09:00 AM', checkOut: '01:30 PM', workingHours: '4h 30m', status: 'Half Day'),
  const AttendanceRecord(id: 'A005', employeeId: 'GC-005', employeeName: 'Vijay Kumar',
      department: 'Operations', date: '22 Jun 2026',
      checkIn: '08:55 AM', checkOut: '06:05 PM', workingHours: '9h 10m', status: 'Present'),
  const AttendanceRecord(id: 'A006', employeeId: 'GC-006', employeeName: 'Sunita Verma',
      department: 'Marketing', date: '22 Jun 2026',
      checkIn: '09:00 AM', checkOut: '05:45 PM', workingHours: '8h 45m', status: 'Present',
      isManual: true, note: 'Manually added by admin'),
];

// ── Main Screen ───────────────────────────────────────────────────────────────

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  List<AttendanceRecord> _records = List.from(_sampleAttendance);
  String _selectedDate = '22 Jun 2026';
  String _search = '';
  String _filterStatus = 'All';

  static const _statuses = ['All', 'Present', 'Late', 'Absent', 'Half Day'];

  List<AttendanceRecord> get _filtered => _records.where((r) {
    final matchSearch = r.employeeName.toLowerCase().contains(_search.toLowerCase()) ||
        r.employeeId.toLowerCase().contains(_search.toLowerCase());
    final matchStatus = _filterStatus == 'All' || r.status == _filterStatus;
    return matchSearch && matchStatus;
  }).toList();

  void _addOrEdit(AttendanceRecord? existing) async {
    final result = await showModalBottomSheet<AttendanceRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttendanceFormSheet(record: existing, date: _selectedDate),
    );
    if (result != null) {
      setState(() {
        if (existing == null) {
          _records.add(result);
        } else {
          final idx = _records.indexWhere((r) => r.id == existing.id);
          if (idx != -1) _records[idx] = result;
        }
      });
      if (mounted) _showSnack(
        existing == null ? 'Attendance added manually' : 'Attendance updated',
        AppColors.success,
      );
    }
  }

  void _delete(AttendanceRecord rec) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDeleteDialog(
        name: rec.employeeName,
        onConfirm: () {
          setState(() => _records.removeWhere((r) => r.id == rec.id));
          _showSnack('Attendance record removed', AppColors.error);
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = '${picked.day.toString().padLeft(2,'0')} ${months[picked.month-1]} ${picked.year}');
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
    final filtered = _filtered;
    final present = _records.where((r) => r.status == 'Present').length;
    final late = _records.where((r) => r.status == 'Late').length;
    final absent = _records.where((r) => r.status == 'Absent').length;
    final halfDay = _records.where((r) => r.status == 'Half Day').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────────
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 190,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.darkGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Attendance Overview',
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white)),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Row(children: [
                                const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.white),
                                const SizedBox(width: 5),
                                Text(_selectedDate,
                                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.white.withOpacity(0.8))),
                                const SizedBox(width: 5),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.white),
                              ]),
                            ),
                          ])),
                          ElevatedButton.icon(
                            onPressed: () => _addOrEdit(null),
                            icon: const Icon(Icons.add, size: 16),
                            label: Text('Add', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        // Stats row
                        Row(children: [
                          _AttStat(label: 'Present', count: present, color: AppColors.success),
                          const SizedBox(width: 8),
                          _AttStat(label: 'Late', count: late, color: AppColors.warning),
                          const SizedBox(width: 8),
                          _AttStat(label: 'Absent', count: absent, color: AppColors.error),
                          const SizedBox(width: 8),
                          _AttStat(label: 'Half Day', count: halfDay, color: AppColors.accent),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Search ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadow.subtle),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Search employee name or ID…',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // ── Filter Chips ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                itemCount: _statuses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = _statuses[i];
                  final active = _filterStatus == s;
                  final color = _statusColor(s);
                  return GestureDetector(
                    onTap: () => setState(() => _filterStatus = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? color : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? color : AppColors.border),
                      ),
                      child: Text(s,
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: active ? AppColors.white : AppColors.textMid)),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── List ─────────────────────────────────────────────────────────────
          filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.event_busy_outlined, size: 56, color: AppColors.neutralGrey),
                    const SizedBox(height: 12),
                    Text('No records found', style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 15)),
                  ])),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _AttendanceCard(
                        record: filtered[i],
                        onEdit: () => _addOrEdit(filtered[i]),
                        onDelete: () => _delete(filtered[i]),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'Present' => AppColors.success,
    'Late' => AppColors.warning,
    'Absent' => AppColors.error,
    'Half Day' => AppColors.accent,
    _ => AppColors.primary,
  };
}

// ── Stat Bubble ───────────────────────────────────────────────────────────────

class _AttStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _AttStat({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text('$count', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.white.withOpacity(0.7))),
      ]),
    ),
  );
}

// ── Attendance Card ───────────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AttendanceCard({required this.record, required this.onEdit, required this.onDelete});

  Color get _statusColor => switch (record.status) {
    'Present' => AppColors.success,
    'Late' => AppColors.warning,
    'Absent' => AppColors.error,
    'Half Day' => AppColors.accent,
    _ => AppColors.secondary,
  };

  @override
  Widget build(BuildContext context) {
    final initials = record.employeeName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadow.subtle,
        border: Border.all(color: _statusColor.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.darkGradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(child: Text(initials,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(record.employeeName,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark))),
                if (record.isManual)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.secondaryBg, borderRadius: BorderRadius.circular(5)),
                    child: Text('Manual', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
                  child: Text(record.status,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor)),
                ),
              ]),
              Text('${record.employeeId} · ${record.department}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
            ])),
          ]),

          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Time row
          Row(children: [
            Expanded(child: _TimeBox(
              icon: Icons.login_rounded,
              label: 'Check In',
              time: record.checkIn ?? '--:-- --',
              color: AppColors.success,
            )),
            Container(width: 1, height: 40, color: AppColors.border),
            Expanded(child: _TimeBox(
              icon: Icons.logout_rounded,
              label: 'Check Out',
              time: record.checkOut ?? '--:-- --',
              color: AppColors.error,
            )),
            Container(width: 1, height: 40, color: AppColors.border),
            Expanded(child: _TimeBox(
              icon: Icons.timer_outlined,
              label: 'Working Hrs',
              time: record.workingHours ?? '--h --m',
              color: AppColors.secondary,
            )),
          ]),

          // Note
          if (record.note != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.notes_rounded, size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Expanded(child: Text(record.note!,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic))),
            ]),
          ],

          const SizedBox(height: 10),
          Row(children: [
            const Spacer(),
            _SmallBtn(icon: Icons.edit_rounded, label: 'Edit', color: AppColors.secondary, onTap: onEdit),
            const SizedBox(width: 8),
            _SmallBtn(icon: Icons.delete_rounded, label: 'Delete', color: AppColors.error, onTap: onDelete),
          ]),
        ]),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final IconData icon;
  final String label, time;
  final Color color;
  const _TimeBox({required this.icon, required this.label, required this.time, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
      ]),
      const SizedBox(height: 3),
      Text(time, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    ]),
  );
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}

// ── Attendance Form Sheet ─────────────────────────────────────────────────────

class _AttendanceFormSheet extends StatefulWidget {
  final AttendanceRecord? record;
  final String date;
  const _AttendanceFormSheet({this.record, required this.date});

  @override
  State<_AttendanceFormSheet> createState() => _AttendanceFormSheetState();
}

class _AttendanceFormSheetState extends State<_AttendanceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _empName, _empId, _department;
  late final TextEditingController _checkIn, _checkOut, _workingHours, _note;
  String _status = 'Present';

  static const _statuses = ['Present', 'Late', 'Absent', 'Half Day', 'Holiday'];

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _empName = TextEditingController(text: r?.employeeName);
    _empId = TextEditingController(text: r?.employeeId);
    _department = TextEditingController(text: r?.department);
    _checkIn = TextEditingController(text: r?.checkIn);
    _checkOut = TextEditingController(text: r?.checkOut);
    _workingHours = TextEditingController(text: r?.workingHours);
    _note = TextEditingController(text: r?.note);
    if (r != null) _status = r.status;
  }

  @override
  void dispose() {
    for (final c in [_empName, _empId, _department, _checkIn, _checkOut, _workingHours, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final min = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      ctrl.text = '${hour.toString().padLeft(2, '0')}:$min $period';
      _autoCalcHours();
    }
  }

  void _autoCalcHours() {
    try {
      final inText = _checkIn.text.trim();
      final outText = _checkOut.text.trim();
      if (inText.isEmpty || outText.isEmpty) return;

      TimeOfDay _parse(String t) {
        final parts = t.split(' ');
        final hm = parts[0].split(':');
        var h = int.parse(hm[0]);
        final m = int.parse(hm[1]);
        if (parts[1] == 'PM' && h != 12) h += 12;
        if (parts[1] == 'AM' && h == 12) h = 0;
        return TimeOfDay(hour: h, minute: m);
      }

      final inTime = _parse(inText);
      final outTime = _parse(outText);
      final totalMins = (outTime.hour * 60 + outTime.minute) - (inTime.hour * 60 + inTime.minute);
      if (totalMins > 0) {
        final h = totalMins ~/ 60;
        final m = totalMins % 60;
        setState(() => _workingHours.text = '${h}h ${m.toString().padLeft(2, '0')}m');
      }
    } catch (_) {}
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final result = AttendanceRecord(
      id: widget.record?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      employeeId: _empId.text.trim(),
      employeeName: _empName.text.trim(),
      department: _department.text.trim(),
      date: widget.date,
      checkIn: _status == 'Absent' ? null : _checkIn.text.trim().isEmpty ? null : _checkIn.text.trim(),
      checkOut: _status == 'Absent' ? null : _checkOut.text.trim().isEmpty ? null : _checkOut.text.trim(),
      workingHours: _status == 'Absent' ? null : _workingHours.text.trim().isEmpty ? null : _workingHours.text.trim(),
      status: _status,
      isManual: true,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      maxChildSize: 0.98,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.neutralGreyLight, borderRadius: BorderRadius.circular(2))),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(gradient: AppColors.darkGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit_calendar_rounded, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_isEdit ? 'Edit Attendance' : 'Add Attendance Manually',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text(widget.date, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
              ]),
            ]),
          ),
          Divider(color: AppColors.border, height: 1),

          // Form
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Employee info
                  _label('Employee Information'),
                  const SizedBox(height: 12),
                  _field('Employee Name *', _empName, Icons.person_outline,
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                  Row(children: [
                    Expanded(child: _field('Employee ID *', _empId, Icons.badge_outlined,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Department', _department, Icons.business_outlined)),
                  ]),
                  const SizedBox(height: 4),

                  // Status
                  _label('Attendance Status *'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: _statuses.map((s) {
                    final active = _status == s;
                    final color = switch (s) {
                      'Present' => AppColors.success,
                      'Late' => AppColors.warning,
                      'Absent' => AppColors.error,
                      'Half Day' => AppColors.accent,
                      _ => AppColors.secondary,
                    };
                    return GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? color : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: active ? color : AppColors.border, width: active ? 1.5 : 1),
                        ),
                        child: Text(s, style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: active ? AppColors.white : AppColors.textMid)),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 18),

                  // Time fields (hide for Absent)
                  if (_status != 'Absent') ...[
                    _label('Time Details'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field('Check In *', _checkIn, Icons.login_rounded,
                          readOnly: true,
                          onTap: () => _pickTime(_checkIn),
                          validator: (v) => (_status != 'Absent' && v!.trim().isEmpty) ? 'Required' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Check Out', _checkOut, Icons.logout_rounded,
                          readOnly: true,
                          onTap: () => _pickTime(_checkOut))),
                    ]),
                    _field('Working Hours', _workingHours, Icons.timer_outlined,
                        hint: 'Auto-calculated e.g. 8h 30m',
                        keyboardType: TextInputType.text),
                    const SizedBox(height: 4),
                  ],

                  // Note
                  _label('Note (Optional)'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _note,
                    maxLines: 2,
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'e.g. Manually added — system was down',
                      hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // Submit
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: AppColors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_isEdit ? 'Save Changes' : 'Add Attendance',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
  );

  Widget _field(String label, TextEditingController ctrl, IconData icon, {
    String? hint, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator, int maxLines = 1, bool readOnly = false, VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: keyboardType, inputFormatters: inputFormatters,
        validator: validator, maxLines: maxLines, readOnly: readOnly, onTap: onTap,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
          prefixIcon: Icon(icon, size: 17, color: AppColors.textLight),
          filled: true, fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    ]),
  );
}

// ── Delete Confirm Dialog ─────────────────────────────────────────────────────

class _ConfirmDeleteDialog extends StatelessWidget {
  final String name;
  final VoidCallback onConfirm;
  const _ConfirmDeleteDialog({required this.name, required this.onConfirm});

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    backgroundColor: AppColors.white,
    title: Column(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
      ),
      const SizedBox(height: 12),
      Text('Delete Record', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    ]),
    content: Text('Remove attendance record for "$name"? This cannot be undone.',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid, height: 1.5)),
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMid)),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: () { Navigator.pop(context); onConfirm(); },
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13),
              backgroundColor: AppColors.error, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Delete', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white)),
        )),
      ]),
    ],
  );
}
