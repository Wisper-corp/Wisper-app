import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

class GroupMemberController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  Future<bool> addRequest({String? memberId, String? groupId}) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {"member": memberId};
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.addMembersById(groupId!),
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

  Future<bool> removeRequest({String? memberId, String? chatId}) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {"chatId": chatId, "participantId": memberId};
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .patchRequest(
            Urls.removePerticipantUrl,
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
  Future<bool> leaveGroup({String? chatId}) async {
    _inProgress.value = true;
    try {
      final myId = StorageUtil.getData(StorageUtil.userId) ?? '';
      final Map<String, dynamic> body = {
        "chatId": chatId,
        "participantId": myId,
      };
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .patchRequest(
            Urls.removePerticipantUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );
      if (response.isSuccess) {
        _inProgress.value = false;
        return true;
      }
      _errorMessage.value = response.errorMessage;
      _inProgress.value = false;
      return false;
    } catch (e) {
      _errorMessage.value = e.toString();
      _inProgress.value = false;
      return false;
    }
  }
}

extension GroupMemberLeave on GroupMemberController {
  Future<bool> leaveGroup({String? chatId}) async {
    _inProgress.value = true;
    try {
      final myId = StorageUtil.getData(StorageUtil.userId) ?? '';
      final Map<String, dynamic> body = {
        "chatId": chatId,
        "participantId": myId,
      };
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .patchRequest(
            Urls.removePerticipantUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );
      if (response.isSuccess) {
        _inProgress.value = false;
        return true;
      }
      _errorMessage.value = response.errorMessage;
      _inProgress.value = false;
      return false;
    } catch (e) {
      _errorMessage.value = e.toString();
      _inProgress.value = false;
      return false;
    }
  }
}

  Future<bool> updateRole({String? chatId, String? participantId, String? role}) async {
    _inProgress.value = true;
    try {
      final Map<String, dynamic> body = {
        "chatId": chatId,
        "participantId": participantId,
        "role": role,
      };
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .patchRequest(
            Urls.updateParticipantRoleUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );
      if (response.isSuccess) {
        _inProgress.value = false;
        return true;
      }
      _errorMessage.value = response.errorMessage;
      _inProgress.value = false;
      return false;
    } catch (e) {
      _errorMessage.value = e.toString();
      _inProgress.value = false;
      return false;
    }
  }
