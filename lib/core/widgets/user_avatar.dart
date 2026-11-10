import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';

/// Avatar bulat: foto profil bila ada, jika tidak inisial nama.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 18,
  });

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts.elementAt(1)[0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = initialsOf(name);
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.tealPrimary.withValues(alpha: 0.15),
      child: initials.isEmpty
          ? Icon(
              Icons.person_rounded,
              size: radius,
              color: AppColors.tealPrimary,
            )
          : Text(
              initials,
              style: TextStyle(
                color: AppColors.tealPrimary,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            ),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;

    return CircleAvatar(
      radius: radius,
      backgroundColor: context.trackColor,
      child: ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}
