import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/core/utils/validators.dart';
import 'package:langkah/core/widgets/custom_button.dart';
import 'package:langkah/features/auth/presentation/auth_view_model.dart';
import 'package:langkah/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final OtpType otpType;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.otpType,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.verifyOtp(
      email: widget.email,
      token: _otpController.text.trim(),
      type: widget.otpType,
    );

    if (!mounted) return;

    if (success) {
      if (widget.otpType == OtpType.recovery) {
        UIFeedback.showSuccess(context, 'Kode OTP valid!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen(),
          ),
        );
      } else {
        UIFeedback.showSuccess(context, 'Akun berhasil diverifikasi! Selamat datang di Langkah.');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else if (authVm.errorMessage != null) {
      UIFeedback.showError(context, authVm.errorMessage!);
    }
  }

  Future<void> _resendOtp() async {
    final authVm = context.read<AuthViewModel>();
    bool success;

    if (widget.otpType == OtpType.recovery) {
      success = await authVm.sendPasswordResetOtp(email: widget.email);
    } else {
      // Re-trigger signup email OTP
      try {
        await Supabase.instance.client.auth.resend(
          type: OtpType.signup,
          email: widget.email,
        );
        success = true;
      } catch (e) {
        success = false;
        if (mounted) UIFeedback.showError(context, e.toString());
        return;
      }
    }

    if (!mounted) return;
    if (success) {
      UIFeedback.showSuccess(context, 'Kode OTP baru telah dikirimkan ke ${widget.email}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final isRecovery = widget.otpType == OtpType.recovery;

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        Icons.mark_email_read_outlined,
                        size: 30,
                        color: AppColors.tealPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isRecovery ? 'Verifikasi Reset Password' : 'Verifikasi Email Anda',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Masukkan 6 digit kode OTP yang kami kirimkan ke '),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const TextSpan(text: '. Periksa juga folder Spam/Junk Anda.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // OTP Input
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                        color: AppColors.tealPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '000000',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
                        ),
                      ),
                      validator: Validators.validateOtp,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitOtp(),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    CustomButton(
                      text: 'Verifikasi Kode',
                      onPressed: _submitOtp,
                      isLoading: authVm.isLoading,
                    ),
                    const SizedBox(height: 20),

                    // Resend Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Tidak menerima kode? ',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: authVm.isLoading ? null : _resendOtp,
                          child: const Text(
                            'Kirim Ulang',
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
