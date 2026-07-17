import 'package:flutter/material.dart';

/// Displays a circular avatar with:
/// - Network image if [imageUrl] is non-empty (with error fallback to initials)
/// - Initials on a consistent color background otherwise
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

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (!hasImage) {
      return _InitialsCircle(name: name, radius: radius, fontSize: fontSize);
    }

    return _NetworkImageAvatar(
      imageUrl: imageUrl!,
      name: name,
      radius: radius,
      fontSize: fontSize,
    );
  }
}

/// Stateful widget so we can swap between image and initials on error
class _NetworkImageAvatar extends StatefulWidget {
  final String imageUrl;
  final String name;
  final double radius;
  final double fontSize;

  const _NetworkImageAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
    required this.fontSize,
  });

  @override
  State<_NetworkImageAvatar> createState() => _NetworkImageAvatarState();
}

class _NetworkImageAvatarState extends State<_NetworkImageAvatar> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _InitialsCircle(
        name: widget.name,
        radius: widget.radius,
        fontSize: widget.fontSize,
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.grey.shade800,
      child: ClipOval(
        child: Image.network(
          widget.imageUrl,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            // Switch to initials on next frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _hasError = true);
            });
            return _InitialsCircle(
              name: widget.name,
              radius: widget.radius,
              fontSize: widget.fontSize,
            );
          },
        ),
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  final String name;
  final double radius;
  final double fontSize;

  const _InitialsCircle({
    required this.name,
    required this.radius,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: InitialsAvatar._colorFromName(name),
      child: Text(
        InitialsAvatar._initials(name),
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
