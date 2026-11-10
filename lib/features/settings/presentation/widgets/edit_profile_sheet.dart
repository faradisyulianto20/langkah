import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/utils/ui_feedback.dart';
import 'package:langkah/core/utils/validators.dart';
import 'package:langkah/core/widgets/custom_button.dart';
import 'package:langkah/core/widgets/custom_text_field.dart';
import 'package:langkah/features/settings/presentation/settings_view_model.dart';
import 'package:provider/provider.dart';

/// Bottom sheet untuk edit profil (username & full name).
class EditProfileSheet extends StatefulWidget {
  final String initialUsername;
  final String initialFullName;

  const EditProfileSheet({
    super.key,
    required this.initialUsername,
    required this.initialFullName,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _fullNameCtrl;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.initialUsername);
    _fullNameCtrl = TextEditingController(text: widget.initialFullName);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<SettingsViewModel>();
    final success = await vm.updateProfile(
      username: _usernameCtrl.text,
      fullName: _fullNameCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      UIFeedback.showSuccess(context, vm.successMessage ?? 'Profil diperbarui!');
      Navigator.of(context).pop();
    } else {
      UIFeedback.showError(context, vm.errorMessage ?? 'Gagal memperbarui profil.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Edit Profil',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _fullNameCtrl,
              label: 'Nama Lengkap',
              hint: 'Contoh: Budi Santoso',
              prefixIcon: Icons.person_outline_rounded,
              validator: Validators.validateUsername,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _usernameCtrl,
              label: 'Username',
              hint: 'Contoh: budi_santoso',
              prefixIcon: Icons.alternate_email_rounded,
              validator: Validators.validateUsername,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Simpan Perubahan',
              onPressed: _submit,
              isLoading: vm.isUpdating,
            ),
          ],
        ),
      ),
    );
  }
}
