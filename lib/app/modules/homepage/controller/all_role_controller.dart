import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/homepage/model/role_model.dart';
import 'package:wisper/app/urls.dart';

class AllRoleController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;
 
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
 
  final Rx<RolesModel?> _allRoleModel = Rx<RolesModel?>(null);
  List<RoleItemModel>? get allRoleData => _allRoleModel.value?.data?.roles;

  Future<bool> getAllRole(String? searchQuery) async {
    _inProgress.value = true;

    Map<String, dynamic> params = {
      "limit": "9999",
      "searchTerm": searchQuery ?? "",
    }; 
    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            Urls.roleUrl,
            queryParams: params,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = ''; 

        _allRoleModel.value = RolesModel.fromJson(response.responseData);
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
