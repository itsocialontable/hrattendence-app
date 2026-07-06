import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/admin_providers.dart';
import '../../models/admin_models.dart';
import 'admin_salary_screen.dart';

// ─── Model ─────────────────────────────────────────────────────────────────────

class CompanySettings {
  // Basic Info
  String companyName;
  String email;
  String phone;
  String website;
  String address;
  String city;
  String state;
  String pincode;

  // Office Timings
  TimeOfDay officeStart;
  TimeOfDay officeEnd;
  List<bool> workingDays; // Mon=0 ... Sun=6

  // Leave Policy
  int annualLeaves;
  int casualLeaves;
  int sickLeaves;
  bool carryForward;
  int maxCarryForward;

  // Payroll
  String currency;
  int salaryDate;
  String payCycle;

  CompanySettings({
    this.companyName = 'Growth Craft Pvt. Ltd.',
    this.email = 'hr@growthcraft.in',
    this.phone = '9876543210',
    this.website = 'www.growthcraft.in',
    this.address = '123, Business Park',
    this.city = 'Jaipur',
    this.state = 'Rajasthan',
    this.pincode = '302001',
    TimeOfDay? officeStart,
    TimeOfDay? officeEnd,
    List<bool>? workingDays,
    this.annualLeaves = 18,
    this.casualLeaves = 6,
    this.sickLeaves = 8,
    this.carryForward = true,
    this.maxCarryForward = 5,
    this.currency = '₹ INR',
    this.salaryDate = 1,
    this.payCycle = 'Monthly',
  })  : officeStart = officeStart ?? const TimeOfDay(hour: 9, minute: 0),
        officeEnd = officeEnd ?? const TimeOfDay(hour: 18, minute: 0),
        workingDays = workingDays ?? [true, true, true, true, true, false, false];
}

// ─── Screen ────────────────────────────────────────────────────────────────────

class AdminCompanySettingsScreen extends StatefulWidget {
  const AdminCompanySettingsScreen({super.key});

  @override
  State<AdminCompanySettingsScreen> createState() =>
      _AdminCompanySettingsScreenState();
}

