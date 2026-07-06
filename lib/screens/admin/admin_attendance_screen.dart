import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../models/admin_models.dart';
import '../../widgets/common_widgets.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});
  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  DateTime _pickedDate = DateTime.now();
  String _search = '';
  String _filterStatus = 'All';
  static const _statuses = ['All', 'Present', 'Late', 'Absent', 'Half Day'];

  String get _selectedDate {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${_pickedDate.day.toString().padLeft(2,'0')} ${months[_pickedDate.month-1]} ${_pickedDate.year}';
  }

  String get _apiDate =>
      '${_pickedDate.year}-${_pickedDate.month.toString().padLeft(2,'0')}-${_pickedDate.day.toString().padLeft(2,'0')}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminAttendanceProvider>().fetchAttendance(date: _apiDate);
    });
  }

  List<AdminAttendanceRecord> get _filtered {
    final prov = context.read<AdminAttendanceProvider>();
    final q = _search.trim().toLowerCase();
    return prov.records.where((r) {
      final matchSearch = q.isEmpty ||
          r.employeeName.toLowerCase().contains(q) ||
          r.userId.toLowerCase().contains(q);
      // "Late" / "Half Day" chips match the is_late / is_half_day flags,
      // not a literal status string — filterCategory handles that.
      final matchStatus = _filterStatus == 'All' ||
          r.filterCategory.trim().toLowerCase() == _filterStatus.trim().toLowerCase();
      return matchSearch && matchStatus;
    }).toList();
  }

  void _addOrEdit(AdminAttendanceRecord? existing) async {
    final result = await showModalBottomSheet<AdminAttendanceInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttendanceFormSheet(record: existing, date: _selectedDate, apiDate: _apiDate),
    );
    if (result == null) return;
    final prov = context.read<AdminAttendanceProvider>();
    bool ok;
    if (existing == null) {
      ok = await prov.addManualAttendance(result);
    } else {
      ok = await prov.updateAttendance(existing.id, result);
    }
    if (mounted) _showSnack(
      ok ? (existing == null ? 'Attendance added manually' : 'Attendance updated') : prov.error ?? 'Failed',
      ok ? AppColors.success : AppColors.error,
    );
  }

  void _deleteRecord(AdminAttendanceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Attendance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Delete ${record.employeeName}\'s attendance record for $_selectedDate? This cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textMid))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Delete', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed != true) return;
    final prov = context.read<AdminAttendanceProvider>();
    final ok = await prov.deleteAttendance(record.id);
    if (mounted) _showSnack(
      ok ? 'Attendance record deleted' : prov.error ?? 'Failed to delete',
      ok ? AppColors.success : AppColors.error,
    );
  }

  Future<void> _pickDate() async {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final picked = await showDatePicker(
      context: context, initialDate: _pickedDate,
      firstDate: DateTime(2024), lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _pickedDate = picked);
      if (mounted) context.read<AdminAttendanceProvider>().fetchAttendance(date: _apiDate);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: AppColors.white, fontWeight: FontWeight.w500)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminAttendanceProvider>();
    final filtered = prov.isLoading ? <AdminAttendanceRecord>[] : _filtered;
    // Summary counts come straight from the API's "summary" object
    // (falls back to counting the fetched records if the backend ever
    // omits it), instead of being recomputed here.
    final summary  = prov.summary;
    final all      = summary.all;
    final present  = summary.present;
    final late     = summary.late;
    final absent   = summary.absent;
    final halfDay  = summary.halfDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => prov.fetchAttendance(date: _apiDate),
        color: AppColors.primary,
        child: CustomScrollView(slivers: [
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
                              backgroundColor: AppColors.white, foregroundColor: AppColors.primary,
                              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          _AttStat(label: 'All', count: all, color: AppColors.white),
                          const SizedBox(width: 6),
                          _AttStat(label: 'Present', count: present, color: AppColors.success),
                          const SizedBox(width: 6),
                          _AttStat(label: 'Late', count: late, color: AppColors.warning),
                          const SizedBox(width: 6),
                          _AttStat(label: 'Absent', count: absent, color: AppColors.error),
                          const SizedBox(width: 6),
                          _AttStat(label: 'Half Day', count: halfDay, color: AppColors.accent),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Error
          if (prov.hasError)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16,12,16,0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(prov.error!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                  TextButton(
                    onPressed: () => prov.fetchAttendance(date: _apiDate),
                    child: const Text('Retry', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ]),
              ),
            )),

          // Search
          SliverToBoxAdapter(child: Padding(
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
          )),

          // Filter chips
          SliverToBoxAdapter(child: SizedBox(
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
                    child: Text(s, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500,
                        color: active ? AppColors.white : AppColors.textMid)),
                  ),
                );
              },
            ),
          )),

          // Loading
          if (prov.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),

          // Empty
          if (!prov.isLoading && filtered.isEmpty)
            SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.event_busy_outlined, size: 56, color: AppColors.neutralGrey),
              const SizedBox(height: 12),
              Text('No records for $_selectedDate', style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 15)),
            ]))),

          // List
          if (!prov.isLoading && filtered.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) => _AttendanceCard(
                  record: filtered[i],
                  onEdit: () => _addOrEdit(filtered[i]),
                  onDelete: () => _deleteRecord(filtered[i]),
                ),
                childCount: filtered.length,
              )),
            ),
        ]),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'Present' => AppColors.success,
    'Late'    => AppColors.warning,
    'Absent'  => AppColors.error,
    'Half Day'=> AppColors.accent,
    _         => AppColors.primary,
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

