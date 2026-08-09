import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/modules/chat/views/group/group_message_screen.dart';

class DeepLinkService extends GetxService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  final Rx<Uri?> pendingDeepLink = Rx<Uri?>(null);

  Future<void> initDeepLinks() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleIncomingLink(initialLink);
    }

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

    // If user is already logged in, process immediately
    final token = StorageUtil.getData(StorageUtil.userAccessToken);
    if (token != null && token.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        processPendingDeepLink();
      });
    }
  }

  void processPendingDeepLink() {
    final uri = pendingDeepLink.value;
    if (uri == null) return;

    String? groupId;
    String? profileType;

    if (uri.pathSegments.length >= 2) {
      final firstSegment = uri.pathSegments[0].toLowerCase();
      if (firstSegment == 'persons' || firstSegment == 'person') {
        profileType = 'person';
        groupId = uri.pathSegments[1];
      } else if (firstSegment == 'businesses' || firstSegment == 'business') {
        profileType = 'business';
        groupId = uri.pathSegments[1];
      } else if (firstSegment == 'groups' || firstSegment == 'group') {
        profileType = 'group';
        groupId = uri.pathSegments[1];
      }
    }

    if (groupId != null && groupId.isNotEmpty && profileType != null) {
      debugPrint("🔗 Processing deep link → $profileType / $groupId");
      pendingDeepLink.value = null;

      if (profileType == 'group') {
        // Navigate to group — no offAllNamed so existing stack stays
        Get.to(
          () => GroupChatScreen(
            groupId: groupId,
            groupName: '',
            groupImage: '',
            hasJoined: false,
            showHeader: true,
            showTabs: true,
          ),
          transition: Transition.rightToLeft,
        );
      } else {
        // For person/business — navigate to dashboard first then profile
        Get.offAllNamed('/dashboard');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (profileType == 'person') {
            Get.toNamed('/profile/person/$groupId');
          } else {
            Get.toNamed('/profile/business/$groupId');
          }
        });
      }
    } else {
      debugPrint("❌ Invalid deep link format: $uri");
      pendingDeepLink.value = null;
    }
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}

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

      Future.delayed(const Duration(milliseconds: 500), () {
        if (profileType == 'person') {
          Get.toNamed('/profile/person/$userId');
        } else if (profileType == 'business') {
          Get.toNamed('/profile/business/$userId');
        } else if (profileType == 'group') {
          // Navigate directly to GroupChatScreen with groupId
          Get.to(
            () => GroupChatScreen(
              groupId: userId,
              groupName: '',
              groupImage: '',
              hasJoined: false, // will check membership inside
            ),
            transition: Transition.rightToLeft,
          );
        }
      });
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