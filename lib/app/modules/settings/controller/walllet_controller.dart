import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/settings/model/wallet_model.dart';
import 'package:wisper/app/urls.dart';

class WallletController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final Rx<AllTransectionModel?> _allTransectionModel =
      Rx<AllTransectionModel?>(null);

  List<TransectionItemModel>? get allTransectionData =>
      _allTransectionModel.value?.data?.payments;

  @override
  void onInit() {
    super.onInit();
    getWallet();
  }

  Future<bool> getWallet() async {
    _inProgress.value = true;

    try {
      // Fetch real wallet transactions from /wallet/transactions
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            Urls.walletTransactionsUrl,
            queryParams: {"page": "1", "limit": "50"},
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _errorMessage.value = '';
        _allTransectionModel.value = AllTransectionModel.fromJson(
          response.responseData!,
        );
        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        if (_errorMessage.value.toLowerCase().contains('expired')) {
          Get.to(SignInScreen());
        }
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to load transactions: ${e.toString()}';
      _inProgress.value = false;
      return false;
    }
  }
}
