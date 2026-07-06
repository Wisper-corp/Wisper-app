import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/modules/homepage/views/connection_screen.dart';
import 'package:wisper/app/modules/chat/controller/all_connection_controller.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/urls.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/gen/assets.gen.dart';

class InfoCard extends StatelessWidget {
  final bool? isEditImage;
  final String imagePath;
  final VoidCallback editOnTap;
  final String title;
  final String memberInfo;
  final Widget child;
  final bool isTrailing;
  final VoidCallback? trailingOnTap;
  final GlobalKey? trailingKey;
  final VoidCallback? showMember;
  final bool? isBack;
  final bool? isShowNotification;

  const InfoCard({
    super.key,
    required this.imagePath,
    required this.editOnTap,
    required this.title,
    required this.memberInfo,
    required this.child,
    this.isTrailing = true,
    this.trailingOnTap,
    this.trailingKey,
    this.showMember,
    this.isEditImage = true,
    this.isBack = false,
    this.isShowNotification,
  });

  // Helper to safely determine the correct ImageProvider and whether it's default
  ({ImageProvider provider, bool isDefault}) _getImageInfo(
    String path,
    String defaultAsset,
  ) {
    if (path.isEmpty) {
      return (provider: AssetImage(defaultAsset), isDefault: true);
    }

    // Local file path
    if (path.startsWith('/') ||
        path.contains('/storage/') ||
        path.contains('/data/')) {
      final file = File(path);
      if (file.existsSync()) {
        return (provider: FileImage(file), isDefault: false);
      }
    }

    // Network URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return (provider: NetworkImage(path), isDefault: false);
    }

    // Fallback to default asset
    return (provider: AssetImage(defaultAsset), isDefault: true);
  }

  @override
  Widget build(BuildContext context) {
    final String defaultAsset = Assets.images.person.keyName;
    final imageInfo = _getImageInfo(imagePath, defaultAsset);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: const Color(0xff121212),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 20.h),
        child: Stack(
          children: [
            // Left button (back arrow)
            if (isBack == true)
              Positioned(
                left: 10.w,
                top: 0,
                child: CircleIconWidget(
                  radius: 14,
                  iconRadius: 14,
                  imagePath: Assets.images.arrowBack.keyName,
                  onTap: () => Navigator.pop(context),
                ),
              ),

            // Right buttons (notification + more)
            if (isTrailing == true)
              Positioned(
                right: 10.w,
                top: 0,
                child: Row(
                  children: [
                    isShowNotification == true
                        ? _NotificationBell()
                        : Container(),
                    widthBox10,
                    CircleIconWidget(
                      key: trailingKey,
                      radius: 14,
                      iconRadius: 18,
                      imagePath: Assets.images.moreHor.keyName,
                      onTap: trailingOnTap ?? () {},
                    ),
                  ],
                ),
              ),

            // Centered profile content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40.r,
                        backgroundColor: Colors.grey.shade800,
                        child: Padding(
                          padding: EdgeInsets.all(
                            imageInfo.isDefault ? 12.0.r : 0.0,
                          ),
                          child: imageInfo.isDefault
                              ? InitialsAvatar(
                                  name: title,
                                  imageUrl: null,
                                  radius: 40.r,
                                  fontSize: 22,
                                )
                              : CircleAvatar(
                                  radius: 40.r,
                                  backgroundImage: imageInfo.provider,
                                  backgroundColor: Colors.transparent,
                                ),
                        ),
                      ),
                      if (isEditImage == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleIconWidget(
                            color: const Color(0xff3C90CB),
                            iconColor: Colors.white,
                            iconRadius: 10,
                            radius: 10,
                            imagePath: Assets.images.edit.keyName,
                            onTap: editOnTap,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: 200.w,
                    child: Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: showMember ?? () {},
                    child: SizedBox(
                      width: 200.w,
                      child: Center(
                        child: Text(
                          memberInfo,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: LightThemeColors.themeGreyColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bell icon with a red badge showing pending connection request count
class _NotificationBell extends StatefulWidget {
  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  late final AllConnectionController _connectionController;
  final RxInt _pendingCount = 0.obs;

  @override
  void initState() {
    super.initState();
    try {
      _connectionController = Get.find<AllConnectionController>();
    } catch (_) {
      _connectionController = Get.put(AllConnectionController());
    }
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final NetworkResponse response = await Get.find<NetworkCaller>().getRequest(
        '${Urls.baseUrl}/notifications/unseen-count',
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );
      if (response.isSuccess && response.responseData != null) {
        final count = response.responseData['data']?['count'] ?? 
                      response.responseData['count'] ?? 0;
        _pendingCount.value = count is int ? count : int.tryParse(count.toString()) ?? 0;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => const ConnectionScreen());
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleIconWidget(
            radius: 14,
            iconRadius: 18,
            imagePath: Assets.images.notification.keyName,
            onTap: () {
              Get.to(() => const ConnectionScreen());
            },
          ),
          Obx(() {
            if (_pendingCount.value <= 0) return const SizedBox.shrink();
            return Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    _pendingCount.value > 99 ? '99+' : '${_pendingCount.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
