import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/settings/model/all_connection_model.dart';
import 'package:wisper/app/urls.dart';

class AllConnectionController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final Rx<AllConnectionModel?> _allConnectionModel = Rx<AllConnectionModel?>(
    null,
  );
  List<AllConnectionItemModel>? get allConnectionData =>
      _allConnectionModel.value?.data?.connections;
 
  // @override
  // void onInit() {
  //   super.onInit();
  //   getMyProfile();
  // }

  Future<bool> getAllConnection(String? status, String? recieverId) async {
    _inProgress.value = true;
 
    Map<String, dynamic> params = recieverId == ''
        ? {"status": status, "limit": 999}
        : {"status": status, "receiverId": recieverId, "limit": 999};
    // Map<String, dynamic> params = {"status": status};
    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            Urls.allConnectionUrl,
            queryParams: params,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';

        _allConnectionModel.value = AllConnectionModel.fromJson(
          response.responseData,
        );

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
