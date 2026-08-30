import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

/// Removes a chat from your own inbox.
///
/// The server records a deletion per person rather than destroying the chat,
/// so the other side keeps their copy and a new message brings it back.
class DeleteChatController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  Future<bool> deleteChat(String chatId) async {
    if (chatId.isEmpty) return false;
    _inProgress.value = true;

    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .deleteRequest(
            Urls.deleteChatUrl(chatId),
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      _inProgress.value = false;
      if (response.isSuccess) {
        _errorMessage.value = '';
        return true;
      }
      _errorMessage.value = response.errorMessage;
      return false;
    } catch (e) {
      _errorMessage.value = 'Could not delete that chat.';
      _inProgress.value = false;
      return false;
    }
  }
}
