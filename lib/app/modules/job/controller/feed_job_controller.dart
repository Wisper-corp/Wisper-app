import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/job/model/feed_job_model.dart';
import 'package:wisper/app/urls.dart';

class AllFeedJobController extends GetxController {
  final NetworkCaller networkCaller = Get.find<NetworkCaller>();

  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final RxList<FeedJobItemModel> _allJobList = <FeedJobItemModel>[].obs;
  List<FeedJobItemModel> get allJobData => _allJobList;

  final int _limit = 2000;
  int page = 0;
  int? lastPage;

  Future<bool> getJobs({
    String? searchQuery,
    String? locationType,
    String? groupId,
  }) async {
    if (_inProgress.value) {
      print('Fetch already in progress → skipping');
      return false;
    }

    if (lastPage != null && page >= lastPage!) {
      print('Already at last page: $lastPage');
      return false;
    }

    _inProgress.value = true;
    _errorMessage.value = '';
    update();

    try {
      page++; // increment only when actually fetching
      print('Fetching jobs | page: $page');

      final Map<String, dynamic> queryParams = {'limit': _limit, 'page': page};

      // Only add parameters when they have meaningful values
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['searchTerm'] = searchQuery.trim();
      }

      if (locationType != null && locationType.isNotEmpty) {
        queryParams['locationType'] = locationType;
      }

      print('Query params: $queryParams');
      // Optional: print full URL for debugging
      // final fullUrl = Uri.parse(Urls.feedJobUrl).replace(queryParameters: queryParams);
      // print('Full URL: $fullUrl');

      var url = groupId == null
          ? Urls.feedJobUrl
          : '${Urls.communityJobUrl}/$groupId';

      final response = await networkCaller.getRequest(
        url,
        queryParams: queryParams,
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );

      print('Status: ${response.statusCode} | Success: ${response.isSuccess}');

      if (response.isSuccess && response.responseData != null) {
        final jobModel = FeedJobModel.fromJson(response.responseData);

        _allJobList.addAll(jobModel.data?.jobs ?? []);

        if (jobModel.data?.meta?.total != null &&
            jobModel.data?.meta?.limit != null) {
          lastPage = (jobModel.data!.meta!.total! / jobModel.data!.meta!.limit!)
              .ceil();
          print(
            'Total jobs: ${jobModel.data?.meta?.total} → last page: $lastPage',
          );
        }

        _inProgress.value = false;
        update();
        return true;
      } else {
        _errorMessage.value = response.errorMessage ?? 'Failed to load jobs';
        if (_errorMessage.value.toLowerCase().contains('expired')) {
          Get.to(() => const SignInScreen());
        }
        _inProgress.value = false;
        update();
        return false;
      }
    } catch (e, stack) {
      print('getJobs error: $e');
      print('Stack: $stack');
      _errorMessage.value = 'Something went wrong: $e';
      _inProgress.value = false;
      update();
      return false;
    }
  }

  void resetPagination() {
    page = 0; // Reset to 0 so first call uses page 1
    lastPage = null;
    _allJobList.clear();
    print('Pagination reset, fetching with categoryId');
    update();
  }
}
