import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/forum/controller/forum_controller.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/views/forum_replies_screen.dart';
import 'package:wisper/app/modules/forum/widget/forum_composer.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_card.dart';
import 'package:wisper/app/modules/forum/widget/forum_post_menu.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/modules/chat/views/person/message_screen.dart';
import 'package:wisper/app/urls.dart';

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

  Future<bool> _post(
    String text,
    List<File> images,
    List<String>? pollOptions,
  ) async {
    final ok = await _controller.createPost(
      text,
      images: images,
      pollOptions: pollOptions,
    );
    if (!ok && mounted) {
      Get.snackbar('Could not post', _controller.errorMessage,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
    return ok;
  }

  Future<void> _openMenu(ForumPostModel post) async {
    final action = await showForumPostMenu(
      context,
      isFollowing: post.isFollowing,
      canDelete: post.canDelete,
      isMine: post.isMine,
      authorName: post.author.name ?? 'the author',
    );
    if (action == null || !mounted) return;

    switch (action) {
      case ForumPostAction.replyPrivately:
        await _replyPrivately(post);
        break;
      case ForumPostAction.toggleFollow:
        final now = await _controller.toggleFollow(post);
        if (!mounted) return;
        Get.snackbar(
          now ? 'Following this post' : 'Stopped following',
          now
              ? 'We\'ll notify you when someone replies.'
              : 'You will not be notified about new replies.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff17191C),
          colorText: Colors.white,
        );
        break;
      case ForumPostAction.delete:
        _confirmDelete(post);
        break;
    }
  }

  /// Opens the one-to-one chat with the author. POST /chats is get-or-create,
  /// so this reuses an existing conversation rather than starting a second.
  Future<void> _replyPrivately(ForumPostModel post) async {
    final authorId = post.author.id;
    if (authorId == null || authorId.isEmpty) return;

    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().postRequest(
        Urls.createChatsUrl,
        body: {'participantId': authorId},
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );
      if (!mounted) return;
      if (res.isSuccess && res.responseData != null) {
        Get.to(() => ChatScreen(
              receiverId: authorId,
              receiverName: post.author.name,
              receiverImage: post.author.image,
              chatId: res.responseData!['data']?['id'],
              isPerson: true,
            ));
      } else {
        Get.snackbar('Could not open the chat', res.errorMessage,
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Could not open the chat', 'Please try again.',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  void _confirmDelete(ForumPostModel post) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xff17191C),
        title: Text(
          post.isMine ? 'Delete your post?' : 'Delete this post?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          post.isMine
              ? 'It will be removed for everyone, along with its replies.'
              : 'This removes ${post.author.name ?? 'this member'}\'s post for '
                  'everyone, along with its replies.',
          style: const TextStyle(color: Color(0xff98A2B3)),
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
                  // Hand the card the colour above it so two neighbouring
                  // names never come out the same.
                  final previous =
                      index == 0 ? null : _controller.posts[index - 1];
                  return ForumPostCard(
                    post: post,
                    avoidNameColor: previous == null || previous.isMine
                        ? null
                        : forumNameColor(previous.author.id),
                    onOpenReplies: () => _openReplies(post),
                    onToggleReaction: () => _controller.toggleReaction(post),
                    onMore: () => _openMenu(post),
                    onVote: (option) => _controller.vote(post, option),
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
