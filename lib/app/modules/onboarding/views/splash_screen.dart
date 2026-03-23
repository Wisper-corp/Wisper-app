import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/others/deeplink_services.dart';
import 'package:wisper/app/core/services/socket/call_services.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/utils/no_inter_screen.dart';
import 'package:wisper/gen/assets.gen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startFlow();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('Splash → Lifecycle changed to: $state');

    if (state == AppLifecycleState.resumed) {
      print('Splash → App resumed → checking pending call dialog');
      try {
        final callService = Get.isRegistered<CallService>()
            ? Get.find<CallService>()
            : Get.put(CallService());
        callService.checkAndShowPendingCallDialogIfNeeded();
      } catch (e) {
        print('Error finding SocketService in splash: $e');
      }
    }
  }

  Future<void> _startFlow() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _requestPermissions();
    await _checkAndNavigate();

    // Extra safety: splash শেষে চেক
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final callService = Get.isRegistered<CallService>()
          ? Get.find<CallService>()
          : Get.put(CallService());
      callService.checkAndShowPendingCallDialogIfNeeded();
    } catch (e) {
      print('SocketService not found yet in splash _startFlow');
    }
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
    await Future.delayed(const Duration(seconds: 2, milliseconds: 500));

    final connectivityService = Get.find<ConnectivityService>();
    final List<ConnectivityResult> results =
        await Connectivity().checkConnectivity();
    final bool hasNetwork =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    bool isActuallyOnline = false;
    if (hasNetwork) {
      isActuallyOnline = await connectivityService.checkInternetAccess();
    }

    connectivityService.isOnline.value = isActuallyOnline;

    if (!isActuallyOnline) {
      Get.offAll(() => const NoInternetScreen());
      return;
    }

    final String? token = StorageUtil.getData(StorageUtil.userAccessToken);
    print('Local Token in Splash: $token');

    if (token != null && token.isNotEmpty) {
      Get.offAllNamed('/dashboard');
      final deepLinkService = Get.find<DeepLinkService>();
      deepLinkService.processPendingDeepLink();
    } else {
      Get.offAllNamed('/onboarding');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightThemeColors.blueColor,
      body: Center(
        child: CrashSafeImage(
          Assets.images.appLogo.keyName,
          height: 84.h,
          width: 84.h,
        ),
      ),
    );
  }
}
