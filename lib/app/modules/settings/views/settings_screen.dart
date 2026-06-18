import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/chat/widgets/toggle_option.dart';
import 'package:wisper/app/modules/job/views/favorite_job_screen.dart';
import 'package:wisper/app/modules/kyc/views/kyc_screen.dart';
import 'package:wisper/app/modules/post/views/my_post_section.dart';
import 'package:wisper/app/modules/profile/controller/buisness/buisness_controller.dart';
import 'package:wisper/app/modules/profile/controller/person/profile_controller.dart';
import 'package:wisper/app/modules/settings/views/change_password_screen.dart';
import 'package:wisper/app/modules/settings/views/content_screen.dart';
import 'package:wisper/app/modules/profile/views/profile_screen.dart';
import 'package:wisper/app/modules/settings/views/wallet_screen.dart';
import 'package:wisper/app/modules/profile/widget/my_info_card.dart';
import 'package:wisper/app/modules/settings/wigdets/seetings_button.dart';
import 'package:wisper/app/modules/settings/wigdets/seetings_feature_row.dart';
import 'package:wisper/app/modules/settings/wigdets/settings_feature_card.dart';
import 'package:wisper/gen/assets.gen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileController profileController = Get.put(ProfileController());
  final BusinessController businessController = Get.put(BusinessController());

  @override
  Widget build(BuildContext context) {
    var profileImage = StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
        ? profileController.profileData?.auth?.person?.image
        : businessController.buisnessData?.auth?.business?.image;

    var name = StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
        ? profileController.profileData?.auth?.person?.name
        : businessController.buisnessData?.auth?.business?.name;

    var job = StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
        ? profileController.profileData?.auth?.person?.title
        : businessController.buisnessData?.auth?.business?.industry;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBox40,
              Row(
                children: [
                  CircleIconWidget(
                    iconRadius: 14.r,
                    imagePath: Assets.images.arrowBack.keyName,
                    onTap: () {
                      Get.back();
                    },
                  ),
                  widthBox12,
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              heightBox10,
              SeetingsFeatureCard(
                iconPath: Assets.images.person.keyName,
                title: 'Account',
                widget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heightBox10,
                    MyInfoCard(
                      ontap: () {
                        Get.to(() => const ProfileScreen());
                      },
                      imagePath: profileImage ?? '',
                      name: name ?? '',
                      job: job ?? '',
                    ),

                    heightBox20,
                    StraightLiner(height: 0.5),
                    heightBox10,
                    SettingsFeatureRow(
                      title: 'Change Password',
                      onTap: () {
                        Get.to(() => const ChangePasswordScreen());
                      },
                    ),
                    heightBox10,
                    StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StraightLiner(height: 0.5),
                              heightBox10,

                              SettingsFeatureRow(
                                title: 'Favorites',
                                onTap: () { 
                                  Get.to(() => const FavoriteJobScreen());
                                },
                              ),
                              heightBox10,
                            ],
                          )
                        : Container(),
                    // StraightLiner(height: 0.5),
                    // heightBox10,
                    // SettingsFeatureRow( 
                    //   title: 'Connections',
                    //   onTap: () {
                    //     Get.to(() => const ConnectionScreen());
                    //   },
                    // ),
                  ],
                ),
              ),

              heightBox16,
              SeetingsFeatureCard(
                iconPath: Assets.images.adds.keyName,
                title: 'Ads & Analytics',
                widget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Control advertising and data collection preferences',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff999999),
                      ),
                    ),
                    heightBox20,
                    ToggleOption(
                      isToggled: false,
                      title: 'Third-party Data',
                      subtitle: 'Use data from partner companies',
                      onToggle: (bool p1) {},
                    ),
                  ],
                ),
              ),
              heightBox16,
              SeetingsFeatureCard(
                iconPath: Assets.images.adds.keyName,
                title: 'Monetization',
                widget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage your earning and revenue settings',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff999999),
                      ),
                    ),
                    heightBox20,
                    ToggleOption(
                      isToggled: false,
                      title: 'Content Creator Mode',
                      subtitle: 'Enable advanced monetization features',
                      onToggle: (bool p1) {},
                    ),
                    heightBox10,
                    ToggleOption(
                      isToggled: false,
                      title: 'Earn from Posts',
                      subtitle: 'Allow monetization of your content',
                      onToggle: (bool p1) {},
                    ),
                    heightBox10,
                    ToggleOption(
                      isToggled: false,
                      title: 'Sponsored Content',
                      subtitle: 'Enable sponsored post opportunities',
                      onToggle: (bool p1) {},
                    ),
                    heightBox20,
                    StraightLiner(height: 0.5),
                    heightBox10,
                  ],
                ),
              ),
              heightBox16,
              // ========= NEW: Identity & Verification Section =========
              SeetingsFeatureCard(
                iconPath: Assets.images.sheild.keyName,
                title: 'Identity & Verification',
                widget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify your identity and manage security',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff999999),
                      ),
                    ),
                    heightBox20,
                    SettingsFeatureRow(
                      title: 'KYC Verification',
                      subtitle: 'Complete identity verification',
                      onTap: () {
                        Get.to(() => const KycScreen());
                      },
                    ),
                  ],
                ),
              ),
              heightBox16,
              // ========= NEW: Separate Wallet Section =========
              SeetingsFeatureCard(
                iconPath: Assets.images.adds.keyName,
                title: 'Wallet & Payments',
                widget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage your wallet and payment methods',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff999999),
                      ),
                    ),
                    heightBox20,
                    SettingsFeatureRow(
                      title: 'Wallet',
                      subtitle: 'View balance and transactions',
                      onTap: () {
                        Get.to(() => const WalletScreen());
                      },
                    ),
                  ],
                ),
              ),
              heightBox16,
              SeetingsFeatureCard(
                iconPath: Assets.images.notification.keyName,
                title: 'Notifications',
                widget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose what notifications you want to receive',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff999999),
                      ),
                    ),
                    heightBox20,
                    ToggleOption(
                      isToggled: false,
                      title: 'Messages',
                      subtitle: 'New messages and replies',
                      onToggle: (bool p1) {},
                    ),
                    heightBox10,
                    ToggleOption(
                      isToggled: false,
                      title: 'Connections',
                      subtitle: 'New connection requests',
                      onToggle: (bool p1) {},
                    ),
                    heightBox10,
                    ToggleOption(
                      isToggled: false,
                      title: 'Posts',
                      subtitle: 'New posts by your connection',
                      onToggle: (bool p1) {},
                    ),
                  ],
                ),
              ),
              heightBox16,
              SeetingsFeatureCard(
                iconPath: Assets.images.sheild.keyName,
                title: 'Privacy & Security',
                widget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Control who can see your information',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff999999),
                      ),
                    ),
                    heightBox20,
                    StraightLiner(height: 0.5),
                    heightBox10,
                    SettingsFeatureRow(
                      title: 'Privacy Policy',
                      onTap: () {
                        Get.to(() => ContentScreen(title: 'Privacy Policy'));
                      },
                    ),
                    heightBox10,
                    StraightLiner(height: 0.5),
                    heightBox10,
                    SettingsFeatureRow(
                      title: 'Terms & Conditions',
                      onTap: () {
                        Get.to(
                          () => ContentScreen(title: 'Terms & Conditions'),
                        );
                      },
                    ),
                  ],
                ),
              ),

              heightBox16,
              SeetingsFeatureCard(
                iconPath: Assets.images.sheild.keyName,
                title: 'App Preferences',
                widget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heightBox20,
                    ToggleOption(
                      isToggled: true,
                      title: 'Dark Mode',
                      subtitle: 'Switch to dark theme',
                      onToggle: (bool p1) {},
                    ),
                    heightBox10,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              Assets.images.browse.keyName,
                              height: 18.h,
                              width: 18.w,
                              color: Colors.white,
                            ),
                            widthBox8,
                            Text(
                              'Language',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'English',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: LightThemeColors.themeGreyColor,
                              ),
                            ),
                            widthBox8,
                            Image.asset(
                              Assets.images.arrowForwoard.keyName,
                              height: 16.h,
                              width: 16.w,
                              color: LightThemeColors.themeGreyColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                    heightBox10,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              Assets.images.glove.keyName,
                              height: 18.h,
                              width: 18.w,
                            ),
                            widthBox8,
                            Text(
                              'Region',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Bangladesh',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: LightThemeColors.themeGreyColor,
                              ),
                            ),
                            widthBox8,
                            Image.asset(
                              Assets.images.arrowForwoard.keyName,
                              height: 16.h,
                              width: 16.w,
                              color: LightThemeColors.themeGreyColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              heightBox10,
              DetailsCard(
                borderWidth: 0.5,
                width: double.infinity,
                borderColor: Colors.white.withValues(alpha: 0.20),
                bgColor: Color(0xff121212),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      SeetingsButton(
                        onTap: () {
                          _showDeleteUser();
                        },
                        title: 'Delete Account',
                        bgColor: Color(0xffE62047).withValues(alpha: 0.16),
                        borderColor: Colors.transparent,
                        iconPath: Assets.images.delete.keyName,
                      ),
                      heightBox10,
                      SeetingsButton(
                        onTap: () {
                          _showLogout();
                        },
                        title: 'Logout',
                        borderColor: Color(0xffFFFFFF).withValues(alpha: 0.10),
                        bgColor: Colors.transparent,
                        iconPath: Assets.images.logout.keyName,
                      ),
                    ],
                  ),
                ),
              ),
              heightBox30,
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteUser() {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Delete Account?",
      message:
          "Are you sure you want to delete your account?\nThis action cannot be undone.",
      onDelete: () {
        // Add your delete account logic here
      },
      // deleteText: "Delete Account", // optional
      // cancelText: "Keep Account",   // optional
    );
  }

  void _showLogout() {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Logout?",
      message: "Are you sure you want to logout from your account?",
      onDelete: () {
        Get.delete<ProfileController>(force: true);
        StorageUtil.deleteData(StorageUtil.userAccessToken);
        StorageUtil.deleteData(StorageUtil.userId);
        StorageUtil.deleteData(StorageUtil.userRole);
        StorageUtil.deleteData(StorageUtil.userAuthId);
        StorageUtil.clear();

        Get.offAll(() => SignInScreen());
      },
    );
  }
}
