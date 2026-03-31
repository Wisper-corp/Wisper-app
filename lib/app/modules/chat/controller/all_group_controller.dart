import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/chat/model/all_group_model.dart';
import 'package:wisper/app/urls.dart';

class AllGroupController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs; 
  String get errorMessage => _errorMessage.value;

  final Rx<AllGroupModel?> _allGroupModel = Rx<AllGroupModel?>(null);
  List<AllGroupItemModel>? get allGroupData =>
      _allGroupModel.value?.data?.groups;

  Future<bool> getAllGroup() async {
    _inProgress.value = true;

    Map<String, dynamic> params = {"limit": "9999", "isPrivate": false};
    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            Urls.allGroupUrl,
            queryParams: params,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';

        _allGroupModel.value = AllGroupModel.fromJson(response.responseData);
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
