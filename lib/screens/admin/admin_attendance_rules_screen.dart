// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../theme/app_theme.dart';
// import '../../widgets/common_widgets.dart';
//
// // ─── Model ─────────────────────────────────────────────────────────────────────
//
// class AttendanceRule {
//   final String id;
//   final String name;
//   final String description;
//   final IconData icon;
//   final Color color;
//   bool isEnabled;
//   final List<AttendanceRuleParam> params;
//
//   AttendanceRule({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.icon,
//     required this.color,
//     this.isEnabled = true,
//     this.params = const [],
//   });
// }
//
// class AttendanceRuleParam {
//   final String key;
//   final String label;
//   final String hint;
//   final String value;
//   final String unit;
//   final ParamType type;
//
//   const AttendanceRuleParam({
//     required this.key,
//     required this.label,
//     required this.hint,
//     required this.value,
//     this.unit = '',
//     this.type = ParamType.text,
//   });
//
//   AttendanceRuleParam copyWith({String? value}) =>
//       AttendanceRuleParam(key: key, label: label, hint: hint, value: value ?? this.value, unit: unit, type: type);
// }
//
// enum ParamType { text, time, number }
//
// // ─── Screen ────────────────────────────────────────────────────────────────────
//
// class AdminAttendanceRulesScreen extends StatefulWidget {
//   const AdminAttendanceRulesScreen({super.key});
//
//   @override
//   State<AdminAttendanceRulesScreen> createState() => _AdminAttendanceRulesScreenState();
// }
//
// class _AdminAttendanceRulesScreenState extends State<AdminAttendanceRulesScreen> {
//   bool _hasChanges = false;
//
//   final List<AttendanceRule> _rules = [
//     AttendanceRule(
//       id: 'shift_timing',
//       name: 'Shift Timings',
//       description: 'Define standard working shift start and end times for all employees.',
//       icon: Icons.schedule_outlined,
//       color: AppColors.primary,
//       params: [
//         const AttendanceRuleParam(key: 'shift_start', label: 'Shift Start Time', hint: 'e.g. 09:00 AM', value: '09:00 AM', type: ParamType.time),
//         const AttendanceRuleParam(key: 'shift_end', label: 'Shift End Time', hint: 'e.g. 06:00 PM', value: '06:00 PM', type: ParamType.time),
//         const AttendanceRuleParam(key: 'grace_minutes', label: 'Grace Period (minutes)', hint: '0–30', value: '10', unit: 'min', type: ParamType.number),
//       ],
//     ),
//     AttendanceRule(
//       id: 'late_arrival',
//       name: 'Late Arrival Rule',
//       description: 'Mark employees as late if they clock in after the allowed grace period. Repeated lates can trigger half-day.',
//       icon: Icons.timer_off_outlined,
//       color: AppColors.warning,
//       params: [
//         const AttendanceRuleParam(key: 'late_threshold', label: 'Late After (time)', hint: 'e.g. 09:10 AM', value: '09:10 AM', type: ParamType.time),
//         const AttendanceRuleParam(key: 'half_day_after', label: 'Half Day After (time)', hint: 'e.g. 11:00 AM', value: '11:00 AM', type: ParamType.time),
//         const AttendanceRuleParam(key: 'absent_after', label: 'Absent After (time)', hint: 'e.g. 02:00 PM', value: '02:00 PM', type: ParamType.time),
//       ],
//     ),
//     AttendanceRule(
//       id: 'early_exit',
//       name: 'Early Exit Rule',
//       description: 'If an employee leaves before the minimum hours threshold, it counts as a half-day or absent.',
//       icon: Icons.exit_to_app_outlined,
//       color: AppColors.accent,
//       params: [
//         const AttendanceRuleParam(key: 'min_hours', label: 'Minimum Work Hours', hint: 'e.g. 4', value: '4', unit: 'hrs', type: ParamType.number),
//         const AttendanceRuleParam(key: 'half_day_hours', label: 'Half Day Min Hours', hint: 'e.g. 4', value: '4', unit: 'hrs', type: ParamType.number),
//         const AttendanceRuleParam(key: 'full_day_hours', label: 'Full Day Min Hours', hint: 'e.g. 8', value: '8', unit: 'hrs', type: ParamType.number),
//       ],
//     ),
//     AttendanceRule(
//       id: 'overtime',
//       name: 'Overtime Rule',
//       description: 'Employees working beyond standard hours will be marked for overtime.',
//       icon: Icons.bolt_outlined,
//       color: AppColors.secondary,
//       isEnabled: false,
//       params: [
//         const AttendanceRuleParam(key: 'ot_after', label: 'OT Starts After (hrs)', hint: 'e.g. 9', value: '9', unit: 'hrs', type: ParamType.number),
//         const AttendanceRuleParam(key: 'ot_multiplier', label: 'OT Pay Multiplier', hint: 'e.g. 1.5', value: '1.5', unit: 'x', type: ParamType.text),
//       ],
//     ),
//     AttendanceRule(
//       id: 'weekend',
//       name: 'Weekend Policy',
//       description: 'Configure which days of the week are considered working days.',
//       icon: Icons.weekend_outlined,
//       color: AppColors.success,
//       params: [
//         const AttendanceRuleParam(key: 'saturday', label: 'Saturday Policy', hint: 'Full / Half / Off', value: 'Half Day'),
//         const AttendanceRuleParam(key: 'sunday', label: 'Sunday Policy', hint: 'Full / Half / Off', value: 'Off'),
//       ],
//     ),
//     AttendanceRule(
//       id: 'auto_absent',
//       name: 'Auto Absent Marking',
//       description: 'Automatically mark employees as absent if no check-in recorded by a specified time.',
//       icon: Icons.person_off_outlined,
//       color: AppColors.error,
//       params: [
//         const AttendanceRuleParam(key: 'auto_absent_time', label: 'Mark Absent After', hint: 'e.g. 02:00 PM', value: '02:00 PM', type: ParamType.time),
//       ],
//     ),
//     AttendanceRule(
//       id: 'break_rule',
//       name: 'Break Time Rule',
//       description: 'Define allowed break duration. Time beyond limit is deducted from work hours.',
//       icon: Icons.free_breakfast_outlined,
//       color: AppColors.warning,
//       isEnabled: false,
//       params: [
//         const AttendanceRuleParam(key: 'max_break', label: 'Max Break Duration', hint: 'e.g. 60', value: '60', unit: 'min', type: ParamType.number),
//       ],
//     ),
//     AttendanceRule(
//       id: 'location',
//       name: 'Location / Geofence Rule',
//       description: 'Only allow clock-in within a defined radius of office location.',
//       icon: Icons.location_on_outlined,
//       color: AppColors.secondary,
//       isEnabled: false,
//       params: [
//         const AttendanceRuleParam(key: 'geo_radius', label: 'Allowed Radius', hint: 'e.g. 200', value: '200', unit: 'meters', type: ParamType.number),
//         const AttendanceRuleParam(key: 'geo_address', label: 'Office Address', hint: 'Enter office address', value: 'Jaipur, Rajasthan'),
//       ],
//     ),
//   ];
//
//   void _saveSettings() {
//     setState(() => _hasChanges = false);
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Row(children: [
//         const Icon(Icons.check_circle, color: Colors.white, size: 18),
//         const SizedBox(width: 10),
//         Text('Attendance rules saved!', style: GoogleFonts.poppins(fontSize: 13)),
//       ]),
//       backgroundColor: AppColors.success,
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       margin: const EdgeInsets.all(16),
//     ));
//   }
//
//   void _openRuleEditor(AttendanceRule rule) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _RuleEditorSheet(
//         rule: rule,
//         onSave: (updatedParams) {
//           setState(() {
//             rule.params.clear();
//             rule.params.addAll(updatedParams);
//             _hasChanges = true;
//           });
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final enabledCount = _rules.where((r) => r.isEnabled).length;
//
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textDark),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text('Attendance Rules',
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
//       ),
//       body: ListView(
//         padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
//         children: [
//           // Summary
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               gradient: AppColors.primaryGradient,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Row(children: [
//               const Icon(Icons.rule_outlined, color: Colors.white, size: 32),
//               const SizedBox(width: 14),
//               Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Text('$enabledCount of ${_rules.length} rules active',
//                     style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
//                 Text('Tap any rule to edit its parameters', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
//               ])),
//             ]),
//           ),
//           const SizedBox(height: 20),
//
//           // Info
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
//             child: Row(children: [
//               const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
//               const SizedBox(width: 8),
//               Expanded(child: Text('Changes apply from the next working day. Disabled rules are not enforced.',
//                   style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary, height: 1.5))),
//             ]),
//           ),
//           const SizedBox(height: 20),
//
//           ..._rules.map((rule) => Padding(
//             padding: const EdgeInsets.only(bottom: 12),
//             child: _ruleCard(rule),
//           )).toList(),
//
//           const SizedBox(height: 12),
//           GestureDetector(
//             onTap: _saveSettings,
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               decoration: BoxDecoration(
//                 gradient: AppColors.primaryGradient,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
//               ),
//               child: Center(child: Text('Save All Rules', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _ruleCard(AttendanceRule rule) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: AppShadow.card,
//         border: rule.isEnabled ? Border.all(color: rule.color.withOpacity(0.25), width: 1.5) : null,
//       ),
//       child: Column(children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: rule.isEnabled ? rule.color.withOpacity(0.12) : AppColors.border,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(rule.icon, color: rule.isEnabled ? rule.color : AppColors.textLight, size: 22),
//             ),
//             const SizedBox(width: 12),
//             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text(rule.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: rule.isEnabled ? AppColors.textDark : AppColors.textLight)),
//               Text(rule.description, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight, height: 1.4)),
//             ])),
//             Switch(
//               value: rule.isEnabled,
//               onChanged: (v) => setState(() { rule.isEnabled = v; _hasChanges = true; }),
//               activeColor: rule.color,
//               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//           ]),
//         ),
//         if (rule.isEnabled && rule.params.isNotEmpty) ...[
//           Container(height: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 6,
//               children: rule.params.map((p) => Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                 decoration: BoxDecoration(
//                   color: rule.color.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: rule.color.withOpacity(0.2)),
//                 ),
//                 child: Text('${p.label}: ${p.value}${p.unit.isNotEmpty ? ' ${p.unit}' : ''}',
//                     style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: rule.color)),
//               )).toList(),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//             child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
//               GestureDetector(
//                 onTap: () => _openRuleEditor(rule),
//                 child: Row(children: [
//                   Text('Edit Parameters', style: GoogleFonts.poppins(fontSize: 11, color: rule.color, fontWeight: FontWeight.w600)),
//                   const SizedBox(width: 4),
//                   Icon(Icons.edit_outlined, size: 14, color: rule.color),
//                 ]),
//               ),
//             ]),
//           ),
//         ] else if (rule.isEnabled) ...[
//           const SizedBox(height: 8),
//         ],
//       ]),
//     );
//   }
// }
//
// // ─── Rule Editor Sheet ──────────────────────────────────────────────────────────
//
// class _RuleEditorSheet extends StatefulWidget {
//   final AttendanceRule rule;
//   final ValueChanged<List<AttendanceRuleParam>> onSave;
//
//   const _RuleEditorSheet({required this.rule, required this.onSave});
//
//   @override
//   State<_RuleEditorSheet> createState() => _RuleEditorSheetState();
// }
//
// class _RuleEditorSheetState extends State<_RuleEditorSheet> {
//   late List<AttendanceRuleParam> _params;
//   late List<TextEditingController> _controllers;
//
//   @override
//   void initState() {
//     super.initState();
//     _params = widget.rule.params.map((p) => p.copyWith()).toList();
//     _controllers = _params.map((p) => TextEditingController(text: p.value)).toList();
//   }
//
//   @override
//   void dispose() {
//     for (final c in _controllers) c.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickTime(int index) async {
//     final current = _params[index].value;
//     final parts = current.split(':');
//     int hour = int.tryParse(parts[0]) ?? 9;
//     final minParts = parts.length > 1 ? parts[1].split(' ') : ['00', 'AM'];
//     int minute = int.tryParse(minParts[0]) ?? 0;
//     final isPm = minParts.length > 1 && minParts[1] == 'PM';
//     if (isPm && hour != 12) hour += 12;
//     if (!isPm && hour == 12) hour = 0;
//
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay(hour: hour, minute: minute),
//       builder: (ctx, child) => Theme(
//         data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white)),
//         child: child!,
//       ),
//     );
//     if (picked != null) {
//       final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
//       final m = picked.minute.toString().padLeft(2, '0');
//       final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
//       final formatted = '$h:$m $period';
//       setState(() {
//         _params[index] = _params[index].copyWith(value: formatted);
//         _controllers[index].text = formatted;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.75,
//       decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       child: Column(children: [
//         Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
//           decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
//         Padding(
//           padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//           child: Row(children: [
//             Container(width: 40, height: 40, decoration: BoxDecoration(color: widget.rule.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
//               child: Icon(widget.rule.icon, color: widget.rule.color, size: 20)),
//             const SizedBox(width: 12),
//             Expanded(child: Text('Edit: ${widget.rule.name}',
//                 style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark))),
//             IconButton(icon: const Icon(Icons.close, color: AppColors.textMid), onPressed: () => Navigator.pop(context)),
//           ]),
//         ),
//         const Divider(height: 24),
//         Expanded(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//             child: Column(children: [
//               ..._params.asMap().entries.map((entry) {
//                 final i = entry.key;
//                 final p = entry.value;
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 16),
//                   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                     Text(p.label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
//                     const SizedBox(height: 6),
//                     if (p.type == ParamType.time)
//                       GestureDetector(
//                         onTap: () => _pickTime(i),
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//                           decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
//                           child: Row(children: [
//                             const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
//                             const SizedBox(width: 10),
//                             Text(p.value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
//                             const Spacer(),
//                             const Icon(Icons.edit_outlined, color: AppColors.textLight, size: 16),
//                           ]),
//                         ),
//                       )
//                     else
//                       TextField(
//                         controller: _controllers[i],
//                         keyboardType: p.type == ParamType.number ? TextInputType.number : TextInputType.text,
//                         onChanged: (v) => _params[i] = _params[i].copyWith(value: v),
//                         style: GoogleFonts.poppins(fontSize: 14),
//                         decoration: InputDecoration(
//                           hintText: p.hint,
//                           hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
//                           suffixText: p.unit.isNotEmpty ? p.unit : null,
//                           suffixStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid),
//                           filled: true,
//                           fillColor: AppColors.background,
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//                           contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//                         ),
//                       ),
//                   ]),
//                 );
//               }).toList(),
//               const SizedBox(height: 8),
//               GestureDetector(
//                 onTap: () { widget.onSave(_params); Navigator.pop(context); },
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   decoration: BoxDecoration(
//                     gradient: AppColors.primaryGradient,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
//                   ),
//                   child: Center(child: Text('Save Rule', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
//                 ),
//               ),
//             ]),
//           ),
//         ),
//       ]),
//     );
//   }
// }
