import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/profile/model/buisness_model.dart';
import 'package:wisper/app/modules/profile/model/profile_model.dart';
import 'package:wisper/app/urls.dart';

class ProfileController extends GetxController {
  final RxBool _inProgress = false.obs; 
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value; 

  final Rx<ProfileModel?> _profileDetailsModel = Rx<ProfileModel?>(null);
  ProfileData? get profileData => _profileDetailsModel.value?.data;

  final Rx<BusinessModel?> _buisnessDetailsModel = Rx<BusinessModel?>(null);
  BusinessData? get buisnessData => _buisnessDetailsModel.value?.data;

  // @override
  // void onInit() {
  //   super.onInit();
  //   getMyProfile(); 
  // }

  Future<bool> getMyProfile() async {
    _inProgress.value = true;

    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            Urls.personProfileUrl,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';
        print(
          'My Profile Response data from controller : ${response.responseData['data']['auth']['person']['id']}',
        );

        StorageUtil.saveData(
          StorageUtil.userAuthId,
          response.responseData['data']['auth']['id'],
        );

        StorageUtil.saveData(
          StorageUtil.userId,
          response.responseData['data']['auth']['id'],
        );

        _profileDetailsModel.value = ProfileModel.fromJson(
          response.responseData,
        );
        // Cache basic profile info for offline display.
        try {
          final person = _profileDetailsModel.value?.data?.auth?.person;
          if (person != null) {
            StorageUtil.saveData(
              StorageUtil.cachedUserName,
              person.name ?? '',
            );
            StorageUtil.saveData(
              StorageUtil.cachedUserImage,
              person.image ?? '',
            );
            StorageUtil.saveData(
              StorageUtil.cachedUserTitle,
              person.title ?? '',
            );
          }
        } catch (_) {}

        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        _errorMessage.value.contains('expired') ? Get.to(SignInScreen()) : null;
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
}
