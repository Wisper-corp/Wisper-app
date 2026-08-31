

// SplashScreen.dart - Updated with Camera & Mic permission
// বাকি সব অপরিবর্তিত রাখা হয়েছে

import 'dart:async';

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
    // Permissions must never gate the splash. Each one opens a system
    // dialog on a fresh install, and this used to be awaited -- so the app
    // sat on the logo until every dialog had been answered, and for good if
    // one was left standing or the app was backgrounded while it was up. A
    // second launch already has the answers and returns at once, which is
    // exactly why the app only ever hung the very first time it was opened.
    unawaited(_requestPermissions());

    /// এরপর original flow
    await _checkAndNavigate();
  }

  Future<void> _requestPermissions() async {
    // A moment first, so the prompt lands on a drawn frame rather than a
    // bare one. Nothing waits on the result, so the delay costs nothing.
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      await [
        Permission.camera,
        Permission.microphone,
        // Android 13 and up delivers nothing without this, and it can only
        // be asked for while the app is in front -- which is here.
        Permission.notification,
      ].request();
    } catch (e) {
      // A refused or unanswered prompt costs that one feature until the
      // user grants it later. It must never cost the launch.
      debugPrint('Permission request did not complete: $e');
    }
    // Never open system settings automatically — user can grant later when needed
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

      // If deep link already processed (hot start), skip dashboard navigation
      final deepLinkService = Get.find<DeepLinkService>();
      if (deepLinkService.deepLinkProcessed) {
        // Deep link already navigated — don't overwrite with dashboard
        deepLinkService.deepLinkProcessed = false;
        return;
      }

      Get.offAllNamed('/dashboard');

      // Wait for dashboard to fully render before processing deep link
      Future.delayed(const Duration(milliseconds: 1000), () {
        deepLinkService.processPendingDeepLink();
      });

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