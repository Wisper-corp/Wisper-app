import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/homepage/views/chat_section.dart';
import 'package:wisper/app/modules/homepage/views/community_section.dart';
import 'package:wisper/app/modules/homepage/views/role_section.dart';
import 'package:wisper/app/modules/job/views/job_section.dart';
import 'package:wisper/app/modules/post/views/post_section.dart';
import 'package:wisper/app/modules/homepage/views/search_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          children: [
            heightBox40,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Explore',
                  style: TextStyle(
                    fontFamily: "Segoe UI",
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    CircleIconWidget(
                      imagePath: Assets.images.search.keyName,
                      onTap: () {
                        Get.to(() => SearchScreen());
                      },
                      iconRadius: 18.r,
                    ),
                  ],
                ),
              ],
            ),

            heightBox12,
            SizedBox(
              height: 30.h,
              width: double.infinity,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = 0;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'General Chat', 
                          style: TextStyle(
                            fontFamily: "Segoe UI",
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: selectedIndex == 0
                                ? Colors.white
                                : Color(0xff93A4B0),
                          ),
                        ),
                        heightBox4,
                        Container(
                          height: 2.h,
                          width: 90.w,
                          color: selectedIndex == 0
                              ? Colors.blue
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  widthBox20,
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = 1;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'Posts',
                          style: TextStyle(
                            fontFamily: "Segoe UI",
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: selectedIndex == 1
                                ? Colors.white
                                : Color(0xff93A4B0),
                          ),
                        ),
                        heightBox4,
                        Container(
                          height: 2.h,
                          width: 40.w,
                          color: selectedIndex == 1
                              ? Colors.blue
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  widthBox20,
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = 2;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'Jobs',
                          style: TextStyle(
                            fontFamily: "Segoe UI",
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: selectedIndex == 2
                                ? Colors.white
                                : Color(0xff93A4B0),
                          ),
                        ),
                        heightBox4,
                        Container(
                          height: 2.h,
                          width: 40.w,
                          color: selectedIndex == 2
                              ? Colors.blue
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  widthBox20,
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = 3;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'Role',
                          style: TextStyle(
                            fontFamily: "Segoe UI",
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: selectedIndex == 3
                                ? Colors.white
                                : Color(0xff93A4B0),
                          ),
                        ),
                        heightBox4,
                        Container(
                          height: 2.h,
                          width: 40.w,
                          color: selectedIndex == 3
                              ? Colors.blue
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  widthBox20,
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = 4;
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          'Community',
                          style: TextStyle(
                            fontFamily: "Segoe UI",
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: selectedIndex == 4
                                ? Colors.white
                                : Color(0xff93A4B0),
                          ),
                        ),
                        heightBox4,
                        Container(
                          height: 2.h,
                          width: 78.w,
                          color: selectedIndex == 4
                              ? Colors.blue
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            StraightLiner(height: 0.4, color: Color(0xff454545)),

            heightBox14,
            selectedIndex == 0 ? ChatSection() : Container(),
            selectedIndex == 1 ? PostSection() : Container(),
            selectedIndex == 2 ? JobSection() : Container(),
            selectedIndex == 3 ? RoleSection() : Container(),
            selectedIndex == 4 ? CommunitySection() : Container(),
          ],
        ),
      ),
    );
  }
}
