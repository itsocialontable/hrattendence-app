import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String designation;
  final String employeeId;
  final String joiningDate;
  final String gender;
  final String bloodGroup;
  final String address;
  final String emergencyContact;
  final String salary;
  final String shiftType;
  final bool isActive;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.designation,
    required this.employeeId,
    required this.joiningDate,
    required this.gender,
    required this.bloodGroup,
    required this.address,
    required this.emergencyContact,
    required this.salary,
    required this.shiftType,
    this.isActive = true,
  });

  EmployeeModel copyWith({
    String? name, String? email, String? phone, String? department,
    String? designation, String? employeeId, String? joiningDate,
    String? gender, String? bloodGroup, String? address,
    String? emergencyContact, String? salary, String? shiftType, bool? isActive,
  }) => EmployeeModel(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    department: department ?? this.department,
    designation: designation ?? this.designation,
    employeeId: employeeId ?? this.employeeId,
    joiningDate: joiningDate ?? this.joiningDate,
    gender: gender ?? this.gender,
    bloodGroup: bloodGroup ?? this.bloodGroup,
    address: address ?? this.address,
    emergencyContact: emergencyContact ?? this.emergencyContact,
    salary: salary ?? this.salary,
    shiftType: shiftType ?? this.shiftType,
    isActive: isActive ?? this.isActive,
  );
}

// ── Sample Data ───────────────────────────────────────────────────────────────

final List<EmployeeModel> _sampleEmployees = [
  const EmployeeModel(
    id: '1', name: 'Arjun Sharma', email: 'arjun@growthcraft.in',
    phone: '9876543210', department: 'Engineering', designation: 'Senior Developer',
    employeeId: 'GC-001', joiningDate: '01 Jan 2022', gender: 'Male',
    bloodGroup: 'O+', address: 'Jaipur, Rajasthan',
    emergencyContact: '9876543211', salary: '75000', shiftType: 'Morning',
  ),
  const EmployeeModel(
    id: '2', name: 'Priya Patel', email: 'priya@growthcraft.in',
    phone: '9123456780', department: 'HR', designation: 'HR Manager',
    employeeId: 'GC-002', joiningDate: '15 Mar 2021', gender: 'Female',
    bloodGroup: 'A+', address: 'Jaipur, Rajasthan',
    emergencyContact: '9123456781', salary: '65000', shiftType: 'Morning',
  ),
  const EmployeeModel(
    id: '3', name: 'Rahul Meena', email: 'rahul@growthcraft.in',
    phone: '9988776655', department: 'Sales', designation: 'Sales Executive',
    employeeId: 'GC-003', joiningDate: '10 Jun 2023', gender: 'Male',
    bloodGroup: 'B+', address: 'Jodhpur, Rajasthan',
    emergencyContact: '9988776656', salary: '40000', shiftType: 'Evening',
    isActive: false,
  ),
];

// ── Main Screen ───────────────────────────────────────────────────────────────

class AdminEmployeeScreen extends StatefulWidget {
  const AdminEmployeeScreen({super.key});

  @override
  State<AdminEmployeeScreen> createState() => _AdminEmployeeScreenState();
}

class _AdminEmployeeScreenState extends State<AdminEmployeeScreen> {
  List<EmployeeModel> _employees = List.from(_sampleEmployees);
  String _search = '';
  String _filterDept = 'All';

  static const _departments = ['All', 'Engineering', 'HR', 'Sales', 'Finance', 'Operations'];

  List<EmployeeModel> get _filtered {
    return _employees.where((e) {
      final matchSearch = e.name.toLowerCase().contains(_search.toLowerCase()) ||
          e.employeeId.toLowerCase().contains(_search.toLowerCase()) ||
          e.designation.toLowerCase().contains(_search.toLowerCase());
      final matchDept = _filterDept == 'All' || e.department == _filterDept;
      return matchSearch && matchDept;
    }).toList();
  }

