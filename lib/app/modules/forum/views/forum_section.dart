import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/forum/controller/forum_controller.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/views/forum_replies_screen.dart';
import 'package:wisper/app/modules/forum/widget/forum_composer.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_card.dart';

/// The Forum tab: a community's discussion feed, with the composer pinned at
/// the bottom the way the chat tab has one.
class ForumSection extends StatefulWidget {
  final String groupId;

  /// Non-members read the forum but cannot post, matching Jobs and Services.
  final bool canPost;

  const ForumSection({
    super.key,
    required this.groupId,
    this.canPost = true,
  });

  @override
  State<ForumSection> createState() => _ForumSectionState();
}

class _ForumSectionState extends State<ForumSection> {
  late final ForumController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ForumController>(tag: widget.groupId)
        ? Get.find<ForumController>(tag: widget.groupId)
        : Get.put(ForumController(widget.groupId), tag: widget.groupId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.getPosts());
  }

  Future<void> _openReplies(ForumPostModel post) async {
    await Get.to(() => ForumRepliesScreen(post: post, canReply: widget.canPost));
    // The reply count on the card is stale once you have been inside.
    await _controller.getPosts();
  }

  Future<bool> _post(String text) async {
    final ok = await _controller.createPost(text);
    if (!ok && mounted) {
      Get.snackbar('Could not post', _controller.errorMessage,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
    return ok;
  }

  void _confirmDelete(ForumPostModel post) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff17191C),
        title: const Text('Delete this post?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'It will be removed for everyone, along with its replies.',
          style: TextStyle(color: Color(0xff98A2B3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xff98A2B3))),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final ok = await _controller.deletePost(post);
              if (!ok) {
                Get.snackbar('Could not delete', _controller.errorMessage,
                    backgroundColor: Colors.red, colorText: Colors.white);
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
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (_controller.inProgress && _controller.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.posts.isEmpty) {
              return RefreshIndicator(
                onRefresh: _controller.getPosts,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 120.h),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: Column(
                          children: [
                            Icon(Icons.forum_outlined,
                                size: 40.sp, color: const Color(0xff4D5860)),
                            SizedBox(height: 14.h),
                            Text(
                              'No discussions yet',
                              style: TextStyle(
                                fontFamily: 'Segoe UI',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              widget.canPost
                                  ? 'Start the first one below.'
                                  : 'Join this community to start one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xff98A2B3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _controller.getPosts,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: 12.h),
                itemCount: _controller.posts.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Color(0xff2A2F35),
                ),
                itemBuilder: (context, index) {
                  final post = _controller.posts[index];
                  return ForumPostCard(
                    post: post,
                    onOpenReplies: () => _openReplies(post),
                    onToggleReaction: () => _controller.toggleReaction(post),
                    onMore: post.isMine ? () => _confirmDelete(post) : null,
                  );
                },
              ),
            );
          }),
        ),
        if (widget.canPost)
          ForumComposer(hintText: 'Type here...', onSend: _post),
      ],
    );
  }
}
