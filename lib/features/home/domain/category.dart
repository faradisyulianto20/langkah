import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

/// Kategori dari tabel `categories`.
@immutable
class Category {
  final String id;
  final String userId;
  final String name;
  final String colorHex;
  final String? icon;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    this.colorHex = '#00897B',
    this.icon,
  });

  /// Warna dari [colorHex]; fallback teal bila format tidak valid.
  Color get color {
    final hex = colorHex.replaceAll('#', '');
    final value = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return Color(value ?? 0xFF00897B);
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? colorHex,
    String? icon,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
    );
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      colorHex: map['color_hex'] as String? ?? '#00897B',
      icon: map['icon'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color_hex': colorHex,
      'icon': icon,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          colorHex == other.colorHex &&
          icon == other.icon;

  @override
  int get hashCode => Object.hash(id, userId, name, colorHex, icon);
}
