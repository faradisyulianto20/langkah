import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/core/utils/validators.dart';
import 'package:langkah/core/widgets/custom_button.dart';
import 'package:langkah/core/widgets/custom_text_field.dart';
import 'package:langkah/features/auth/presentation/auth_view_model.dart';
import 'package:langkah/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final authVm = context.read<AuthViewModel>();

    final success = await authVm.register(
      email: email,
      password: _passwordController.text,
      username: _usernameController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      UIFeedback.showSuccess(context, 'Akun dibuat! Silakan verifikasi kode OTP Anda.');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(
            email: email,
            otpType: OtpType.signup,
          ),
        ),
      );
    } else if (authVm.errorMessage != null) {
      UIFeedback.showError(context, authVm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Mulai Langkah Baru',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daftarkan akun Anda dan mulailah membangun konsistensi pengembangan diri.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Username Input
                    CustomTextField(
                      controller: _usernameController,
                      label: 'Username',
                      hint: 'contoh: faradis_y',
                      prefixIcon: Icons.alternate_email_rounded,
                      validator: Validators.validateUsername,
                      enabled: !authVm.isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Email Input
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'nama@email.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                      enabled: !authVm.isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Minimal 8 karakter',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: Validators.validatePassword,
                      enabled: !authVm.isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Input
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Konfirmasi Password',
                      hint: 'Ulangi password di atas',
                      prefixIcon: Icons.lock_reset_rounded,
                      isPassword: true,
                      validator: (val) => Validators.validateConfirmPassword(
                        val,
                        _passwordController.text,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitRegister(),
                      enabled: !authVm.isLoading,
                    ),
                    const SizedBox(height: 28),

                    // Submit Register
                    CustomButton(
                      text: 'Daftar & Kirim OTP',
                      onPressed: _submitRegister,
                      isLoading: authVm.isLoading,
                    ),
                    const SizedBox(height: 20),

                    // Back to Login Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Sudah memiliki akun? ',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: authVm.isLoading ? null : () => Navigator.of(context).pop(),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.tealPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
