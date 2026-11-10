import 'package:flutter/foundation.dart';

/// Ide/tugas mentah dari tabel `backlog_items`.
@immutable
class BacklogItem {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final String? notes;
  final DateTime? createdAt;

  const BacklogItem({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    this.notes,
    this.createdAt,
  });

  BacklogItem copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? title,
    String? notes,
    DateTime? createdAt,
  }) {
    return BacklogItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BacklogItem.fromMap(Map<String, dynamic> map) {
    return BacklogItem(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      categoryId: map['category_id'] as String?,
      title: map['title'] as String? ?? '',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BacklogItem &&
          id == other.id &&
          userId == other.userId &&
          categoryId == other.categoryId &&
          title == other.title &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(id, userId, categoryId, title, notes);
}
