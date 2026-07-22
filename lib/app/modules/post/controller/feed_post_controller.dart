import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/post/model/feed_post_model.dart';
import 'package:wisper/app/urls.dart';

class AllFeedPostController extends GetxController {
  final NetworkCaller networkCaller = Get.find<NetworkCaller>();

  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final RxList<FeedPostItemModel> _allPostList = <FeedPostItemModel>[].obs;
  RxList<FeedPostItemModel> get allPostData => _allPostList;

  final int _limit = 2000;
  int page = 0;
  int? lastPage;

  // Category filter
  final RxString _selectedCategoryId = ''.obs;
  String get selectedCategoryId => _selectedCategoryId.value;
  set selectedCategoryId(String value) {
    _selectedCategoryId.value = value;
    resetPagination(); // Reset and fetch data when category changes
    update(); // Ensure UI updates
  }

  Future<bool> getAllPost({String? categoryId, String? groupId}) async {
    if (_inProgress.value) {
      print('Fetch already in progress, skipping');
      return false;
    }

    if (lastPage != null && page >= lastPage!) {
      print('Reached last page: $lastPage');
      _inProgress.value = false;
      update();
      return false;
    }

    _inProgress.value = true;
    update();

    try {
      page++;
      print('Fetching posts for page: $page');

      Map<String, dynamic> queryParams = {'limit': _limit, 'page': page};
      final effectiveCategoryId = categoryId ?? _selectedCategoryId.value;
      if (effectiveCategoryId.isNotEmpty) {
        queryParams['category'] = effectiveCategoryId;
      }

      // Use group-specific URL if groupId provided
      final url = (groupId != null && groupId.isNotEmpty)
          ? Urls.groupPostsUrl(groupId)
          : Urls.feedPostUrl;

      final NetworkResponse response = await networkCaller.getRequest(
        url,
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
    page = 0;
    lastPage = null;
    _allPostList.clear();
    print('Pagination reset, fetching with categoryId: $_selectedCategoryId');
    getAllPost(categoryId: _selectedCategoryId.value);
  }

  // Track which posts have already been viewed this session to avoid duplicate calls
  final Set<String> _viewedPostIds = {};

  Future<void> incrementView(String postId) async {
    if (postId.isEmpty || _viewedPostIds.contains(postId)) return;
    _viewedPostIds.add(postId);
    try {
      await networkCaller.patchRequest(
        Urls.postViewUrl(postId),
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );
    } catch (_) {
      // Silently fail - view count is non-critical
    }
  }
}
