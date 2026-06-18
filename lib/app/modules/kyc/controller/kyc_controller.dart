import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/kyc/model/kyc_model.dart';
import 'package:wisper/app/urls.dart';

class KycController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final Rx<KycData?> _kycData = Rx<KycData?>(null);
  KycData? get kycData => _kycData.value;

  bool get isVerified => _kycData.value?.isVerified == true;

  /// Submit Biometric KYC — called after SmileID SDK returns a job result
  Future<bool> submitKyc({
    required String smileJobId,
    required String idNumber,
    required String idType,    // e.g. "BVN", "NIN"
    required String country,   // e.g. "NG"
    required String selfieImagePath,
    required String resultCode,
    required String resultText,
  }) async {
    _inProgress.value = true;

    try {
      final Map<String, dynamic> body = {
        "smileJobId": smileJobId,
        "idNumber": idNumber,
        "idType": idType,
        "country": country,
        "selfieImagePath": selfieImagePath,
        "resultCode": resultCode,
        "resultText": resultText,
      };

      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.kycSubmitUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        final model = KycModel.fromJson(response.responseData!);
        _kycData.value = model.data;
        _errorMessage.value = '';
        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'KYC submission failed: ${e.toString()}';
      _inProgress.value = false;
      return false;
    }
  }

  /// Get current KYC status for the logged-in user
  Future<void> getKycStatus() async {
    _inProgress.value = true;
    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            Urls.kycStatusUrl,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        final model = KycModel.fromJson(response.responseData!);
        _kycData.value = model.data;
      }
    } catch (e) {
      // Silently fail — KYC not started yet
    } finally {
      _inProgress.value = false;
    }
  }
}
