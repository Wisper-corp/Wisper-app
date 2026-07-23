import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeepLinkService extends GetxService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription; 

  // Pending deep link সেভ করার জন্য
  final Rx<Uri?> pendingDeepLink = Rx<Uri?>(null);

  Future<void> initDeepLinks() async {
    // Cold start: অ্যাপ খোলার সময় যদি deep link দিয়ে আসে
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleIncomingLink(initialLink);
    }

    // Hot start: অ্যাপ চলার সময় deep link আসলে
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (uri != null) {
          _handleIncomingLink(uri);
        }
      },
      onError: (err) => debugPrint("DeepLink error: $err"),
    );
  }

  void _handleIncomingLink(Uri uri) {
    debugPrint("🔗 DeepLink received: $uri");
    pendingDeepLink.value = uri;
    // এখানে আর কোনো নেভিগেশন করা হবে না
    // স্প্ল্যাশ/অথেন্টিকেশন থেকে হ্যান্ডেল করা হবে
  }

  /// স্প্ল্যাশ স্ক্রিন থেকে কল করতে হবে (লগইন সফল হলে)
  void processPendingDeepLink() {
    final uri = pendingDeepLink.value;
    if (uri == null) return;

    String? userId;
    String? profileType;
 
    // প্যাথ পার্স করা
    if (uri.pathSegments.length >= 2) {
      final firstSegment = uri.pathSegments[0].toLowerCase();

      if (firstSegment == 'persons' || firstSegment == 'person') {
        profileType = 'person';
        userId = uri.pathSegments[1];
      } else if (firstSegment == 'businesses' || firstSegment == 'business') {
        profileType = 'business';
        userId = uri.pathSegments[1];
      } else if (firstSegment == 'groups' || firstSegment == 'group') {
        profileType = 'group';
        userId = uri.pathSegments[1];
      }
    }

    if (userId != null && userId.isNotEmpty && profileType != null) {
      debugPrint("Processing pending deep link → $profileType / $userId");

      Get.offAllNamed('/dashboard');

      if (profileType == 'person') {
        Get.toNamed('/profile/person/$userId');
      } else if (profileType == 'business') {
        Get.toNamed('/profile/business/$userId');
      } else if (profileType == 'group') {
        Get.toNamed('/groups/$userId');
      }
    } else {
      debugPrint("❌ Invalid deep link format: $uri");
    }

    // পরিষ্কার করে দাও
    pendingDeepLink.value = null;
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}