import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/post/model/feed_post_model.dart';
import 'package:wisper/app/urls.dart';

class GigMarketSearchController extends GetxController {
  final RxBool inProgress = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<FeedPostItemModel> results = <FeedPostItemModel>[].obs;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      results.clear();
      return;
    }

    inProgress.value = true;
    errorMessage.value = '';

    try {
      final NetworkResponse response = await Get.find<NetworkCaller>().getRequest(
        Urls.gigMarketSearchUrl(query.trim()),
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );

      if (response.isSuccess && response.responseData != null) {
        final data = response.responseData['data'];
        final posts = data['posts'] as List? ?? [];
        results.value = posts
            .map((p) => FeedPostItemModel.fromJson(p as Map<String, dynamic>))
            .toList();
      } else {
        errorMessage.value = response.errorMessage;
      }
    } catch (e) {
      errorMessage.value = 'Search failed: ${e.toString()}';
    } finally {
      inProgress.value = false;
    }
  }

  void clear() {
    results.clear();
    errorMessage.value = '';
  }
}
