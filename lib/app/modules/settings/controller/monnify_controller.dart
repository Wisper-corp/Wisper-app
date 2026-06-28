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

      // Launch Monnify payment SDK
      final response = await _monnify?.initializePayment(transaction: transaction);
      final status = response?.transactionStatus?.toUpperCase() ?? '';
      print('Monnify response status: $status');

      _inProgress.value = false;

      // Poll balance up to 5 times with 2s intervals to catch webhook credit
      await _pollBalanceUntilUpdated();

      final isPaid = status == 'PAID' || status == 'SUCCESS' || status == 'SUCCESSFUL';
      return isPaid;

    } catch (e) {
      print('Payment error: $e');
      _inProgress.value = false;
      // Still refresh - webhook may have fired
      await _pollBalanceUntilUpdated();
      _errorMessage.value = 'Payment error: ${e.toString()}';
      return false;
    }
  }

  /// Poll balance up to 5 times until it changes (webhook may take a moment)
  Future<void> _pollBalanceUntilUpdated() async {
    final double balanceBefore = _walletBalance.value;
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 2));
      await getWalletBalance();
      if (_walletBalance.value > balanceBefore) {
        print('Balance updated: ${_walletBalance.value}');
        break;
      }
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

      print('Wallet balance response: ${response.responseData}');

      if (response.isSuccess && response.responseData != null) {
        final data = response.responseData;
        // Handle both { balance: x } and { data: { balance: x } }
        final balance = data['balance'] ?? data['data']?['balance'] ?? 0.0;
        _walletBalance.value = (balance is int)
            ? balance.toDouble()
            : (balance as num).toDouble();
        _errorMessage.value = '';
        print('Wallet balance set to: ${_walletBalance.value}');
      }
    } catch (e) {
      print('Balance fetch error: $e');
    }
  }

  /// Withdraw Funds
  /// Returns a map with keys:
  ///   'success': bool
  ///   'status': 'PENDING_OTP' | 'SUCCESS'
  ///   'reference': String (present when PENDING_OTP)
  ///   'authorizationCode': String (present when PENDING_OTP)
  ///   'amount': double (present when PENDING_OTP)
  ///   'errorMessage': String (present on failure)
  Future<Map<String, dynamic>> withdrawFunds({
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

      _inProgress.value = false;

      if (response.isSuccess && response.responseData != null) {
        final data = response.responseData['data'] ?? response.responseData;
        final status = data['status'] ?? 'SUCCESS';

        if (status == 'PENDING_OTP') {
          return {
            'success': true,
            'status': 'PENDING_OTP',
            'reference': data['reference'] ?? '',
            'authorizationCode': data['authorizationCode'] ?? '',
            'amount': (data['amount'] is int)
                ? (data['amount'] as int).toDouble()
                : (data['amount'] ?? amount) as double,
          };
        }

        await getWalletBalance();
        _errorMessage.value = '';
        return {'success': true, 'status': 'SUCCESS'};
      } else {
        _errorMessage.value = response.errorMessage;
        return {'success': false, 'errorMessage': response.errorMessage};
      }
    } catch (e) {
      _inProgress.value = false;
      _errorMessage.value = 'Withdrawal failed: ${e.toString()}';
      return {'success': false, 'errorMessage': _errorMessage.value};
    }
  }

  /// Authorize withdrawal with OTP from email
  Future<bool> authorizeWithdrawal({
    required String reference,
    required String otp,
    required String authorizationCode,
    required double amount,
  }) async {
    _inProgress.value = true;

    try {
      final Map<String, dynamic> body = {
        "reference": reference,
        "otp": otp,
        "authorizationCode": authorizationCode,
        "amount": amount,
      };

      final NetworkResponse response = await Get.find<NetworkCaller>()
          .postRequest(
            Urls.monnifyAuthorizeWithdrawalUrl,
            body: body,
            accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
          );

      _inProgress.value = false;

      if (response.isSuccess && response.responseData != null) {
        await getWalletBalance();
        _errorMessage.value = '';
        return true;
      } else {
        _errorMessage.value = response.errorMessage;
        return false;
      }
    } catch (e) {
      _inProgress.value = false;
      _errorMessage.value = 'OTP verification failed: ${e.toString()}';
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