import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/homepage/views/chat_section.dart';
import 'package:wisper/app/modules/homepage/views/community_section.dart';
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

  // Tab config - Role tab hidden until 5k users
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Announcement', 'width': 110.0},
    {'label': 'Gig Market',   'width': 80.0},
    {'label': 'Jobs',         'width': 40.0},
    // Role tab hidden: {'label': 'Members', 'width': 60.0},
    {'label': 'Community',    'width': 78.0},
  ];

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
 
            // ── Dummy Members Row ────────────────────────────────────────
            _buildDummyMembersRow(),
            heightBox12,

            SizedBox(
              height: 30.h,
              width: double.infinity,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => widthBox20,
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIndex = index),
                    child: Column(
                      children: [
                        Text(
                          tab['label'] as String,
                          style: TextStyle(
                            fontFamily: "Segoe UI",
                            fontSize: index == 0 ? 15.sp : 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xff93A4B0),
                          ),
                        ),
                        heightBox4,
                        Container(
                          height: 2.h,
                          width: (tab['width'] as double).w,
                          color: isSelected
                              ? Colors.blue
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            StraightLiner(height: 0.4, color: const Color(0xff454545)),


            // 0=Announcement 1=Gig Market 2=Jobs 3=Community
            // Role tab hidden - will re-enable at 5k users
            if (selectedIndex == 0) const ChatSection(),
            if (selectedIndex == 1) const PostSection(),
            if (selectedIndex == 2) const JobSection(),
            if (selectedIndex == 3) const CommunitySection(),
            if (selectedIndex > 3) Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildDummyMembersRow() {
    final List<Color> colors = [
      const Color(0xff1F7DE9),
      const Color(0xff11AE46),
      const Color(0xff9B59B6),
      const Color(0xffE74C3C),
      const Color(0xffF39C12),
    ];
    final List<String> initials = ['S', 'A', 'K', 'J', 'M'];
    const double size = 28;
    const double overlap = 16;
    const int count = 5;

    return Row(
      children: [
        SizedBox(
          width: size + (count - 1) * (size - overlap),
          height: size,
          child: Stack(
            children: List.generate(count, (i) {
              return Positioned(
                left: i * (size - overlap).toDouble(),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[i],
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      initials[i],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '23.8K members',
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
