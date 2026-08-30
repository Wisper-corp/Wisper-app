import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/widgets/common/expandable_text.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/modules/forum/widget/author_tap.dart';
import 'package:wisper/app/modules/saved/widget/save_button.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_card.dart';

/// One reply, and the thread hanging off it.
///
/// A child reply is drawn against a vertical rule rather than simply indented:
/// the rule makes it obvious at a glance where a thread starts and ends, which
/// plain indentation stops doing after the first level.
///
/// Nesting is capped at one visible level. Deeper replies still exist and are
/// still counted; they open in their own thread rather than marching off the
/// right edge of a phone screen.
class ForumReplyTile extends StatelessWidget {
  final ForumReplyModel reply;
  final void Function(ForumReplyModel reply) onReply;
  final void Function(ForumReplyModel reply) onToggleReaction;
  final void Function(ForumReplyModel reply) onShowMore;
  final void Function(ForumReplyModel reply)? onMore;

  /// Child replies are drawn against the rule; top-level ones are not.
  final bool nested;

  const ForumReplyTile({
    super.key,
    required this.reply,
    required this.onReply,
    required this.onToggleReaction,
    required this.onShowMore,
    this.onMore,
    this.nested = false,
  });

  static const _rule = Color(0xff3A4048);
  static const _heart = Color(0xffE5484D);
  static const _pill = Color(0xff17191C);

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        SizedBox(height: 6.h),
        ExpandableText(
          reply.text,
          maxLines: 4,
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 15.sp,
            height: 1.4,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10.h),
        _actions(),
        // Children, and the way into the rest of the thread.
        for (final child in reply.replies) ...[
          SizedBox(height: 12.h),
          ForumReplyTile(
            reply: child,
            nested: true,
            onReply: onReply,
            onToggleReaction: onToggleReaction,
            onShowMore: onShowMore,
            onMore: onMore,
          ),
        ],
        if (reply.hasHiddenReplies) ...[
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () => onShowMore(reply),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Text(
                'Show more replies',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff8B949E),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (!nested) return body;

    // The rule is drawn as a left border rather than a sibling in an
    // IntrinsicHeight row: the body contains a LayoutBuilder, which cannot
    // take part in an intrinsic-height pass, and doing it that way throws.
    // A border stretches to whatever height the child ends up being.
    return Container(
      padding: EdgeInsets.only(left: 12.w),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _rule, width: 2)),
      ),
      child: body,
    );
  }

  Widget _header() {
    final author = reply.author;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Same as on a post: the face and the name go to the person.
        GestureDetector(
          onTap: () => openForumAuthor(author),
          behavior: HitTestBehavior.opaque,
          child: _avatar(author),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: GestureDetector(
            onTap: () => openForumAuthor(author),
            behavior: HitTestBehavior.opaque,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.name ?? 'User',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w700,
                  color: forumNameColor(author.id),
                ),
              ),
              if ((author.title ?? '').isNotEmpty)
                Text(
                  author.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: const Color(0xff98A2B3),
                  ),
                ),
            ],
          ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          forumShortAge(reply.createdAt),
          style: TextStyle(fontSize: 11.5.sp, color: const Color(0xff8B949E)),
        ),
        if (onMore != null)
          GestureDetector(
            onTap: () => onMore!(reply),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Icon(Icons.more_horiz,
                  size: 17.sp, color: const Color(0xff8B949E)),
            ),
          ),
      ],
    );
  }

  Widget _actions() {
    return Row(
      children: [
        _chip(
          onTap: () => onReply(reply),
          child: reply.replyCount > 0
              ? Text('${reply.replyCount} '
                  '${reply.replyCount == 1 ? 'Reply' : 'Replies'}',
                  style: _chipText())
              : Text('Reply', style: _chipText()),
        ),
        SizedBox(width: 10.w),
        _chip(
          onTap: () => onToggleReaction(reply),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                reply.hasReacted ? Icons.favorite : Icons.favorite_border,
                size: 15.sp,
                color: reply.hasReacted ? _heart : const Color(0xffC9D1D9),
              ),
              if (reply.reactionCount > 0) ...[
                SizedBox(width: 6.w),
                Text('${reply.reactionCount}', style: _chipText()),
              ],
            ],
          ),
        ),
        const Spacer(),
        // Keeping a reply, the same gesture as on a post.
        SaveButton(kind: 'reply', itemId: reply.id, size: 17.sp),
      ],
    );
  }

  TextStyle _chipText() => TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xffC9D1D9),
      );

  Widget _chip({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: _pill,
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: child,
      ),
    );
  }

  Widget _avatar(ForumAuthor author) {
    final image = author.image ?? '';
    if (image.isEmpty) {
      return InitialsAvatar(name: author.name ?? 'User', radius: 17.r);
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: image,
        width: 34.r,
        height: 34.r,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(color: Color(0xff1C1F23)),
        errorWidget: (_, __, ___) =>
            InitialsAvatar(name: author.name ?? 'User', radius: 17.r),
      ),
    );
  }
}
