import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/gen/assets.gen.dart';

class MemberListTile extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isGroup;
  final bool isClass;
  final String imagePath;
  final String name;
  final String message;
  final String time;
  final String unreadMessageCount;
  final bool isOnline;

  const MemberListTile({
    super.key,
    this.onTap,
    required this.isGroup,
    required this.imagePath,
    required this.name,
    required this.message,
    required this.time,
    required this.unreadMessageCount,
    required this.isClass,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final int unreadCount = int.tryParse(unreadMessageCount) ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Stack(
                children: [
                  // মেইন প্রোফাইল পিকচার / আইকন
                  CircleAvatar(
                    radius: 25.r,
                    backgroundColor: isGroup
                        ? const Color(0xff051B33)
                        : isClass
                        ? const Color(0xff102B19)
                        : Colors.grey.shade800,
                    child: isGroup && imagePath.isEmpty
                        ? CrashSafeImage(
                            Assets.images.userGroup.keyName,
                            color: const Color(0xff1F7DE9),
                            height: 26.h,
                          )
                        : isGroup && imagePath.isNotEmpty
                        ? CircleAvatar(
                            radius: 25.r,
                            backgroundImage: NetworkImage(imagePath),
                            backgroundColor: Colors.transparent,
                          )
                        : isClass && imagePath.isEmpty
                        ? CrashSafeImage(
                            Assets.images.education.keyName,
                            color: const Color(0xff11AE46),
                            height: 22.h,
                          )
                        : CircleAvatar(
                            radius: 25.r,
                            backgroundImage: NetworkImage(imagePath),
                            backgroundColor: Colors.transparent,
                          ),
                  ),

                  // শুধু Individual চ্যাটে এবং online থাকলে online dot দেখাবে
                  if (!isGroup && !isClass && isOnline)
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
                        Row(
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
                            widthBox5,
                            isGroup
                                ? Tag(
                                    text: 'Group',
                                    color: Color(0xff051B33),
                                    textColor: Color(0xff1F7DE9),
                                  )
                                : isClass
                                ? Tag(
                                    text: 'Class',
                                    color: Color(0xff102B19),
                                    textColor: Color(0xff11AE46),
                                  )
                                : Container(),
                          ],
                        ),
                        if (unreadCount > 0)
                          CircleAvatar(
                            radius: 10.r,
                            backgroundColor: Colors.blue,
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color.fromARGB(255, 207, 208, 209),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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

class Tag extends StatelessWidget {
  final Color? color;
  final Color? textColor;
  final String? text;
  const Tag({super.key, this.color, this.textColor, this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.green,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        child: Text(
          text ?? 'Group',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w400,
            color: textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
