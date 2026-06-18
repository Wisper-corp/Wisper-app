import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/modules/calls/views/add_call_screen.dart';
import 'package:wisper/app/modules/calls/widget/call_feature.dart';
import 'package:wisper/app/modules/calls/widget/connected_member.dart';
import 'package:wisper/gen/assets.gen.dart';

class GroupAudioCallScreen extends StatefulWidget {
  const GroupAudioCallScreen({super.key});

  @override
  State<GroupAudioCallScreen> createState() => _GroupAudioCallScreenState();
}

class _GroupAudioCallScreenState extends State<GroupAudioCallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 0, 0),
              Color.fromARGB(255, 0, 0, 0),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        height: double.infinity,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              heightBox30,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.expand, color: Colors.white, size: 20),
                  Column(
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            Assets.images.userGroup.path,
                            height: 24.h,
                            color: LightThemeColors.blueColor,
                          ),
                          widthBox8,
                          Text(
                            'Group Call',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      Text(
                        '0:15',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: LightThemeColors.blueColor,
                        ),
                      ),
                    ],
                  ),
                  Image.asset(
                    Assets.images.userGroup.path,
                    height: 20.h,
                    color: Colors.white,
                  ),
                ],
              ),
              heightBox10,
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50.r),
                  color: Colors.white.withValues(alpha: 0.20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4,
                  ),
                  child: Text(
                    '4 perticipants',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              heightBox10,
              Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    child: Container(
                      height: 105,
                      width: 105,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(Assets.images.image.path),
                          fit: BoxFit.cover,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50.r),
                        color: LightThemeColors.blueColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4,
                        ),
                        child: Center(
                          child: Text(
                            'Speaking..',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              heightBox10,
              Text(
                'Aminul Islam',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              Text(
                'Connected',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff05DF72),
                ),
              ),

              heightBox16,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConnectedMember(),
                  widthBox10,
                  ConnectedMember(),
                  widthBox10,
                  ConnectedMember(),
                ],
              ),
              heightBox200,
              heightBox100,

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CallFeature(
                    radius: 24,
                    onTap: () {},
                    imagePath: Assets.images.mic.keyName,
                  ),
                  widthBox20,
                  CallFeature(
                    radius: 24,
                    onTap: () {},
                    imagePath: Assets.images.mic.keyName,
                  ),
                  widthBox20,
                  CallFeature(
                    radius: 24,
                    color: Colors.red,
                    onTap: () {},
                    imagePath: Assets.images.callOff.keyName,
                  ),
                  widthBox20,
                  CallFeature(
                    radius: 24,
                    onTap: () {},
                    imagePath: Assets.images.userAdd.keyName,
                  ),
                  widthBox20,
                  CallFeature(
                    radius: 24,

                    onTap: () {},
                    imagePath: Assets.images.unselectedChat.keyName,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGroupCall() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return AddCallScreen();
      },
    );
  }
}
