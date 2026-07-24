import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/chat/views/group/group_message_screen.dart';
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
  static const String _generalChatId = 'd3139d42-5671-41d1-9824-6162be10125a';
  static const String _generalGroupId = 'd3139d42-5671-41d1-9824-6162be10125a';
  final SocketService socketService = Get.find<SocketService>();

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

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
                  _buildTab('General Chat', 0, 90.w),
                  widthBox20,

                  _buildTab('Posts', 1, 40.w),
                  widthBox20,

                  _buildTab('Jobs', 2, 40.w),
                  widthBox20,

                  _buildTab('Role', 3, 40.w),
                  widthBox20,
                  _buildTab('Community', 4, 78.w),
                ],
              ),
            ),
            StraightLiner(height: 0.4, color: const Color(0xff454545)),
            heightBox14,

            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: [
                  // Tab 0: General Chat
                  SizedBox.expand(
                    child: Obx(() {
                      final generalChat = _resolveGeneralChat();
                      final chatId = (generalChat?['id'] ?? _generalChatId)
                          .toString();
                      final groupId =
                          (generalChat?['groupId'] ?? _generalGroupId)
                              .toString();
                      final groupImage = (generalChat?['group']?['image'] ?? '')
                          .toString();

                      if (chatId.isEmpty || groupId.isEmpty) {
                        return const Center(
                          child: Text(
                            'General Chat is not configured',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return GroupChatScreen(
                        key: ValueKey('home_general_chat_$chatId'),
                        isGeneralChat: true,
                        chatId: chatId,
                        groupId: groupId,
                        groupName: 'General Chat',
                        groupImage: groupImage,
                      );
                    }),
                  ),

                  // Tab 1: Posts
                  const SizedBox.expand(child: PostSection()),

                  // Tab 2: Jobs
                  const SizedBox.expand(child: JobSection()),

                  // Tab 3: Role
                  const SizedBox.expand(child: RoleSection()),

                  // Tab 4: Community
                  const SizedBox.expand(child: CommunitySection()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _resolveGeneralChat() {
    for (final item in socketService.socketFriendList) {
      final type = (item['type'] ?? '').toString().toUpperCase();
      if (type != 'GROUP') continue;

      final id = (item['id'] ?? '').toString();
      final groupId = (item['groupId'] ?? '').toString();
      final classId = (item['classId'] ?? '').toString();
      final group = item['group'];
      final groupName = (item['group']?['name'] ?? '').toString();
      final bool looksLikeSystemGeneralGroup =
          id.isNotEmpty &&
          groupId == id &&
          classId.isEmpty &&
          (group == null || groupName.isEmpty);

      if (id == _generalChatId ||
          groupId == _generalGroupId ||
          groupName.toLowerCase() == 'general chat' ||
          looksLikeSystemGeneralGroup) {
        return item;
      }
    }
    return null;
  }

  Widget _buildTab(String label, int index, double underlineWidth) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: "Segoe UI",
              fontSize: index == 0 ? 15.sp : 14.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xff93A4B0),
            ),
          ),
          heightBox4,
          Container(
            height: 2.h,
            width: underlineWidth,
            color: isSelected ? Colors.blue : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
