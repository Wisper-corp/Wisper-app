import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/urls.dart';

class SeenMessageController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  Future<bool> seenMessage(String chatId) async {
    _inProgress.value = true;

    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .patchRequest(
            Urls.seenMessageById(chatId),
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';
        // Reset unread count in socket list so badge disappears immediately
        try {
          final socketService = Get.find<SocketService>();
          final idx = socketService.socketFriendList
              .indexWhere((e) => e['id'] == chatId);
          if (idx != -1) {
            socketService.socketFriendList[idx]['unreadMessageCount'] = 0;
            socketService.socketFriendList.refresh();
          }
        } catch (_) {}
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        _errorMessage.value.contains('expired') ? Get.to(SignInScreen()) : null;
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to fetch district data: ${e.toString()}';
      _inProgress.value = false;
      return false;
    }
  }
}
