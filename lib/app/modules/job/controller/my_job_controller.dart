import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/job/model/feed_job_model.dart';

import 'package:wisper/app/urls.dart';

class MyFeedJobController extends GetxController {
  final NetworkCaller networkCaller = Get.find<NetworkCaller>(); 

  final RxBool _inProgress = false.obs; 
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final RxList<FeedJobItemModel> _allJobList = <FeedJobItemModel>[].obs;
  RxList<FeedJobItemModel> get allJobData => _allJobList;

  final int _limit = 2000;
  int page = 0;
  int? lastPage;

  // Category filter

  Future<bool> getJobs({String? categoryId, String? authorId}) async {
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

      print('Fetching assets with params: $queryParams');

      final NetworkResponse response = await networkCaller.getRequest(
        Urls.feedJobUrl,
        queryParams: queryParams,
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );

      print('Raw response: ${response.responseData}');

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';
        print('My job Response: ${response.responseData}');
        FeedJobModel jobModel = FeedJobModel.fromJson(response.responseData);
        _allJobList.addAll(jobModel.data?.jobs ?? []);

        if (jobModel.data?.meta?.total != null &&
            jobModel.data?.meta?.limit != null) {
          lastPage = (jobModel.data!.meta!.total! / jobModel.data!.meta!.limit!)
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

  /// Clears what is loaded and fetches it again.
  ///
  /// This used to clear only. Publishing a job calls it, and the profile's Job
  /// tab is already mounted by then, so nothing refetched -- posting a job
  /// emptied the very list it was supposed to appear in.
  void resetPagination() {
    page = 0; // Reset to 0 so first call uses page 1
    lastPage = null;
    _allJobList.clear();
    update();

    final userId = StorageUtil.getData(StorageUtil.userId);
    if (userId != null && userId.toString().isNotEmpty) {
      getJobs(authorId: userId);
    }
  }
}
