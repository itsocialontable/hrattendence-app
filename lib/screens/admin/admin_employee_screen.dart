import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../models/admin_models.dart';
import '../../widgets/common_widgets.dart';

class AdminEmployeeScreen extends StatefulWidget {
  const AdminEmployeeScreen({super.key});
  @override
  State<AdminEmployeeScreen> createState() => _AdminEmployeeScreenState();
}

class _AdminEmployeeScreenState extends State<AdminEmployeeScreen> {
  String _search = '';
  String _filterDept = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminEmployeeProvider>().fetchEmployees();
    });
  }

  void _addOrEdit(AdminEmployee? existing) async {
    final result = await showModalBottomSheet<AdminEmployeeInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeFormSheet(employee: existing),
    );
    if (result == null || !mounted) return;
    final prov = context.read<AdminEmployeeProvider>();
    bool ok;
    if (existing == null) {
      ok = await prov.createEmployee(result);
    } else {
      ok = await prov.updateEmployee(existing.id, result);
    }
    if (!mounted) return;
    final errMsg = prov.error;
    _showSnack(
      ok ? (existing == null ? 'Employee added successfully' : 'Employee updated successfully')
          : errMsg ?? 'Operation failed',
      ok ? AppColors.success : AppColors.error,
    );
  }

  void _viewDetail(AdminEmployee listItem) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeDetailSheet(id: listItem.id, fallback: listItem),
    );
  }

  void _delete(AdminEmployee emp) {
    showDialog(
      context: context,
      builder: (_) => _DeleteDialog(
        name: emp.name,
        onConfirm: () async {
          final ok = await context.read<AdminEmployeeProvider>().deleteEmployee(emp.id);
          if (mounted) _showSnack(
            ok ? '${emp.name} removed' : context.read<AdminEmployeeProvider>().error ?? 'Delete failed',
            ok ? AppColors.error : AppColors.textDark,
          );
        },
      ),
    );
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
    final prov = context.watch<AdminEmployeeProvider>();
    final allEmps = prov.employees;

    // Build dept list dynamically from API data
    final depts = ['All', ...allEmps.map((e) => e.dept).toSet().toList()..sort()];

    final filtered = allEmps.where((e) {
      final matchSearch = e.name.toLowerCase().contains(_search.toLowerCase()) ||
          (e.username).toLowerCase().contains(_search.toLowerCase()) ||
          e.designation.toLowerCase().contains(_search.toLowerCase());
      final matchDept = _filterDept == 'All' || e.dept == _filterDept;
      return matchSearch && matchDept;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminEmployeeProvider>().fetchEmployees(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Employee Management',
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white)),
                      const SizedBox(height: 2),
                      Text(
                        prov.isLoading ? 'Loading…' : '${allEmps.length} total employees',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.white.withOpacity(0.75)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _addOrEdit(null),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Add', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ),
              ],
            ),

            // ── Error Banner ─────────────────────────────────────────────────────
            if (prov.hasError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(prov.error!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                      TextButton(
                        onPressed: () => context.read<AdminEmployeeProvider>().fetchEmployees(),
                        child: const Text('Retry', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ]),
                  ),
                ),
              ),

            // ── Stats Row ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  _StatChip(label: 'Active', count: allEmps.where((e) => e.isActive).length, color: AppColors.success),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Inactive', count: allEmps.where((e) => !e.isActive).length, color: AppColors.error),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Departments', count: allEmps.map((e) => e.dept).toSet().length, color: AppColors.secondary),
                ]),
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
                      hintText: 'Search by name, ID, designation…',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // ── Department Filter ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  itemCount: depts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final dept = depts[i];
                    final active = _filterDept == dept;
                    return GestureDetector(
                      onTap: () => setState(() => _filterDept = dept),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(dept,
                            style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: active ? AppColors.white : AppColors.textMid,
                            )),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Loading ──────────────────────────────────────────────────────────
            if (prov.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),

            // ── Empty ────────────────────────────────────────────────────────────
            if (!prov.isLoading && filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_outline, size: 56, color: AppColors.neutralGrey),
                    const SizedBox(height: 12),
                    Text('No employees found', style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 15)),
                  ]),
                ),
              ),

            // ── List ─────────────────────────────────────────────────────────────
            if (!prov.isLoading && filtered.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _EmployeeCard(
                      employee: filtered[i],
                      onTap: () => _viewDetail(filtered[i]),
                      onEdit: () => _addOrEdit(filtered[i]),
                      onDelete: () => _delete(filtered[i]),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text('$count', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color.withOpacity(0.8))),
      ]),
    ),
  );
}

