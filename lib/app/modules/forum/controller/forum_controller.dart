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

  Future<bool> createPost(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().postRequest(
        Urls.forumUrl,
        body: {'groupId': groupId, 'text': trimmed},
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

  Future<bool> addReply(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    try {
      final NetworkResponse res = await Get.find<NetworkCaller>().postRequest(
        Urls.forumRepliesUrl(postId),
        body: {'text': trimmed},
        accessToken: _token,
      );
      if (res.isSuccess && res.responseData != null) {
        // Oldest first, so a new reply belongs at the end.
        replies.add(ForumReplyModel.fromJson(res.responseData!['data']));
        return true;
      }
      _errorMessage.value = res.errorMessage;
      return false;
    } catch (e) {
      _errorMessage.value = 'Could not post your reply.';
      return false;
    }
  }
}
