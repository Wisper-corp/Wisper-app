import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wisper/app/core/others/app_binder.dart';
import 'package:wisper/app/core/config/theme/my_theme.dart';
import 'package:wisper/app/core/config/translations/localization_service.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/local_cache/chat_cache_service.dart';
import 'package:wisper/app/core/services/others/deeplink_services.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/utils/no_inter_screen.dart';
 
import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';
import 'package:wisper/app/modules/onboarding/views/onboarding_view.dart';
import 'package:wisper/app/modules/onboarding/views/splash_screen.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';

import 'package:wisper/firebase_options.dart';
import 'package:wisper/push_notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hot restart can re-run `main()` while the native FirebaseApp instance still
  // exists, causing `[core/duplicate-app]` for the default app.
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) { 
      if (e.code != 'duplicate-app') rethrow;
    }
  }

  await StorageUtil.init();
  // Local cache init (Hive).
  await Hive.initFlutter();
  await ChatCacheService.init();

  // ── SocketService init ──
  // _setupCallkitListeners() এখন SocketService.init() এর ভেতরেই আছে
  // সেখানে সব callkit event handle হবে — terminated, background, foreground সব
  final SocketService socketService = Get.put(SocketService());
  await socketService.init();

  await Future.delayed(const Duration(milliseconds: 300));

  // ── Push Notification init ──
  await PushNotificationService().init(
    onTap: (route) {
      if (route != null && route.isNotEmpty) {
        Get.toNamed(route);
      }
    },
  );

  Get.put(ConnectivityService());
  Get.put(DeepLinkService());

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
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
              GetPage(
                name: '/dashboard',
                page: () => const MainButtonNavbarScreen(),
              ),
              GetPage(name: '/onboarding', page: () => const OnboardingView()),
              GetPage(
                name: '/profile/person/:id',
                page: () =>
                    OthersPersonScreen(userId: Get.parameters['id'] ?? ''),
              ),
              GetPage(
                name: '/profile/business/:id',
                page: () =>
                    OthersBusinessScreen(userId: Get.parameters['id'] ?? ''),
              ),
              GetPage(
                name: '/no-internet',
                page: () => const NoInternetScreen(),
              ),
            ],
            locale: StorageUtil.getLocale(),
            translations: LocalizationService.getInstance(),
          );
        },
      ),
    );
  });
}
