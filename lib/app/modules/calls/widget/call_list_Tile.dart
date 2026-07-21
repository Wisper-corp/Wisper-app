import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';

class CallListTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String time;
  final String callType;   // OUTGOING | INCOMING | MISSED
  final String callMode;   // VIDEO | AUDIO
  final String duration;   // e.g. "2:05" or ""

  const CallListTile({
    super.key,
    required this.name,
    this.imageUrl,
    required this.time,
    required this.callType,
    required this.callMode,
    this.duration = '',
  });

  Color get _callTypeColor {
    switch (callType.toUpperCase()) {
      case 'MISSED':
        return Colors.red;
      case 'INCOMING':
        return Colors.green;
      default:
        return LightThemeColors.themeGreyColor;
    }
  }

  String get _callTypeLabel {
    switch (callType.toUpperCase()) {
      case 'MISSED':
        return 'Missed';
      case 'INCOMING':
        return 'Incoming';
      default:
        return 'Outgoing';
    }
  }

  IconData get _callModeIcon {
    return callMode.toUpperCase() == 'VIDEO'
        ? Icons.videocam_rounded
        : Icons.call_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InitialsAvatar(
                name: name,
                imageUrl: imageUrl,
                radius: 22.r,
                fontSize: 14,
              ),
              widthBox10,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Icon(
                        _callModeIcon,
                        size: 13.sp,
                        color: _callTypeColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _callTypeLabel,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: _callTypeColor,
                        ),
                      ),
                      if (duration.isNotEmpty) ...[
                        SizedBox(width: 4.w),
                        Text(
                          '· $duration',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: LightThemeColors.themeGreyColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: LightThemeColors.themeGreyColor,
                ),
              ),
              SizedBox(width: 12.w),
              Icon(
                Icons.info_outline,
                size: 16.sp,
                color: LightThemeColors.themeGreyColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
