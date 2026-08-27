import 'package:get/get.dart';
import 'dart:async';
import 'package:wisper/push_notification.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

class OtpVerifyController extends GetxController {
  String? _extractAuthIdFromJwt(Map<String, dynamic> decodedToken) {
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

  String? _accessToken;
  String? get accessToken => _accessToken;

  Future<bool> otpVerify({
    String? email,
    String? otp,
    bool? isShowVerify = true,
  }) async {
    _inProgress.value = true;

    try {
      Map<String, dynamic> body = {
        "email": email,
        "otp": otp,
        "verifyAccount": true,
      };

      Map<String, dynamic> body2 = {"email": email, "otp": otp};
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.otpVerifyUrl,
            body: isShowVerify == true ? body : body2,
      );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';
        _accessToken = response.responseData?['data']?['accessToken'];

        if (_accessToken != null && _accessToken!.trim().isNotEmpty) {
          final decodedToken = JwtDecoder.decode(_accessToken!);
          final role = decodedToken['role'];

          await StorageUtil.saveData(StorageUtil.userRole, role);
          await StorageUtil.deleteData(StorageUtil.userId);
          await StorageUtil.deleteData(StorageUtil.userAuthId);
          await StorageUtil.saveData(StorageUtil.userAccessToken, _accessToken);

          final authId = _extractAuthIdFromJwt(decodedToken);
          if (authId != null) {
            await StorageUtil.saveData(StorageUtil.userId, authId);
            await StorageUtil.saveData(StorageUtil.userAuthId, authId);
          }

          // Same as sign-in: the token predates the session, so register it
          // against the user who just signed in.
          unawaited(PushNotificationService().syncTokenToServer());
        }

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
