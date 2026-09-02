import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What a long press on a message offers.
enum MessageAction { reply, forward, copy, delete }

/// The long-press menu on a chat message.
///
/// A floating card next to the message rather than a sheet from the bottom of
/// the screen: the actions belong to the message you are touching, so they
/// appear beside it and the message stays in view.
///
/// [canDelete] is false on someone else's message — the server only lets you
/// delete your own, and offering a row that always fails is worse than not
/// offering it. [canCopy] is false when there are no words to copy.
Future<MessageAction?> showMessageActionMenu(
  BuildContext context, {
  required Offset at,
  required bool canDelete,
  required bool canCopy,
}) {
  final media = MediaQuery.of(context);
  const width = 210.0;

  // Rows are only added when they apply, so the card's height follows.
  final rows = <_Row>[
    const _Row(MessageAction.reply, Icons.reply_rounded, 'Reply'),
    const _Row(MessageAction.forward, Icons.shortcut_rounded, 'Forward'),
    if (canCopy) const _Row(MessageAction.copy, Icons.copy_rounded, 'Copy'),
    if (canDelete)
      const _Row(MessageAction.delete, Icons.delete_outline_rounded, 'Delete',
          destructive: true),
  ];

  final rowHeight = 48.h;
  // The divider above Delete, when there is one.
  final height = rows.length * rowHeight + (canDelete ? 9.h : 0) + 12.h;

  // Kept on screen: pushed left if it would run off the right edge, and up if
  // it would run off the bottom.
  final left = (at.dx).clamp(8.0, media.size.width - width - 8.0);
  final top = (at.dy).clamp(
    media.padding.top + 8.0,
    media.size.height - height - media.padding.bottom - 8.0,
  );

  return showGeneralDialog<MessageAction>(
    context: context,
    barrierLabel: 'Message actions',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 130),
    pageBuilder: (dialogContext, _, __) => Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: const Color(0xff2A2C31),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in rows) ...[
                    // Destructive last, and set apart, so it is not the one
                    // hit by accident.
                    if (row.destructive)
                      Divider(
                        height: 9.h,
                        thickness: 0.5,
                        color: const Color(0xff3A3D43),
                        indent: 16.w,
                        endIndent: 16.w,
                      ),
                    _MenuRow(
                      row: row,
                      height: rowHeight,
                      onTap: () =>
                          Navigator.of(dialogContext).pop(row.action),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        alignment: Alignment.topLeft,
        scale: Tween<double>(begin: 0.92, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    ),
  );
}

class _Row {
  const _Row(this.action, this.icon, this.label, {this.destructive = false});

  final MessageAction action;
  final IconData icon;
  final String label;
  final bool destructive;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.row,
    required this.height,
    required this.onTap,
  });

  final _Row row;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = row.destructive ? const Color(0xffE5484D) : Colors.white;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(row.icon, size: 21.sp, color: tint, semanticLabel: row.label),
              SizedBox(width: 16.w),
              Text(
                row.label,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: tint,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
