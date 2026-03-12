import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

class CallController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;
 
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final RxString _callId = ''.obs;
  String get callId => _callId.value;

  final RxString _roomId = ''.obs;
  String get roomId => _roomId.value;

  final RxString _token = ''.obs;
  String get token => _token.value;

  final RxInt _uuid = 0.obs;
  int get uuid => _uuid.value;

  // ✅ ONE_TO_ONE — single receiverUserId দিয়ে room তৈরি
  Future<bool> getRoom({
    String? callType,
    String? mode,
    String? receiverUserId,
  }) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {
        "type": callType ?? "VIDEO",
        "mode": mode ?? "ONE_TO_ONE",
        "participants": [
          {"id": receiverUserId, "status": "INCOMING"},
        ],
      };

      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.roomUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';
        _roomId.value = response.responseData['data']['roomId'];
        _callId.value = response.responseData['data']['id'];
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

  // ✅ GROUP — multiple participants list দিয়ে room তৈরি
  // participants format: [{"id": "authId", "status": "INCOMING"}, ...]
  Future<bool> getRoomWithParticipants({
    String? callType,
    String? mode,
    required List<Map<String, dynamic>> participants,
  }) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {
        "type": callType ?? "VIDEO",
        "mode": mode ?? "GROUP",
        "participants": participants,
      };

      print('📞 getRoomWithParticipants body: $body');

      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.roomUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';
        _roomId.value = response.responseData['data']['roomId'];
        _callId.value = response.responseData['data']['id'];
        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to create room: ${e.toString()}';
      print('Error creating room: $e');
      _inProgress.value = false;
      return false;
    }
  }

  Future<bool> getToken({String? callId, String? roomId}) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {
        "callId": callId ?? "uuid",
        "roomId": roomId ?? "call_xxx",
      };

      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.callTokenUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';
        _token.value = response.responseData['data']['token'];
        _uuid.value = response.responseData['data']['uid'];
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