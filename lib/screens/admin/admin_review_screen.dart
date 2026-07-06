import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../providers/admin_review_provider.dart';
import '../../models/admin_models.dart';
import '../../models/admin_review_models.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

const List<String> _kCategories = [
  'overall',
  'performance',
  'attendance',
  'teamwork',
  'communication',
  'leadership',
  'punctuality',
];

String _categoryLabel(String c) =>
    c.isEmpty ? 'Overall' : '${c[0].toUpperCase()}${c.substring(1)}';

String _monthLabel(String apiMonth) {
  // "2026-07" → "Jul 2026"
  try {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final parts = apiMonth.split('-');
    final month = int.parse(parts[1]);
    return '${m[month - 1]} ${parts[0]}';
  } catch (_) {
    return apiMonth;
  }
}

/// Generates the last N months as "YYYY-MM" strings.
List<String> _recentMonths([int count = 6]) {
  final now = DateTime.now();
  return List.generate(count, (i) {
    final d = DateTime(now.year, now.month - i);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  });
}

Color _ratingColor(double r) {
  if (r >= 4.5) return AppColors.success;
  if (r >= 3.5) return const Color(0xFF2F8F5B);
  if (r >= 2.5) return AppColors.warning;
  if (r >= 1.5) return AppColors.error;
  return AppColors.error;
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  String _filterUserId = '';
  String _filterMonth = '';
  String _searchQuery = '';

  late final List<String> _months;

  @override
  void initState() {
    super.initState();
    _months = _recentMonths(12);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger employee list fetch so the form can pick a user
      context.read<AdminEmployeeProvider>().fetchEmployees();
      _fetchReviews();
    });
  }

  void _fetchReviews() {
    context.read<AdminReviewProvider>().fetchReviews(
          userId: _filterUserId.isEmpty ? null : _filterUserId,
          month: _filterMonth.isEmpty ? null : _filterMonth,
        );
  }

  // ── Snackbar ────────────────────────────────────────────────────────────────

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Open Review Form ────────────────────────────────────────────────────────

  void _openReviewForm({AdminReview? existing}) async {
    final employees =
        context.read<AdminEmployeeProvider>().employees;

    if (employees.isEmpty) {
      _snack('Loading employees… please try again.', isError: true);
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewFormSheet(
        employees: employees,
        months: _months,
        existing: existing,
        onSubmit: (input) => _handleSubmit(input),
        onUpdate: existing != null
            ? (upd) => _handleUpdate(existing.id, upd)
            : null,
      ),
    );
  }

  Future<void> _handleSubmit(AdminReviewInput input) async {
    final ok = await context.read<AdminReviewProvider>().submitReview(input);
    if (!mounted) return;
    final err = context.read<AdminReviewProvider>().mutationError;
    _snack(ok ? 'Review submitted successfully!' : err ?? 'Submit failed',
        isError: !ok);
    if (ok) _fetchReviews();
  }

  Future<void> _handleUpdate(
      String id, AdminReviewUpdateInput input) async {
    final ok = await context.read<AdminReviewProvider>().updateReview(id, input);
    if (!mounted) return;
    final err = context.read<AdminReviewProvider>().mutationError;
    _snack(ok ? 'Review updated!' : err ?? 'Update failed', isError: !ok);
  }

  Future<void> _confirmDelete(AdminReview review) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(review: review),
    );
    if (ok != true || !mounted) return;
    final deleted =
        await context.read<AdminReviewProvider>().deleteReview(review.id);
    if (!mounted) return;
    final err = context.read<AdminReviewProvider>().mutationError;
    _snack(deleted ? 'Review deleted.' : err ?? 'Delete failed',
        isError: !deleted);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminReviewProvider>().refresh(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildFilters(),
            _buildBody(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReviewForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.rate_review_rounded, color: Colors.white),
        label: Text('New Review',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.star_rate_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Performance Reviews',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Consumer<AdminReviewProvider>(
                              builder: (_, p, __) => Text(
                                '${p.reviews.length} review${p.reviews.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 13),
                              ),
                            ),
                          ]),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: Text('Reviews',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Filters ─────────────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildFilters() {
    final employees = context.watch<AdminEmployeeProvider>().employees;

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Search by employee or category…',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textLight, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Employee + Month filter chips row
            Row(children: [
              Expanded(
                child: _DropdownFilter(
                  icon: Icons.person_outline,
                  hint: 'All Employees',
                  value: _filterUserId.isEmpty ? null : _filterUserId,
                  items: employees
                      .map((e) =>
                          DropdownMenuItem(value: e.id, child: Text(e.name)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _filterUserId = v ?? '');
                    _fetchReviews();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownFilter(
                  icon: Icons.calendar_month_outlined,
                  hint: 'All Months',
                  value: _filterMonth.isEmpty ? null : _filterMonth,
                  items: _months
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(_monthLabel(m))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _filterMonth = v ?? '');
                    _fetchReviews();
                  },
                ),
              ),
            ]),
            // Active filter chips
            if (_filterUserId.isNotEmpty || _filterMonth.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  if (_filterMonth.isNotEmpty)
                    _FilterChip(
                      label: _monthLabel(_filterMonth),
                      onRemove: () {
                        setState(() => _filterMonth = '');
                        _fetchReviews();
                      },
                    ),
                  if (_filterUserId.isNotEmpty)
                    _FilterChip(
                      label: employees
                              .firstWhere((e) => e.id == _filterUserId,
                                  orElse: () => AdminEmployee(
                                      id: '', name: 'Employee',
                                      username: '', email: '',
                                      role: '', dept: '',
                                      designation: '', salary: 0,
                                      joinDate: ''))
                              .name,
                      onRemove: () {
                        setState(() => _filterUserId = '');
                        _fetchReviews();
                      },
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterUserId = '';
                        _filterMonth = '';
                        _searchQuery = '';
                      });
                      _fetchReviews();
                    },
                    child: Text('Clear all',
                        style: GoogleFonts.poppins(
                            color: AppColors.error,
                            fontSize: 8,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  // ── Body (list / loading / error / empty) ────────────────────────────────────

  Widget _buildBody() {
    return Consumer<AdminReviewProvider>(
      builder: (_, prov, __) {
        if (prov.isLoading) {
          return const SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (prov.hasError) {
          return SliverFillRemaining(
            child: _ErrorState(
              message: prov.error!,
              onRetry: _fetchReviews,
            ),
          );
        }

        final reviews = prov.reviews.where((r) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return r.employeeName.toLowerCase().contains(q) ||
              r.category.toLowerCase().contains(q) ||
              r.title.toLowerCase().contains(q) ||
              r.comment.toLowerCase().contains(q);
        }).toList();

        if (reviews.isEmpty) {
          return SliverFillRemaining(
            child: _EmptyState(
              hasFilters: _filterUserId.isNotEmpty ||
                  _filterMonth.isNotEmpty ||
                  _searchQuery.isNotEmpty,
              onAdd: () => _openReviewForm(),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ReviewCard(
                review: reviews[i],
                onEdit: () => _openReviewForm(existing: reviews[i]),
                onDelete: () => _confirmDelete(reviews[i]),
              ),
              childCount: reviews.length,
            ),
          ),
        );
      },
    );
  }
}

// ── Review Card ────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final AdminReview review;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.review,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(review.rating);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.card,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    review.employeeName.isNotEmpty
                        ? review.employeeName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.employeeName,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(children: [
                        _Chip(
                            label: _categoryLabel(review.category),
                            color: AppColors.secondary),
                        const SizedBox(width: 6),
                        _Chip(
                            label: _monthLabel(review.month),
                            color: AppColors.textMid),
                      ]),
                    ]),
              ),
              // Rating badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.star_rounded, color: color, size: 15),
                  const SizedBox(width: 3),
                  Text(review.rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ]),
              ),
              const SizedBox(width: 4),
              // Action menu
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Text('Edit', style: GoogleFonts.poppins(fontSize: 13)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: 10),
                      Text('Delete',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.error)),
                    ]),
                  ),
                ],
                child: const Icon(Icons.more_vert,
                    color: AppColors.textLight, size: 20),
              ),
            ]),
          ),
          // Stars row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _StarRow(rating: review.rating),
          ),
          // Title
          if (review.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(review.title,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textDark)),
            ),
          // Comment
          if (review.comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(review.comment,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textMid, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(children: [
              Icon(
                review.isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 14,
                color: review.isVisible
                    ? AppColors.success
                    : AppColors.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                review.isVisible ? 'Visible to employee' : 'Hidden',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: review.isVisible
                        ? AppColors.success
                        : AppColors.textLight),
              ),
              if (review.createdAt != null) ...[
                const Spacer(),
                Text(
                  _formatDate(review.createdAt!),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Star Row ───────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final fill = (rating - i).clamp(0.0, 1.0);
        return Icon(
          fill >= 1.0
              ? Icons.star_rounded
              : fill >= 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          color: fill > 0 ? const Color(0xFFF5A623) : AppColors.neutralGreyLight,
          size: 18,
        );
      }),
    );
  }
}

