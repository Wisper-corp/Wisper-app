import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

class EditPersonProfileController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  Future<bool> editProfile({
    String? name,
    String? phone,
    String? title,
    String? address,
  }) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {
        "name": name,
        "phone": phone,
        "title": title,
        "address": address,
      };
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .patchRequest(
            Urls.personEditProfileUrl,
            body: body,
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

  Future<bool> updateAddress({String? address}) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {"address": address};
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .patchRequest(
            Urls.personEditProfileUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
         print('Address updated successfully');
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
}