// ── Attendance Card (exact same UI as original) ───────────────────────────────
class _AttendanceCard extends StatelessWidget {
  final AdminAttendanceRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AttendanceCard({required this.record, required this.onEdit, required this.onDelete});

  Color get _statusColor => switch (record.status) {
    'Present'  => AppColors.success,
    'Late'     => AppColors.warning,
    'Absent'   => AppColors.error,
    'Half Day' => AppColors.accent,
    _          => AppColors.secondary,
  };

  @override
  Widget build(BuildContext context) {
    final initials = record.employeeName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadow.subtle, border: Border.all(color: _statusColor.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(gradient: AppColors.darkGradient, borderRadius: BorderRadius.circular(13)),
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
                  child: Text(record.status, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor)),
                ),
              ]),
              Text('${record.userId} · ${record.department}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
            ])),
          ]),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _TimeBox(icon: Icons.login_rounded, label: 'Check In', time: record.checkIn ?? '--:-- --', color: AppColors.success)),
            Container(width: 1, height: 40, color: AppColors.border),
            Expanded(child: _TimeBox(icon: Icons.logout_rounded, label: 'Check Out', time: record.checkOut ?? '--:-- --', color: AppColors.error)),
            Container(width: 1, height: 40, color: AppColors.border),
            Expanded(child: _TimeBox(icon: Icons.timer_outlined, label: 'Working Hrs', time: record.workingHours ?? '--h --m', color: AppColors.secondary)),
          ]),
          if (record.note != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.notes_rounded, size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Expanded(child: Text(record.note!, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic))),
            ]),
          ],
          const SizedBox(height: 10),
          Row(children: [
            const Spacer(),
            _SmallBtn(icon: Icons.delete_outline_rounded, label: 'Delete', color: AppColors.error, onTap: onDelete),
            const SizedBox(width: 8),
            _SmallBtn(icon: Icons.edit_rounded, label: 'Edit', color: AppColors.secondary, onTap: onEdit),
          ]),
        ]),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final IconData icon; final String label, time; final Color color;
  const _TimeBox({required this.icon, required this.label, required this.time, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 13, color: color), const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
      ]),
      const SizedBox(height: 3),
      Text(time, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    ]),
  );
}

class _SmallBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, size: 13, color: color), const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}

// ── Attendance Form Sheet ─────────────────────────────────────────────────────
class _AttendanceFormSheet extends StatefulWidget {
  final AdminAttendanceRecord? record;
  final String date;
  final String apiDate;
  const _AttendanceFormSheet({this.record, required this.date, required this.apiDate});
  @override
  State<_AttendanceFormSheet> createState() => _AttendanceFormSheetState();
}

