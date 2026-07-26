// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/post/model/feed_post_model.dart';
import 'package:wisper/app/urls.dart';

class MyFeedPostController extends GetxController {
  final NetworkCaller networkCaller = Get.find<NetworkCaller>();

  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final RxList<FeedPostItemModel> _allPostList = <FeedPostItemModel>[].obs;
  List<FeedPostItemModel> get allPostData => _allPostList;

  final int _limit = 2000;
  int page = 0;
  int? lastPage;
 
  // Category filter
  final RxString _selectedCategoryId = ''.obs;
  String get selectedCategoryId => _selectedCategoryId.value;
  set selectedCategoryId(String value) {
    _selectedCategoryId.value = value;
    resetPagination();
    update();
  }

  Future<bool> getAllPost({String? categoryId, bool? itsMe}) async {
    if (_inProgress.value) {
      print('Fetch already in progress, skipping');
      return false;
    }

    if (lastPage != null && page >= lastPage!) {
      print('Reached last page: $lastPage');
      _inProgress.value = false;
      update();
      return false; // Stop if we've reached the last page
    }

    _inProgress.value = true;
    update();

    try {
      // Increment page after checking lastPage
      page++;
      print('Fetching assets for page: $page');

      Map<String, dynamic> queryParams = {
        'limit': _limit,
        'page': page,
        'authorId': StorageUtil.getData(StorageUtil.userId),
      };
      final effectiveCategoryId = categoryId ?? _selectedCategoryId.value;
      if (effectiveCategoryId.isNotEmpty) {
        queryParams['category'] = effectiveCategoryId;
      }

      print('Fetching assets with params: $queryParams');

      final NetworkResponse response = await networkCaller.getRequest(
        Urls.myFeedPostUrl,
        queryParams: queryParams,
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );

      print('Raw response: ${response.responseData}');

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';
        FeedPostModel assetsModel = FeedPostModel.fromJson(
          response.responseData,
        );
        _allPostList.addAll(assetsModel.data?.posts ?? []);

        if (assetsModel.data?.meta?.total != null &&
            assetsModel.data?.meta?.limit != null) {
          lastPage =
              (assetsModel.data!.meta!.total! / assetsModel.data!.meta!.limit!)
                  .ceil();
          print('Last page calculated: $lastPage');
        }

        _inProgress.value = false;
        update();
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        if (_errorMessage.value.contains('expired')) {
          Get.to(() => SignInScreen());
        }
        _inProgress.value = false;
        update();
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to fetch asset data: ${e.toString()}';
      print('Error fetching asset data: $e');
      _inProgress.value = false;
      update();
      return false;
    }
  }

  void resetPagination() {
    page = 0; // Reset to 0 so first call uses page 1
    lastPage = null;
    _allPostList.clear();
    update();
  }

  void setPostCommentCount({required String postId, required int count}) {
    if (postId.isEmpty) return;
    final int index = _allPostList.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _allPostList[index];
    final updated = FeedPostItemModel(
      id: post.id,
      caption: post.caption,
      images: post.images,
      views: post.views,
      createdAt: post.createdAt,
      commentAccess: post.commentAccess,
      author: post.author,
      count: Count(comment: count),
    );

    _allPostList[index] = updated;
    update();
  }
}
