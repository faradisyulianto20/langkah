import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/core/utils/validators.dart';
import 'package:langkah/core/widgets/custom_button.dart';
import 'package:langkah/core/widgets/custom_text_field.dart';
import 'package:langkah/features/auth/presentation/auth_view_model.dart';
import 'package:langkah/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:langkah/features/auth/presentation/screens/register_screen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success && authVm.errorMessage != null) {
      UIFeedback.showError(context, authVm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.tealPrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        size: 36,
                        color: AppColors.tealPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Selamat Datang di Langkah',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kelola aksi harian dan target pengembangan diri Anda secara konsisten.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

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
                    const SizedBox(height: 18),

                    // Password Input
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Minimal 8 karakter',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: Validators.validatePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitLogin(),
                      enabled: !authVm.isLoading,
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: authVm.isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.tealPrimary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Lupa password?',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    CustomButton(
                      text: 'Masuk',
                      onPressed: _submitLogin,
                      isLoading: authVm.isLoading,
                    ),
                    const SizedBox(height: 24),

                    // Register Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Belum memiliki akun? ',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: authVm.isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Daftar Sekarang',
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
