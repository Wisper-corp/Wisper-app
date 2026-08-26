import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays an avatar with:
/// - Network image via CachedNetworkImage (handles S3, Google, etc.)
/// - Initials on a consistent color background as fallback
///
/// Circular by default. Pass [cornerRadius] for the rounded-square shape used
/// by community covers, so a community reads as a place rather than a person.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;
  final double fontSize;

  /// Null renders a circle. A value renders a rounded square of the same
  /// diameter, so callers can swap the shape without touching the layout.
  final double? cornerRadius;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
    this.fontSize = 14,
    this.cornerRadius,
  });

  double get _diameter => radius * 2;

  BorderRadius? get _shape =>
      cornerRadius == null ? null : BorderRadius.circular(cornerRadius!);

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
    final label = Text(
      _initials(name),
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );

    if (_shape == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _colorFromName(name),
        child: label,
      );
    }

    return Container(
      width: _diameter,
      height: _diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _colorFromName(name),
        borderRadius: _shape,
      ),
      child: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (!hasImage) return _initialsCircle();

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => _shape == null
          ? CircleAvatar(radius: radius, backgroundImage: imageProvider)
          : Container(
              width: _diameter,
              height: _diameter,
              decoration: BoxDecoration(
                borderRadius: _shape,
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
      placeholder: (context, url) => _initialsCircle(),
      errorWidget: (context, url, error) => _initialsCircle(),
      width: _diameter,
      height: _diameter,
    );
  }
}
