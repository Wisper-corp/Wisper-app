import 'dart:io';

import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/urls.dart';

class ForumController extends GetxController {
  final String groupId;
  ForumController(this.groupId);

  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final RxList<ForumPostModel> posts = <ForumPostModel>[].obs;

  String get _token => StorageUtil.getData(StorageUtil.userAccessToken);

  Future<void> getPosts() async {
    _inProgress.value = true;
    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().getRequest(
        Urls.groupForumUrl(groupId),
        queryParams: {'limit': '100'},
        accessToken: _token,
      );
      if (res.isSuccess && res.responseData != null) {
        _errorMessage.value = '';
        final list = (res.responseData!['data']?['posts'] as List?) ?? [];
        posts.assignAll(list.map((e) => ForumPostModel.fromJson(e)));
      } else {
        _errorMessage.value = res.errorMessage;
      }
    } catch (e) {
      _errorMessage.value = 'Could not load the forum. Pull to try again.';
    }
    _inProgress.value = false;
  }

  /// A caption is required even when images are attached, so an empty text is
  /// rejected here before it reaches the server.
  Future<bool> createPost(
    String text, {
    List<File>? images,
    List<String>? pollOptions,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().postRequest(
        Urls.forumUrl,
        body: {
          'groupId': groupId,
          'text': trimmed,
          if (pollOptions != null && pollOptions.isNotEmpty)
            'pollOptions': pollOptions,
        },
        images: (images != null && images.isNotEmpty) ? images : null,
        keyNameImage: 'images',
        accessToken: _token,
      );
      if (res.isSuccess && res.responseData != null) {
        // Newest sits at the top of the feed, matching the list order.
        posts.insert(0, ForumPostModel.fromJson(res.responseData!['data']));
        return true;
      }
      _errorMessage.value = res.errorMessage;
      return false;
    } catch (e) {
      _errorMessage.value = 'Could not post. Try again.';
      return false;
    }
  }

  /// Flips the heart immediately, then reconciles with the server's count so a
  /// failed request cannot leave the card lying.
  Future<void> toggleReaction(ForumPostModel post) async {
    final wasReacted = post.hasReacted;
    final wasCount = post.reactionCount;

    post.hasReacted = !wasReacted;
    post.reactionCount = wasCount + (wasReacted ? -1 : 1);
    posts.refresh();

    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().patchRequest(
        Urls.forumReactionUrl(post.id),
        body: const {},
        accessToken: _token,
      );
      if (res.isSuccess && res.responseData != null) {
        final data = res.responseData!['data'] ?? {};
        post.hasReacted = data['hasReacted'] ?? post.hasReacted;
        post.reactionCount = data['reactionCount'] ?? post.reactionCount;
      } else {
        post.hasReacted = wasReacted;
        post.reactionCount = wasCount;
      }
    } catch (e) {
      post.hasReacted = wasReacted;
      post.reactionCount = wasCount;
    }
    posts.refresh();
  }

  /// Records a vote and swaps in the server's recomputed tallies, so every
  /// client shows the same percentages rather than each rounding its own.
  Future<void> vote(ForumPostModel post, ForumPollOption option) async {
    final poll = post.poll;
    if (poll == null) return;
    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().postRequest(
        Urls.forumPollVoteUrl(post.id),
        body: {'optionId': option.id},
        accessToken: _token,
      );
      if (res.isSuccess && res.responseData != null) {
        post.poll = ForumPoll.fromJson(res.responseData!['data']);
        posts.refresh();
      } else {
        _errorMessage.value = res.errorMessage;
      }
    } catch (e) {
      _errorMessage.value = 'Could not record your vote.';
    }
  }

  Future<bool> toggleFollow(ForumPostModel post) async {
    final was = post.isFollowing;
    post.isFollowing = !was;
    posts.refresh();
    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().patchRequest(
        Urls.forumFollowUrl(post.id),
        body: const {},
        accessToken: _token,
      );
      if (res.isSuccess && res.responseData != null) {
        post.isFollowing = res.responseData!['data']?['isFollowing'] ?? !was;
      } else {
        post.isFollowing = was;
      }
    } catch (e) {
      post.isFollowing = was;
    }
    posts.refresh();
    return post.isFollowing;
  }

  Future<bool> deletePost(ForumPostModel post) async {
    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().deleteRequest(
        Urls.forumPostUrl(post.id),
        accessToken: _token,
      );
      if (res.isSuccess) {
        posts.removeWhere((p) => p.id == post.id);
        return true;
      }
      _errorMessage.value = res.errorMessage;
      return false;
    } catch (e) {
      _errorMessage.value = 'Could not delete the post.';
      return false;
    }
  }
}

