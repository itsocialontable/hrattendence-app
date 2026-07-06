import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import 'admin_otp_screen.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({Key? key}) : super(key: key);

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false; // local guard, independent of provider state —
  // prevents a fast double-tap from firing two concurrent registerAdmin()
  // calls that both mutate the same shared AdminAuthProvider instance.

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_isSubmitting) return; // block double-tap re-entry
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<AdminAuthProvider>();

    final success = await provider.registerAdmin(
      fullName: _firstNameController.text.trim(),
      lName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNo: _phoneController.text.trim(),
      companyName: _companyController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      secret: '', // Add secret field to form if required by backend
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    debugPrint('[RegisterScreen] after await -> success=$success, '
        'isDuplicateEmail=${provider.isDuplicateEmail}, '
        'isLoading=${provider.isLoading}, error=${provider.error}');

    if (success) {
      // Navigate to OTP verification screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminOtpScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    } else if (provider.isDuplicateEmail) {
      // This email is already registered — either a genuine duplicate, or
      // a prior request that timed out client-side but actually succeeded
      // server-side. Either way, pushing the user back into the same form
      // to "try again" would be wrong. Send them to Sign In instead.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ??
                'This email is already registered. Please sign in instead.',
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      // Show error from provider
      final error = provider.error ?? 'Registration failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                // Back
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

                SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                // Admin badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Admin Portal',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Create Admin\nAccount',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register to manage your organization',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // First + Last name row
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _firstNameController,
                              label: 'First Name',
                              hint: 'John',
                              icon: Icons.person_outline,
                              validator: (v) => (v?.isEmpty ?? true)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              hint: 'Doe',
                              icon: Icons.person_outline,
                              validator: (v) => (v?.isEmpty ?? true)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'admin@company.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Email is required';
                          if (!v!.contains('@')) return 'Enter valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '+91 98765 43210',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v?.isEmpty ?? true)
                            ? 'Phone is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        controller: _companyController,
                        label: 'Company / Organization Name',
                        hint: 'GrowthCraft Pvt. Ltd.',
                        icon: Icons.business_outlined,
                        validator: (v) => (v?.isEmpty ?? true)
                            ? 'Company name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Create a strong password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade400,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Password is required';
                          if ((v?.length ?? 0) < 6)
                            return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade400,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) {
                          if (v?.isEmpty ?? true)
                            return 'Please confirm password';
                          if (v != _passwordController.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                // Register button — watches isLoading from provider
                Consumer<AdminAuthProvider>(
                  builder: (context, provider, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (provider.isLoading || _isSubmitting)
                            ? null
                            : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: (provider.isLoading || _isSubmitting)
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
                                'Create Admin Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                // Visible hint while the request is in flight, so a slow
                // cold-starting backend doesn't look like a frozen loader.
                Consumer<AdminAuthProvider>(
                  builder: (context, provider, _) {
                    if (!provider.isLoading && !_isSubmitting) {
                      return const SizedBox.shrink();
                    }
                    return const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Connecting to server… this can take up to a minute '
                        'on first use.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textLight),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.grey.shade400),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }
}
