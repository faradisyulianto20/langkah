import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/core/utils/validators.dart';
import 'package:langkah/core/widgets/custom_button.dart';
import 'package:langkah/core/widgets/custom_text_field.dart';
import 'package:langkah/features/auth/presentation/auth_view_model.dart';
import 'package:provider/provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.resetPassword(
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      UIFeedback.showSuccess(context, 'Password berhasil diubah. Silakan masuk kembali.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (authVm.errorMessage != null) {
      UIFeedback.showError(context, authVm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.tealPrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 30,
                        color: AppColors.tealPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Buat Password Baru',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan masukkan password baru yang kuat untuk mengamankan akun Langkah Anda.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password Baru',
                      hint: 'Minimal 8 karakter',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: Validators.validatePassword,
                      enabled: !authVm.isLoading,
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Konfirmasi Password Baru',
                      hint: 'Ulangi password baru',
                      prefixIcon: Icons.lock_reset,
                      isPassword: true,
                      validator: (val) => Validators.validateConfirmPassword(
                        val,
                        _passwordController.text,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitResetPassword(),
                      enabled: !authVm.isLoading,
                    ),
                    const SizedBox(height: 28),
                    CustomButton(
                      text: 'Simpan Password Baru',
                      onPressed: _submitResetPassword,
                      isLoading: authVm.isLoading,
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