class _AttendanceFormSheetState extends State<_AttendanceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _empName, _empId, _department, _checkIn, _checkOut, _workingHours, _note;
  String _status = 'Present';
  static const _statuses = ['Present', 'Late', 'Absent', 'Half Day', 'Holiday'];
  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _empName = TextEditingController(text: r?.employeeName);
    _empId = TextEditingController(text: r?.userId);
    _department = TextEditingController(text: r?.department);
    _checkIn = TextEditingController(text: r?.checkIn);
    _checkOut = TextEditingController(text: r?.checkOut);
    _workingHours = TextEditingController(text: r?.workingHours);
    _note = TextEditingController(text: r?.note);
    if (r != null) _status = r.status;
  }

  @override
  void dispose() {
    for (final c in [_empName, _empId, _department, _checkIn, _checkOut, _workingHours, _note]) c.dispose();
    super.dispose();
  }

  /// Parses a "hh:mm AM/PM" string (as shown in the Check In / Check Out
  /// fields) into a 24-hour TimeOfDay.
  TimeOfDay _parse12h(String t) {
    final parts = t.split(' ');
    final hm = parts[0].split(':');
    var h = int.parse(hm[0]);
    final m = int.parse(hm[1]);
    if (parts[1] == 'PM' && h != 12) h += 12;
    if (parts[1] == 'AM' && h == 12) h = 0;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Formats a TimeOfDay as a 24-hour "HH:mm" string — the format the
  /// backend/API expects (it does its own server-side parsing of
  /// checkIn/checkOut and chokes on a "hh:mm AM/PM" string).
  String _format24h(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(TextEditingController ctrl) async {
    final picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      // Force 24-hour dial/input so there's no separate AM/PM toggle button
      // to forget — the selected hour (0–23) is unambiguous.
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
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
      final inT = _parse12h(inText), outT = _parse12h(outText);
      final totalMins = (outT.hour * 60 + outT.minute) - (inT.hour * 60 + inT.minute);
      if (totalMins > 0) {
        setState(() => _workingHours.text = '${totalMins ~/ 60}h ${(totalMins % 60).toString().padLeft(2,'0')}m');
      }
    } catch (_) {}
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Computed net working minutes from Check In / Check Out — sent to the
    // backend as `net_mins` so it never receives NaN/undefined.
    int netMins = 0;
    // 24-hour "HH:mm" versions of checkIn/checkOut for the API payload —
    // the backend parses these itself and fails on "hh:mm AM/PM" text.
    String? apiCheckIn;
    String? apiCheckOut;

    if (_status != 'Absent') {
      final inText = _checkIn.text.trim();
      final outText = _checkOut.text.trim();
      if (inText.isNotEmpty && outText.isNotEmpty) {
        try {
          final inT = _parse12h(inText), outT = _parse12h(outText);
          final totalMins =
              (outT.hour * 60 + outT.minute) - (inT.hour * 60 + inT.minute);
          if (totalMins <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Check Out time must be after Check In time (same day).'),
              backgroundColor: AppColors.error,
            ));
            return;
          }
          netMins = totalMins;
          apiCheckIn = _format24h(inT);
          apiCheckOut = _format24h(outT);
        } catch (_) {
          // If parsing fails, fall back to the raw text — backend/form
          // validators will catch it.
          apiCheckIn = inText;
          apiCheckOut = outText;
        }
      }
    }

    Navigator.pop(context, AdminAttendanceInput(
      userId: _empId.text.trim(),
      date: widget.apiDate,
      checkIn: _status == 'Absent' ? null : apiCheckIn,
      checkOut: _status == 'Absent' ? null : apiCheckOut,
      status: _status,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      netMins: netMins,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.93, maxChildSize: 0.98,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.neutralGreyLight, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(gradient: AppColors.darkGradient, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_calendar_rounded, color: AppColors.white, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_isEdit ? 'Edit Attendance' : 'Add Attendance Manually',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text(widget.date, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
              ]),
            ]),
          ),
          Divider(color: AppColors.border, height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  _label('Attendance Status *'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: _statuses.map((s) {
                    final active = _status == s;
                    final color = switch (s) {
                      'Present' => AppColors.success, 'Late' => AppColors.warning,
                      'Absent' => AppColors.error, 'Half Day' => AppColors.accent,
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
                        child: Text(s, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500,
                            color: active ? AppColors.white : AppColors.textMid)),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 18),
                  if (_status != 'Absent') ...[
                    _label('Time Details'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field('Check In *', _checkIn, Icons.login_rounded, readOnly: true, onTap: () => _pickTime(_checkIn),
                          validator: (v) => (_status != 'Absent' && v!.trim().isEmpty) ? 'Required' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Check Out', _checkOut, Icons.logout_rounded, readOnly: true, onTap: () => _pickTime(_checkOut))),
                    ]),
                    _field('Working Hours', _workingHours, Icons.timer_outlined, hint: 'Auto-calculated e.g. 8h 30m'),
                    const SizedBox(height: 4),
                  ],
                  _label('Note (Optional)'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _note, maxLines: 2,
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
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(color: AppColors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))]),
            child: SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
    String? hint, TextInputType? keyboardType, String? Function(String?)? validator,
    int maxLines = 1, bool readOnly = false, VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: keyboardType, validator: validator,
        maxLines: maxLines, readOnly: readOnly, onTap: onTap,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
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