import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/modules/calls/views/add_call_screen.dart';
import 'package:wisper/app/modules/calls/widget/call_feature.dart';
import 'package:wisper/gen/assets.gen.dart';

class GroupVideoCallScreen extends StatefulWidget {
  const GroupVideoCallScreen({super.key});

  @override
  State<GroupVideoCallScreen> createState() => _GroupVideoCallScreenState();
}

class _GroupVideoCallScreenState extends State<GroupVideoCallScreen> {
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
              Expanded(
                child: GridView.builder(
                  itemCount: 4,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 4,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(Assets.images.image.keyName),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    );
                  },
                ),
              ),
              heightBox40,
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
              heightBox20,
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
