import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'salary_screen.dart';
import 'hr_policy_screen.dart';
import 'document_upload_screen.dart';
import 'my_documents_screen.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();

    // Agar auth abhi bhi initialize ho raha hai toh wait karo
    if (authProvider.isLoading) {
      debugPrint('⏳ [Profile] Auth still loading, waiting...');
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return context.read<AuthProvider>().isLoading;
      });
    }

    final userId = context.read<AuthProvider>().user?.id ?? '';
    debugPrint('🔍 [Profile] userId from AuthProvider: "$userId"');

    if (userId.isEmpty) {
      debugPrint('❌ [Profile] userId is empty — user not logged in or session expired');
      return;
    }

    debugPrint('▶ [Profile] Calling fetchUserById($userId)');
    await context.read<ProfileProvider>().fetchUserById(userId);
  }

  // ─── helpers ───────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  String _formatJoinDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _maskBankAc(String ac) {
    if (ac.length <= 4) return ac;
    return '•••• ${ac.substring(ac.length - 4)}';
  }

  String _maskAadhar(String no) {
    if (no.length < 4) return no;
    return 'XXXX XXXX ${no.substring(no.length - 4)}';
  }

  // ─── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return _buildShimmer();
        if (provider.errorMessage != null) return _buildError(provider);
        if (provider.profile == null) return _buildShimmer();
        return _buildContent(context, provider.profile!);
      },
    );
  }

  // ─── Shimmer ───────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(children: [
        const SizedBox(height: 16),
        _ShimmerBox(height: 180, radius: AppSpacing.cardRadius),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _ShimmerBox(height: 90, radius: AppSpacing.cardRadius)),
          const SizedBox(width: 8),
          Expanded(child: _ShimmerBox(height: 90, radius: AppSpacing.cardRadius)),
          const SizedBox(width: 8),
          Expanded(child: _ShimmerBox(height: 90, radius: AppSpacing.cardRadius)),
        ]),
        const SizedBox(height: 20),
        _ShimmerBox(height: 280, radius: AppSpacing.cardRadius),
        const SizedBox(height: 20),
        _ShimmerBox(height: 220, radius: AppSpacing.cardRadius),
      ]),
    );
  }

  // ─── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(ProfileProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.wifi_off_rounded,
                color: AppColors.error, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Failed to load profile',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(provider.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textLight)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                boxShadow: AppShadow.strong,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Retry',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Main content ──────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, UserProfile p) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          _buildProfileHero(context, p),
          const SizedBox(height: 20),
          _buildQuickActions(context),
          const SizedBox(height: 20),
          _buildPersonalInfo(p),
          const SizedBox(height: 20),
          _buildBankInfo(p),
          const SizedBox(height: 20),
          _buildDocumentInfo(p),
          const SizedBox(height: 28),
          _buildLogoutButton(context),
          const SizedBox(height: 8),

        ]),
      ),
    );
  }

  // ─── Hero card ─────────────────────────────────────────────────────────────

  Widget _buildProfileHero(BuildContext context, UserProfile p) {
    return PremiumCard(
      gradient: AppColors.darkGradient,
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Row(children: [
          // Avatar
          Stack(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16, offset: const Offset(0, 6),
                )],
              ),
              child: Center(child: Text(
                _initials(p.name),
                style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              )),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 16),
          // Name & role
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name,
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text(p.dept,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 8),
            Row(children: [
              TagBadge(
                label: p.role[0].toUpperCase() + p.role.substring(1),
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              TagBadge(label: 'Full-Time', color: AppColors.success),
            ]),
          ])),
        ]),
        const SizedBox(height: 20),
        Container(height: 1, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildProfileStat(
              p.id.toUpperCase(), 'Employee ID', Icons.badge_rounded)),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          Expanded(child: _buildProfileStat(
              p.dept, 'Department', Icons.business_rounded)),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          Expanded(child: _buildProfileStat(
              '₹${(p.salary / 1000).toStringAsFixed(0)}K', 'Salary/Mo', Icons.account_balance_wallet_rounded)),
        ]),
      ]),
    );
  }

  Widget _buildProfileStat(String value, String label, IconData icon) {
    return Column(children: [
      Icon(icon, color: AppColors.primary, size: 16),
      const SizedBox(height: 4),
      Text(value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.4))),
    ]);
  }

  // ─── Quick actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'label': 'Salary',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.success,
        'screen': const SalaryScreen()
      },
      {
        'label': 'HR Policy',
        'icon': Icons.policy_rounded,
        'color': AppColors.primary,
        'screen': const HRPolicyScreen()
      },
      {
        'label': 'Support',
        'icon': Icons.support_agent_rounded,
        'color': AppColors.accent,
        'screen': null
      },
    ];

    return Row(
      children: actions.map((a) {
        final color = a['color'] as Color;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (a['screen'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: AppColors.background,
                        appBar: AppBar(
                          backgroundColor: AppColors.background,
                          elevation: 0,
                          title: Text(a['label'] as String,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded,
                                color: AppColors.textDark),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        body: SafeArea(child: a['screen'] as Widget),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${a['label']} coming soon',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    backgroundColor: color,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              child: PremiumCard(
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                child: Column(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(a['icon'] as IconData, color: color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(a['label'] as String,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Personal info ─────────────────────────────────────────────────────────

  Widget _buildPersonalInfo(UserProfile p) {
    final info = [
      {
        'icon': Icons.person_rounded,
        'label': 'Username',
        'value': p.username,
        'color': AppColors.secondary
      },
      {
        'icon': Icons.email_rounded,
        'label': 'Email',
        'value': p.email,
        'color': AppColors.primary
      },
      {
        'icon': Icons.work_rounded,
        'label': 'Department',
        'value': p.dept,
        'color': AppColors.success
      },
      {
        'icon': Icons.calendar_month_rounded,
        'label': 'Joined',
        'value': _formatJoinDate(p.joinDate),
        'color': AppColors.warning
      },
    ];

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_pin_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Text('Personal Information',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        ...info.map((i) => _infoRow(
            icon: i['icon'] as IconData,
            label: i['label'] as String,
            value: i['value'] as String,
            color: i['color'] as Color)),
      ]),
    );
  }

  // ─── Bank info ─────────────────────────────────────────────────────────────

  Widget _buildBankInfo(UserProfile p) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Text('Bank Details',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        _infoRow(
            icon: Icons.account_balance_rounded,
            label: 'Bank Name',
            value: p.bankName,
            color: AppColors.success),
        _infoRow(
            icon: Icons.location_city_rounded,
            label: 'Branch',
            value: p.bankBranch,
            color: AppColors.primary),
        _infoRow(
            icon: Icons.credit_card_rounded,
            label: 'Account No',
            value: _maskBankAc(p.bankAccountNo),
            color: AppColors.secondary,
            copyValue: p.bankAccountNo),
        _infoRow(
            icon: Icons.tag_rounded,
            label: 'IFSC Code',
            value: p.bankIfsc,
            color: AppColors.warning,
            copyValue: p.bankIfsc),
      ]),
    );
  }

  // ─── Document info ─────────────────────────────────────────────────────────

  Widget _buildDocumentInfo(UserProfile p) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.folder_special_rounded,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Documents',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark))),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: AppColors.background,
                  appBar: AppBar(
                    backgroundColor: AppColors.background,
                    elevation: 0,
                    title: Text('My Documents',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: const SafeArea(child: DocumentUploadScreen()),
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8, offset: const Offset(0, 3),
                )],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.upload_file_rounded,
                    color: Colors.white, size: 13),
                const SizedBox(width: 4),
                Text('Manage',
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Aadhar & PAN quick view
        _infoRow(
            icon: Icons.fingerprint_rounded,
            label: 'Aadhar Number',
            value: _maskAadhar(p.aadharNo),
            color: AppColors.accent,
            copyValue: p.aadharNo),
        _infoRow(
            icon: Icons.assignment_ind_rounded,
            label: 'PAN Number',
            value: p.panNo,
            color: AppColors.secondary,
            copyValue: p.panNo),

        // Document tiles row
        const SizedBox(height: 4),
        Row(children: [
          _docTile(Icons.school_rounded, 'Marksheet', AppColors.warning),
          const SizedBox(width: 8),
          _docTile(Icons.account_balance_rounded, 'Bank Proof', AppColors.success),
          const SizedBox(width: 8),
          _docTile(Icons.description_rounded, 'Resume', AppColors.primary),
        ]),

        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  title: Text('My Documents',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: AppColors.textDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                body: const SafeArea(child: DocumentUploadScreen()),
              ),
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.upload_file_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Upload Documents',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: AppColors.primary),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyDocumentsScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8, offset: const Offset(0, 3),
              )],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.folder_open_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text('View Uploaded Documents',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _docTile(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ),
    );
  }

  // ─── Shared info row ───────────────────────────────────────────────────────

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? copyValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textLight)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ])),
        if (copyValue != null)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: copyValue));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$label copied',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                backgroundColor: color,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.copy_rounded, color: color, size: 14),
            ),
          ),
      ]),
    );
  }
}

// ─── Logout Button + Confirm Sheet ───────────────────────────────────────────

Widget _buildLogoutButton(BuildContext context) {
  return _LogoutButton();
}

class _LogoutButton extends StatefulWidget {
  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _LogoutConfirmSheet(),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await context.read<AuthProvider>().logout();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Log out',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LogoutConfirmSheet extends StatelessWidget {
  const _LogoutConfirmSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.logout_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Log out?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Cancel
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMid,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Confirm
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Yes, log out',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Box ──────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double radius;
  final double? width;

  const _ShimmerBox(
      {required this.height, required this.radius, this.width});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              AppColors.neutralGreyLight,
              AppColors.background,
              AppColors.neutralGreyLight,
            ],
          ),
        ),
      ),
    );
  }
}