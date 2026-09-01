import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/gen/assets.gen.dart';

class MemberListTile extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isGroup;
  final bool isClass;
  final String imagePath;
  final String name;
  final String message;

  /// Shown before the message when it stands for a file rather than words.
  /// Null for an ordinary text message.
  final IconData? messageIcon;
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
    this.messageIcon,
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
      // Nothing below the separator: it is the last thing this tile draws, so
      // the swipe buttons revealed behind the row end level with it rather
      // than running on past into the gap under it.
      // The 12 that used to sit under the line lives up here instead, so the
      // distance from one row's line to the next row's picture is what it
      // always was. 4 + 12.
      padding: const EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
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
                            ? InitialsAvatar(
                                name: name,
                                imageUrl: imagePath.startsWith('http')
                                    ? imagePath
                                    : null,
                                radius: 25.r,
                                fontSize: 16,
                              )
                            : isClass
                            ? InitialsAvatar(
                                name: name,
                                imageUrl: imagePath.startsWith('http')
                                    ? imagePath
                                    : null,
                                radius: 25.r,
                                fontSize: 16,
                              )
                            : InitialsAvatar(
                                name: name,
                                imageUrl: imagePath.startsWith('http')
                                    ? imagePath
                                    : null,
                                radius: 25.r,
                                fontSize: 16,
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
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
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
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  widthBox5,
                                  isGroup
                                      ? Tag(
                                          text: 'Community',
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
                            ),
                            // The time belongs beside the name, not alone on a
                            // line of its own -- a community with no messages yet
                            // has nothing else to put on the second row.
                            if (time.isNotEmpty) ...[
                              SizedBox(width: 8.w),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: const Color.fromARGB(
                                    255,
                                    207,
                                    208,
                                    209,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Nothing to say and nothing unread: no empty second line.
                        if (message.isNotEmpty || unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (messageIcon != null) ...[
                                      Icon(
                                        messageIcon,
                                        size: 14.sp,
                                        color: const Color(0xff98A2B3),
                                      ),
                                      SizedBox(width: 5.w),
                                    ],
                                    Flexible(
                                      child: Text(
                                        message,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                          color: message.contains('🧾')
                                              ? const Color(0xff2799EA)
                                              : const Color(0xff98A2B3),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                SizedBox(width: 8.w),
                                CircleAvatar(
                                  radius: 10.r,
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : unreadCount.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        // Members row for groups/classes
                        if ((isGroup || isClass) && memberCount != null) ...[
                          const SizedBox(height: 6),
                          _buildMembersRow(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Just clear of the picture, where this line has always sat.
            const SizedBox(height: 3),
            // Indented to line up with the text, not the picture: avatar (50) plus
            // the 12 beside it plus the row's own 8 of padding.
            Padding(
              padding: const EdgeInsets.only(left: 70, right: 8),
              child: Container(
                height: 0.5,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMemberCount(int count) {
    if (count >= 1000000)
      return '${(count / 1000000).toStringAsFixed(1)}M members';
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
          text ?? 'Community',
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
