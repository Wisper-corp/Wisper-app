import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

class SignInController extends GetxController {
  String? _extractAuthIdFromJwt(Map<String, dynamic> decodedToken) {
    // Support common claim names
    final candidates = [
      decodedToken['id'],
      decodedToken['authId'], 
      decodedToken['userId'],
      decodedToken['sub'],
    ];
    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  Future<bool> signIn({String? email, String? password}) async {

    _inProgress.value = true;

    try {

      /// 🔹 Get FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      print("FCM TOKEN: $fcmToken");

      Map<String, dynamic> body = {
        "email": email,
        "password": password,
        "isMobileApp": true,
        "fcmToken": fcmToken,
        "deviceType": "android"
      };

      final NetworkResponse response =
          await Get.find<NetworkCaller>()
              .postRequest(Urls.signInUrl, body: body);

      if (response.isSuccess && response.responseData != null) {

        _errorMessage.value = '';

        var token = response.responseData['data']['accessToken'];

        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

        var role = decodedToken['role'];

        StorageUtil.saveData(StorageUtil.userRole, role);

        // Clear stale IDs before writing the new session.
        await StorageUtil.deleteData(StorageUtil.userId);
        await StorageUtil.deleteData(StorageUtil.userAuthId);

        StorageUtil.saveData(
          StorageUtil.userAccessToken,
          response.responseData['data']['accessToken'],
        );

        // Best-effort: set auth id from JWT immediately so SocketService can connect
        // without waiting for profile APIs.
        final authId = _extractAuthIdFromJwt(decodedToken);
        if (authId != null) {
          StorageUtil.saveData(StorageUtil.userId, authId);
          StorageUtil.saveData(StorageUtil.userAuthId, authId);
        }

        _inProgress.value = false;

        return true;

      } else {

        _errorMessage.value = response.errorMessage;

        _inProgress.value = false;

        return false;

      }

    } catch (e) {

      _errorMessage.value = e.toString();

      print("SignIn Error: $e");

      _inProgress.value = false;

      return false;
    }
  }
}
