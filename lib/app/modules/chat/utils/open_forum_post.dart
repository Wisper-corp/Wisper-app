import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';
import 'package:wisper/app/modules/forum/views/forum_replies_screen.dart';
import 'package:wisper/app/urls.dart';

/// Opens a forum post from anywhere that only knows its id.
///
/// A private reply carries a preview of the post it is about — a name, a line
/// of text, a picture — which is enough to draw the card but not enough to
/// open the post. This fetches the real one and shows it with its replies.
Future<void> openForumPostById(String postId) async {
  if (postId.isEmpty) return;

  try {
    final NetworkResponse res = await Get.find<NetworkCaller>().getRequest(
      Urls.forumPostUrl(postId),
      accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
    );

    final data = res.responseData?['data'];
    if (res.isSuccess && data is Map<String, dynamic>) {
      Get.to(() => ForumRepliesScreen(post: ForumPostModel.fromJson(data)));
      return;
    }

    // A deleted post, or a community the reader has since left. Saying so
    // beats a blank screen.
    Get.snackbar(
      'Cannot open that post',
      res.errorMessage.isNotEmpty
          ? res.errorMessage
          : 'It may have been deleted.',
      backgroundColor: const Color(0xff17191C),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  } catch (_) {
    Get.snackbar(
      'Cannot open that post',
      'Please try again.',
      backgroundColor: const Color(0xff17191C),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