// ── Employee Card ─────────────────────────────────────────────────────────────
class _EmployeeCard extends StatelessWidget {
  final AdminEmployee employee;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _EmployeeCard({required this.employee, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final initials = employee.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppShadow.subtle),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(initials,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(employee.name,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: employee.isActive ? AppColors.successBg : AppColors.errorBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(employee.isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600,
                          color: employee.isActive ? AppColors.success : AppColors.error)),
                ),
              ]),
              const SizedBox(height: 2),
              Text(employee.designation, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMid)),
              const SizedBox(height: 4),
              Row(children: [
                Flexible(child: _InfoPill(icon: Icons.badge_outlined, label: employee.username)),
                const SizedBox(width: 8),
                Flexible(child: _InfoPill(icon: Icons.business_outlined, label: employee.dept)),
              ]),
            ])),
            const SizedBox(width: 6),
            Column(children: [
              _ActionBtn(icon: Icons.edit_rounded, color: AppColors.secondary, onTap: onEdit),
              const SizedBox(height: 6),
              _ActionBtn(icon: Icons.delete_rounded, color: AppColors.error, onTap: onDelete),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 12, color: AppColors.textLight),
    const SizedBox(width: 3),
    Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight))),
  ]);
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}

// ── Employee Form Sheet ────────────────────────────────────────────────────────
class _EmployeeFormSheet extends StatefulWidget {
  final AdminEmployee? employee;
  const _EmployeeFormSheet({this.employee});
  @override
  State<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<_EmployeeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName, _lastName, _username, _email, _password,
      _designation, _address, _emergencyContact, _salary, _joiningDate, _phone;

  String _department = 'IT';
  String _gender = 'Male';
  String _bloodGroup = 'O+';
  String _shiftType = 'Morning';
  bool _isActive = true;

  static const _depts = ['HR', 'Sales', 'IT', 'Graphic Designer', 'SMM','SCO','Video Editor'];

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    // Split existing "First Last" name into separate fields for editing.
    final nameParts = (e?.name ?? '').trim().split(RegExp(r'\s+'));
    final initialFirst = nameParts.isNotEmpty ? nameParts.first : '';
    final initialLast = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    _firstName = TextEditingController(text: e != null ? initialFirst : '');
    _lastName = TextEditingController(text: e != null ? initialLast : '');
    _username = TextEditingController(text: e?.username);
    _email = TextEditingController(text: e?.email);
    _password = TextEditingController();
    _phone = TextEditingController(text: e?.phone);
    _designation = TextEditingController(text: e?.designation);
    _address = TextEditingController(text: e?.address);
    _emergencyContact = TextEditingController(text: e?.emergencyContact);
    _salary = TextEditingController(text: e != null ? e.salary.toString() : '');
    _joiningDate = TextEditingController(text: e?.joinDate ?? _today());
    if (e != null) {
      _department = e.dept;
      _gender = e.gender ?? 'Male';
      _bloodGroup = e.bloodGroup ?? 'O+';
      _shiftType = e.shiftType ?? 'Morning';
      _isActive = e.isActive;
    }
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _username, _email, _password, _phone, _designation,
      _address, _emergencyContact, _salary, _joiningDate]) {
      c.dispose();
    }
    super.dispose();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, AdminEmployeeInput(
      fullName: _firstName.text.trim(),
      lName: _lastName.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: 'employee',
      dept: _department,
      designation: _designation.text.trim(),
      salary: int.tryParse(_salary.text.trim()) ?? 0,
      joinDate: _joiningDate.text.trim(),
      phone: _phone.text.trim().isNotEmpty ? _phone.text.trim() : null,
      gender: _gender,
      bloodGroup: _bloodGroup,
      address: _address.text.trim().isNotEmpty ? _address.text.trim() : null,
      emergencyContact: _emergencyContact.text.trim().isNotEmpty ? _emergencyContact.text.trim() : null,
      shiftType: _shiftType,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95, minChildSize: 0.6, maxChildSize: 0.98,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.neutralGreyLight, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person_add_rounded, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_isEdit ? 'Edit Employee' : 'Add Employee',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text(_isEdit ? 'Update employee details' : 'Fill all required fields',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
              ])),
            ]),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionLabel('Personal Information'),
                  const SizedBox(height: 12),
                  _buildField('First Name *', _firstName, hint: 'e.g. Arjun', icon: Icons.person_outline,
                      validator: (v) => v!.trim().isEmpty ? 'First name is required' : null),
                  _buildField('Last Name *', _lastName, hint: 'e.g. Sharma', icon: Icons.person_outline,
                      validator: (v) => v!.trim().isEmpty ? 'Last name is required' : null),
                  _buildField('Username *', _username, hint: 'e.g. arjun.sharma', icon: Icons.alternate_email,
                      validator: (v) => v!.trim().isEmpty ? 'Username is required' : null),
                  _buildField('Email Address *', _email, hint: 'e.g. arjun@company.in', icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => !v!.contains('@') ? 'Valid email required' : null),
                  if (!_isEdit)
                    _buildField('Password *', _password, hint: 'Min 6 characters', icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null),
                  _buildField('Phone Number', _phone, hint: '10-digit mobile number', icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
                  _buildField('Address', _address, hint: 'City, State', icon: Icons.location_on_outlined, maxLines: 2),
                  const SizedBox(height: 8),
                  _sectionLabel('Employment Details'),
                  const SizedBox(height: 12),
                  _buildField('Designation *', _designation, hint: 'e.g. Senior Developer', icon: Icons.work_outline,
                      validator: (v) => v!.trim().isEmpty ? 'Designation required' : null),
                  _buildDropdown('Department *', _department, _depts, Icons.business_outlined,
                          (v) => setState(() => _department = v!)),
                  _buildField('Joining Date *', _joiningDate, hint: 'YYYY-MM-DD', icon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context, initialDate: DateTime.now(),
                          firstDate: DateTime(2010), lastDate: DateTime.now(),
                          builder: (c, child) => Theme(data: Theme.of(c).copyWith(
                              colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
                        );
                        if (picked != null) {
                          _joiningDate.text = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
                        }
                      },
                      validator: (v) => v!.trim().isEmpty ? 'Joining date required' : null),
                  const SizedBox(height: 8),
                  _sectionLabel('Salary & Emergency'),
                  const SizedBox(height: 12),
                  _buildField('Monthly Salary (₹) *', _salary, hint: 'e.g. 50000', icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v!.trim().isEmpty ? 'Salary required' : null),
                  _buildField('Emergency Contact', _emergencyContact, hint: '10-digit number', icon: Icons.emergency_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
                 const SizedBox(height: 60)
                ]),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                child: Text(_isEdit ? 'Save Changes' : 'Add Employee',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
  );

  Widget _buildField(String label, TextEditingController ctrl, {
    String? hint, IconData? icon, TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator,
    int maxLines = 1, bool readOnly = false, bool isPassword = false, VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: keyboardType, inputFormatters: inputFormatters,
        validator: validator, maxLines: maxLines, readOnly: readOnly, onTap: onTap,
        obscureText: isPassword,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
          prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.textLight) : null,
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

  Widget _buildDropdown(String label, String value, List<String> items, IconData icon, ValueChanged<String?> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value, onChanged: onChanged,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textLight),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: AppColors.textLight),
              filled: true, fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          ),
        ]),
      );
}

