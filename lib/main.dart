

import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:wisper/app/core/others/app_binder.dart';
import 'package:wisper/app/core/config/theme/my_theme.dart';
import 'package:wisper/app/core/config/translations/localization_service.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/others/deeplink_services.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/utils/no_inter_screen.dart';

import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';
import 'package:wisper/app/modules/onboarding/views/onboarding_view.dart';
import 'package:wisper/app/modules/onboarding/views/splash_screen.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';
import 'package:wisper/app/modules/chat/views/group/group_message_screen.dart';

import 'package:smile_id/smile_id.dart';
import 'package:wisper/firebase_options.dart';
import 'package:wisper/push_notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A build failure in release renders an unpainted grey box, which on a dark
  // theme reads as "the app is blank" and says nothing about why. Show the
  // reason instead: a screenshot of it is worth more than a black screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    return Material(
      color: const Color(0xff121212),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Something went wrong on this screen.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                details.exceptionAsString(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Initialize SmileID SDK
  SmileID.initialize(useSandbox: false, enableCrashReporting: false);

  // Local set-up only. Nothing above runApp may touch the network: the first
  // frame cannot be drawn until main() reaches runApp, so anything that waits
  // on a server holds the screen black for exactly as long as it waits.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await StorageUtil.init();

  Get.put(SocketService());
  Get.put(ConnectivityService());
  Get.put(DeepLinkService());

  // A platform-channel round trip the first frame has no reason to wait on.
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]));

  // Sockets, the FCM token and the notification handlers all reach the
  // network. They start once the UI exists.
  unawaited(_startServices());

  {
    runApp(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        builder: (context, widget) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            Get.find<DeepLinkService>().initDeepLinks();
          });

          return GetMaterialApp(
            initialBinding: ControllerBinder(),
            debugShowCheckedModeBanner: false,
            theme: MyTheme.getThemeData(isLight: true),
            darkTheme: MyTheme.getThemeData(isLight: false),
            themeMode: StorageUtil.isLightTheme()
                ? ThemeMode.light
                : ThemeMode.dark,
            initialRoute: '/',
            getPages: [
              GetPage(name: '/', page: () => const SplashScreen()),
              GetPage(name: '/dashboard', page: () => const MainButtonNavbarScreen()),
              GetPage(name: '/onboarding', page: () => const OnboardingView()),
              GetPage(
                name: '/profile/person/:id',
                page: () => OthersPersonScreen(
                  userId: Get.parameters['id'] ?? '',
                ),
              ),
              GetPage(
                name: '/profile/business/:id',
                page: () => OthersBusinessScreen(
                  userId: Get.parameters['id'] ?? '',
                ),
              ),
              GetPage(
                name: '/groups/:id',
                page: () => GroupChatScreen(
                  groupId: Get.parameters['id'] ?? '',
                  chatId: Get.parameters['id'] ?? '',
                  groupName: 'Group',
                  groupImage: '',
                ),
              ),
              GetPage(name: '/no-internet', page: () => const NoInternetScreen()),
            ],
            locale: StorageUtil.getLocale(),
            translations: LocalizationService.getInstance(),
          );
        },
      ),
    );
  }
}

/// Everything that talks to a server, started after the first frame.
///
/// This used to run before runApp. On a first launch there is no cached FCM
/// token, so getToken() makes a network round trip -- and with no timeout, a
/// slow or blocked connection held the screen black until it finished. The
/// second launch read the cached token and returned at once, which is why the
/// app only ever looked broken the first time it was opened.
Future<void> _startServices() async {
  try {
    await Get.find<SocketService>().init();
  } catch (e) {
    debugPrint('🔌 Socket init failed (non-fatal): $e');
  }

  // Before the token, not after. This asks for the notification permission,
  // and it used to sit behind a token fetch that is allowed twenty seconds --
  // so on a first install the prompt could arrive long after the user had
  // moved on, or not at all. Nothing here needs the token.
  try {
    // Registers the FCM background handler, which nothing else does.
    await PushNotificationService().init();
  } catch (e) {
    debugPrint('🔥 Notification init failed (non-fatal): $e');
  }

  await _initFCMToken();
}

Future<void> _initFCMToken() async {
  try {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Bounded on purpose: an unbounded getToken() is what made a first launch
    // hang. A missing token costs notifications until the next launch, which
    // is survivable; a hang costs the whole app.
    final fcmToken = await FirebaseMessaging.instance
        .getToken()
        .timeout(const Duration(seconds: 20));
    debugPrint("✅ FCM Token: $fcmToken");
  } catch (e) {
    debugPrint("❌ FCM Token Error: $e");
  }
}