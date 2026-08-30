import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/forum/controller/forum_controller.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_menu.dart';
import 'package:wisper/app/modules/chat/utils/open_direct_chat.dart';
import 'package:wisper/app/modules/saved/controller/saved_controller.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/widget/forum_composer.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_card.dart';
import 'package:wisper/app/modules/forum/widget/forum_reply_tile.dart';

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
  final FocusNode _composerFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  /// The reply being answered, or null when writing to the post itself.
  ForumReplyModel? _replyingTo;

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
    _composerFocus.dispose();
    Get.delete<ForumRepliesController>(tag: _tag);
    super.dispose();
  }

  Future<bool> _send(String text, List<File> images, List<String>? _) async {
    final ok = await _controller.addReply(text, parentId: _replyingTo?.id);
    if (ok && mounted) setState(() => _replyingTo = null);
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

  final SavedController _savedController = Get.isRegistered<SavedController>()
      ? Get.find<SavedController>()
      : Get.put(SavedController(), permanent: true);

  /// Seeds this reply and everything nested under it.
  void _seedSaved(ForumReplyModel reply) {
    _savedController.seed('reply', reply.id, reply.isSaved);
    for (final child in reply.replies) {
      _seedSaved(child);
    }
  }

  /// The reply's overflow menu. Following is a property of the post, not of
  /// one comment inside it, so it is not offered here.
  Future<void> _openReplyMenu(ForumReplyModel reply) async {
    final action = await showForumReplyMenu(
      context,
      canDelete: reply.canDelete,
      isMine: reply.isMine,
      authorName: reply.author.name ?? 'the author',
    );
    if (action == null || !mounted) return;

    switch (action) {
      case ForumReplyAction.replyPrivately:
        await openDirectChat(
          userId: reply.author.id,
          name: reply.author.name,
          image: reply.author.image,
        );
      case ForumReplyAction.delete:
        _confirmDeleteReply(reply);
    }
  }

  void _confirmDeleteReply(ForumReplyModel reply) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff17191C),
        title: const Text('Delete reply?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          reply.replyCount > 0
              ? 'Anything replying to it goes too. This cannot be undone.'
              : 'This cannot be undone.',
          style: const TextStyle(color: Color(0xff98A2B3)),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xff98A2B3))),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final ok = await _controller.deleteReply(reply);
              if (!mounted) return;
              if (!ok) {
                Get.snackbar(
                  'Could not delete',
                  _controller.errorMessage,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xff17191C),
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xffE5484D))),
          ),
        ],
      ),
    );
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
                    ...replies.map(
                      (reply) => Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                        child: Builder(builder: (_) {
                          // The listing already said whether each reply is
                          // bookmarked, so the icon is right on first paint.
                          _seedSaved(reply);
                          return ForumReplyTile(
                          reply: reply,
                          onReply: (r) {
                            setState(() => _replyingTo = r);
                            _composerFocus.requestFocus();
                          },
                          onToggleReaction: _controller.toggleReplyReaction,
                          onShowMore: _controller.loadThread,
                          onMore: _openReplyMenu,
                        );
                        }),
                      ),
                    ),
                ],
              );
            }),
          ),
          if (widget.canReply) ...[
            if (_replyingTo != null) _replyingToBanner(),
            ForumComposer(
              key: _composerKey,
              focusNode: _composerFocus,
              hintText: _replyingTo == null
                  ? 'Type here...'
                  : 'Reply to ${_replyingTo!.author.name ?? 'this'}...',
              // Replies are text only.
              allowImages: false,
              onSend: _send,
            ),
          ],
        ],
      ),
    );
  }

  /// Makes it unmistakable which reply the composer is aimed at - otherwise a
  /// nested reply lands at the top level and the thread quietly breaks.
  Widget _replyingToBanner() {
    return Container(
      color: const Color(0xff17191C),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 12.w, 8.h),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 15.sp, color: const Color(0xff8B949E)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Replying to ${_replyingTo!.author.name ?? 'this reply'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: const Color(0xff98A2B3),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyingTo = null),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: Icon(Icons.close,
                  size: 15.sp, color: const Color(0xff8B949E)),
            ),
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
