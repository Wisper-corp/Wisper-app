

// SplashScreen.dart - Updated with Camera & Mic permission
// বাকি সব অপরিবর্তিত রাখা হয়েছে

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/others/deeplink_services.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/utils/no_inter_screen.dart';
import 'package:wisper/gen/assets.gen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {

    /// 🔥 Permission request (UI ready হওয়ার পর)
    await Future.delayed(const Duration(milliseconds: 500));
    await _requestPermissions();

    /// এরপর original flow
    await _checkAndNavigate();
  }

  Future<void> _requestPermissions() async {

    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isPermanentlyDenied ||
        statuses[Permission.microphone]!.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _checkAndNavigate() async {

    // স্প্ল্যাশ স্ক্রিন delay
    await Future.delayed(const Duration(seconds: 2, milliseconds: 500));

    final connectivityService = Get.find<ConnectivityService>();

    final List<ConnectivityResult> results =
        await Connectivity().checkConnectivity();

    final bool hasNetwork =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    bool isActuallyOnline = false;

    if (hasNetwork) {
      isActuallyOnline =
          await connectivityService.checkInternetAccess();
    }

    connectivityService.isOnline.value = isActuallyOnline;

    if (!isActuallyOnline) {
      Get.offAll(() => const NoInternetScreen());
      return;
    }

    final String? token =
        StorageUtil.getData(StorageUtil.userAccessToken);

    print('Local Token in Splash: $token');

    if (token != null && token.isNotEmpty) {

      Get.offAllNamed('/dashboard');

      final deepLinkService =
          Get.find<DeepLinkService>();
      deepLinkService.processPendingDeepLink();

    } else {
      Get.offAllNamed('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightThemeColors.blueColor,
      body: Center(
        child: Image.asset(
          Assets.images.appLogo.keyName,
          height: 84.h,
          width: 84.h,
        ),
      ),
    );
  }
}