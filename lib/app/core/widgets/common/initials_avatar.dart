import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays a circular avatar with:
/// - Network image via CachedNetworkImage (handles S3, Google, etc.)
/// - Initials on a consistent color background as fallback
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

  static Color _colorFromName(String name) {
    const colors = [
      Color(0xff1877F2),
      Color(0xff11AE46),
      Color(0xff9B59B6),
      Color(0xffE74C3C),
      Color(0xffF39C12),
      Color(0xff1ABC9C),
      Color(0xff2ECC71),
      Color(0xff3498DB),
      Color(0xffE67E22),
      Color(0xff8E44AD),
    ];
    if (name.isEmpty) return colors[0];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _initialsCircle() {
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

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (!hasImage) return _initialsCircle();

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => _initialsCircle(),
      errorWidget: (context, url, error) => _initialsCircle(),
      width: radius * 2,
      height: radius * 2,
    );
  }
}
