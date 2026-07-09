import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/modules/kyc/model/kyc_status_model.dart';
import 'package:wisper/app/urls.dart';

class KycStatusController extends GetxController {
  final RxBool inProgress = false.obs;
  final Rx<KycStatusModel?> status = Rx<KycStatusModel?>(null);
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadStatus();
  }

  Future<void> loadStatus() async {
    inProgress.value = true;
    errorMessage.value = '';
    try {
      final response = await Get.find<NetworkCaller>().getRequest(
        Urls.kycStatusUrl,
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );
      if (response.isSuccess && response.responseData != null) {
        final data = response.responseData['data'];
        if (data != null) {
          status.value = KycStatusModel.fromJson(data as Map<String, dynamic>);
        }
      } else {
        errorMessage.value = response.errorMessage;
      }
    } catch (e) {
      errorMessage.value = 'Failed to load KYC status.';
    } finally {
      inProgress.value = false;
    }
  }

  // Helpers for easy reading in UI
  bool get emailVerified => status.value?.email.isVerified ?? false;
  bool get phoneVerified => status.value?.phone.isVerified ?? false;
  bool get ninVerified => status.value?.nin.isVerified ?? false;
  bool get addressVerified => status.value?.address.isVerified ?? false;
  bool get badgeActive => status.value?.badge.isActive ?? false;
}
