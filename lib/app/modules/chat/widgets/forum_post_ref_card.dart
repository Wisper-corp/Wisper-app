import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/modules/chat/model/forum_post_ref.dart';

/// The forum post a private reply is about, drawn as a card.
///
/// The same card appears in two places, which is the point: above the composer
/// while you write the reply, and on the message once it is sent. Seeing the
/// same thing the recipient will see is what makes it obvious the post travels
/// with the message.
class ForumPostRefCard extends StatelessWidget {
  const ForumPostRefCard({
    super.key,
    required this.post,
    this.onTap,
    this.onDismiss,
    this.onLight = false,
  });

  final ForumPostRef post;

  /// Opens the original post. Null in the composer, where you are already
  /// looking at the thing you just came from.
  final VoidCallback? onTap;

  /// Shows the close button. Only the composer offers it — once sent, the
  /// context is part of the message.
  final VoidCallback? onDismiss;

  /// A sent message sits on a coloured bubble, so the card lightens instead of
  /// darkening to stay legible on it.
  final bool onLight;

  static const _accent = Color(0xff1F7DE9);

  @override
  Widget build(BuildContext context) {
    final background =
        onLight ? Colors.white.withValues(alpha: 0.18) : const Color(0xff1B1E22);
    final bodyColour = onLight ? Colors.white : const Color(0xffC9D1D9);
    final nameColour = onLight ? Colors.white : _accent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10.r),
          // The bar down the leading edge is what says "this is quoted", the
          // same shorthand every messaging app uses for a reply.
          border: Border(
            left: BorderSide(color: onLight ? Colors.white : _accent, width: 3),
          ),
        ),
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 8.w, 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.forum_outlined,
                          size: 13.sp, color: nameColour),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: nameColour,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    post.text.isEmpty ? 'Forum post' : post.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.3,
                      color: bodyColour,
                    ),
                  ),
                ],
              ),
            ),
            if (post.thumbnail != null || post.hasVideo) ...[
              SizedBox(width: 8.w),
              _Thumbnail(post: post),
            ],
            if (onDismiss != null) ...[
              SizedBox(width: 4.w),
              GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(2.r),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16.sp,
                    color: const Color(0xff8B949E),
                    semanticLabel: 'Remove the post from this reply',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A picture if the post has one, and a play badge if what it has is a clip —
/// a video URL handed to an image loader draws nothing at all.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.post});

  final ForumPostRef post;

  @override
  Widget build(BuildContext context) {
    final side = 38.r;
    final image = post.thumbnail;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        width: side,
        height: side,
        child: image != null
            ? CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: Color(0xff2A2F35),
                ),
              )
            : ColoredBox(
                color: const Color(0xff2A2F35),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 20.sp,
                  color: Colors.white70,
                  semanticLabel: 'Video',
                ),
              ),
      ),
    );
  }
}
