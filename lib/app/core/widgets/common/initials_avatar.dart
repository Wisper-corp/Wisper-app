import 'package:flutter/material.dart';

/// Displays a circular avatar with:
/// - Network image if [imageUrl] is non-empty
/// - Initials (first + last letter of each word) on a consistent color background otherwise
class InitialsAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;
  final double fontSize;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
    this.fontSize = 14,
  });

  /// Generate consistent color from name
  static Color _colorFromName(String name) {
    const colors = [
      Color(0xff1877F2), // blue
      Color(0xff11AE46), // green
      Color(0xff9B59B6), // purple
      Color(0xffE74C3C), // red
      Color(0xffF39C12), // orange
      Color(0xff1ABC9C), // teal
      Color(0xff2ECC71), // emerald
      Color(0xff3498DB), // sky blue
      Color(0xffE67E22), // carrot
      Color(0xff8E44AD), // wisteria
    ];
    if (name.isEmpty) return colors[0];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  /// Extract up to 2 initials from a name
  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: Colors.grey.shade800,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _colorFromName(name),
      child: Text(
        _initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
