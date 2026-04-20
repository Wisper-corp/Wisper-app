import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/gen/assets.gen.dart';

class CommunitiesListTile extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isGroup;
  final String imagePath;
  final String name;
  final String message;
  final String time;
  final bool isOnline;
  final int memberCount;
  final List<String> membersImage;

  const CommunitiesListTile({
    super.key,
    this.onTap,
    this.isGroup = true,
    required this.imagePath,
    required this.name,
    required this.message,

    required this.time,

    required this.isOnline,
    required this.memberCount,
    required this.membersImage,
  });

  bool _isValidImagePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return false;
    final lowered = trimmed.toLowerCase();
    return lowered != 'null' && lowered != 'undefined';
  }

  bool _isAssetPath(String path) {
    final trimmed = path.trim();
    return trimmed.startsWith('assets/') || trimmed.startsWith('packages/');
  }

  String _initialsFromName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _isValidImagePath(imagePath);
    final bool isAsset = _isAssetPath(imagePath);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              Stack(
                children: [
                  // মেইন প্রোফাইল পিকচার / আইকন
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: isGroup
                        ? const Color(0xff051B33)
                        : Colors.grey.shade800,
                    child: isGroup && !hasImage
                        ? CrashSafeImage(
                            Assets.images.userGroup.keyName,
                            color: const Color(0xff1F7DE9),
                            height: 26.h,
                          )
                        : isGroup && hasImage
                        ? CircleAvatar(
                            radius: 25.r,
                            backgroundImage: isAsset
                                ? null
                                : NetworkImage(imagePath),
                            backgroundColor: Colors.transparent,
                            child: isAsset
                                ? CrashSafeImage(imagePath, height: 28.h)
                                : null,
                          )
                        : !hasImage
                        ? Text(
                            _initialsFromName(name),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : CircleAvatar(
                            radius: 25.r,
                            backgroundImage: isAsset
                                ? null
                                : NetworkImage(imagePath),
                            backgroundColor: Colors.transparent,
                            child: isAsset
                                ? CrashSafeImage(imagePath, height: 28.h)
                                : null,
                          ),
                  ),

                  // শুধু Individual চ্যাটে এবং online থাকলে online dot দেখাবে
                  if (!isGroup && isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // const SizedBox(height: 4),
                    Text(
                      '$memberCount Members',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff98A2B3),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xff98A2B3),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color.fromARGB(255, 207, 208, 209),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(height: 0.5, color: Colors.grey.withOpacity(0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
