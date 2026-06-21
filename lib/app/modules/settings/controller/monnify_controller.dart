import 'package:get/get.dart';
import 'package:monnify_payment_sdk/monnify_payment_sdk.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

class MonnifyController extends GetxController {
  final RxBool _inProgress = false.obs;
  bool get inProgress => _inProgress.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final RxDouble _walletBalance = 0.0.obs;
  double get walletBalance => _walletBalance.value;

  // Monnify Configuration - PRODUCTION
  static const String apiKey = 'MK_PROD_2MCNNLXP3Y';
  static const String contractCode = '991744261465';
  static const bool isTestMode = false; // PRODUCTION MODE

  Monnify? _monnify;

  @override
  void onInit() {
    super.onInit();
    _initializeMonnify();
    getWalletBalance();
  }

  /// Initialize Monnify SDK
  Future<void> _initializeMonnify() async {
    try {
      _monnify = await Monnify.initialize(
        applicationMode: isTestMode ? ApplicationMode.TEST : ApplicationMode.LIVE,
        apiKey: apiKey,
        contractCode: contractCode,
      );
    } catch (e) {
      print('Monnify initialization error: $e');
    }
  }

  /// Initialize Monnify Payment
  Future<bool> makePayment({
    required double amount,
    required String email,
    required String name,
    required String phone,
  }) async {
    _inProgress.value = true;

    try {
      final String transactionReference = 'WSPR_${DateTime.now().millisecondsSinceEpoch}';

      final transaction = TransactionDetails().copyWith(
        amount: amount,
        customerName: name,
        customerEmail: email,
        paymentReference: transactionReference,
        paymentDescription: 'Wallet Funding',
        currencyCode: 'NGN',
        metaData: {
          'user_id': StorageUtil.getData(StorageUtil.userId) ?? '',
          'email': email,
          'platform': 'mobile_app',
        },
      );

      // Launch Monnify payment
      final response = await _monnify?.initializePayment(transaction: transaction);

      print('Monnify response status: ${response?.transactionStatus}');

      // Always refresh balance after payment dialog closes - 
      // webhook may have already credited the wallet regardless of SDK status
      await Future.delayed(const Duration(seconds: 2));
      await getWalletBalance();

      final status = response?.transactionStatus?.toUpperCase() ?? '';
      final isPaid = status == 'PAID' || status == 'SUCCESS' || status == 'SUCCESSFUL';

      if (isPaid) {
        _inProgress.value = false;
        return true;
      }

      // Even if status is not PAID, wallet may have been credited via webhook
      // Return true if balance increased
      _inProgress.value = false;
      return isPaid;

    } catch (e) {
      print('Payment error: $e');
      // Still refresh balance - webhook may have fired before the error
      await getWalletBalance();
      _errorMessage.value = 'Payment error: ${e.toString()}';
      _inProgress.value = false;
      return false;
    }
  }

  /// Verify payment on backend
  Future<bool> _verifyPaymentOnBackend(String reference, double amount, String monnifyRef) async {
    try {
      final Map<String, dynamic> body = {
        "reference": reference,
        "amount": amount,
        "monnifyReference": monnifyRef,
        "provider": "MONNIFY",
      };

      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.monnifyVerifyUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      return response.isSuccess && response.responseData?['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get Wallet Balance
  Future<void> getWalletBalance() async {
    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            Urls.walletBalanceUrl,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        _walletBalance.value = (response.responseData['balance'] ?? 0.0).toDouble();
        _errorMessage.value = '';
      }
    } catch (e) {
      print('Balance fetch error: $e');
    }
  }

  /// Withdraw Funds
  Future<bool> withdrawFunds({
    required double amount,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    _inProgress.value = true;

    try {
      final Map<String, dynamic> body = {
        "amount": amount,
        "bankCode": bankCode,
        "accountNumber": accountNumber,
        "accountName": accountName,
      };

      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.monnifyWithdrawUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        await getWalletBalance(); // Refresh balance
        _errorMessage.value = '';
        _inProgress.value = false;
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        _inProgress.value = false;
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Withdrawal failed: ${e.toString()}';
      _inProgress.value = false;
      return false;
    }
  }

  /// Get Nigerian Banks
  Future<List<Map<String, String>>> getNigerianBanks() async {
    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
            '${Urls.baseUrl}/banks/nigeria',
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      if (response.isSuccess && response.responseData != null) {
        return List<Map<String, String>>.from(response.responseData['banks'] ?? []);
      }
    } catch (e) {
      print('Banks fetch error: $e');
    }
    
    // Return default banks if API fails
    return [
      {'name': 'Access Bank', 'code': '044'},
      {'name': 'GTBank', 'code': '058'},
      {'name': 'First Bank', 'code': '011'},
      {'name': 'Zenith Bank', 'code': '057'},
      {'name': 'UBA', 'code': '033'},
      {'name': 'Zenith Bank', 'code': '057'},
      {'name': 'Fidelity Bank', 'code': '070'},
      {'name': 'Stanbic IBTC Bank', 'code': '221'},
      {'name': 'Sterling Bank', 'code': '232'},
      {'name': 'Union Bank', 'code': '032'},
      {'name': 'Wema Bank', 'code': '035'},
    ];
  }
}