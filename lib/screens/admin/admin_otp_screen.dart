import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import 'admin_login_screen.dart';

class AdminOtpScreen extends StatefulWidget {
  final String email;
  final bool isReset; // true = reset password flow, false = registration flow

  const AdminOtpScreen({
    Key? key,
    required this.email,
    this.isReset = false,
  }) : super(key: key);

  @override
  State<AdminOtpScreen> createState() => _AdminOtpScreenState();
}

class _AdminOtpScreenState extends State<AdminOtpScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendSeconds > 0) _resendSeconds--;
      });
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _handleVerify() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<AdminAuthProvider>();

    // Registration flow: POST /api/register/verify-otp
    // Forgot-password flow: POST /api/verify-otp (already handled via provider)
    // For registration OTP verify we call verifyOtp on provider
    // The provider uses _pendingEmail internally — for registration flow we
    // need to set it by calling sendForgotPasswordOtp first, but since
    // registration sends OTP automatically, we call verifyOtp directly on
    // admin_api_service via a dedicated path.
    bool success = false;

    if (widget.isReset) {
      // Forgot-password OTP verify flow — provider handles email internally
      success = await provider.verifyOtp(otp: _otp);
    } else {
      // Registration OTP verify — call /api/register/verify-otp
      success = await provider.verifyRegistrationOtp(
        email: widget.email,
        otp: _otp,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isReset
              ? 'OTP verified! Set your new password.'
              : 'Admin account verified successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    } else {
      final error = provider.error ?? 'Invalid or expired OTP.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _handleResend() async {
    if (_resendSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _resendSeconds = 60;
    });

    final provider = context.read<AdminAuthProvider>();
    bool success = false;

    if (widget.isReset) {
      // Forgot-password resend — uses _pendingEmail from provider
      success = await provider.resendOtp();
    } else {
      // Registration resend — POST /api/register/resend-otp
      success = await provider.resendRegistrationOtp(email: widget.email);
    }

    if (!mounted) return;
    setState(() => _isResending = false);

    if (success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP resent to ${widget.email}'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      final error = provider.error ?? 'Failed to resend OTP.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.06),

                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      color: Colors.white, size: 36),
                ),

                const SizedBox(height: 24),

                Text(
                  'Verify OTP',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.5),
                    children: [
                      const TextSpan(
                          text: 'Enter the 6-digit OTP sent to\n'),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.06),

                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextFormField(
                        controller: _otpControllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Colors.white, width: 2),
                          ),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          }
                          if (v.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive the OTP? ",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: _resendSeconds == 0 ? _handleResend : null,
                      child: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _resendSeconds > 0
                                  ? 'Resend in ${_resendSeconds}s'
                                  : 'Resend OTP',
                              style: TextStyle(
                                color: _resendSeconds == 0
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: _resendSeconds == 0
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