class ForumRepliesController extends GetxController {
  final String postId;
  ForumRepliesController(this.postId);

  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final Rxn<ForumPostModel> post = Rxn<ForumPostModel>();
  final RxList<ForumReplyModel> replies = <ForumReplyModel>[].obs;
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  String get _token => StorageUtil.getData(StorageUtil.userAccessToken);

  Future<void> getReplies() async {
    _inProgress.value = true;
    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().getRequest(
        Urls.forumRepliesUrl(postId),
        queryParams: {'limit': '200'},
        accessToken: _token,
      );
      if (res.isSuccess && res.responseData != null) {
        final data = res.responseData!['data'] ?? {};
        if (data['post'] != null) {
          post.value = ForumPostModel.fromJson(data['post']);
        }
        final list = (data['replies'] as List?) ?? [];
        replies.assignAll(list.map((e) => ForumReplyModel.fromJson(e)));
      } else {
        _errorMessage.value = res.errorMessage;
      }
    } catch (e) {
      _errorMessage.value = 'Could not load replies.';
    }
    _inProgress.value = false;
  }

  /// Adds a reply. With [parentId] it joins that reply's thread instead of
  /// the post's top level.
  Future<bool> addReply(String text, {String? parentId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().postRequest(
        Urls.forumRepliesUrl(postId),
        body: {
          'text': trimmed,
          if (parentId != null) 'parentId': parentId,
        },
        accessToken: _token,
      );
      if (!res.isSuccess || res.responseData == null) {
        _errorMessage.value = res.errorMessage;
        return false;
      }

      final created = ForumReplyModel.fromJson(res.responseData!['data']);
      if (parentId == null) {
        // Oldest first, so a new top-level reply belongs at the end.
        replies.add(created);
      } else {
        // Slot it under its parent so the thread updates without a refetch.
        final parent = _findReply(parentId);
        parent?.replies.add(created);
        replies.refresh();
      }
      return true;
    } catch (e) {
      _errorMessage.value = 'Could not post your reply.';
      return false;
    }
  }

  ForumReplyModel? _findReply(String id) {
    for (final r in replies) {
      if (r.id == id) return r;
      for (final c in r.replies) {
        if (c.id == id) return c;
      }
    }
    return null;
  }

  /// Likes or unlikes a reply, flipping immediately and reverting if the
  /// request fails, so the count never sits lying to the user.
  Future<void> toggleReplyReaction(ForumReplyModel reply) async {
    final wasReacted = reply.hasReacted;
    final wasCount = reply.reactionCount;
    reply.hasReacted = !wasReacted;
    reply.reactionCount = wasCount + (wasReacted ? -1 : 1);
    replies.refresh();

    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().patchRequest(
        Urls.forumReplyReactionUrl(reply.id),
        body: const {},
        accessToken: _token,
      );
      if (res.isSuccess && res.responseData != null) {
        final data = res.responseData!['data'] ?? {};
        reply.hasReacted = data['hasReacted'] ?? reply.hasReacted;
        reply.reactionCount = data['reactionCount'] ?? reply.reactionCount;
      } else {
        reply.hasReacted = wasReacted;
        reply.reactionCount = wasCount;
      }
    } catch (e) {
      reply.hasReacted = wasReacted;
      reply.reactionCount = wasCount;
    }
    replies.refresh();
  }

  /// Loads the rest of one reply's thread, behind "Show more replies".
  Future<void> loadThread(ForumReplyModel reply) async {
    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().getRequest(
        Urls.forumReplyThreadUrl(reply.id),
        queryParams: {'limit': '100'},
        accessToken: _token,
      );
      if (res.isSuccess && res.responseData != null) {
        final list = (res.responseData!['data']?['replies'] as List?) ?? [];
        reply.replies = list.map((e) => ForumReplyModel.fromJson(e)).toList();
        replies.refresh();
      }
    } catch (e) {
      _errorMessage.value = 'Could not load the rest of this thread.';
    }
  }
}
