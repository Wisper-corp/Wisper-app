import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/job/model/favourite_job_list_model.dart';
import 'package:wisper/app/urls.dart';

class FavoriteController extends GetxController { 
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final Rx<FavoriteJobModel?> _favoriteJobModel = Rx<FavoriteJobModel?>(null);
  List<FavoriteJobItemModel>? get favoriteJobData =>
      _favoriteJobModel.value?.data;

  Future<bool> favorite({String? jobId}) async {
    _inProgress.value = true;

    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.favoriteJobById(jobId ?? ''),
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';

        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to fetch district data: ${e.toString()}';
      print('Error fetching district data: $e');
      _inProgress.value = false;
      return false;
    }
  }

  Future<bool> getAllFavorite() async {
    _inProgress.value = true;
    

    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            Urls.favoritesUrl,
            queryParams: {"limit": "9999"},
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';

        _favoriteJobModel.value = FavoriteJobModel.fromJson(
          response.responseData,
        );
        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        if (_errorMessage.value.contains('expired')) {
          Get.offAll(() => SignInScreen());
        }
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to fetch resume data: $e';
      _inProgress.value = false;
      return false;
    }
  }
}
