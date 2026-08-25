import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/widgets/common/image_container_widget.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';

/// A stable colour per author, so the same person reads the same way down the
/// feed. Derived from their id rather than their position in the list, which
/// would shuffle as posts arrive.
Color forumNameColor(String? id) {
  const palette = [
    Color(0xffE5484D), // red
    Color(0xff30A46C), // green
    Color(0xff0091FF), // blue
    Color(0xffF76808), // orange
    Color(0xff8E4EC6), // purple
    Color(0xff00A2C7), // teal
  ];
  if (id == null || id.isEmpty) return Colors.white;
  var hash = 0;
  for (final unit in id.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}

/// Compact age for the corner of a card: "12m", "2h", "3d". The shared
/// DateFormatter spells it out ("12 minutes ago"), which is too wide here and
/// is relied on by other screens, so it is left alone.
String forumShortAge(DateTime? time) {
  if (time == null) return '';
  final d = DateTime.now().difference(time);
  if (d.inSeconds < 60) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  if (d.inDays < 365) return '${(d.inDays / 7).floor()}w';
  return '${(d.inDays / 365).floor()}y';
}

class ForumPostCard extends StatelessWidget {
  final ForumPostModel post;
  final VoidCallback onOpenReplies;
  final VoidCallback onToggleReaction;
  final VoidCallback? onMore;

  /// The replies screen shows the original post as a quiet header: no actions,
  /// because the counts sit in their own strip beneath it.
  final bool showActions;

  const ForumPostCard({
    super.key,
    required this.post,
    required this.onOpenReplies,
    required this.onToggleReaction,
    this.onMore,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final author = post.author;

    return Container(
      width: double.infinity,
      // Your own posts are called out in blue, the way a sent message is.
      color: post.isMine ? const Color(0xff1B4F8C) : Colors.transparent,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(author),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author.name ?? 'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: post.isMine
                            ? Colors.white
                            : forumNameColor(author.id),
                      ),
                    ),
                    if ((author.title ?? '').isNotEmpty)
                      Text(
                        author.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xff98A2B3),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                forumShortAge(post.createdAt),
                style: TextStyle(fontSize: 12.sp, color: const Color(0xff8B949E)),
              ),
              if (onMore != null)
                GestureDetector(
                  onTap: onMore,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Icon(Icons.more_horiz,
                        size: 18.sp, color: const Color(0xff8B949E)),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 2.w),
            child: Text(
              post.text,
              style: TextStyle(
                fontSize: 15.sp,
                height: 1.4,
                color: Colors.white,
              ),
            ),
          ),
          // Attached photos, using the same grid as the rest of the app so a
          // forum post and a service post lay their images out identically.
          if (post.images.isNotEmpty) ...[
            SizedBox(height: 10.h),
            ImageContainer(
              images: post.images,
              height: 200,
              width: double.infinity,
              borderRadius: 12,
            ),
          ],
          if (showActions) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                _pill(
                  onTap: onOpenReplies,
                  child: post.replyCount > 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _avatarStack(post.replyAvatars),
                            SizedBox(width: 8.w),
                            Text(
                                '${post.replyCount} '
                                '${post.replyCount == 1 ? 'reply' : 'replies'}',
                                style: _pillText()),
                          ],
                        )
                      : Text('Reply', style: _pillText()),
                ),
                SizedBox(width: 10.w),
                _pill(
                  onTap: onToggleReaction,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.hasReacted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16.sp,
                        color: post.hasReacted
                            ? const Color(0xffE5484D)
                            : const Color(0xffC9D1D9),
                      ),
                      if (post.reactionCount > 0) ...[
                        SizedBox(width: 6.w),
                        Text('${post.reactionCount}', style: _pillText()),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _pillText() => TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xffC9D1D9),
      );

  Widget _pill({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xff17191C),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: child,
      ),
    );
  }

  Widget _avatar(ForumAuthor author) {
    final image = author.image ?? '';
    if (image.isEmpty) {
      return InitialsAvatar(name: author.name ?? 'User', radius: 20.r);
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: image,
        width: 40.r,
        height: 40.r,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(color: Color(0xff1C1F23)),
        errorWidget: (_, __, ___) =>
            InitialsAvatar(name: author.name ?? 'User', radius: 20.r),
      ),
    );
  }

  Widget _avatarStack(List<ForumReplyAvatar> avatars) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    final shown = avatars.take(3).toList();
    return SizedBox(
      width: (14.r * shown.length) + 8.r,
      height: 22.r,
      child: Stack(
        children: List.generate(shown.length, (i) {
          final image = shown[i].image ?? '';
          return Positioned(
            left: i * 14.r,
            child: Container(
              width: 22.r,
              height: 22.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xff0D0D0D), width: 1.5),
                color: const Color(0xff2A2F35),
              ),
              child: image.isEmpty
                  ? Icon(Icons.person, size: 12.sp, color: Colors.white54)
                  : ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.person, size: 12.sp, color: Colors.white54),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}
