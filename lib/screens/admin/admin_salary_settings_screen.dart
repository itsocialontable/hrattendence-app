// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../theme/app_theme.dart';
// import '../../widgets/common_widgets.dart';
//
// // ─── Models ────────────────────────────────────────────────────────────────────
//
// class SalarySettings {
//   final DateTime fromDate;
//   final DateTime toDate;
//   final int workingDaysPerMonth;
//   final bool enableHalfDayDeduction;
//   final bool enableAbsentDeduction;
//   final bool enableLeaveDeduction;
//   final bool countSundayOff;
//   final bool countSaturdayHalf;
//
//   SalarySettings({
//     DateTime? fromDate,
//     DateTime? toDate,
//     this.workingDaysPerMonth = 26,
//     this.enableHalfDayDeduction = true,
//     this.enableAbsentDeduction = true,
//     this.enableLeaveDeduction = false,
//     this.countSundayOff = true,
//     this.countSaturdayHalf = false,
//   })  : fromDate = fromDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
//         toDate = toDate ?? DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
//
//   SalarySettings copyWith({
//     DateTime? fromDate,
//     DateTime? toDate,
//     int? workingDaysPerMonth,
//     bool? enableHalfDayDeduction,
//     bool? enableAbsentDeduction,
//     bool? enableLeaveDeduction,
//     bool? countSundayOff,
//     bool? countSaturdayHalf,
//   }) {
//     return SalarySettings(
//       fromDate: fromDate ?? this.fromDate,
//       toDate: toDate ?? this.toDate,
//       workingDaysPerMonth: workingDaysPerMonth ?? this.workingDaysPerMonth,
//       enableHalfDayDeduction: enableHalfDayDeduction ?? this.enableHalfDayDeduction,
//       enableAbsentDeduction: enableAbsentDeduction ?? this.enableAbsentDeduction,
//       enableLeaveDeduction: enableLeaveDeduction ?? this.enableLeaveDeduction,
//       countSundayOff: countSundayOff ?? this.countSundayOff,
//       countSaturdayHalf: countSaturdayHalf ?? this.countSaturdayHalf,
//     );
//   }
// }
//
// class EmployeeSalaryEntry {
//   final String id;
//   final String name;
//   final String department;
//   final String designation;
//   double monthlySalary;
//   int presentDays;
//   double halfDays;
//   int absentDays;
//   int leaveDays;
//
//   EmployeeSalaryEntry({
//     required this.id,
//     required this.name,
//     required this.department,
//     required this.designation,
//     required this.monthlySalary,
//     this.presentDays = 26,
//     this.halfDays = 0,
//     this.absentDays = 0,
//     this.leaveDays = 0,
//   });
//
//   double netSalary(SalarySettings s) {
//     final perDay = monthlySalary / s.workingDaysPerMonth;
//     double deduction = 0;
//     if (s.enableHalfDayDeduction) deduction += halfDays * perDay * 0.5;
//     if (s.enableAbsentDeduction) deduction += absentDays * perDay;
//     if (s.enableLeaveDeduction) deduction += leaveDays * perDay;
//     return (monthlySalary - deduction).clamp(0, double.infinity);
//   }
//
//   double totalDeduction(SalarySettings s) {
//     return (monthlySalary - netSalary(s)).clamp(0, double.infinity);
//   }
// }
//
// // ─── Sample Data ───────────────────────────────────────────────────────────────
//
// List<EmployeeSalaryEntry> _buildEmployeeList() => [
//       EmployeeSalaryEntry(id: 'GC-001', name: 'Arjun Sharma', department: 'Engineering', designation: 'Senior Developer', monthlySalary: 75000, presentDays: 24, halfDays: 0, absentDays: 0, leaveDays: 2),
//       EmployeeSalaryEntry(id: 'GC-002', name: 'Priya Patel', department: 'HR', designation: 'HR Manager', monthlySalary: 65000, presentDays: 23, halfDays: 1.0, absentDays: 0, leaveDays: 2),
//       EmployeeSalaryEntry(id: 'GC-003', name: 'Rahul Meena', department: 'Sales', designation: 'Sales Executive', monthlySalary: 40000, presentDays: 20, halfDays: 0.5, absentDays: 3, leaveDays: 0),
//       EmployeeSalaryEntry(id: 'GC-004', name: 'Neha Singh', department: 'Finance', designation: 'Finance Analyst', monthlySalary: 55000, presentDays: 25, halfDays: 0, absentDays: 1, leaveDays: 0),
//       EmployeeSalaryEntry(id: 'GC-005', name: 'Vijay Kumar', department: 'Operations', designation: 'Ops Manager', monthlySalary: 48000, presentDays: 22, halfDays: 1.5, absentDays: 2, leaveDays: 0),
//       EmployeeSalaryEntry(id: 'GC-006', name: 'Sunita Verma', department: 'Marketing', designation: 'Marketing Lead', monthlySalary: 52000, presentDays: 26, halfDays: 0, absentDays: 0, leaveDays: 0),
//       EmployeeSalaryEntry(id: 'GC-007', name: 'Amit Joshi', department: 'Engineering', designation: 'Flutter Dev', monthlySalary: 62000, presentDays: 21, halfDays: 1.0, absentDays: 2, leaveDays: 2),
//       EmployeeSalaryEntry(id: 'GC-008', name: 'Kavita Rao', department: 'Design', designation: 'UI/UX Designer', monthlySalary: 44000, presentDays: 24, halfDays: 0.5, absentDays: 1, leaveDays: 0),
//     ];
//
// // ─── Screen ────────────────────────────────────────────────────────────────────
//
// class AdminSalarySettingsScreen extends StatefulWidget {
//   const AdminSalarySettingsScreen({super.key});
//
//   @override
//   State<AdminSalarySettingsScreen> createState() => _AdminSalarySettingsScreenState();
// }
//
// class _AdminSalarySettingsScreenState extends State<AdminSalarySettingsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   SalarySettings _settings = SalarySettings();
//   final List<EmployeeSalaryEntry> _employees = _buildEmployeeList();
//   String _search = '';
//   bool _hasChanges = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   String _fmtDate(DateTime d) {
//     const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
//     return '${d.day.toString().padLeft(2,'0')} ${months[d.month-1]} ${d.year}';
//   }
//
//   String _fmtMoney(double v) {
//     if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
//     if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
//     return '₹${v.toStringAsFixed(0)}';
//   }
//
//   List<EmployeeSalaryEntry> get _filtered => _employees
//       .where((e) =>
//           e.name.toLowerCase().contains(_search.toLowerCase()) ||
//           e.id.toLowerCase().contains(_search.toLowerCase()) ||
//           e.department.toLowerCase().contains(_search.toLowerCase()))
//       .toList();
//
//   double get _totalPayroll =>
//       _employees.fold(0.0, (s, e) => s + e.netSalary(_settings));
//   double get _totalDeductions =>
//       _employees.fold(0.0, (s, e) => s + e.totalDeduction(_settings));
//
//   Future<void> _pickDate(DateTime initial, ValueChanged<DateTime> onPicked) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initial,
//       firstDate: DateTime(2023),
//       lastDate: DateTime(2027),
//       builder: (ctx, child) => Theme(
//         data: Theme.of(ctx).copyWith(
//           colorScheme: const ColorScheme.light(
//             primary: AppColors.primary,
//             onPrimary: Colors.white,
//           ),
//         ),
//         child: child!,
//       ),
//     );
//     if (picked != null) onPicked(picked);
//   }
//
//   void _saveSettings() {
//     setState(() => _hasChanges = false);
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Row(children: [
//         const Icon(Icons.check_circle, color: Colors.white, size: 18),
//         const SizedBox(width: 10),
//         Text('Settings saved!', style: GoogleFonts.poppins(fontSize: 13)),
//       ]),
//       backgroundColor: AppColors.success,
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       margin: const EdgeInsets.all(16),
//     ));
//   }
//
//   void _openEmployeeDetail(EmployeeSalaryEntry emp) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _EmployeeSalaryDetailSheet(
//         employee: emp,
//         settings: _settings,
//         onSave: (updated) {
//           setState(() {
//             final idx = _employees.indexWhere((e) => e.id == updated.id);
//             if (idx >= 0) _employees[idx] = updated;
//           });
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textDark),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text('Salary Settings',
//             style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
//         actions: [
//           if (_hasChanges)
//             Padding(
//               padding: const EdgeInsets.only(right: 12),
//               child: TextButton(
//                 onPressed: _saveSettings,
//                 style: TextButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 ),
//                 child: Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
//               ),
//             ),
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           labelColor: AppColors.primary,
//           unselectedLabelColor: AppColors.textLight,
//           indicatorColor: AppColors.primary,
//           indicatorWeight: 3,
//           labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
//           unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
//           tabs: const [
//             Tab(text: 'Settings'),
//             Tab(text: 'Employees'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildSettingsTab(),
//           _buildEmployeesTab(),
//         ],
//       ),
//     );
//   }
//
//   // ── Settings Tab ─────────────────────────────────────────────────────────────
//   Widget _buildSettingsTab() {
//     return ListView(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
//       children: [
//         // Summary cards
//         Row(children: [
//           Expanded(child: _summaryCard('Total Payroll', _fmtMoney(_totalPayroll), AppColors.primary, Icons.account_balance_wallet_outlined)),
//           const SizedBox(width: 12),
//           Expanded(child: _summaryCard('Total Deductions', _fmtMoney(_totalDeductions), AppColors.error, Icons.remove_circle_outline)),
//         ]),
//         const SizedBox(height: 20),
//
//         // Salary Period
//         _sectionHeader(Icons.date_range_outlined, 'Salary Period', AppColors.secondary),
//         const SizedBox(height: 12),
//         PremiumCard(
//           padding: const EdgeInsets.all(20),
//           child: Column(children: [
//             _datePickerRow(
//               label: 'From Date',
//               date: _settings.fromDate,
//               onTap: () => _pickDate(_settings.fromDate, (d) => setState(() {
//                 _settings = _settings.copyWith(fromDate: d);
//                 _hasChanges = true;
//               })),
//             ),
//             const SizedBox(height: 12),
//             const Divider(color: AppColors.border),
//             const SizedBox(height: 12),
//             _datePickerRow(
//               label: 'To Date',
//               date: _settings.toDate,
//               onTap: () => _pickDate(_settings.toDate, (d) => setState(() {
//                 _settings = _settings.copyWith(toDate: d);
//                 _hasChanges = true;
//               })),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: AppColors.primaryBg,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Row(children: [
//                 const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
//                 const SizedBox(width: 8),
//                 Expanded(child: Text(
//                   'Salary period: ${_fmtDate(_settings.fromDate)} → ${_fmtDate(_settings.toDate)}',
//                   style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
//                 )),
//               ]),
//             ),
//           ]),
//         ),
//         const SizedBox(height: 20),
//
//         // Working Days
//         _sectionHeader(Icons.calendar_month_outlined, 'Working Days', AppColors.secondary),
//         const SizedBox(height: 12),
//         PremiumCard(
//           padding: const EdgeInsets.all(20),
//           child: Column(children: [
//             Row(children: [
//               Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Text('Working Days / Month', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
//                 Text('Used for per-day salary calculation', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
//               ])),
//               _counterWidget(
//                 value: _settings.workingDaysPerMonth,
//                 min: 20,
//                 max: 31,
//                 onChanged: (v) => setState(() { _settings = _settings.copyWith(workingDaysPerMonth: v); _hasChanges = true; }),
//               ),
//             ]),
//             const SizedBox(height: 16),
//             const Divider(color: AppColors.border),
//             const SizedBox(height: 12),
//             _toggleRow(icon: Icons.weekend_outlined, title: 'Sunday is Off', subtitle: 'Sundays not counted in working days',
//               value: _settings.countSundayOff, color: AppColors.secondary,
//               onChanged: (v) => setState(() { _settings = _settings.copyWith(countSundayOff: v); _hasChanges = true; }),
//             ),
//             const SizedBox(height: 12),
//             _toggleRow(icon: Icons.wb_sunny_outlined, title: 'Saturday Half Day', subtitle: 'Saturday = 0.5 working day',
//               value: _settings.countSaturdayHalf, color: AppColors.warning,
//               onChanged: (v) => setState(() { _settings = _settings.copyWith(countSaturdayHalf: v); _hasChanges = true; }),
//             ),
//           ]),
//         ),
//         const SizedBox(height: 20),
//
//         // Deduction Rules
//         _sectionHeader(Icons.remove_circle_outline, 'Deduction Rules', AppColors.error),
//         const SizedBox(height: 12),
//         PremiumCard(
//           padding: const EdgeInsets.all(20),
//           child: Column(children: [
//             _toggleRow(icon: Icons.access_time_outlined, title: 'Half Day Deduction', subtitle: 'Half day attendance counted as 0.5 day deduction',
//               value: _settings.enableHalfDayDeduction, color: AppColors.warning,
//               onChanged: (v) => setState(() { _settings = _settings.copyWith(enableHalfDayDeduction: v); _hasChanges = true; }),
//             ),
//             const SizedBox(height: 12),
//             const Divider(color: AppColors.border),
//             const SizedBox(height: 12),
//             _toggleRow(icon: Icons.event_busy_outlined, title: 'Absent Day Deduction', subtitle: 'Absent days reduce net salary (per day deduction)',
//               value: _settings.enableAbsentDeduction, color: AppColors.error,
//               onChanged: (v) => setState(() { _settings = _settings.copyWith(enableAbsentDeduction: v); _hasChanges = true; }),
//             ),
//             const SizedBox(height: 12),
//             const Divider(color: AppColors.border),
//             const SizedBox(height: 12),
//             _toggleRow(icon: Icons.beach_access_outlined, title: 'Leave Deduction', subtitle: 'Approved leaves also deducted from salary',
//               value: _settings.enableLeaveDeduction, color: AppColors.secondary,
//               onChanged: (v) => setState(() { _settings = _settings.copyWith(enableLeaveDeduction: v); _hasChanges = true; }),
//             ),
//             const SizedBox(height: 16),
//             _formulaPreview(),
//           ]),
//         ),
//         const SizedBox(height: 28),
//         GestureDetector(
//           onTap: _saveSettings,
//           child: Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             decoration: BoxDecoration(
//               gradient: AppColors.primaryGradient,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
//             ),
//             child: Center(child: Text('Save Settings', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ── Employees Tab ─────────────────────────────────────────────────────────────
//   Widget _buildEmployeesTab() {
//     final list = _filtered;
//     return Column(children: [
//       Container(
//         color: Colors.white,
//         padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
//         child: TextField(
//           onChanged: (v) => setState(() => _search = v),
//           style: GoogleFonts.poppins(fontSize: 13),
//           decoration: InputDecoration(
//             hintText: 'Search employee by name or ID...',
//             hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
//             prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
//             filled: true,
//             fillColor: AppColors.background,
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//             contentPadding: const EdgeInsets.symmetric(vertical: 12),
//           ),
//         ),
//       ),
//       Expanded(
//         child: ListView.separated(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
//           itemCount: list.length,
//           separatorBuilder: (_, __) => const SizedBox(height: 10),
//           itemBuilder: (_, i) => _employeeCard(list[i]),
//         ),
//       ),
//     ]);
//   }
//
//   Widget _employeeCard(EmployeeSalaryEntry emp) {
//     final net = emp.netSalary(_settings);
//     final deduction = emp.totalDeduction(_settings);
//     final hasDeduction = deduction > 0;
//
//     return GestureDetector(
//       onTap: () => _openEmployeeDetail(emp),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: AppShadow.card,
//         ),
//         child: Column(children: [
//           Row(children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 gradient: AppColors.primaryGradient,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Center(child: Text(
//                 emp.name.split(' ').map((w) => w[0]).take(2).join(),
//                 style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
//               )),
//             ),
//             const SizedBox(width: 12),
//             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text(emp.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
//               Text('${emp.designation} • ${emp.department}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
//               Text(emp.id, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMid, fontWeight: FontWeight.w500)),
//             ])),
//             Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
//               Text(_fmtMoney(net), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
//               Text('Net Salary', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
//               if (hasDeduction)
//                 Container(
//                   margin: const EdgeInsets.only(top: 4),
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(20)),
//                   child: Text('-${_fmtMoney(deduction)}', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
//                 ),
//             ]),
//           ]),
//           const SizedBox(height: 12),
//           const Divider(color: AppColors.border, height: 1),
//           const SizedBox(height: 10),
//           Row(children: [
//             _miniStat(Icons.check_circle_outline, '${emp.presentDays}d', 'Present', AppColors.success),
//             _divider(),
//             _miniStat(Icons.access_time_outlined, '${emp.halfDays}', 'Half Day', AppColors.warning),
//             _divider(),
//             _miniStat(Icons.cancel_outlined, '${emp.absentDays}d', 'Absent', AppColors.error),
//             _divider(),
//             _miniStat(Icons.beach_access_outlined, '${emp.leaveDays}d', 'Leave', AppColors.secondary),
//           ]),
//           const SizedBox(height: 6),
//           Row(mainAxisAlignment: MainAxisAlignment.end, children: [
//             Text('Tap to edit', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
//             const SizedBox(width: 4),
//             const Icon(Icons.edit_outlined, size: 12, color: AppColors.textLight),
//           ]),
//         ]),
//       ),
//     );
//   }
//
//   Widget _miniStat(IconData icon, String value, String label, Color color) {
//     return Expanded(child: Column(children: [
//       Icon(icon, color: color, size: 16),
//       const SizedBox(height: 2),
//       Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
//       Text(label, style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textLight)),
//     ]));
//   }
//
//   Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);
//
//   // ── Shared widgets ─────────────────────────────────────────────────────────
//
//   Widget _summaryCard(String title, String value, Color color, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Row(children: [
//         Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
//           child: Icon(icon, color: color, size: 18)),
//         const SizedBox(width: 10),
//         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
//           Text(title, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMid)),
//         ])),
//       ]),
//     );
//   }
//
//   Widget _sectionHeader(IconData icon, String title, Color color) {
//     return Row(children: [
//       Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
//         child: Icon(icon, color: color, size: 18)),
//       const SizedBox(width: 10),
//       Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
//     ]);
//   }
//
//   Widget _datePickerRow({required String label, required DateTime date, required VoidCallback onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//         decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
//         child: Row(children: [
//           const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
//           const SizedBox(width: 10),
//           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
//             Text(_fmtDate(date), style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
//           ]),
//           const Spacer(),
//           const Icon(Icons.edit_outlined, color: AppColors.textLight, size: 16),
//         ]),
//       ),
//     );
//   }
//
//   Widget _toggleRow({required IconData icon, required String title, required String subtitle,
//       required bool value, required ValueChanged<bool> onChanged, required Color color}) {
//     return Row(children: [
//       Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
//         child: Icon(icon, color: color, size: 18)),
//       const SizedBox(width: 12),
//       Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
//         Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
//       ])),
//       Switch(value: value, onChanged: onChanged, activeColor: color, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
//     ]);
//   }
//
//   Widget _counterWidget({required int value, required int min, required int max, required ValueChanged<int> onChanged}) {
//     return Row(mainAxisSize: MainAxisSize.min, children: [
//       _iconBtn(Icons.remove, value > min ? () => onChanged(value - 1) : null),
//       SizedBox(width: 40, child: Center(child: Text('$value', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)))),
//       _iconBtn(Icons.add, value < max ? () => onChanged(value + 1) : null),
//     ]);
//   }
//
//   Widget _iconBtn(IconData icon, VoidCallback? onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 32, height: 32,
//         decoration: BoxDecoration(color: onTap != null ? AppColors.primaryBg : AppColors.border, borderRadius: BorderRadius.circular(8)),
//         child: Icon(icon, size: 16, color: onTap != null ? AppColors.primary : AppColors.textLight),
//       ),
//     );
//   }
//
//   Widget _formulaPreview() {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Row(children: [
//           const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 16),
//           const SizedBox(width: 6),
//           Text('Salary Formula', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
//         ]),
//         const SizedBox(height: 8),
//         Text('Per Day = Monthly Salary ÷ ${_settings.workingDaysPerMonth} days', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMid)),
//         if (_settings.enableHalfDayDeduction)
//           Text('Half Day Deduction = Half Days × Per Day × 0.5', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMid)),
//         if (_settings.enableAbsentDeduction)
//           Text('Absent Deduction = Absent Days × Per Day', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMid)),
//         if (_settings.enableLeaveDeduction)
//           Text('Leave Deduction = Leave Days × Per Day', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMid)),
//         const SizedBox(height: 6),
//         Text('Net Salary = Monthly Salary − All Deductions', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
//       ]),
//     );
//   }
// }
//
// // ─── Employee Detail Sheet ──────────────────────────────────────────────────────
//
// class _EmployeeSalaryDetailSheet extends StatefulWidget {
//   final EmployeeSalaryEntry employee;
//   final SalarySettings settings;
//   final ValueChanged<EmployeeSalaryEntry> onSave;
//
//   const _EmployeeSalaryDetailSheet({required this.employee, required this.settings, required this.onSave});
//
//   @override
//   State<_EmployeeSalaryDetailSheet> createState() => _EmployeeSalaryDetailSheetState();
// }
//
// class _EmployeeSalaryDetailSheetState extends State<_EmployeeSalaryDetailSheet> {
//   late double _salary;
//   late int _present;
//   late double _halfDays;
//   late int _absent;
//   late int _leave;
//   late TextEditingController _salaryCtrl;
//
//   @override
//   void initState() {
//     super.initState();
//     final e = widget.employee;
//     _salary = e.monthlySalary;
//     _present = e.presentDays;
//     _halfDays = e.halfDays;
//     _absent = e.absentDays;
//     _leave = e.leaveDays;
//     _salaryCtrl = TextEditingController(text: e.monthlySalary.toStringAsFixed(0));
//   }
//
//   @override
//   void dispose() { _salaryCtrl.dispose(); super.dispose(); }
//
//   String _fmtMoney(double v) {
//     if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
//     if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
//     return '₹${v.toStringAsFixed(0)}';
//   }
//
//   EmployeeSalaryEntry get _preview {
//     final e = widget.employee;
//     return EmployeeSalaryEntry(id: e.id, name: e.name, department: e.department, designation: e.designation,
//       monthlySalary: _salary, presentDays: _present, halfDays: _halfDays, absentDays: _absent, leaveDays: _leave);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final s = widget.settings;
//     final emp = _preview;
//     final perDay = _salary / s.workingDaysPerMonth;
//     final halfDedAmt = s.enableHalfDayDeduction ? _halfDays * perDay * 0.5 : 0.0;
//     final absDedAmt = s.enableAbsentDeduction ? _absent * perDay : 0.0;
//     final leaveDedAmt = s.enableLeaveDeduction ? _leave * perDay : 0.0;
//     final net = emp.netSalary(s);
//
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.88,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: Column(children: [
//         Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
//           decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
//         Padding(
//           padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//           child: Row(children: [
//             Container(width: 44, height: 44, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
//               child: Center(child: Text(widget.employee.name.split(' ').map((w) => w[0]).take(2).join(),
//                 style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)))),
//             const SizedBox(width: 12),
//             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text(widget.employee.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
//               Text('${widget.employee.designation} • ${widget.employee.department}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
//             ])),
//             IconButton(icon: const Icon(Icons.close, color: AppColors.textMid), onPressed: () => Navigator.pop(context)),
//           ]),
//         ),
//         const Divider(height: 24),
//         Expanded(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               // Salary input
//               Text('Monthly Salary (₹)', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: _salaryCtrl,
//                 keyboardType: TextInputType.number,
//                 inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                 onChanged: (v) => setState(() => _salary = double.tryParse(v) ?? _salary),
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
//                 decoration: InputDecoration(
//                   prefixText: '₹ ',
//                   prefixStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
//                   filled: true,
//                   fillColor: AppColors.primaryBg,
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // Attendance data
//               Text('Attendance Details', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
//               const SizedBox(height: 12),
//               _attendanceRow('Present Days', _present, AppColors.success, Icons.check_circle_outline, 0, 31,
//                 onChanged: (v) => setState(() => _present = v)),
//               const SizedBox(height: 10),
//               _attendanceRowDouble('Half Days', _halfDays, AppColors.warning, Icons.access_time_outlined,
//                 onMinus: () => setState(() { if (_halfDays > 0) _halfDays = (_halfDays - 0.5).clamp(0, 30); }),
//                 onPlus: () => setState(() { _halfDays = (_halfDays + 0.5).clamp(0, 30); })),
//               const SizedBox(height: 10),
//               _attendanceRow('Absent Days', _absent, AppColors.error, Icons.cancel_outlined, 0, 31,
//                 onChanged: (v) => setState(() => _absent = v)),
//               const SizedBox(height: 10),
//               _attendanceRow('Leave Days', _leave, AppColors.secondary, Icons.beach_access_outlined, 0, 31,
//                 onChanged: (v) => setState(() => _leave = v)),
//               const SizedBox(height: 20),
//
//               // Breakdown
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
//                 child: Column(children: [
//                   _breakdownRow('Gross Salary', _fmtMoney(_salary), AppColors.textDark, bold: true),
//                   const SizedBox(height: 8), const Divider(color: AppColors.border),
//                   const SizedBox(height: 8),
//                   Text('Deductions', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMid)),
//                   const SizedBox(height: 6),
//                   if (s.enableHalfDayDeduction && _halfDays > 0)
//                     _breakdownRow('Half Day (${_halfDays}×${_fmtMoney(perDay)}×0.5)', '-${_fmtMoney(halfDedAmt)}', AppColors.warning),
//                   if (s.enableAbsentDeduction && _absent > 0)
//                     _breakdownRow('Absent ($_absent×${_fmtMoney(perDay)})', '-${_fmtMoney(absDedAmt)}', AppColors.error),
//                   if (s.enableLeaveDeduction && _leave > 0)
//                     _breakdownRow('Leave ($_leave×${_fmtMoney(perDay)})', '-${_fmtMoney(leaveDedAmt)}', AppColors.secondary),
//                   if (halfDedAmt + absDedAmt + leaveDedAmt == 0)
//                     Text('No deductions', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
//                   const SizedBox(height: 8), const Divider(color: AppColors.border),
//                   const SizedBox(height: 8),
//                   _breakdownRow('Net Salary', _fmtMoney(net), AppColors.primary, bold: true, large: true),
//                 ]),
//               ),
//               const SizedBox(height: 20),
//               GestureDetector(
//                 onTap: () { widget.onSave(_preview); Navigator.pop(context); },
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   decoration: BoxDecoration(
//                     gradient: AppColors.primaryGradient,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
//                   ),
//                   child: Center(child: Text('Save Employee Salary', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
//                 ),
//               ),
//             ]),
//           ),
//         ),
//       ]),
//     );
//   }
//
//   Widget _breakdownRow(String label, String value, Color color, {bool bold = false, bool large = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(children: [
//         Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: large ? 13 : 12, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: AppColors.textMid))),
//         Text(value, style: GoogleFonts.poppins(fontSize: large ? 16 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color)),
//       ]),
//     );
//   }
//
//   Widget _attendanceRow(String label, int value, Color color, IconData icon, int min, int max, {required ValueChanged<int> onChanged}) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
//       child: Row(children: [
//         Icon(icon, color: color, size: 18),
//         const SizedBox(width: 10),
//         Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
//         _sheetCounter(value: value, min: min, max: max, color: color, onChanged: onChanged),
//       ]),
//     );
//   }
//
//   Widget _attendanceRowDouble(String label, double value, Color color, IconData icon,
//       {required VoidCallback onMinus, required VoidCallback onPlus}) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
//       child: Row(children: [
//         Icon(icon, color: color, size: 18),
//         const SizedBox(width: 10),
//         Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
//         GestureDetector(onTap: onMinus, child: Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.remove, size: 16, color: color))),
//         SizedBox(width: 40, child: Center(child: Text('$value', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: color)))),
//         GestureDetector(onTap: onPlus, child: Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.add, size: 16, color: color))),
//       ]),
//     );
//   }
//
//   Widget _sheetCounter({required int value, required int min, required int max, required Color color, required ValueChanged<int> onChanged}) {
//     return Row(mainAxisSize: MainAxisSize.min, children: [
//       GestureDetector(onTap: value > min ? () => onChanged(value - 1) : null,
//         child: Container(width: 30, height: 30, decoration: BoxDecoration(color: value > min ? color.withOpacity(0.15) : AppColors.border, borderRadius: BorderRadius.circular(8)),
//           child: Icon(Icons.remove, size: 16, color: value > min ? color : AppColors.textLight))),
//       SizedBox(width: 40, child: Center(child: Text('$value', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: color)))),
//       GestureDetector(onTap: value < max ? () => onChanged(value + 1) : null,
//         child: Container(width: 30, height: 30, decoration: BoxDecoration(color: value < max ? color.withOpacity(0.15) : AppColors.border, borderRadius: BorderRadius.circular(8)),
//           child: Icon(Icons.add, size: 16, color: value < max ? color : AppColors.textLight))),
//     ]);
//   }
// }