  void _addOrEdit(EmployeeModel? existing) async {
    final result = await showModalBottomSheet<EmployeeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeFormSheet(employee: existing),
    );
    if (result != null) {
      setState(() {
        if (existing == null) {
          _employees.add(result);
        } else {
          final idx = _employees.indexWhere((e) => e.id == existing.id);
          if (idx != -1) _employees[idx] = result;
        }
      });
      if (mounted) {
        _showSnack(
          existing == null ? 'Employee added successfully' : 'Employee updated successfully',
          AppColors.success,
        );
      }
    }
  }

  void _delete(EmployeeModel emp) {
    showDialog(
      context: context,
      builder: (_) => _DeleteDialog(
        name: emp.name,
        onConfirm: () {
          setState(() => _employees.removeWhere((e) => e.id == emp.id));
          _showSnack('${emp.name} removed', AppColors.error);
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
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            iconTheme: const IconThemeData(
              color: Colors.white, // Back arrow color
            ),
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
                    Text('${_employees.length} total employees',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.white.withOpacity(0.75))),
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

          // ── Stats Row ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                _StatChip(label: 'Active', count: _employees.where((e) => e.isActive).length, color: AppColors.success),
                const SizedBox(width: 8),
                _StatChip(label: 'Inactive', count: _employees.where((e) => !e.isActive).length, color: AppColors.error),
                const SizedBox(width: 8),
                _StatChip(label: 'Departments', count: _employees.map((e) => e.department).toSet().length, color: AppColors.secondary),
              ]),
            ),
          ),

          // ── Search ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppShadow.subtle,
                ),
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
                itemCount: _departments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final dept = _departments[i];
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

          // ── List ─────────────────────────────────────────────────────────────
          filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.people_outline, size: 56, color: AppColors.neutralGrey),
                      const SizedBox(height: 12),
                      Text('No employees found', style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 15)),
                    ]),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _EmployeeCard(
                        employee: filtered[i],
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
  final EmployeeModel employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _EmployeeCard({required this.employee, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final initials = employee.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadow.subtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
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
            Text(employee.designation,
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMid)),
            const SizedBox(height: 4),
            Row(children: [
              _InfoPill(icon: Icons.badge_outlined, label: employee.employeeId),
              const SizedBox(width: 8),
              _InfoPill(icon: Icons.business_outlined, label: employee.department),
            ]),
          ])),
          // Actions
          Column(children: [
            _ActionBtn(icon: Icons.edit_rounded, color: AppColors.secondary, onTap: onEdit),
            const SizedBox(height: 6),
            _ActionBtn(icon: Icons.delete_rounded, color: AppColors.error, onTap: onDelete),
          ]),
        ]),
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
    Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
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
  final EmployeeModel? employee;
  const _EmployeeFormSheet({this.employee});

  @override
  State<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<_EmployeeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _email, _phone, _empId,
      _designation, _address, _emergencyContact, _salary, _joiningDate;

  String _department = 'Engineering';
  String _gender = 'Male';
  String _bloodGroup = 'O+';
  String _shiftType = 'Morning';
  bool _isActive = true;

  static const _depts = ['Engineering', 'HR', 'Sales', 'Finance', 'Operations', 'Marketing'];
  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  static const _shifts = ['Morning', 'Evening', 'Night', 'Flexible'];

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _name = TextEditingController(text: e?.name);
    _email = TextEditingController(text: e?.email);
    _phone = TextEditingController(text: e?.phone);
    _empId = TextEditingController(text: e?.employeeId ?? 'GC-00${DateTime.now().millisecondsSinceEpoch % 100}');
    _designation = TextEditingController(text: e?.designation);
    _address = TextEditingController(text: e?.address);
    _emergencyContact = TextEditingController(text: e?.emergencyContact);
    _salary = TextEditingController(text: e?.salary);
    _joiningDate = TextEditingController(text: e?.joiningDate ?? _today());
    if (e != null) {
      _department = e.department;
      _gender = e.gender;
      _bloodGroup = e.bloodGroup;
      _shiftType = e.shiftType;
      _isActive = e.isActive;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _empId, _designation, _address, _emergencyContact, _salary, _joiningDate]) {
      c.dispose();
    }
    super.dispose();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][now.month-1]} ${now.year}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final result = EmployeeModel(
      id: widget.employee?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      department: _department,
      designation: _designation.text.trim(),
      employeeId: _empId.text.trim(),
      joiningDate: _joiningDate.text.trim(),
      gender: _gender,
      bloodGroup: _bloodGroup,
      address: _address.text.trim(),
      emergencyContact: _emergencyContact.text.trim(),
      salary: _salary.text.trim(),
      shiftType: _shiftType,
      isActive: _isActive,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.6,
      maxChildSize: 0.98,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.neutralGreyLight, borderRadius: BorderRadius.circular(2))),
          // Header
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
              // if (_isEdit)
              //   Row(children: [
              //     Text('Active', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMid)),
              //     const SizedBox(width: 6),
              //     Switch.adaptive(
              //       value: _isActive,
              //       onChanged: (v) => setState(() => _isActive = v),
              //       activeColor: AppColors.success,
              //     ),
              //   ]),
            ]),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),

          // Form
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionLabel('Personal Information'),
                  const SizedBox(height: 12),
                  _buildField('Full Name *', _name, hint: 'e.g. Arjun Sharma', icon: Icons.person_outline,
                      validator: (v) => v!.trim().isEmpty ? 'Name is required' : null),
                  _buildField('Email Address *', _email, hint: 'e.g. arjun@company.in', icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => !v!.contains('@') ? 'Valid email required' : null),
                  _buildField('Phone Number *', _phone, hint: '10-digit mobile number', icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      validator: (v) => v!.length != 10 ? 'Enter valid 10-digit number' : null),
                  // Row(children: [
                  //   Expanded(child: _buildDropdown('Gender *', _gender, _genders, Icons.wc, (v) => setState(() => _gender = v!))),
                  //   const SizedBox(width: 12),
                  //   Expanded(child: _buildDropdown('Blood Group', _bloodGroup, _bloodGroups, Icons.bloodtype_outlined, (v) => setState(() => _bloodGroup = v!))),
                  // ]),
                  _buildField('Address', _address, hint: 'City, State', icon: Icons.location_on_outlined, maxLines: 2),
                  const SizedBox(height: 8),

                  _sectionLabel('Employment Details'),
                  const SizedBox(height: 12),
                  _buildField('Employee ID *', _empId, hint: 'e.g. GC-001', icon: Icons.badge_outlined,
                      validator: (v) => v!.trim().isEmpty ? 'Employee ID required' : null),
                  _buildField('Designation *', _designation, hint: 'e.g. Senior Developer', icon: Icons.work_outline,
                      validator: (v) => v!.trim().isEmpty ? 'Designation required' : null),
                  _buildDropdown('Department *', _department, _depts, Icons.business_outlined, (v) => setState(() => _department = v!)),
                  // _buildDropdown('Shift Type *', _shiftType, _shifts, Icons.access_time_outlined, (v) => setState(() => _shiftType = v!)),
                  _buildField('Joining Date *', _joiningDate, hint: 'DD MMM YYYY', icon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context, initialDate: DateTime.now(),
                          firstDate: DateTime(2010), lastDate: DateTime.now(),
                          builder: (c, child) => Theme(data: Theme.of(c).copyWith(
                            colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
                        );
                        if (picked != null) {
                          final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                          _joiningDate.text = '${picked.day.toString().padLeft(2,'0')} ${months[picked.month-1]} ${picked.year}';
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
                  _buildField('Emergency Contact *', _emergencyContact, hint: '10-digit number', icon: Icons.emergency_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      validator: (v) => v!.length != 10 ? 'Valid emergency number required' : null),
                ]),
              ),
            ),
          ),

          // Submit
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    int maxLines = 1, bool readOnly = false, VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.textLight) : null,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ]),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, IconData icon, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMid)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
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
}

// ── Delete Dialog ─────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  final String name;
  final VoidCallback onConfirm;
  const _DeleteDialog({required this.name, required this.onConfirm});

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
      Text('Delete Employee', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    ]),
    content: Text('Are you sure you want to remove "$name"? This action cannot be undone.',
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