// ── Review Form Sheet ──────────────────────────────────────────────────────────

class _ReviewFormSheet extends StatefulWidget {
  final List<AdminEmployee> employees;
  final List<String> months;
  final AdminReview? existing;
  final Future<void> Function(AdminReviewInput) onSubmit;
  final Future<void> Function(AdminReviewUpdateInput)? onUpdate;

  const _ReviewFormSheet({
    required this.employees,
    required this.months,
    required this.existing,
    required this.onSubmit,
    required this.onUpdate,
  });

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  String? _selectedUserId;
  String? _selectedMonth;
  String _selectedCategory = 'overall';
  double _rating = 3;
  bool _isVisible = true;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _selectedUserId = e.userId;
      _selectedMonth = e.month;
      _selectedCategory = e.category;
      _rating = e.rating;
      _titleCtrl.text = e.title;
      _commentCtrl.text = e.comment;
      _isVisible = e.isVisible;
    } else {
      _selectedMonth = widget.months.first;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    if (_isEdit) {
      await widget.onUpdate!(AdminReviewUpdateInput(
        rating: _rating,
        title: _titleCtrl.text.trim(),
        comment: _commentCtrl.text.trim(),
        category: _selectedCategory,
        isVisible: _isVisible,
      ));
    } else {
      await widget.onSubmit(AdminReviewInput(
        userId: _selectedUserId!,
        month: _selectedMonth!,
        rating: _rating,
        title: _titleCtrl.text.trim(),
        comment: _commentCtrl.text.trim(),
        category: _selectedCategory,
      ));
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.rate_review_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(_isEdit ? 'Edit Review' : 'New Performance Review',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                ]),
              ),

              // Employee picker (only for new)
              if (!_isEdit) ...[
                _Label('Employee *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedUserId,
                  isExpanded: true,
                  decoration: _inputDeco(
                      Icons.person_outline, 'Select employee'),
                  hint: Text('Select employee',
                      style: GoogleFonts.poppins(
                          color: AppColors.textLight, fontSize: 14)),
                  items: widget.employees
                      .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name,
                              style: GoogleFonts.poppins(fontSize: 14),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please select an employee' : null,
                  onChanged: (v) => setState(() => _selectedUserId = v),
                ),
                const SizedBox(height: 16),
              ],

              // Month picker (only for new)
              if (!_isEdit) ...[
                _Label('Month *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  isExpanded: true,
                  decoration: _inputDeco(
                      Icons.calendar_month_outlined, 'Select month'),
                  items: widget.months
                      .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(_monthLabel(m),
                              style: GoogleFonts.poppins(fontSize: 14))))
                      .toList(),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please select a month' : null,
                  onChanged: (v) => setState(() => _selectedMonth = v),
                ),
                const SizedBox(height: 16),
              ],

              // Category
              _Label('Category'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration:
                    _inputDeco(Icons.category_outlined, 'Category'),
                items: _kCategories
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(_categoryLabel(c),
                            style: GoogleFonts.poppins(fontSize: 14))))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCategory = v ?? 'overall'),
              ),
              const SizedBox(height: 20),

              // Rating slider
              _Label('Rating *'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(5, (i) {
                        final filled = _rating > i;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = (i + 1).toDouble()),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: filled
                                  ? const Color(0xFFF5A623)
                                  : AppColors.neutralGreyLight,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 12),
                      Text(
                        _rating.toStringAsFixed(0),
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _ratingColor(_rating)),
                      ),
                      Text('/5',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textLight)),
                    ],
                  ),
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 8, // 0.5 steps
                    activeColor: _ratingColor(_rating),
                    inactiveColor: AppColors.border,
                    onChanged: (v) =>
                        setState(() => _rating = (v * 2).round() / 2),
                  ),
                  Text(
                    _ratingText(_rating),
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _ratingColor(_rating),
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Title
              _Label('Title (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textDark),
                decoration: _inputDeco(
                    Icons.title_rounded, 'e.g. Excellent Performer'),
                maxLength: 100,
              ),
              const SizedBox(height: 4),

              // Comment
              _Label('Comment (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _commentCtrl,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textDark),
                maxLines: 4,
                maxLength: 500,
                decoration: _inputDeco(null, 'Add detailed feedback…'),
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 12),

              // Visibility toggle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Icon(
                    _isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _isVisible
                        ? AppColors.success
                        : AppColors.textLight,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Visible to Employee',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark)),
                          Text(
                            _isVisible
                                ? 'Employee can see this review'
                                : 'Review is hidden from employee',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textLight),
                          ),
                        ]),
                  ),
                  Switch(
                    value: _isVisible,
                    activeColor: AppColors.success,
                    onChanged: (v) => setState(() => _isVisible = v),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isEdit ? 'Update Review' : 'Submit Review',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingText(double r) {
    if (r >= 5) return 'Outstanding';
    if (r >= 4) return 'Excellent';
    if (r >= 3) return 'Good';
    if (r >= 2) return 'Needs Improvement';
    return 'Poor';
  }

  InputDecoration _inputDeco(IconData? icon, String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14),
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.textLight, size: 20)
            : null,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        counterStyle: GoogleFonts.poppins(
            fontSize: 10, color: AppColors.textLight),
      );
}