class _AdminCompanySettingsScreenState
    extends State<AdminCompanySettingsScreen> {
  final CompanySettings _s = CompanySettings();
  bool _hasChanges = false;

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;

  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final _currencies = ['₹ INR', '\$ USD', '€ EUR', '£ GBP'];
  final _payCycles = ['Monthly', 'Weekly', 'Bi-Weekly'];

  @override
  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: _s.companyName);
    _emailCtrl   = TextEditingController(text: _s.email);
    _phoneCtrl   = TextEditingController(text: _s.phone);
    _websiteCtrl = TextEditingController(text: _s.website);
    _addressCtrl = TextEditingController(text: _s.address);
    _cityCtrl    = TextEditingController(text: _s.city);
    _stateCtrl   = TextEditingController(text: _s.state);
    _pincodeCtrl = TextEditingController(text: _s.pincode);

    // Load real settings from API and pre-fill fields
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<AdminSettingsProvider>();
      await prov.fetchGlobalSettings();
      final gs = prov.globalSettings;
      if (gs != null && mounted) {
        setState(() {
          _nameCtrl.text  = gs.companyName;
          _emailCtrl.text = gs.companyEmail;
          if (gs.companyPhone != null) _phoneCtrl.text = gs.companyPhone!;
          if (gs.companyAddress != null) {
            _addressCtrl.text = gs.companyAddress!;
          }
          _s.companyName = gs.companyName;
          _s.email       = gs.companyEmail;
        });
      }
      await prov.fetchAttendanceRules();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _emailCtrl, _phoneCtrl, _websiteCtrl,
      _addressCtrl, _cityCtrl, _stateCtrl, _pincodeCtrl,
    ]) c.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  void _changed() => setState(() => _hasChanges = true);

  Future<void> _pickTime(TimeOfDay current, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) { onPicked(picked); _changed(); }
  }

  Future<void> _save() async {
    _s.companyName = _nameCtrl.text;
    _s.email       = _emailCtrl.text;
    _s.phone       = _phoneCtrl.text;
    _s.website     = _websiteCtrl.text;
    _s.address     = _addressCtrl.text;
    _s.city        = _cityCtrl.text;
    _s.state       = _stateCtrl.text;
    _s.pincode     = _pincodeCtrl.text;

    // Save to API
    final prov = context.read<AdminSettingsProvider>();
    final current = prov.globalSettings;
    bool apiOk = false;
    if (current != null) {
      final updated = current.copyWith(
        companyName:    _s.companyName,
        companyEmail:   _s.email,
        companyPhone:   _s.phone.isNotEmpty ? _s.phone : null,
        companyAddress: _s.address.isNotEmpty ? _s.address : null,
      );
      apiOk = await prov.saveGlobalSettings(updated);
    }

    setState(() => _hasChanges = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(apiOk ? Icons.check_circle : Icons.save_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text(apiOk ? 'Settings saved to server!' : 'Saved locally (server unreachable)',
            style: GoogleFonts.poppins(fontSize: 13)),
      ]),
      backgroundColor: apiOk ? AppColors.success : AppColors.warning,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Company Settings',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _save,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('Save',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Logo / Header ──────────────────────────────────────────────
          _logoSection(),
          const SizedBox(height: 24),

          // ── Basic Info ─────────────────────────────────────────────────
          _sectionHeader(Icons.business_outlined, 'Basic Information', AppColors.primary),
          const SizedBox(height: 12),
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _field('Company Name', _nameCtrl, Icons.business_outlined,
                  hint: 'e.g. Growth Craft Pvt. Ltd.'),
              _divider(),
              _field('Email Address', _emailCtrl, Icons.email_outlined,
                  hint: 'hr@company.com', type: TextInputType.emailAddress),
              _divider(),
              _field('Phone Number', _phoneCtrl, Icons.phone_outlined,
                  hint: '9876543210', type: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
              _divider(),
              _field('Website', _websiteCtrl, Icons.language_outlined,
                  hint: 'www.company.com', type: TextInputType.url),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Address ───────────────────────────────────────────────────
          _sectionHeader(Icons.location_on_outlined, 'Office Address', AppColors.secondary),
          const SizedBox(height: 12),
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _field('Street Address', _addressCtrl, Icons.home_outlined,
                  hint: 'e.g. 123, Business Park'),
              _divider(),
              Row(children: [
                Expanded(child: _field('City', _cityCtrl, Icons.location_city_outlined,
                    hint: 'Jaipur')),
                const SizedBox(width: 12),
                Expanded(child: _field('State', _stateCtrl, Icons.map_outlined,
                    hint: 'Rajasthan')),
              ]),
              _divider(),
              _field('PIN Code', _pincodeCtrl, Icons.pin_outlined,
                  hint: '302001', type: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Office Timings ────────────────────────────────────────────
          _sectionHeader(Icons.access_time_outlined, 'Office Timings', AppColors.warning),
          const SizedBox(height: 12),
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _timeRow(
                label: 'Office Start Time',
                time: _s.officeStart,
                onTap: () => _pickTime(_s.officeStart,
                        (t) => setState(() => _s.officeStart = t)),
              ),
              _divider(),
              _timeRow(
                label: 'Office End Time',
                time: _s.officeEnd,
                onTap: () => _pickTime(
                    _s.officeEnd, (t) => setState(() => _s.officeEnd = t)),
              ),
              _divider(),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Working Days',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final active = _s.workingDays[i];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _s.workingDays[i] = !_s.workingDays[i];
                      _hasChanges = true;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_days[i],
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textMid)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              // Summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${_s.workingDays.where((d) => d).length} working days/week • ${_fmtTime(_s.officeStart)} – ${_fmtTime(_s.officeEnd)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Leave Policy ──────────────────────────────────────────────
          _sectionHeader(Icons.beach_access_outlined, 'Leave Policy', AppColors.accent),
          const SizedBox(height: 12),
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _leaveCounter('Annual Leaves', _s.annualLeaves, AppColors.primary,
                  Icons.calendar_month_outlined,
                  onChanged: (v) => setState(() { _s.annualLeaves = v; _hasChanges = true; })),
              _divider(),
              _leaveCounter('Casual Leaves', _s.casualLeaves, AppColors.secondary,
                  Icons.free_breakfast_outlined,
                  onChanged: (v) => setState(() { _s.casualLeaves = v; _hasChanges = true; })),
              _divider(),
              _leaveCounter('Sick Leaves', _s.sickLeaves, AppColors.error,
                  Icons.local_hospital_outlined,
                  onChanged: (v) => setState(() { _s.sickLeaves = v; _hasChanges = true; })),
              _divider(),
              _toggleRow(
                icon: Icons.autorenew_outlined,
                title: 'Carry Forward',
                subtitle: 'Unused leaves carry to next year',
                value: _s.carryForward,
                color: AppColors.success,
                onChanged: (v) => setState(() { _s.carryForward = v; _hasChanges = true; }),
              ),
              if (_s.carryForward) ...[
                _divider(),
                _leaveCounter(
                    'Max Carry Forward Days', _s.maxCarryForward,
                    AppColors.success, Icons.arrow_forward_outlined,
                    onChanged: (v) => setState(() { _s.maxCarryForward = v; _hasChanges = true; }),
                    min: 1, max: 30),
              ],
              _divider(),
              // Total summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.accentBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.summarize_outlined,
                      color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total: ${_s.annualLeaves + _s.casualLeaves + _s.sickLeaves} leaves/year  (Annual ${_s.annualLeaves} + Casual ${_s.casualLeaves} + Sick ${_s.sickLeaves})',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Payroll ───────────────────────────────────────────────────
          // _sectionHeader(Icons.account_balance_wallet_outlined, 'Payroll', AppColors.success),
          // const SizedBox(height: 12),
          // PremiumCard(
          //   padding: const EdgeInsets.all(20),
          //   child: Column(children: [
          //     // Currency dropdown
          //     _dropdownRow(
          //       icon: Icons.currency_rupee_outlined,
          //       label: 'Currency',
          //       value: _s.currency,
          //       items: _currencies,
          //       onChanged: (v) => setState(() { _s.currency = v!; _hasChanges = true; }),
          //     ),
          //     _divider(),
          //     // Pay Cycle dropdown
          //     _dropdownRow(
          //       icon: Icons.repeat_outlined,
          //       label: 'Pay Cycle',
          //       value: _s.payCycle,
          //       items: _payCycles,
          //       onChanged: (v) => setState(() { _s.payCycle = v!; _hasChanges = true; }),
          //     ),
          //     _divider(),
          //     // Salary Date
          //     Row(children: [
          //       Container(
          //         padding: const EdgeInsets.all(8),
          //         decoration: BoxDecoration(
          //             color: AppColors.success.withOpacity(0.1),
          //             borderRadius: BorderRadius.circular(10)),
          //         child: const Icon(Icons.event_outlined,
          //             color: AppColors.success, size: 18),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text('Salary Disbursement Date',
          //                 style: GoogleFonts.poppins(
          //                     fontSize: 13,
          //                     fontWeight: FontWeight.w600,
          //                     color: AppColors.textDark)),
          //             Text('Day of every month',
          //                 style: GoogleFonts.poppins(
          //                     fontSize: 11, color: AppColors.textLight)),
          //           ])),
          //       _counterWidget(
          //         value: _s.salaryDate,
          //         min: 1,
          //         max: 31,
          //         color: AppColors.success,
          //         onChanged: (v) => setState(() { _s.salaryDate = v; _hasChanges = true; }),
          //       ),
          //     ]),
          //     _divider(),
          //     Container(
          //       padding: const EdgeInsets.all(12),
          //       decoration: BoxDecoration(
          //           color: AppColors.successBg,
          //           borderRadius: BorderRadius.circular(10),
          //           border: Border.all(color: AppColors.success.withOpacity(0.2))),
          //       child: Row(children: [
          //         const Icon(Icons.info_outline,
          //             color: AppColors.success, size: 14),
          //         const SizedBox(width: 8),
          //         Expanded(
          //           child: Text(
          //             'Salary paid ${_s.payCycle.toLowerCase()} on day ${_s.salaryDate} of each month in ${_s.currency}',
          //             style: GoogleFonts.poppins(
          //                 fontSize: 11,
          //                 color: AppColors.success,
          //                 fontWeight: FontWeight.w500),
          //           ),
          //         ),
          //       ]),
          //     ),
          //     _divider(),
          //     // ── Calculate Salary Button ──────────────────────────────
          //     GestureDetector(
          //       onTap: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (_) => const AdminSalaryScreen(),
          //           ),
          //         );
          //       },
          //       child: Container(
          //         width: double.infinity,
          //         padding: const EdgeInsets.symmetric(vertical: 14),
          //         decoration: BoxDecoration(
          //           gradient: LinearGradient(
          //             colors: [
          //               AppColors.success,
          //               AppColors.success.withOpacity(0.8),
          //             ],
          //             begin: Alignment.centerLeft,
          //             end: Alignment.centerRight,
          //           ),
          //           borderRadius: BorderRadius.circular(12),
          //           boxShadow: [
          //             BoxShadow(
          //               color: AppColors.success.withOpacity(0.3),
          //               blurRadius: 8,
          //               offset: const Offset(0, 4),
          //             ),
          //           ],
          //         ),
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             const Icon(Icons.calculate_outlined,
          //                 color: Colors.white, size: 20),
          //             const SizedBox(width: 8),
          //             Text(
          //               'Calculate Employee Salary',
          //               style: GoogleFonts.poppins(
          //                 fontSize: 14,
          //                 fontWeight: FontWeight.w600,
          //                 color: Colors.white,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ]),
          // ),
          const SizedBox(height: 28),

          // ── Save Button ───────────────────────────────────────────────
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Center(
                child: Text('Save Company Settings',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo Section ──────────────────────────────────────────────────────────────
  Widget _logoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 36),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppShadow.card),
              child: const Icon(Icons.edit, color: AppColors.primary, size: 14),
            ),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Company Name',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text(_emailCtrl.text,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(_phoneCtrl.text,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Tap fields below to edit',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white)),
          ),
        ])),
      ]),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark)),
    ]);
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 14),
    child: Divider(color: AppColors.border, height: 1),
  );

  Widget _field(
      String label,
      TextEditingController ctrl,
      IconData icon, {
        String hint = '',
        TextInputType type = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMid)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: type,
        inputFormatters: inputFormatters,
        onChanged: (_) => _changed(),
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: AppColors.textLight),
          hintText: hint,
          hintStyle:
          GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
      ),
    ]);
  }

  Widget _timeRow({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.access_time_outlined,
              color: AppColors.warning, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(children: [
            Text(_fmtTime(time),
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined,
                size: 14, color: AppColors.primary),
          ]),
        ),
      ]),
    );
  }

  Widget _leaveCounter(
      String label,
      int value,
      Color color,
      IconData icon, {
        required ValueChanged<int> onChanged,
        int min = 0,
        int max = 60,
      }) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark))),
      _counterWidget(
          value: value, min: min, max: max, color: color, onChanged: onChanged),
    ]);
  }

  Widget _toggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textLight)),
          ])),
      Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
    ]);
  }

  Widget _dropdownRow({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.success, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500))))
                .toList(),
            onChanged: onChanged,
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textMid, size: 18),
            isDense: true,
          ),
        ),
      ),
    ]);
  }

  Widget _counterWidget({
    required int value,
    required int min,
    required int max,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: value > min ? () => onChanged(value - 1) : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: value > min ? color.withOpacity(0.12) : AppColors.border,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.remove,
              size: 16,
              color: value > min ? color : AppColors.textLight),
        ),
      ),
      SizedBox(
        width: 40,
        child: Center(
          child: Text('$value',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ),
      ),
      GestureDetector(
        onTap: value < max ? () => onChanged(value + 1) : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: value < max ? color.withOpacity(0.12) : AppColors.border,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.add,
              size: 16,
              color: value < max ? color : AppColors.textLight),
        ),
      ),
    ]);
  }
}