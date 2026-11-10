import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/network/supabase_config.dart';
import 'package:langkah/core/utils/ui_feedback.dart';

import 'package:langkah/features/auth/presentation/auth_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:langkah/features/settings/data/profile_repository_impl.dart';
import 'package:langkah/features/settings/domain/avatar_image.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';
import 'package:langkah/features/settings/presentation/settings_view_model.dart';
import 'package:langkah/features/settings/presentation/widgets/edit_profile_sheet.dart';
import 'package:langkah/features/settings/presentation/widgets/profile_header.dart';
import 'package:langkah/features/settings/presentation/widgets/stats_card.dart';
import 'package:langkah/features/settings/presentation/widgets/theme_toggle_tile.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  /// Dipicu setiap kali tab Settings dibuka kembali agar data tersinkron.
  final Listenable? refreshSignal;

  const SettingsScreen({super.key, this.refreshSignal});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(repository: ProfileRepositoryImpl()),
      child: _SettingsBody(refreshSignal: refreshSignal),
    );
  }
}

class _SettingsBody extends StatefulWidget {
  final Listenable? refreshSignal;

  const _SettingsBody({this.refreshSignal});

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_loadData);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!SupabaseConfig.isInitialized) return;
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !mounted) return;
    context.read<SettingsViewModel>().loadProfileAndStats(userId);
  }

  /// Pilih foto dari galeri, validasi, lalu unggah sebagai foto profil.
  Future<void> _changePhoto(SettingsViewModel vm) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final type = AvatarImage.resolve(
        mimeType: picked.mimeType,
        fileName: picked.name,
      );
      if (type == null) {
        UIFeedback.showError(
          context,
          'Format foto tidak didukung. Gunakan JPG, PNG, atau WebP.',
        );
        return;
      }
      final bytes = await picked.readAsBytes();
      if (bytes.length > AvatarImage.maxBytes) {
        if (mounted) UIFeedback.showError(context, 'Ukuran foto maksimal 5 MB.');
        return;
      }

      final ok = await vm.uploadAvatar(
        bytes,
        contentType: type.contentType,
        extension: type.extension,
      );
      if (!mounted) return;
      if (ok) {
        UIFeedback.showSuccess(
          context,
          vm.successMessage ?? 'Foto profil diperbarui!',
        );
      } else {
        UIFeedback.showError(
          context,
          vm.errorMessage ?? 'Gagal mengunggah foto.',
        );
      }
    } catch (_) {
      if (mounted) {
        UIFeedback.showError(context, 'Tidak dapat membuka galeri.');
      }
    }
  }

  Future<void> _openEditSheet(
    BuildContext context,
    SettingsViewModel vm,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: EditProfileSheet(
          initialUsername: vm.profile?.username ?? '',
          initialFullName: vm.profile?.fullName ?? '',
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthViewModel>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final user = SupabaseConfig.isInitialized
        ? SupabaseConfig.client.auth.currentUser
        : null;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (vm.status == SettingsStatus.success && vm.profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profil',
              onPressed: () => _openEditSheet(context, vm),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.tealPrimary,
        onRefresh: () async {
          if (user != null) {
            await vm.loadProfileAndStats(user.id);
          }
        },
        child: _buildBody(context, vm, email),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SettingsViewModel vm, String email) {
    switch (vm.status) {
      case SettingsStatus.loading:
      case SettingsStatus.initial:
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealPrimary),
          ),
        );

      case SettingsStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  vm.errorMessage ?? 'Gagal memuat data.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
        );

      case SettingsStatus.success:
        return _buildContent(context, vm, email);
    }
  }

  Widget _buildContent(
    BuildContext context,
    SettingsViewModel vm,
    String email,
  ) {
    final profile = vm.profile!;
    final stats = vm.stats ?? StreakData.empty(profile.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile header
        ProfileHeader(
          profile: profile,
          email: email,
          onChangePhoto: () => _changePhoto(vm),
          isUploading: vm.isUploadingAvatar,
        ),
        const SizedBox(height: 8),

        // Edit profile shortcut
        TextButton.icon(
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit Profil'),
          style: TextButton.styleFrom(foregroundColor: AppColors.tealPrimary),
          onPressed: () => _openEditSheet(context, vm),
        ),
        const SizedBox(height: 8),

        // Stats card
        StatsCard(stats: stats),
        const SizedBox(height: 12),

        // Theme toggle
        const ThemeToggleTile(),
        const SizedBox(height: 16),

        // Akun section
        const _SectionLabel(label: 'Akun'),
        const SizedBox(height: 8),

        // Email info (read-only)
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.email_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text('Email'),
            subtitle: Text(email),
            trailing: const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // App version
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
            ),
            title: const Text('Versi Aplikasi'),
            subtitle: const Text('1.0.0'),
          ),
        ),
        const SizedBox(height: 20),

        // Logout button
        OutlinedButton.icon(
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          label: const Text(
            'Keluar dari Akun',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _confirmLogout(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
