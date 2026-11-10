import 'package:flutter/foundation.dart';
import 'package:langkah/features/settings/data/profile_repository.dart';
import 'package:langkah/features/settings/domain/profile_model.dart';
import 'package:langkah/features/settings/domain/streak_data.dart';

enum SettingsStatus { initial, loading, success, failure }

class SettingsViewModel extends ChangeNotifier {
  final ProfileRepository repository;

  SettingsViewModel({required this.repository});

  SettingsStatus _status = SettingsStatus.initial;
  SettingsStatus _updateStatus = SettingsStatus.initial;
  SettingsStatus _avatarStatus = SettingsStatus.initial;
  ProfileModel? _profile;
  StreakData? _stats;
  String? _errorMessage;
  String? _successMessage;

  SettingsStatus get status => _status;
  SettingsStatus get updateStatus => _updateStatus;
  ProfileModel? get profile => _profile;
  StreakData? get stats => _stats;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _status == SettingsStatus.loading;
  bool get isUpdating => _updateStatus == SettingsStatus.loading;
  bool get isUploadingAvatar => _avatarStatus == SettingsStatus.loading;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Load profil dan stats user secara bersamaan.
  Future<void> loadProfileAndStats(String userId) async {
    _status = SettingsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.getProfile(userId),
        repository.getStats(userId),
      ]);

      _profile = results[0] as ProfileModel;
      _stats = results[1] as StreakData;
      _status = SettingsStatus.success;
    } catch (e) {
      _status = SettingsStatus.failure;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  /// Unggah foto profil dari galeri dan perbarui profil di layar.
  Future<bool> uploadAvatar(
    Uint8List bytes, {
    required String contentType,
    required String extension,
  }) async {
    final current = _profile;
    if (current == null) return false;

    _avatarStatus = SettingsStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final url = await repository.uploadAvatar(
        current.id,
        bytes,
        contentType: contentType,
        extension: extension,
      );
      _profile = current.copyWith(avatarUrl: url);
      _avatarStatus = SettingsStatus.success;
      _successMessage = 'Foto profil diperbarui!';
      notifyListeners();
      return true;
    } catch (e) {
      _avatarStatus = SettingsStatus.failure;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Update profil user (username & fullName).
  Future<bool> updateProfile({
    required String username,
    required String fullName,
  }) async {
    if (_profile == null) return false;

    _updateStatus = SettingsStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = _profile!.copyWith(
        username: username.trim(),
        fullName: fullName.trim(),
      );
      await repository.updateProfile(updated);
      _profile = updated;
      _updateStatus = SettingsStatus.success;
      _successMessage = 'Profil berhasil diperbarui!';
      notifyListeners();
      return true;
    } catch (e) {
      _updateStatus = SettingsStatus.failure;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
