/// Validasi tipe foto profil yang boleh diunggah.
class AvatarImage {
  AvatarImage._();

  /// Batas ukuran foto (setelah dikompres picker): 5 MB.
  static const int maxBytes = 5 * 1024 * 1024;

  static const _byMime = {
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  static const _byExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// Menentukan (contentType, ekstensi) dari [mimeType] atau, bila kosong,
  /// dari akhiran [fileName]. null bila format tidak didukung.
  static ({String contentType, String extension})? resolve({
    String? mimeType,
    required String fileName,
  }) {
    final mime = mimeType?.toLowerCase();
    if (mime != null && _byMime.containsKey(mime)) {
      final ext = _byMime[mime]!;
      return (contentType: _byExtension[ext]!, extension: ext);
    }
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return null;
    final ext = fileName.substring(dot + 1).toLowerCase();
    final contentType = _byExtension[ext];
    if (contentType == null) return null;
    return (contentType: contentType, extension: ext == 'jpeg' ? 'jpg' : ext);
  }
}
