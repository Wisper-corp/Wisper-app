import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
 
class CircleIconWidget extends StatelessWidget {
  final String imagePath;
  final double radius; 
  final double iconRadius;
  final Color color;
  final VoidCallback onTap;
  final Color? iconColor;
  const CircleIconWidget({
    super.key,
    required this.imagePath,
    this.radius = 17,
    this.color = LightThemeColors.circleIconColor,
    required this.onTap,
    this.iconRadius = 12.5,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: color,
        radius: radius,
        child: Image.asset(
          imagePath,
          height: iconRadius,
          width: iconRadius,
          color: iconColor,
        ),
      ),
    );
  }
}

class CircleIconProfileWidget extends StatelessWidget {
  final String imagePath;
  final double radius;
  final double iconRadius;
  final Color color;
  final VoidCallback onTap;
  final Color? iconColor;

  const CircleIconProfileWidget({
    super.key,
    required this.imagePath,
    this.radius = 17,
    this.color = LightThemeColors.circleIconColor,
    required this.onTap,
    this.iconRadius = 12.5,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's a local file (from gallery/camera)
    final bool isFileImage =
        imagePath.startsWith('/') ||
        imagePath.contains('/storage/') ||
        imagePath.contains('/data/');

    // Check if it's a network image
    final bool isNetworkImage =
        imagePath.startsWith('http') || imagePath.startsWith('https');

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: color,
        radius: radius,
        child: ClipOval(
          child: isFileImage
              ? Image.file(
                  File(imagePath),
                  width: iconRadius * 2,
                  height: iconRadius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    size: 10,
                    color: iconColor ?? Colors.white70,
                  ),
                )
              : isNetworkImage
              ? Image.network(
                  imagePath,
                  height: iconRadius * 2,
                  width: iconRadius * 2,
                  fit: BoxFit.cover,
                  color: iconColor,
                )
              : Image.asset(
                  // Asset image
                  imagePath,
                  height: iconRadius * 2,
                  width: iconRadius * 2,
                  fit: BoxFit.cover,
                  color: iconColor,
                ),
        ),
      ),
    );
  }
}