// ── Delete Dialog ──────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  final AdminReview review;
  const _DeleteDialog({required this.review});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.errorBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.delete_outline,
              color: AppColors.error, size: 20),
        ),
        const SizedBox(width: 12),
        Text('Delete Review',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark)),
      ]),
      content: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textMid),
          children: [
            const TextSpan(text: 'Delete the '),
            TextSpan(
                text: _categoryLabel(review.category),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const TextSpan(text: ' review for '),
            TextSpan(
                text: review.employeeName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const TextSpan(
                text:
                    '? This action cannot be undone.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: GoogleFonts.poppins(color: AppColors.textMid)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Empty / Error States ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onAdd;
  const _EmptyState({required this.hasFilters, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.rate_review_outlined,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters
                  ? 'No reviews match your filters'
                  : 'No reviews yet',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try clearing filters or a different month.'
                  : 'Tap the button below to submit your first performance review.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            if (!hasFilters) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text(message,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textMid),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color)),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 14, color: AppColors.primary),
          ),
        ]),
      );
}

class _DropdownFilter extends StatelessWidget {
  final IconData icon;
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.icon,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.textLight),
          hint: Row(children: [
            const SizedBox(width: 10),
            Icon(icon, size: 16, color: AppColors.textLight),
            const SizedBox(width: 6),
            Expanded(
              child: Text(hint,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textLight),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          selectedItemBuilder: (_) => [
            // "All" option displayed in hint style
            Row(children: [
              const SizedBox(width: 10),
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(hint,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            ...items.map((item) => Row(children: [
                  const SizedBox(width: 10),
                  Icon(icon, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DefaultTextStyle(
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                      child: item.child,
                    ),
                  ),
                ])),
          ],
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(hint,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textLight)),
            ),
            ...items,
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
