import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/modules/kyc/controller/kyc_controller.dart';
import 'package:wisper/app/modules/kyc/views/kyc_screen.dart';
import 'package:wisper/app/modules/profile/controller/buisness/buisness_controller.dart';
import 'package:wisper/app/modules/profile/controller/person/profile_controller.dart';
import 'package:wisper/app/modules/settings/controller/monnify_controller.dart';
import 'package:wisper/app/modules/settings/controller/walllet_controller.dart';
import 'package:wisper/app/modules/settings/views/transaction_section.dart';
import 'package:wisper/app/modules/settings/wigdets/wallet_option.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WallletController wallletController = Get.put(WallletController());
  final ProfileController profileController = Get.find<ProfileController>();
  final BusinessController businessController = Get.find<BusinessController>();
  final KycController _kycController = Get.put(KycController());
  final MonnifyController _monnifyController = Get.put(MonnifyController());
  
  int isSelected = 1;

  @override
  void initState() {
    wallletController.getWallet();
    profileController.getMyProfile();
    businessController.getMyProfile();
    _kycController.getKycStatus();
    // Always fetch latest balance when screen opens
    _monnifyController.getWalletBalance();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (wallletController.inProgress) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150.h,
                width: double.infinity,
                decoration: BoxDecoration(color: LightThemeColors.blueColor),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Obx(() {
                        if (profileController.inProgress) {
                          return const CircularProgressIndicator();
                        } else {
                          var isPerson =
                              StorageUtil.getData(StorageUtil.userRole) ==
                                  'PERSON';

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // Back button
                                  GestureDetector(
                                    onTap: () => Get.back(),
                                    child: const Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Total Balance',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '₦${_monnifyController.walletBalance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 26.sp,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              CircleAvatar(
                                radius: 21.r,
                                backgroundImage: NetworkImage(
                                  isPerson
                                      ? profileController
                                                .profileData
                                                ?.auth
                                                ?.person
                                                ?.image ??
                                            ''
                                      : businessController
                                                .buisnessData
                                                ?.auth
                                                ?.business
                                                ?.image ??
                                            '',
                                ),
                              ),
                            ],
                          );
                        }
                      }),
                    ],
                  ),
                ),
              ),

              heightBox20,
              heightBox20,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    // Add Fund button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isSelected = 1;
                          });
                        },
                        child: Container(
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: isSelected == 1
                                ? LightThemeColors.blueColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(
                              color: isSelected == 1
                                  ? Colors.transparent
                                  : Colors.white.withOpacity(0.30),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Add Fund',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Withdraw button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // KYC check temporarily disabled for testing
                          // if (!_kycController.isVerified) {
                          //   _showKycRequiredDialog();
                          // } else {
                            setState(() {
                              isSelected = 2;
                            });
                          // }
                        },
                        child: Container(
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: isSelected == 2
                                ? LightThemeColors.blueColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(
                              color: isSelected == 2
                                  ? Colors.transparent
                                  : Colors.white.withOpacity(0.30),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Withdraw',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              heightBox10,
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (isSelected == 1) _buildFundWalletSection(),
                      if (isSelected == 2) _buildWithdrawSection(),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  // ── Fund Wallet Section (Monnify SDK Integration) ─────────────────────────────────────
  Widget _buildFundWalletSection() {
    final TextEditingController amountController = TextEditingController();
    
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: LightThemeColors.blueColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 32.sp, color: LightThemeColors.blueColor),
                    widthBox12,
                    Text(
                      'Fund Wallet',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
                heightBox16,
                Text(
                  'Add money to your wallet using Monnify payment gateway (Card, Bank Transfer, USSD)',
                  style: TextStyle(fontSize: 14.sp, color: const Color(0xFFD1D1D1)),
                ),
                heightBox20,
                
                // Amount Input
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    labelText: 'Amount (₦)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.money, color: LightThemeColors.blueColor),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter amount to add',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  ),
                ),
                
                heightBox20,
                
                // Quick Amount Buttons
                Text('Quick amounts:', style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                heightBox8,
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _buildQuickAmountButton('₦1,000', () => amountController.text = '1000'),
                    _buildQuickAmountButton('₦5,000', () => amountController.text = '5000'),
                    _buildQuickAmountButton('₦10,000', () => amountController.text = '10000'),
                    _buildQuickAmountButton('₦20,000', () => amountController.text = '20000'),
                  ],
                ),
                
                heightBox20,
                
                Obx(() => CustomElevatedButton(
                  title: _monnifyController.inProgress ? 'Processing...' : 'Fund Wallet with Monnify',
                  onPress: _monnifyController.inProgress ? null : () => _fundWallet(amountController.text),
                )),
                
                heightBox12,
                
                // Payment Methods Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card, size: 16.sp, color: Colors.grey),
                    widthBox4,
                    Text('Card', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                    widthBox20,
                    Icon(Icons.account_balance, size: 16.sp, color: Colors.grey),
                    widthBox4,
                    Text('Bank Transfer', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                    widthBox20,
                    Icon(Icons.phone_android, size: 16.sp, color: Colors.grey),
                    widthBox4,
                    Text('USSD', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(String amount, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: LightThemeColors.blueColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: LightThemeColors.blueColor.withOpacity(0.3)),
        ),
        child: Text(
          amount,
          style: TextStyle(fontSize: 10.sp, color: LightThemeColors.blueColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _fundWallet(String amountText) async {
    if (amountText.isEmpty) {
      Get.snackbar('Error', 'Please enter an amount');
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Please enter a valid amount');
      return;
    }

    if (amount < 100) {
      Get.snackbar('Error', 'Minimum funding amount is ₦100');
      return;
    }

    // Get user data
    var isPerson = StorageUtil.getData(StorageUtil.userRole) == 'PERSON';
    String name = '';
    String email = '';
    String phone = '';

    if (isPerson && profileController.profileData != null) {
      name = profileController.profileData?.auth?.person?.name ?? 'User';
      email = profileController.profileData?.auth?.person?.email ?? '';
      phone = profileController.profileData?.auth?.person?.phone ?? '';
    } else if (!isPerson && businessController.buisnessData != null) {
      name = businessController.buisnessData?.auth?.business?.name ?? 'Business';
      email = businessController.buisnessData?.auth?.business?.email ?? '';
      phone = businessController.buisnessData?.auth?.business?.phone ?? '';
    }

    if (email.isEmpty) {
      Get.snackbar('Error', 'User email not found. Please update your profile.');
      return;
    }

    // Launch Monnify SDK payment
    final bool success = await _monnifyController.makePayment(
      amount: amount,
      email: email,
      name: name,
      phone: phone,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Wallet funded successfully with ₦${amount.toStringAsFixed(2)}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      setState(() => isSelected = 0); // Switch to transactions tab
      wallletController.getWallet(); // Refresh transactions
    } else {
      Get.snackbar(
        'Error',
        _monnifyController.errorMessage.isNotEmpty 
          ? _monnifyController.errorMessage 
          : 'Payment failed or cancelled. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // ── Withdrawal Section (KYC protected) ─────────────────────────────────────
  Widget _buildWithdrawSection() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController accountNumberController = TextEditingController();
    final TextEditingController accountNameController = TextEditingController();
    final RxString selectedBank = 'Select Bank'.obs;
    final RxString selectedBankCode = ''.obs;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: LightThemeColors.blueColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.send_outlined, size: 32.sp, color: LightThemeColors.blueColor),
                    widthBox12,
                    Text(
                      'Withdraw Funds',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
                heightBox8,
                Text(
                  'Transfer money from your wallet to your bank account',
                  style: TextStyle(fontSize: 14.sp, color: const Color(0xFFD1D1D1)),
                ),
                heightBox20,

                // Available Balance
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: LightThemeColors.blueColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 20.sp, color: LightThemeColors.blueColor),
                      widthBox8,
                      Text(
                        'Available Balance: ',
                        style: TextStyle(fontSize: 14.sp, color: Colors.white),
                      ),
                      Obx(() => Text(
                        '₦${_monnifyController.walletBalance.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: LightThemeColors.blueColor),
                      )),
                    ],
                  ),
                ),
                
                heightBox20,

                // Amount Input
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    labelText: 'Amount to withdraw (₦)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.money, color: LightThemeColors.blueColor),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter withdrawal amount',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  ),
                ),

                heightBox16,

                // Bank Selection
                GestureDetector(
                  onTap: () => _showBankSelection(selectedBank, selectedBankCode),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, color: LightThemeColors.blueColor),
                        widthBox12,
                        Expanded(
                          child: Obx(() => Text(
                            selectedBank.value,
                            style: TextStyle(
                              color: selectedBank.value == 'Select Bank' ? Colors.grey : Colors.white,
                              fontSize: 16.sp,
                            ),
                          )),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                heightBox16,

                // Account Number
                TextField(
                  controller: accountNumberController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.account_box, color: LightThemeColors.blueColor),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter 10-digit account number',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                    counterText: '',
                  ),
                ),

                heightBox16,

                // Account Name
                TextField(
                  controller: accountNameController,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.person, color: LightThemeColors.blueColor),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter account name',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  ),
                ),

                heightBox20,

                Obx(() => CustomElevatedButton(
                  title: _monnifyController.inProgress ? 'Processing...' : 'Withdraw Funds',
                  onPress: _monnifyController.inProgress ? null : () => _withdrawFunds(
                    amountController.text,
                    selectedBankCode.value,
                    accountNumberController.text,
                    accountNameController.text,
                  ),
                )),

                heightBox12,

                // Withdrawal Info
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16.sp, color: Colors.orange),
                      widthBox8,
                      Expanded(
                        child: Text(
                          'Withdrawals are processed within 24 hours on business days.',
                          style: TextStyle(fontSize: 11.sp, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBankSelection(RxString selectedBank, RxString selectedBankCode) async {
    final banks = await _monnifyController.getNigerianBanks();
    
    Get.bottomSheet(
      Container(
        height: 400.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Select Bank',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: banks.length,
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  return ListTile(
                    title: Text(
                      bank['name'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      selectedBank.value = bank['name'] ?? '';
                      selectedBankCode.value = bank['code'] ?? '';
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _withdrawFunds(String amountText, String bankCode, String accountNumber, String accountName) async {
    if (amountText.isEmpty || bankCode.isEmpty || accountNumber.isEmpty || accountName.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    if (bankCode == 'Select Bank') {
      Get.snackbar('Error', 'Please select a bank');
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Please enter a valid amount');
      return;
    }

    if (amount > _monnifyController.walletBalance) {
      Get.snackbar('Error', 'Insufficient balance');
      return;
    }

    if (amount < 1000) {
      Get.snackbar('Error', 'Minimum withdrawal amount is ₦1,000');
      return;
    }

    if (accountNumber.length != 10) {
      Get.snackbar('Error', 'Account number must be 10 digits');
      return;
    }

    final Map<String, dynamic> result = await _monnifyController.withdrawFunds(
      amount: amount,
      bankCode: bankCode,
      accountNumber: accountNumber,
      accountName: accountName,
    );

    if (result['success'] == true) {
      if (result['status'] == 'PENDING_OTP') {
        // Monnify requires OTP — show OTP dialog
        _showOtpDialog(
          reference: result['reference'] as String,
          authorizationCode: result['authorizationCode'] as String,
          amount: result['amount'] as double,
        );
      } else {
        // Direct success (no OTP required)
        Get.snackbar(
          'Success',
          'Withdrawal successful! Funds will be in your account shortly.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        setState(() => isSelected = 0);
        wallletController.getWallet();
      }
    } else {
      Get.snackbar(
        'Error',
        result['errorMessage'] ?? 'Withdrawal failed. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// OTP dialog — shown when Monnify returns PENDING_AUTHORIZATION
  void _showOtpDialog({
    required String reference,
    required String authorizationCode,
    required double amount,
  }) {
    final TextEditingController otpController = TextEditingController();

    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: LightThemeColors.blueColor, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              'Enter OTP',
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monnify sent an OTP to your registered email address to authorize this withdrawal of ₦${amount.toStringAsFixed(2)}.',
              style: TextStyle(color: Colors.white70, fontSize: 13.sp),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '------',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), letterSpacing: 8),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: LightThemeColors.blueColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: LightThemeColors.blueColor, width: 2),
                ),
                counterText: '',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Check your email and enter the 6-digit OTP.',
              style: TextStyle(color: Colors.grey, fontSize: 11.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              otpController.dispose();
              Get.back();
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          ),
          Obx(() => TextButton(
            onPressed: _monnifyController.inProgress
                ? null
                : () async {
                    final otp = otpController.text.trim();
                    if (otp.length < 4) {
                      Get.snackbar('Error', 'Please enter the OTP from your email');
                      return;
                    }

                    final bool success = await _monnifyController.authorizeWithdrawal(
                      reference: reference,
                      otp: otp,
                      authorizationCode: authorizationCode,
                      amount: amount,
                    );

                    if (success) {
                      otpController.dispose();
                      Get.back(); // Close dialog
                      Get.snackbar(
                        'Success',
                        'Withdrawal successful! Funds will be in your account shortly.',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 5),
                      );
                      setState(() => isSelected = 0);
                      wallletController.getWallet();
                    } else {
                      Get.snackbar(
                        'Invalid OTP',
                        _monnifyController.errorMessage.isNotEmpty
                            ? _monnifyController.errorMessage
                            : 'Incorrect OTP. Please check your email and try again.',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
            child: _monnifyController.inProgress
                ? SizedBox(
                    width: 18.w,
                    height: 18.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LightThemeColors.blueColor,
                    ),
                  )
                : Text(
                    'Confirm',
                    style: TextStyle(
                      color: LightThemeColors.blueColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          )),
        ],
      ),
    );
  }

  void _showKycRequiredDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Identity Verification Required', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        content: Text(
          'Please complete your BVN/NIN verification to withdraw funds from your wallet.',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => const KycScreen());
            },
            child: Text('Verify Now', style: TextStyle(color: LightThemeColors.blueColor)),
          ),
        ],
      ),
    );
  }
}
