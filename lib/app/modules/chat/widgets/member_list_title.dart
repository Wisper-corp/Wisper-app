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
  final int? memberCount;

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
    this.memberCount,
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
                    child: isGroup
                        ? Image.asset(
                            Assets.images.userGroup.keyName,
                            color: const Color(0xff1F7DE9),
                            height: 26.h,
                          )
                        : isClass
                        ? Image.asset(
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
                    // Members row for groups/classes
                    if ((isGroup || isClass) && memberCount != null) ...[
                      const SizedBox(height: 6),
                      _buildMembersRow(),
                    ],
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

  String _formatMemberCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M members';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K members';
    return '$count members';
  }

  Widget _buildMembersRow() {
    final List<Color> avatarColors = [
      const Color(0xff1F7DE9),
      const Color(0xff11AE46),
      const Color(0xff9B59B6),
    ];
    const double avatarSize = 18;
    const double overlap = 10;
    const int showCount = 3;

    return Row(
      children: [
        SizedBox(
          width: avatarSize + (showCount - 1) * (avatarSize - overlap),
          height: avatarSize,
          child: Stack(
            children: List.generate(showCount, (i) {
              return Positioned(
                left: i * (avatarSize - overlap).toDouble(),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarColors[i % avatarColors.length],
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _formatMemberCount(memberCount!),
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xff98A2B3),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
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