// ── Employee Detail Sheet (GET /api/users/:id) ─────────────────────────────────
class _EmployeeDetailSheet extends StatefulWidget {
  final String id;
  final AdminEmployee fallback;
  const _EmployeeDetailSheet({required this.id, required this.fallback});
  @override
  State<_EmployeeDetailSheet> createState() => _EmployeeDetailSheetState();
}

class _EmployeeDetailSheetState extends State<_EmployeeDetailSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminEmployeeProvider>().fetchEmployeeById(widget.id);
    });
  }

  Widget _row(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 130,
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminEmployeeProvider>();
    final e = prov.selectedEmployee ?? widget.fallback;
    final loading = prov.isLoading && prov.selectedEmployee == null;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(e.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            Text(e.designation, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMid)),
            const SizedBox(height: 16),

            Text('Basic Info', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 10),
            _row('Employee ID', e.empId),
            _row('Full Name', e.fullName),
            _row('Last Name', e.lName),
            _row('Username', e.username),
            _row('Email', e.email),
            _row('Role', e.role),
            _row('Admin ID', e.adminId),
            _row('Gender', e.gender),
            _row('Blood Group', e.bloodGroup),
            _row('Phone', e.phone),
            _row('Address', e.address),

            const SizedBox(height: 8),
            Text('Employment', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 10),
            _row('Department', e.dept),
            _row('Designation', e.designation),
            _row('Joining Date', e.joinDate),
            _row('Shift Type', e.shiftType),
            _row('Salary', '₹${e.salary}'),
            _row('Status', e.isActive ? 'Active' : 'Inactive'),
            _row('Emergency Contact', e.emergencyContact),

            const SizedBox(height: 8),
            Text('Bank & ID Details', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 10),
            _row('Bank Name', e.bankName),
            _row('Bank Branch', e.bankBranch),
            _row('Bank A/C No', e.bankAccountNo),
            _row('Bank IFSC', e.bankIfsc),
            _row('Aadhar No', e.aadharNo),
            _row('PAN No', e.panNo),
          ],
        ),
      ),
    );
  }
}


class _DeleteDialog extends StatelessWidget {
  final String name;
  final VoidCallback onConfirm;
  const _DeleteDialog({required this.name, required this.onConfirm});

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    backgroundColor: AppColors.white,
    title: Column(children: [
      Container(width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28)),
      const SizedBox(height: 12),
      Text('Delete Employee', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    ]),
    content: Text('Are you sure you want to remove "$name"? This cannot be undone.',
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