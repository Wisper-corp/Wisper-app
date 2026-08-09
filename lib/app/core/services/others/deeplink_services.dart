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

    String? targetId;
    String? profileType;

    if (uri.pathSegments.length >= 2) {
      final firstSegment = uri.pathSegments[0].toLowerCase();
      if (firstSegment == 'persons' || firstSegment == 'person') {
        profileType = 'person';
        targetId = uri.pathSegments[1];
      } else if (firstSegment == 'businesses' || firstSegment == 'business') {
        profileType = 'business';
        targetId = uri.pathSegments[1];
      } else if (firstSegment == 'groups' || firstSegment == 'group') {
        profileType = 'group';
        targetId = uri.pathSegments[1];
      }
    }

    if (targetId != null && targetId.isNotEmpty && profileType != null) {
      debugPrint("🔗 Processing deep link → $profileType / $targetId");
      pendingDeepLink.value = null;

      if (profileType == 'group') {
        Get.to(
          () => GroupChatScreen(
            groupId: targetId,
            groupName: '',
            groupImage: '',
            hasJoined: false,
            showHeader: true,
            showTabs: true,
          ),
          transition: Transition.rightToLeft,
        );
      } else {
        Get.offAllNamed('/dashboard');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (profileType == 'person') {
            Get.toNamed('/profile/person/$targetId');
          } else {
            Get.toNamed('/profile/business/$targetId');
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
