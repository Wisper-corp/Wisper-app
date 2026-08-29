// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/collapsible_header.dart';
import 'package:wisper/app/core/utils/community_tabs.dart';
import 'package:wisper/app/core/widgets/common/community_tab_bar.dart';
import 'package:wisper/app/modules/forum/views/forum_section.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/core/widgets/shimmer/chat_shimmer.dart';
import 'package:wisper/app/modules/chat/controller/group/add_group_member.dart';
import 'package:wisper/app/modules/chat/controller/group/all_group_member_controller.dart';
import 'package:wisper/app/modules/chat/controller/group/group_info_controller.dart';
import 'package:wisper/app/modules/homepage/controller/join_group_controller.dart';
import 'package:wisper/app/modules/chat/controller/message_controller.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/modules/chat/controller/all_chats_controller.dart';
import 'package:wisper/app/modules/chat/controller/seen_message_controller.dart';
import 'package:wisper/app/modules/chat/model/message_keys.dart';
import 'package:wisper/app/modules/chat/views/group/group_info_screen.dart';
import 'package:wisper/app/modules/chat/views/person/message_input_bar.dart';
import 'package:wisper/app/modules/chat/widgets/empty_group_card.dart';
import 'package:wisper/app/modules/chat/widgets/message_bubble.dart';
import 'package:wisper/app/modules/job/views/job_post_screen.dart';
import 'package:wisper/app/core/widgets/common/location_filter_sheet.dart';
import 'package:wisper/app/modules/job/views/job_section.dart';
import 'package:wisper/app/modules/post/views/gallery_post_screen.dart';
import 'package:wisper/app/modules/post/views/post_section.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String? groupName;
  final String? groupImage;
  final String? chatId;
  final String? groupId;
  final bool showHeader;
  final bool showTabs;
  final bool hasJoined;

  const GroupChatScreen({
    super.key,
    this.groupName,
    this.groupImage,
    this.chatId,
    this.groupId,
    this.showHeader = true,
    this.showTabs = true,
    this.hasJoined = true,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  // Use simple unique keys — no complex tag management
  late final String _ctrlTag;
  late final String _membersTag;
  late final MessageController _ctrl;
  late final GroupMembersController _membersCtrl;
  final SeenMessageController _seenCtrl = SeenMessageController();

  int _tabIndex = 0;
  final TextEditingController _serviceSearchCtrl = TextEditingController();
  final TextEditingController _jobSearchCtrl = TextEditingController();
  String _serviceSearchQuery = '';
  String _jobSearchQuery = '';
  LocationFilters _jobFilters = const LocationFilters();
  LocationFilters _serviceFilters = const LocationFilters();
  List<String> _tagPills = [];
  late bool _hasJoined;
  bool _isJoining = false;
  final RxString _effectiveChatId = ''.obs; // resolved chatId (may come from group info)

  // Tab list, visibility and index mapping live in core/utils/community_tabs.dart
  // so they can be tested without standing up this whole screen. General Chat is
  // hidden there, not deleted: _buildChat() and its controllers are untouched.

  /// Collapsed hides the member-avatars row so the feed gets that height back.
  /// The title row and tabs stay put, so nothing the user is aiming at moves.
  bool _headerCollapsed = false;

  bool _onFeedScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return false;
    // Only the feed drives this; a nested horizontal strip must not.
    if (notification.metrics.axis != Axis.vertical) return false;

    final intent = headerCollapseIntent(
      metrics: notification.metrics,
      scrollDelta: notification.scrollDelta ?? 0,
    );
    if (intent == null || intent == _headerCollapsed) return false;

    setState(() => _headerCollapsed = intent);
    return false; // keep letting the notification bubble
  }

  // Current user is admin in this group
  bool get _isCurrentUserAdmin {
    final myId = StorageUtil.getData(StorageUtil.userId) ?? '';
    final members = _membersCtrl.groupMemnersData ?? [];
    return members.any((m) => m.auth?.id == myId && m.role == 'ADMIN');
  }

  String get _myUserId => StorageUtil.getData(StorageUtil.userId) ?? '';

  // When no groupId, only show General Chat tab (home announcement feed)
  List<String> get _activeTabs => visibleCommunityTabs(
        hasGroupId: widget.groupId != null && widget.groupId!.isNotEmpty,
      );

  int get _canonicalTabIndex => canonicalTabIndex(
        hasGroupId: widget.groupId != null && widget.groupId!.isNotEmpty,
        visibleIndex: _tabIndex,
      );

  @override
  void initState() {
    super.initState();
    _hasJoined = widget.hasJoined;
    _effectiveChatId.value = widget.chatId ?? '';

    // If chatId is empty OR hasJoined is false, try to resolve from socket list
    if (_effectiveChatId.value.isEmpty || !_hasJoined) {
      if (widget.groupId != null && widget.groupId!.isNotEmpty) {
        _resolveChatIdWithRetry(widget.groupId!);
      }
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    _ctrlTag = 'msg_${widget.chatId ?? widget.groupId ?? 'g'}_$ts';
    _membersTag = 'mem_${widget.groupId ?? 'g'}_$ts';

    _ctrl = Get.put(MessageController(), tag: _ctrlTag);
    _membersCtrl = Get.put(GroupMembersController(), tag: _membersTag);

    // Fetch members immediately — don't wait for frame callback
    if (widget.groupId != null && widget.groupId!.isNotEmpty) {
      _fetchMembersWithRetry(widget.groupId!);

      // Fetch group info for tag pills — also get chatId if missing
      final infoCtrl = Get.put(GroupInfoController(), tag: 'grp_${widget.groupId}');
      infoCtrl.getGroupInfo(widget.groupId).then((ok) {
        if (ok && mounted) {
          setState(() => _tagPills = _parseTags(infoCtrl.groupInfoData?.description));
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.chatId != null && widget.chatId!.isNotEmpty) {
        _seenCtrl.seenMessage(widget.chatId!);
      } else if (_effectiveChatId.value.isNotEmpty) {
        _seenCtrl.seenMessage(_effectiveChatId.value);
      }
      _ctrl.setupChat(chatId: _effectiveChatId.value.isNotEmpty ? _effectiveChatId.value : widget.chatId);
    });
  }

  @override
  void dispose() {
    Get.delete<MessageController>(tag: _ctrlTag, force: true);
    Get.delete<GroupMembersController>(tag: _membersTag, force: true);
    _serviceSearchCtrl.dispose();
    _jobSearchCtrl.dispose();
    super.dispose();
  }

  // ── Resolve chatId with retry (same pattern as _fetchMembersWithRetry) ──────
  Future<void> _resolveChatIdWithRetry(String groupId) async {
    // Wait for auth token
    String? token;
    for (int i = 0; i < 10; i++) {
      token = StorageUtil.getData(StorageUtil.userAccessToken);
      if (token != null && token.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!mounted) return;

    // Helper to check socket list
    String? _findChatId() {
      try {
        final socketService = Get.find<SocketService>();
        // Try by groupId
        final match = socketService.socketFriendList.firstWhereOrNull(
          (e) => e['groupId'] == groupId,
        );
        if (match != null && (match['id'] ?? '').isNotEmpty) return match['id'];
      } catch (_) {}
      return null;
    }

    // First attempt
    String? found = _findChatId();
    if (found != null) {
      _effectiveChatId.value = found;
      _ctrl.setupChat(chatId: found);
      if (mounted) setState(() => _hasJoined = true);
      return;
    }

    // If socket list is empty, trigger getAllChats then retry
    try {
      final allChatsCtrl = Get.find<AllChatsController>();
      if (allChatsCtrl.allChatsModel.value == null) {
        await allChatsCtrl.getAllChats();
      }
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    found = _findChatId();
    if (found != null) {
      _effectiveChatId.value = found;
      _ctrl.setupChat(chatId: found);
      if (mounted) setState(() => _hasJoined = true);
      return;
    }

    // Final retry after 2s
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    found = _findChatId();
    if (found != null) {
      _effectiveChatId.value = found;
      _ctrl.setupChat(chatId: found);
      if (mounted) setState(() => _hasJoined = true);
    }
  }

  // ── Retry member fetch until token is available ──────────────────────────
  Future<void> _fetchMembersWithRetry(String groupId) async {
    // Wait up to 5 seconds for auth token to be available
    String? token;
    for (int i = 0; i < 10; i++) {
      token = StorageUtil.getData(StorageUtil.userAccessToken);
      if (token != null && token.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!mounted) return;
    final ok = await _membersCtrl.getGroupMembers(groupId);
    // If failed or empty, retry once after short delay
    if ((!ok || (_membersCtrl.groupMemnersData?.isEmpty ?? true)) && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) await _membersCtrl.getGroupMembers(groupId);
    }
  }

  // ── Parse community tag pills from description ───────────────────────────
  List<String> _parseTags(String? description) {
    if (description == null || description.isEmpty) return [];
    final tags = <String>[];
    final lines = description.split('\n');
    for (final line in lines) {
      final parts = line.split('|');
      for (final part in parts) {
        final trimmed = part.trim();
        // Skip the Suffix metadata — it belongs in the name, not in tag pills
        if (trimmed.startsWith('Suffix:')) continue;
        final colonIdx = trimmed.indexOf(':');
        if (colonIdx != -1) {
          final value = trimmed.substring(colonIdx + 1).trim();
          if (value.isNotEmpty) tags.add(value);
        }
      }
    }
    return tags;
  }

  // ── Admin: change member role ──────────────────────────────────────────────
  void _showRoleOptions(String participantId, String memberName, String currentRole) {
    final chatId = _effectiveChatId.value.isNotEmpty
        ? _effectiveChatId.value
        : widget.chatId ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set role for $memberName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 16),
            ...[
              {'label': 'Admin', 'value': 'ADMIN', 'color': Colors.blue},
              {'label': 'Moderator', 'value': 'MODERATOR', 'color': Colors.orange},
              {'label': 'Member', 'value': 'MEMBER', 'color': Colors.grey},
            ].map((r) {
              final isSelected = currentRole == r['value'];
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final ctrl = GroupMemberController();
                  final ok = await ctrl.updateRole(
                    chatId: chatId,
                    participantId: participantId,
                    role: r['value'] as String,
                  );
                  if (ok) {
                    await _membersCtrl.getGroupMembers(widget.groupId ?? '');
                    if (mounted) setState(() {});
                    Get.snackbar('Done', '${memberName} is now ${r['label']}',
                        backgroundColor: Colors.green, colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM);
                  } else {
                    Get.snackbar('Error', ctrl.errorMessage,
                        backgroundColor: Colors.red, colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM);
                  }
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (r['color'] as Color).withValues(alpha: 0.2)
                        : const Color(0xff1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? (r['color'] as Color) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        r['value'] == 'ADMIN' ? Icons.shield : r['value'] == 'MODERATOR' ? Icons.star : Icons.person,
                        color: r['color'] as Color, size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(r['label'] as String,
                          style: TextStyle(color: r['color'] as Color, fontWeight: FontWeight.w600)),
                      if (isSelected) ...[
                        const Spacer(),
                        Icon(Icons.check, color: r['color'] as Color, size: 16),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  void _confirmRemoveMember(String memberAuthId, String memberName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remove $memberName?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('This member will be removed from the community.',
                style: TextStyle(color: Color(0xff9FA3AA))),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xff262629))),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final chatId = _effectiveChatId.value.isNotEmpty
                        ? _effectiveChatId.value
                        : widget.chatId ?? '';
                    final ctrl = GroupMemberController();
                    final ok = await ctrl.removeRequest(
                        memberId: memberAuthId, chatId: chatId);
                    if (ok) {
                      await _membersCtrl.getGroupMembers(widget.groupId ?? '');
                      if (mounted) setState(() {});
                      Get.snackbar('Done', '$memberName removed',
                          backgroundColor: Colors.green, colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      Get.snackbar('Error', ctrl.errorMessage,
                          backgroundColor: Colors.red, colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Remove', style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── User: leave community ──────────────────────────────────────────────
  void _confirmLeaveGroup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leave Community?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Text('You will leave "${widget.groupName ?? 'this community'}" and lose access to its content.',
                style: const TextStyle(color: Color(0xff9FA3AA))),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xff262629))),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final chatId = _effectiveChatId.value.isNotEmpty
                        ? _effectiveChatId.value
                        : widget.chatId ?? '';
                    // Find own ChatParticipant ID from members list
                    final myMember = _membersCtrl.groupMemnersData?.firstWhereOrNull(
                        (m) => m.auth?.id == _myUserId);
                    final myParticipantId = myMember?.id ?? '';
                    if (myParticipantId.isEmpty) {
                      Get.snackbar('Error', 'Could not find your membership',
                          backgroundColor: Colors.red, colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    final ctrl = GroupMemberController();
                    final ok = await ctrl.removeRequest(
                        memberId: myParticipantId, chatId: chatId);
                    if (ok) {
                      if (Get.isRegistered<AllChatsController>()) {
                        Get.find<AllChatsController>().getAllChats();
                      }
                      Get.back();
                      Get.snackbar('Left', 'You have left the community',
                          backgroundColor: Colors.orange, colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      Get.snackbar('Error', ctrl.errorMessage,
                          backgroundColor: Colors.red, colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Leave', style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Admin/owner: delete a message ──────────────────────────────────────
  void _confirmDeleteMessage(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delete Message?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('This message will be permanently removed for everyone.',
                style: TextStyle(color: Color(0xff9FA3AA))),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xff262629))),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final ok = await _ctrl.deleteMessage(messageId);
                    if (!ok) {
                      Get.snackbar('Error', 'Could not delete message',
                          backgroundColor: Colors.red, colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Obx(() {
      final members = _membersCtrl.groupMemnersData ?? [];
      final previewMembers = members.take(3).toList();

      return GestureDetector(
        onTap: () {
          if (widget.groupId != null && widget.groupId!.isNotEmpty) {
            Get.to(() => GroupInfoScreen(
              groupId: widget.groupId!,
              chatId: widget.chatId ?? '',
            ));
          }
        },
        child: Container(
          color: Colors.black,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 6.h,
            left: 16.w, right: 16.w, bottom: 8.h,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
              SizedBox(width: 10.w),
              Builder(builder: (_) {
                final infoCtrl = widget.groupId != null
                    ? Get.find<GroupInfoController>(tag: 'grp_${widget.groupId}')
                    : null;
                final liveImage = infoCtrl?.groupInfoData?.image?.isNotEmpty == true
                    ? infoCtrl!.groupInfoData!.image!
                    : (widget.groupImage?.isNotEmpty == true ? widget.groupImage : null);
                final liveName = infoCtrl?.groupInfoData?.name?.isNotEmpty == true
                    ? infoCtrl!.groupInfoData!.name!
                    : (widget.groupName ?? 'G');
                return InitialsAvatar(
                  name: liveName,
                  imageUrl: liveImage,
                  radius: 20.r,
                  fontSize: 14,
                  // Rounded square, matching the community covers on Home: a
                  // community is a place, and a circle reads as a person.
                  cornerRadius: 12.r,
                );
              }),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() {
                      final infoCtrl = widget.groupId != null &&
                              Get.isRegistered<GroupInfoController>(tag: 'grp_${widget.groupId}')
                          ? Get.find<GroupInfoController>(tag: 'grp_${widget.groupId}')
                          : null;
                      final liveName = infoCtrl?.groupInfoData?.name?.isNotEmpty == true
                          ? infoCtrl!.groupInfoData!.name!
                          : (widget.groupName ?? '');
                      return Text(liveName,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    // Community tag pills
                    if (_tagPills.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Wrap(
                        spacing: 5.w,
                        runSpacing: 3.h,
                        children: _tagPills.map((tag) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xff1A2C3D),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: const Color(0xff1F7DE9), width: 0.8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w500, color: const Color(0xff5BB8FF)),
                          ),
                        )).toList(),
                      ),
                    ],
                    SizedBox(height: 2.h),
                    // Member count shown in avatars row below tabs — not duplicated here
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Member avatars row (below header, above tabs) ─────────────────────────
  Widget _buildMemberAvatarsRow() {
    return Obx(() {
      final members = _membersCtrl.groupMemnersData ?? [];
      if (members.isEmpty) return const SizedBox.shrink();
      final preview = members.take(5).toList();
      // The list is one page of 10; the community may be far larger, so the
      // overflow chip and the label both count against the real total.
      final total = _membersCtrl.totalMembers;
      final extra = total - preview.length;
      return Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Row(
          children: [
            // Overlapping avatars
            SizedBox(
              height: 22.h,
              width: (preview.length * 16.0) + (extra > 0 ? 20 : 0),
              child: Stack(
                children: [
                  ...List.generate(preview.length, (i) {
                    final m = preview[i];
                    return Positioned(
                      left: i * 16.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: InitialsAvatar(
                          name: m.auth?.person?.name ?? m.auth?.business?.name ?? '?',
                          imageUrl: m.auth?.person?.image ?? m.auth?.business?.image,
                          radius: 10.r, fontSize: 7,
                        ),
                      ),
                    );
                  }),
                  if (extra > 0)
                    Positioned(
                      left: preview.length * 16.0,
                      child: Container(
                        width: 20.r, height: 20.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xff2A2A2A),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Center(
                          child: Text('+$extra',
                            style: TextStyle(fontSize: 7.sp, color: Colors.white70)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              '$total member${total == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12.sp, color: Colors.white60,
                fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    });
  }

  // ── Tabs ─────────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CommunityTabBar(
          tabs: _activeTabs,
          selectedIndex: _tabIndex,
          onSelected: (i) => setState(() => _tabIndex = i),
        ),
        StraightLiner(height: 0.4, color: const Color(0xff454545)),
      ],
    );
  }

  // ── General Chat ─────────────────────────────────────────────────────────────
  Widget _encryptionNotice() => Container(
    margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10.r),
    ),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.lock_rounded, size: 12.sp, color: Colors.grey[500]),
        SizedBox(width: 4.w),
        Flexible(child: Text('Messages and calls are end-to-end encrypted',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]))),
      ]),
      SizedBox(height: 2.h),
      Text('No one outside of this chat can read or listen to them.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10.sp, color: Colors.grey[600])),
    ]),
  );

  Widget _buildChat() {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return const Expanded(child: Center(child: ChatShimmerEffectWidget()));
      }
      if (_ctrl.messages.isEmpty) {
        return Expanded(
          child: Column(
            children: [
              _encryptionNotice(),
              Expanded(child: Center(
                child: EmptyGroupInfoCard(
                  isGroup: true,
                  name: widget.groupName ?? '',
                  member: _membersCtrl.totalMembers.toString(),
                ),
              )),
            ],
          ),
        );
      }
      final msgs = _ctrl.messages.reversed.toList();
      return Expanded(
        child: ListView.builder(
          controller: _ctrl.scrollController,
          padding: EdgeInsets.all(10.r),
          itemCount: msgs.length + 1,
          itemBuilder: (context, idx) {
            if (idx == 0) return _dateSep(_dateLabel(msgs.isNotEmpty ? msgs[0][SocketMessageKeys.createdAt]?.toString() : null));
            final mi = idx - 1;
            if (mi >= msgs.length) return const SizedBox.shrink();
            final msg = msgs[mi];
            final isMe = msg[SocketMessageKeys.senderId] == _ctrl.userAuthId;
            String? sep;
            if (mi > 0) {
              final p = _dateLabel(msgs[mi-1][SocketMessageKeys.createdAt]?.toString());
              final c = _dateLabel(msg[SocketMessageKeys.createdAt]?.toString());
              if (c != p) sep = c;
            }
            return Column(children: [
              if (sep != null) _dateSep(sep),
              GestureDetector(
                onLongPress: () {
                  final msgId = msg[SocketMessageKeys.id] ?? '';
                  final senderId = msg[SocketMessageKeys.senderId] ?? '';
                  // Admin can delete any message; user can delete own
                  if (_isCurrentUserAdmin || senderId == _myUserId) {
                    _confirmDeleteMessage(msgId);
                  }
                },
                child: MessageBubble(
                  message: msg, isMe: isMe,
                  fileUrl: msg[SocketMessageKeys.imageUrl] ?? '',
                  fileType: msg[SocketMessageKeys.fileType] ?? '',
                  senderImage: msg[SocketMessageKeys.senderImage],
                  senderName: msg[SocketMessageKeys.senderName],
                  time: DateFormatter(msg[SocketMessageKeys.createdAt]).getRelativeTimeFormat(),
                  isGroupChat: true,
                  senderId: msg[SocketMessageKeys.senderId],
                  senderType: msg[SocketMessageKeys.senderType],
                ),
              ),
            ]);
          },
        ),
      );
    });
  }

  Widget _dateSep(String text) => text.isEmpty ? const SizedBox.shrink() : Align(
    alignment: Alignment.center,
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(12.r)),
      child: Text(text, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
    ),
  );

  String _dateLabel(String? s) {
    if (s == null) return '';
    final dt = DateTime.tryParse(s)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) return 'Today';
    final y = now.subtract(const Duration(days: 1));
    if (dt.year == y.year && dt.month == y.month && dt.day == y.day) return 'Yesterday';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month-1]} ${dt.year}';
  }

  // ── Members ──────────────────────────────────────────────────────────────────
  Widget _buildMembers() {
    return Expanded(
      child: Obx(() {
        final members = _membersCtrl.groupMemnersData ?? [];
        if (_membersCtrl.inProgress) return const Center(child: CircularProgressIndicator());
        if (members.isEmpty) return const Center(child: Text('No members yet', style: TextStyle(color: Colors.white54)));
        final isAdmin = _isCurrentUserAdmin;
        final myId = _myUserId;
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: members.length,
                separatorBuilder: (_, __) => const Divider(color: Color(0xff2A2A2A), height: 1, thickness: 0.5),
                itemBuilder: (context, i) {
                  final m = members[i];
                  final name = m.auth?.person?.name ?? m.auth?.business?.name ?? 'Unknown';
                  final image = m.auth?.person?.image ?? m.auth?.business?.image;
                  final title = m.auth?.person?.title ?? m.auth?.business?.industry;
                  final role = m.role ?? 'MEMBER';
                  final isPerson = m.auth?.person != null;
                  final authId = m.auth?.id ?? '';
                  final participantId = m.id ?? ''; // ChatParticipant record ID
                  final isSelf = authId == myId;
                  return GestureDetector(
                    onTap: authId.isNotEmpty
                        ? () => Get.to(() => isPerson
                            ? OthersPersonScreen(userId: authId)
                            : OthersBusinessScreen(userId: authId))
                        : null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Row(children: [
                        InitialsAvatar(name: name, imageUrl: image, radius: 22.r, fontSize: 14),
                        SizedBox(width: 12.w),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                            if (role == 'ADMIN')
                              Text('Moderator', style: TextStyle(fontSize: 11.sp, color: Colors.blue))
                            else if (role == 'MODERATOR')
                              Text('Moderator', style: TextStyle(fontSize: 11.sp, color: Colors.orange))
                            else if (title != null && title.isNotEmpty)
                              Text(title, style: TextStyle(fontSize: 11.sp, color: Colors.white54)),
                          ],
                        )),
                        // Three-dot menu for admin actions on non-self members
                        if (isAdmin && !isSelf)
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: const Color(0xff1A1A1A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                                ),
                                builder: (_) => Container(
                                  padding: EdgeInsets.all(20.w),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                                      SizedBox(height: 4.h),
                                      Text(role == 'MODERATOR' ? 'Moderator' : role == 'ADMIN' ? 'Moderator' : 'Member',
                                          style: TextStyle(fontSize: 12.sp, color: Colors.white54)),
                                      SizedBox(height: 16.h),
                                      // Only show role options for non-admin members
                                      if (role != 'ADMIN') ...[
                                        ListTile(
                                          leading: Icon(Icons.star, color: Colors.orange, size: 20.sp),
                                          title: Text(role == 'MODERATOR' ? 'Remove Moderator' : 'Make Moderator',
                                              style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _showRoleOptions(participantId, name, role);
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.shield, color: Colors.blue, size: 20.sp),
                                          title: Text('Make Admin', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            final chatId = _effectiveChatId.value.isNotEmpty
                                                ? _effectiveChatId.value
                                                : widget.chatId ?? '';
                                            final ctrl = GroupMemberController();
                                            final ok = await ctrl.updateRole(
                                                chatId: chatId, participantId: participantId, role: 'ADMIN');
                                            if (ok) {
                                              await _membersCtrl.getGroupMembers(widget.groupId ?? '');
                                              if (mounted) setState(() {});
                                              Get.snackbar('Done', '$name is now Admin',
                                                  backgroundColor: Colors.green, colorText: Colors.white,
                                                  snackPosition: SnackPosition.BOTTOM);
                                            }
                                          },
                                        ),
                                      ],
                                      ListTile(
                                        leading: Icon(Icons.remove_circle_outline, color: Colors.red, size: 20.sp),
                                        title: Text('Remove from community',
                                            style: TextStyle(fontSize: 14.sp, color: Colors.red)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _confirmRemoveMember(participantId, name);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Icon(Icons.more_vert, color: Colors.white54, size: 22.sp),
                          ),
                      ]),
                    ),
                  );
                },
              ),
            ),
            // Leave Community — only for someone who is actually in the
            // community. Testing !isAdmin alone offered it to visitors, who
            // were being shown the way out of somewhere they had not entered.
            if (_hasJoined && !isAdmin)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmLeaveGroup,
                    icon: const Icon(Icons.exit_to_app, color: Colors.orange),
                    label: const Text('Leave Community',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  // ── Join Community Banner ─────────────────────────────────────────────────
  Widget _buildJoinBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: const Color(0xff2A2A2A), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.groupName ?? 'This community'} is open to join',
                    style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    // The banner shows on every tab now, so the wording cannot
                    // promise only chats and services.
                    'Join to post, reply and connect with its subscribers',
                    style: TextStyle(fontSize: 11.sp, color: Colors.white38),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: _isJoining ? null : _joinGroup,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xff1F7DE9),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: _isJoining
                    ? SizedBox(width: 16.w, height: 16.h,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Join', style: TextStyle(fontSize: 14.sp,
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinGroup() async {
    if (_isJoining || widget.groupId == null) return;
    setState(() => _isJoining = true);
    try {
      final ctrl = JoinGroupController();
      final ok = await ctrl.joinGroup(groupId: widget.groupId);
      if (ok && mounted) {
        // Use the chatId returned from join
        final newChatId = ctrl.chatId;
        if (newChatId.isNotEmpty) {
          _effectiveChatId.value = newChatId;
          _ctrl.setupChat(chatId: newChatId);
        }
        setState(() {
          _hasJoined = true;
          _isJoining = false;
        });
        _membersCtrl.getGroupMembers(widget.groupId);
        // Refresh chat list so the new community appears
        if (Get.isRegistered<AllChatsController>()) {
          Get.find<AllChatsController>().getAllChats();
        }
        Get.snackbar('Success', 'You joined ${widget.groupName ?? 'the community'}!',
          backgroundColor: Colors.green, colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      } else if (mounted) {
        setState(() => _isJoining = false);
        Get.snackbar('Error', ctrl.errorMessage,
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ALWAYS use Scaffold as root — never return a plain Column as root
    return Scaffold(
      backgroundColor: Colors.black,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onFeedScroll,
        child: Column(
        children: [
          // Header (skip for embedded announcement tab)
          if (widget.showHeader) _buildHeader(),
          // Member avatars row — ABOVE tabs. Collapses out of the way as the
          // feed scrolls down; the rows around it never move, so nothing the
          // user is reaching for shifts under their thumb.
          if (widget.showTabs && widget.groupId != null && widget.groupId!.isNotEmpty)
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _headerCollapsed
                  ? const SizedBox(width: double.infinity)
                  : AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 160),
                      child: _buildMemberAvatarsRow(),
                    ),
            ),
          // Tabs (skip for embedded announcement tab)
          if (widget.showTabs) _buildTabs(),

          // Content — always wrapped in Expanded so Column has bounded height
          if (!widget.showTabs) ...[
            _buildChat(),
            if (_hasJoined)
              MessageInputBar(
                controller: _ctrl.textController,
                chatId: _effectiveChatId.value.isNotEmpty ? _effectiveChatId.value : widget.chatId ?? '',
                receiverId: '',
                onSend: () => _ctrl.sendMessage(_effectiveChatId.value.isNotEmpty ? _effectiveChatId.value : widget.chatId ?? ''),
              )
            else
              _buildJoinBanner(),
          ] else ...[
            if (_canonicalTabIndex == 0) ...[
              _buildChat(),
              if (_hasJoined)
                MessageInputBar(
                  controller: _ctrl.textController,
                  chatId: _effectiveChatId.value.isNotEmpty ? _effectiveChatId.value : widget.chatId ?? '',
                  receiverId: '',
                  onSend: () => _ctrl.sendMessage(_effectiveChatId.value.isNotEmpty ? _effectiveChatId.value : widget.chatId ?? ''),
                ),
            ],
            if (_canonicalTabIndex == 1) Expanded(
              child: ForumSection(
                groupId: widget.groupId!,
                canPost: _hasJoined,
              ),
            ),
            if (_canonicalTabIndex == 2) Expanded(
              child: Column(children: [
                // Search bar — same pattern as Jobs tab
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _serviceSearchCtrl,
                          hintText: 'Search services...',
                          prefixIcon: Icons.search_rounded,
                          onChanged: (v) =>
                              setState(() => _serviceSearchQuery = v ?? ''),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      FilterIconButton(
                        active: !_serviceFilters.isEmpty,
                        onTap: () async {
                          final picked = await showLocationFilterSheet(
                            context,
                            current: _serviceFilters,
                            options: kServiceLocationOptions,
                            ctaLabel: 'Show services',
                          );
                          if (picked == null || !mounted) return;
                          setState(() => _serviceFilters = picked);
                        },
                      ),
                    ],
                  ),
                ),
                // Service posts filtered by groupId + searchQuery
                Expanded(
                  child: Stack(children: [
                    Positioned.fill(
                      child: PostSection(
                        key: ValueKey('services_${widget.groupId}_'
                            '$_serviceSearchQuery${_serviceFilters.value}'),
                        groupId: widget.groupId,
                        searchQuery: _serviceSearchQuery.isEmpty
                            ? null
                            : _serviceSearchQuery,
                        local: _serviceFilters.isLocal,
                        isAdmin: _isCurrentUserAdmin,
                      ),
                    ),
                    Positioned(
                      bottom: 16.h, left: 20.w, right: 20.w,
                      child: _hasJoined
                          ? CustomElevatedButton(
                              title: 'Post your service', borderRadius: 50, height: 48,
                              onPress: () => Get.to(() => GalleryPostScreen(groupId: widget.groupId)),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ]),
                ),
              ]),
            ),
            if (_canonicalTabIndex == 3) Expanded(
              child: Column(children: [
                // Search and filters share one row: the location dropdown used
                // to sit on its own line and cost a whole row of listings for
                // a control most people never touch.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _jobSearchCtrl,
                          hintText: 'Search jobs...',
                          onChanged: (v) =>
                              setState(() => _jobSearchQuery = v ?? ''),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      FilterIconButton(
                        active: !_jobFilters.isEmpty,
                        onTap: () async {
                          final picked = await showLocationFilterSheet(
                            context,
                            current: _jobFilters,
                            options: kJobLocationOptions,
                            ctaLabel: 'Show jobs',
                          );
                          if (picked == null || !mounted) return;
                          setState(() => _jobFilters = picked);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(child: Stack(children: [
                  Positioned.fill(child: JobSection(
                    key: ValueKey('jobs_${widget.groupId}_'
                        '$_jobSearchQuery${_jobFilters.value}'),
                    groupId: widget.groupId,
                    searchQuery: _jobSearchQuery.isEmpty ? null : _jobSearchQuery,
                    jobType: _jobFilters.locationType,
                    local: _jobFilters.isLocal,
                  )),
                  Positioned(
                    bottom: 16.h, left: 20.w, right: 20.w,
                    child: _hasJoined
                        ? CustomElevatedButton(
                            title: 'Post a job', borderRadius: 50, height: 48,
                            onPress: () => Get.to(() => JobPostScreen(groupId: widget.groupId)),
                          )
                        : const SizedBox.shrink(),
                  ),
                ])),
              ]),
            ),
            if (_canonicalTabIndex == 4) _buildMembers(),
            // Every tab, not just the two that happened to carry their own
            // copy: someone who lands on Forum or Members needs the way in
            // just as much as someone on Services.
            if (!_hasJoined) _buildJoinBanner(),
          ],
        ],
        ),
      ),
    );
  }
}
