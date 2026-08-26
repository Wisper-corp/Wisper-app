import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ForumPostAction { replyPrivately, toggleFollow, delete }

/// The post's overflow menu. Actions are ordered by how often they are wanted
/// and how hard they are to undo, so the destructive one sits last and apart.
Future<ForumPostAction?> showForumPostMenu(
  BuildContext context, {
  required bool isFollowing,
  required bool canDelete,
  required bool isMine,
  required String authorName,
}) {
  return showModalBottomSheet<ForumPostAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: const Color(0xff121417),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xff3A4048),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 14.h),
            // Replying privately to yourself is meaningless, so it is only
            // offered on someone else's post.
            if (!isMine)
              _Item(
                icon: Icons.mail_outline_rounded,
                label: 'Reply privately',
                detail: 'Message $authorName instead of the whole community',
                onTap: () => Navigator.of(sheetContext)
                    .pop(ForumPostAction.replyPrivately),
              ),
            _Item(
              icon: isFollowing
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_rounded,
              label: isFollowing ? 'Stop notifying me' : 'Notify me of replies',
              detail: isFollowing
                  ? 'You currently get a notification for every new reply'
                  : 'Get a notification when someone replies',
              onTap: () =>
                  Navigator.of(sheetContext).pop(ForumPostAction.toggleFollow),
            ),
            if (canDelete) ...[
              Divider(
                height: 20.h,
                thickness: 0.5,
                color: const Color(0xff2A2F35),
                indent: 20.w,
                endIndent: 20.w,
              ),
              _Item(
                icon: Icons.delete_outline_rounded,
                label: 'Delete post',
                detail: isMine
                    ? 'Removes it for everyone'
                    : 'Removes it for everyone, as a moderator',
                destructive: true,
                onTap: () =>
                    Navigator.of(sheetContext).pop(ForumPostAction.delete),
              ),
            ],
            SizedBox(height: 8.h),
          ],
        ),
      ),
    ),
  );
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final bool destructive;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? const Color(0xffE5484D) : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 13.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21.sp, color: tint),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: tint,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      height: 1.35,
                      color: const Color(0xff8B949E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
