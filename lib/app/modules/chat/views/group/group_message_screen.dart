// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/core/widgets/shimmer/chat_shimmer.dart';
import 'package:wisper/app/modules/chat/controller/group/all_group_member_controller.dart';
import 'package:wisper/app/modules/chat/controller/group/group_info_controller.dart';
import 'package:wisper/app/modules/homepage/controller/join_group_controller.dart';
import 'package:wisper/app/modules/chat/controller/message_controller.dart';
import 'package:wisper/app/modules/chat/controller/seen_message_controller.dart';
import 'package:wisper/app/modules/chat/model/message_keys.dart';
import 'package:wisper/app/modules/chat/views/group/group_info_screen.dart';
import 'package:wisper/app/modules/chat/views/person/message_input_bar.dart';
import 'package:wisper/app/modules/chat/widgets/empty_group_card.dart';
import 'package:wisper/app/modules/chat/widgets/message_bubble.dart';
import 'package:wisper/app/modules/job/views/job_post_screen.dart';
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
  String? _jobLocationType;
  List<String> _tagPills = [];
  late bool _hasJoined;
  bool _isJoining = false; // community tag pills

  static const _tabs = ['General Chat', 'Services', 'Jobs', 'Members'];

  // When no groupId, only show General Chat tab (home announcement feed)
  List<String> get _activeTabs =>
      (widget.groupId != null && widget.groupId!.isNotEmpty)
          ? _tabs
          : ['General Chat'];

  @override
  void initState() {
    super.initState();
    _hasJoined = widget.hasJoined;
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
      }
      _ctrl.setupChat(chatId: widget.chatId);
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
        final colonIdx = part.indexOf(':');
        if (colonIdx != -1) {
          final value = part.substring(colonIdx + 1).trim();
          if (value.isNotEmpty) tags.add(value);
        }
      }
    }
    return tags;
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Obx(() {
      final members = _membersCtrl.groupMemnersData ?? [];
      final memberCount = members.length;
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
              InitialsAvatar(
                name: widget.groupName ?? 'G',
                imageUrl: widget.groupImage?.isNotEmpty == true ? widget.groupImage : null,
                radius: 20.r,
                fontSize: 14,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.groupName ?? '',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    Row(
                      children: [
                        // Member avatars hidden for now
                        Text('$memberCount members',
                          style: TextStyle(fontSize: 11.sp, color: Colors.white54)),
                      ],
                    ),
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
      final extra = members.length - preview.length;
      return Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Row(
          children: [
            // Overlapping avatars
            SizedBox(
              height: 32.h,
              width: (preview.length * 22.0) + (extra > 0 ? 28 : 0),
              child: Stack(
                children: [
                  ...List.generate(preview.length, (i) {
                    final m = preview[i];
                    return Positioned(
                      left: i * 22.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: InitialsAvatar(
                          name: m.auth?.person?.name ?? m.auth?.business?.name ?? '?',
                          imageUrl: m.auth?.person?.image ?? m.auth?.business?.image,
                          radius: 14.r, fontSize: 9,
                        ),
                      ),
                    );
                  }),
                  if (extra > 0)
                    Positioned(
                      left: preview.length * 22.0,
                      child: Container(
                        width: 28.r, height: 28.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xff2A2A2A),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Center(
                          child: Text('+$extra',
                            style: TextStyle(fontSize: 9.sp, color: Colors.white70)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              '${members.length} member${members.length == 1 ? '' : 's'}',
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
        Row(
          children: List.generate(_activeTabs.length, (i) {
            final sel = _tabIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(_activeTabs[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : Colors.white38,
                        ),
                      ),
                    ),
                    Container(height: 2, color: sel ? Colors.blue : Colors.transparent),
                  ],
                ),
              ),
            );
          }),
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
                child: EmptyGroupInfoCard(isGroup: true, name: widget.groupName ?? '', member: '5'),
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
              MessageBubble(
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
        return ListView.separated(
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
                        Text('Admin', style: TextStyle(fontSize: 11.sp, color: Colors.blue))
                      else if (title != null && title.isNotEmpty)
                        Text(title, style: TextStyle(fontSize: 11.sp, color: Colors.white54)),
                    ],
                  )),
                ]),
              ),
            );
          },
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
                    'Join to participate in chats and post services',
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
        setState(() {
          _hasJoined = true;
          _isJoining = false;
        });
        // Reload members after joining
        _membersCtrl.getGroupMembers(widget.groupId);
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
      body: Column(
        children: [
          // Header (skip for embedded announcement tab)
          if (widget.showHeader) _buildHeader(),
          // Tabs (skip for embedded announcement tab)
          if (widget.showTabs) _buildTabs(),

          // Content — always wrapped in Expanded so Column has bounded height
          if (!widget.showTabs) ...[
            _buildChat(),
            if (_hasJoined)
              MessageInputBar(
                controller: _ctrl.textController,
                chatId: widget.chatId ?? '',
                receiverId: '',
                onSend: () => _ctrl.sendMessage(widget.chatId ?? ''),
              )
            else
              _buildJoinBanner(),
          ] else ...[
            if (_tabIndex == 0) ...[
              _buildChat(),
              if (_hasJoined)
                MessageInputBar(
                  controller: _ctrl.textController,
                  chatId: widget.chatId ?? '',
                  receiverId: '',
                  onSend: () => _ctrl.sendMessage(widget.chatId ?? ''),
                )
              else
                _buildJoinBanner(),
            ],
            if (_tabIndex == 1) Expanded(
              child: Column(children: [
                // Search bar — same pattern as Jobs tab
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: CustomTextField(
                    controller: _serviceSearchCtrl,
                    hintText: 'Search services...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (v) => setState(() => _serviceSearchQuery = v ?? ''),
                  ),
                ),
                // Service posts filtered by groupId + searchQuery
                Expanded(
                  child: Stack(children: [
                    Positioned.fill(
                      child: PostSection(
                        key: ValueKey('services_${widget.groupId}_$_serviceSearchQuery'),
                        groupId: widget.groupId,
                        searchQuery: _serviceSearchQuery.isEmpty ? null : _serviceSearchQuery,
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
                if (!_hasJoined) _buildJoinBanner(),
              ]),
            ),
            if (_tabIndex == 2) Expanded(
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: CustomTextField(
                    controller: _jobSearchCtrl,
                    hintText: 'Search jobs...',
                    onChanged: (v) => setState(() => _jobSearchQuery = v ?? ''),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: CustomTextField(
                    hintText: 'Location type',
                    value: _jobLocationType,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any location')),
                      DropdownMenuItem(value: 'REMOTE', child: Text('Remote')),
                      DropdownMenuItem(value: 'ON_SITE', child: Text('On-site')),
                      DropdownMenuItem(value: 'HYBRID', child: Text('Hybrid')),
                    ],
                    onChanged: (v) => setState(() => _jobLocationType = v),
                  ),
                ),
                SizedBox(height: 8.h),
                Expanded(child: Stack(children: [
                  Positioned.fill(child: JobSection(
                    key: ValueKey('jobs_${widget.groupId}_$_jobSearchQuery$_jobLocationType'),
                    groupId: widget.groupId,
                    searchQuery: _jobSearchQuery.isEmpty ? null : _jobSearchQuery,
                    jobType: _jobLocationType,
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
                if (!_hasJoined) _buildJoinBanner(),
              ]),
            ),
            if (_tabIndex == 3) _buildMembers(),
          ],
        ],
      ),
    );
  }
}
