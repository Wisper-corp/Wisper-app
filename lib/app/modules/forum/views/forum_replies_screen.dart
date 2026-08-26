import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/forum/controller/forum_controller.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/core/widgets/common/expandable_text.dart';
import 'package:wisper/app/modules/forum/widget/forum_composer.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_card.dart';

/// The comment section for a single forum post: the post on top, a counts
/// strip, then the replies, with the composer pinned at the bottom.
class ForumRepliesScreen extends StatefulWidget {
  final ForumPostModel post;
  final bool canReply;

  const ForumRepliesScreen({
    super.key,
    required this.post,
    this.canReply = true,
  });

  @override
  State<ForumRepliesScreen> createState() => _ForumRepliesScreenState();
}

class _ForumRepliesScreenState extends State<ForumRepliesScreen> {
  late final ForumRepliesController _controller;

  /// Per-instance tag. Keying on the post id alone means double-tapping a post
  /// gives two screens the same controller, and the first one to close deletes
  /// it out from under the second.
  late final String _tag = 'forum_replies_${widget.post.id}_$hashCode';
  final GlobalKey<State<ForumComposer>> _composerKey =
      GlobalKey<State<ForumComposer>>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      ForumRepliesController(widget.post.id),
      tag: _tag,
    );
    // Show the post we already have while the replies load, so the screen
    // never opens empty.
    _controller.post.value = widget.post;
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.getReplies());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<ForumRepliesController>(tag: _tag);
    super.dispose();
  }

  Future<bool> _send(String text, List<File> images, List<String>? _) async {
    final ok = await _controller.addReply(text);
    if (!ok && mounted) {
      Get.snackbar('Could not reply', _controller.errorMessage,
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Replies',
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final post = _controller.post.value ?? widget.post;
              final replies = _controller.replies;

              return ListView(
                controller: _scrollController,
                padding: EdgeInsets.only(bottom: 16.h),
                children: [
                  // The original post, quiet: no action pills, because the
                  // counts sit in their own strip directly beneath.
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xff2A2F35)),
                    ),
                    child: ForumPostCard(
                      post: post,
                      showActions: false,
                      onOpenReplies: () {},
                      onToggleReaction: () {},
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 14.h),
                    child: Row(
                      children: [
                        Text('${post.replyCount} '
                            '${post.replyCount == 1 ? 'Reply' : 'Replies'}',
                            style: _statStyle()),
                        SizedBox(width: 28.w),
                        Text('${post.reactionCount} '
                            '${post.reactionCount == 1 ? 'Like' : 'Likes'}',
                            style: _statStyle()),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xff2A2F35)),
                  if (_controller.inProgress && replies.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (replies.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 44.h),
                      child: Center(
                        child: Text(
                          widget.canReply
                              ? 'No replies yet — say something.'
                              : 'No replies yet.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xff8B949E),
                          ),
                        ),
                      ),
                    )
                  else
                    ...replies.map((reply) => _ReplyRow(reply: reply)),
                ],
              );
            }),
          ),
          if (widget.canReply)
            ForumComposer(
              key: _composerKey,
              hintText: 'Type here...',
              // Replies are text only.
              allowImages: false,
              onSend: _send,
            ),
        ],
      ),
    );
  }

  TextStyle _statStyle() => TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xffC9D1D9),
      );
}

class _ReplyRow extends StatelessWidget {
  final ForumReplyModel reply;
  const _ReplyRow({required this.reply});

  @override
  Widget build(BuildContext context) {
    // Replies reuse the post card's shape by hand rather than the widget
    // itself: they carry no counts, so none of its action pills apply.
    final author = reply.author;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        color: forumNameColor(author.id),
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
                forumShortAge(reply.createdAt),
                style:
                    TextStyle(fontSize: 12.sp, color: const Color(0xff8B949E)),
              ),
            ],
          ),
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
        ],
      ),
    );
  }
}
