import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/auth_models.dart';
import '../../services/admin_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _oldFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _oldFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ─── Password strength (visual hint only, not a validation gate) ─────────

  double get _strengthScore {
    final v = _newPasswordController.text;
    if (v.isEmpty) return 0;
    double score = 0;
    if (v.length >= 8) score += 0.25;
    if (v.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(v)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(v)) score += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) score += 0.2;
    return score.clamp(0, 1);
  }

  String get _strengthLabel {
    final s = _strengthScore;
    if (s == 0) return '';
    if (s < 0.4) return 'Weak';
    if (s < 0.75) return 'Medium';
    return 'Strong';
  }

  Color get _strengthColor {
    final s = _strengthScore;
    if (s < 0.4) return AppColors.error;
    if (s < 0.75) return AppColors.warning;
    return AppColors.success;
  }

  // ─── Validation ────────────────────────────────────────────────────────

  String? _validateOldPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Use a mix of letters and numbers';
    }
    if (value == _oldPasswordController.text) {
      return 'New password must be different from current password';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ─── Submit ────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final adminApiService = context.read<AdminApiService>();
      final message = await adminApiService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      setState(() {
        _successMessage = message;
        _isSubmitting = false;
      });

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Password changed successfully',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Give the user a moment to see the success state, then go back.
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isSubmitting = false;
      });
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderIcon(),
                const SizedBox(height: 24),
                _buildErrorBanner(),

                PremiumCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Current Password'),
                      const SizedBox(height: 8),
                      _passwordField(
                        controller: _oldPasswordController,
                        focusNode: _oldFocus,
                        obscure: _obscureOld,
                        hint: 'Enter your current password',
                        onToggleObscure: () => setState(() => _obscureOld = !_obscureOld),
                        validator: _validateOldPassword,
                        onFieldSubmitted: (_) => _newFocus.requestFocus(),
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 20),
                      Container(height: 1, color: AppColors.border),
                      const SizedBox(height: 20),

                      _fieldLabel('New Password'),
                      const SizedBox(height: 8),
                      _passwordField(
                        controller: _newPasswordController,
                        focusNode: _newFocus,
                        obscure: _obscureNew,
                        hint: 'At least 8 characters',
                        onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                        validator: _validateNewPassword,
                        onChanged: (_) => setState(() {}),
                        onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                        textInputAction: TextInputAction.next,
                      ),
                      if (_newPasswordController.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildStrengthMeter(),
                      ],

                      const SizedBox(height: 20),

                      _fieldLabel('Confirm New Password'),
                      const SizedBox(height: 8),
                      _passwordField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmFocus,
                        obscure: _obscureConfirm,
                        hint: 'Re-enter new password',
                        onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: _validateConfirmPassword,
                        onFieldSubmitted: (_) => _handleSubmit(),
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                _buildRequirementsCard(),

                const SizedBox(height: 28),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update your password',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Keep your account secure',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textMid,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool obscure,
    required String hint,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      enabled: !_isSubmitting,
      textInputAction: textInputAction,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textLight, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textLight,
            size: 20,
          ),
          onPressed: onToggleObscure,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 11, color: AppColors.error),
      ),
    );
  }

  Widget _buildStrengthMeter() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _strengthScore,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _strengthLabel,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _strengthColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsCard() {
    final newPass = _newPasswordController.text;
    final rules = [
      _RuleCheck('At least 8 characters', newPass.length >= 8),
      _RuleCheck('Contains a letter and a number',
          RegExp(r'[A-Za-z]').hasMatch(newPass) && RegExp(r'[0-9]').hasMatch(newPass)),
      _RuleCheck('Different from current password',
          newPass.isNotEmpty && newPass != _oldPasswordController.text),
    ];

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      color: AppColors.primaryBg,
      shadows: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...rules.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  r.met ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 15,
                  color: r.met ? AppColors.success : AppColors.textLight,
                ),
                const SizedBox(width: 8),
                Text(
                  r.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: r.met ? AppColors.textDark : AppColors.textMid,
                    fontWeight: r.met ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 20),
            const SizedBox(width: 10),
            Text(
              'Update Password',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleCheck {
  final String label;
  final bool met;
  _RuleCheck(this.label, this.met);
}