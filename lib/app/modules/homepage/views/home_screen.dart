import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/homepage/views/chat_section.dart';
import 'package:wisper/app/modules/homepage/views/community_section.dart';
import 'package:wisper/app/modules/job/views/job_section.dart';
import 'package:wisper/app/modules/post/views/post_section.dart';
import 'package:wisper/app/modules/homepage/views/search_screen.dart';
import 'package:wisper/app/modules/chat/views/group/group_message_screen.dart';
import 'package:wisper/app/urls.dart';
import 'package:wisper/gen/assets.gen.dart';

// General/Announcement chat ID (matches GENERAL_CHAT_ID in server .env)
const String _kGeneralChatId = '7d1256e7-ad1e-4fd9-ad4b-53dec78b6cb9';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Real member data
  final RxList<Map<String, dynamic>> _memberAvatars = <Map<String, dynamic>>[].obs;
  final RxInt _totalUsers = 0.obs;

  @override
  void initState() {
    super.initState();
    _fetchMemberData();
  }

  Future<void> _fetchMemberData() async {
    try {
      // Fetch a large batch so we can find at least 5 with real photos
      final res = await Get.find<NetworkCaller>().getRequest(
        '${Urls.roleUrl}?limit=50',
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );
      if (res.isSuccess && res.responseData != null) {
        final data = res.responseData;
        final meta = data['data']?['meta'];
        final total = meta?['total'] ?? 0;
        _totalUsers.value = total is int ? total : int.tryParse(total.toString()) ?? 0;

        final roles = data['data']?['roles'] as List? ?? [];

        // Only pick users who actually have a profile photo
        final withImages = <Map<String, dynamic>>[];
        for (final r in roles) {
          final person = r['person'];
          final business = r['business'];
          final name = (person?['name'] ?? business?['name'] ?? '').toString().trim();
          final image = (person?['image'] ?? business?['image'] ?? '').toString().trim();
          if (image.isNotEmpty) {
            withImages.add({'name': name.isEmpty ? '?' : name, 'image': image});
            if (withImages.length == 5) break;
          }
        }

        if (withImages.isNotEmpty) {
          _memberAvatars.value = withImages;
        }
      }
    } catch (e) {
      debugPrint('[MemberAvatars] fetch error: $e');
    }
  }

  /// Format count: real users × 10 (10 signups = 100, 100 = 1K, 1000 = 10K)
  String _formatMemberCount(int realUsers) {
    final computed = realUsers * 10;
    if (computed >= 1000000) return '${(computed / 1000000).toStringAsFixed(1)}M';
    if (computed >= 1000) return '${(computed / 1000).toStringAsFixed(1)}K';
    return computed.toString();
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

            heightBox8,

            // 0=Announcement 1=Gig Market 2=Jobs 3=Community
            // Announcement tab embeds the general group chat directly
            if (selectedIndex == 0) Expanded(
              child: GroupChatScreen(
                chatId: _kGeneralChatId,
                groupId: '',
                groupName: 'General Chat',
                groupImage: '',
                showHeader: false,
                showTabs: false,
              ),
            ),
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
    const double size = 28;
    const double overlap = 16;

    return Obx(() {
      final List<Map<String, dynamic>> avatars = List<Map<String, dynamic>>.from(_memberAvatars);
      // Show placeholder circles while loading
      final displayAvatars = avatars.isEmpty
          ? List.generate(5, (i) => <String, dynamic>{'name': '', 'image': ''})
          : avatars;
      final count = displayAvatars.length;
      final memberLabel = _totalUsers.value > 0
          ? '${_formatMemberCount(_totalUsers.value)} members'
          : '620 members';

      return Row(
        children: [
          SizedBox(
            width: size + (count - 1) * (size - overlap),
            height: size,
            child: Stack(
              children: List.generate(count, (i) {
                final item = displayAvatars[i] as Map<String, dynamic>;
                return Positioned(
                  left: i * (size - overlap).toDouble(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: InitialsAvatar(
                      name: item['name'] as String,
                      imageUrl: (item['image'] as String).isEmpty
                          ? null
                          : item['image'] as String,
                      radius: size / 2,
                      fontSize: 10,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            memberLabel,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    });
  }
}
