import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/socket/call_services.dart';
import 'package:wisper/app/core/services/socket/pending_banner.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/modules/calls/views/call_screen.dart';
import 'package:wisper/app/modules/chat/views/chat_list_screen.dart';
import 'package:wisper/app/modules/homepage/controller/all_role_controller.dart';
import 'package:wisper/app/modules/job/controller/feed_job_controller.dart';
import 'package:wisper/app/modules/post/controller/feed_post_controller.dart';
import 'package:wisper/app/modules/job/controller/my_job_controller.dart';
import 'package:wisper/app/modules/post/controller/my_post_controller.dart';
import 'package:wisper/app/modules/homepage/views/create_post_screen.dart';
import 'package:wisper/app/modules/homepage/views/home_screen.dart';
import 'package:wisper/app/modules/profile/controller/buisness/buisness_controller.dart';
import 'package:wisper/app/modules/profile/controller/person/profile_controller.dart';
import 'package:wisper/app/modules/profile/views/profile_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class MainButtonNavbarScreen extends StatefulWidget {
  const MainButtonNavbarScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainButtonNavbarScreen> createState() => _MainButtonNavbarScreenState();
}

class _MainButtonNavbarScreenState extends State<MainButtonNavbarScreen>
    with WidgetsBindingObserver {
  late int selectedKey;

  final ProfileController profileController = Get.put(ProfileController());
  final BusinessController businessController = Get.put(BusinessController());
  final SocketService socketService = Get.find<SocketService>();
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();
  final CallService callService = Get.isRegistered<CallService>()
      ? Get.put(CallService())
      : Get.put(CallService());

  final AllFeedPostController allFeedPostController = Get.put(
    AllFeedPostController(),
  );
  final AllFeedJobController allFeedJobController = Get.put(
    AllFeedJobController(),
  );
  final MyFeedJobController myFeedJobController = Get.put(
    MyFeedJobController(),
  );
  final MyFeedPostController myFeedPostController = Get.put(
    MyFeedPostController(),
  );
  final AllRoleController allRoleController = Get.put(AllRoleController());

  final List<Widget> screens = const [
    HomeScreen(),
    CallScreen(),
    CreatePostScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    selectedKey = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    _initializeData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      socketService.onInit();
      callService.checkAndShowPendingCallDialogIfNeeded();
      connectivityService.suppressDialog.value = selectedKey == 3;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      callService.checkAndShowPendingCallDialogIfNeeded();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeData() async {
    allFeedJobController.resetPagination();
    allFeedPostController.resetPagination();
    myFeedJobController.resetPagination();
    myFeedPostController.resetPagination();

    await Future.wait([
      allFeedJobController.getJobs(),
      allFeedPostController.getAllPost(),
      myFeedJobController.getJobs(),
      myFeedPostController.getAllPost(),
      allRoleController.getAllRole(''),
      businessController.getMyProfile(),
      profileController.getMyProfile(),
    ]);
  }

  String _getProfileImageUrl() {
    final role = StorageUtil.getData(StorageUtil.userRole);
    String? url;

    if (role == 'PERSON') {
      url = profileController.profileData?.auth?.person?.image;
    } else {
      url = businessController.buisnessData?.auth?.business?.image;
    }

    if (url == null || url.isEmpty || url == 'null') return '';
    return url;
  }

  @override
  Widget build(BuildContext context) {
    // ── PendingCallBanner দিয়ে পুরো screen wrap করো ──
    // Background/terminated থেকে call accept হলে এখানে banner দেখাবে
    return PendingCallBanner(
      child: Scaffold(
        body: IndexedStack(index: selectedKey, children: screens),
        bottomNavigationBar: Container(
          height: 80.h,
          color: const Color(0xff121212),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                selectedIcon: Assets.images.home.keyName,
                unselectedIcon: Assets.images.unselectedHome.keyName,
                label: "Home",
              ),
              _buildNavItem(
                index: 1,
                selectedIcon: Assets.images.selectedCall.keyName,
                unselectedIcon: Assets.images.call.keyName,
                label: "Call",
              ),
              _buildNavItem(
                index: 2,
                height: 50.h,
                width: 56.h,
                selectedIcon: Assets.images.frame5313.keyName,
                unselectedIcon: Assets.images.frame5313.keyName,
                label: "",
              ),
              _buildNavItem(
                index: 3,
                selectedIcon: Assets.images.unselectedChat.keyName,
                unselectedIcon: Assets.images.selectedChat.keyName,
                label: "Chat",
              ),
              Obx(() => _buildProfileNavItem(index: 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String selectedIcon,
    required String unselectedIcon,
    required String label,
    double? height,
    double? width,
  }) {
    final bool isSelected = selectedKey == index;

    return GestureDetector(
      onTap: () {
        if (selectedKey != index) {
          setState(() => selectedKey = index);
          connectivityService.suppressDialog.value = selectedKey == 3;
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CrashSafeImage(
              isSelected ? selectedIcon : unselectedIcon,
              height: height ?? 24.h,
              width: width ?? 24.h,
            ),
            SizedBox(height: 4.h),
            label == ''
                ? const SizedBox()
                : Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xff98A2B3),
                      fontSize: 12.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem({required int index}) {
    final bool isSelected = selectedKey == index;
    final String imageUrl = _getProfileImageUrl();

    return GestureDetector(
      onTap: () {
        if (selectedKey != index) setState(() => selectedKey = index);
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            heightBox8,
            CircleAvatar(
              radius: 14.r,
              backgroundColor: const Color(0xff2A2A2A),
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl) as ImageProvider
                  : null,
              child: imageUrl.isEmpty
                  ? Icon(Icons.person, size: 18.r, color: Colors.white70)
                  : null,
            ),
            SizedBox(height: 4.h),
            Text(
              "Profile",
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xff98A2B3),
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
