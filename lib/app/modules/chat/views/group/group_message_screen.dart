// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/core/widgets/shimmer/chat_shimmer.dart';
import 'package:wisper/app/modules/chat/controller/group/all_group_member_controller.dart';
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

class GroupChatScreen extends StatefulWidget {
  final String? groupName;
  final String? groupImage;
  final String? chatId;
  final String? groupId;
  final bool showHeader;
  final bool showTabs;

  const GroupChatScreen({
    super.key,
    this.groupName,
    this.groupImage,
    this.chatId,
    this.groupId,
    this.showHeader = true,
    this.showTabs = true,
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

  static const _tabs = ['General Chat', 'Services', 'Jobs', 'Members'];

  @override
  void initState() {
    super.initState();
    // Use timestamp to guarantee unique tag — prevents any possible collision
    final ts = DateTime.now().millisecondsSinceEpoch;
    _ctrlTag = 'msg_${widget.chatId ?? widget.groupId ?? 'g'}_$ts';
    _membersTag = 'mem_${widget.groupId ?? 'g'}_$ts';

    // Force delete any existing controller with same base before creating new
    _ctrl = Get.put(MessageController(), tag: _ctrlTag);
    _membersCtrl = Get.put(GroupMembersController(), tag: _membersTag);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.chatId != null && widget.chatId!.isNotEmpty) {
        _seenCtrl.seenMessage(widget.chatId!);
      }
      _ctrl.setupChat(chatId: widget.chatId);
      _membersCtrl.getGroupMembers(widget.groupId);
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
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        if (previewMembers.isNotEmpty)
                          SizedBox(
                            height: 16,
                            width: 16.0 + (previewMembers.length - 1) * 10.0,
                            child: Stack(
                              children: List.generate(previewMembers.length, (i) {
                                final m = previewMembers[i];
                                return Positioned(
                                  left: i * 10.0,
                                  child: InitialsAvatar(
                                    name: m.auth?.person?.name ?? m.auth?.business?.name ?? '?',
                                    imageUrl: m.auth?.person?.image ?? m.auth?.business?.image,
                                    radius: 8, fontSize: 6,
                                  ),
                                );
                              }),
                            ),
                          ),
                        if (previewMembers.isNotEmpty) SizedBox(width: 4.w),
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

  // ── Tabs ─────────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(_tabs.length, (i) {
            final sel = _tabIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(_tabs[i],
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
          itemCount: msgs.length + 2,
          itemBuilder: (context, idx) {
            if (idx == 0) return _encryptionNotice();
            if (idx == 1) return _dateSep(_dateLabel(msgs.isNotEmpty ? msgs[0][SocketMessageKeys.createdAt]?.toString() : null));
            final mi = idx - 2;
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
              ),
            ]);
          },
        ),
      );
    });
  }

  Widget _encryptionNotice() => Container(
    margin: EdgeInsets.all(8.w),
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
            return Padding(
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
            );
          },
        );
      }),
    );
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
            MessageInputBar(
              controller: _ctrl.textController,
              chatId: widget.chatId ?? '',
              receiverId: '',
              onSend: () => _ctrl.sendMessage(widget.chatId ?? ''),
            ),
          ] else ...[
            if (_tabIndex == 0) ...[
              _buildChat(),
              MessageInputBar(
                controller: _ctrl.textController,
                chatId: widget.chatId ?? '',
                receiverId: '',
                onSend: () => _ctrl.sendMessage(widget.chatId ?? ''),
              ),
            ],
            if (_tabIndex == 1) Expanded(
              child: Stack(children: [
                Positioned.fill(child: PostSection(
                  groupId: widget.groupId,
                  searchQuery: _serviceSearchQuery.isEmpty ? null : _serviceSearchQuery,
                )),
                Positioned(
                  bottom: 16.h, left: 20.w, right: 20.w,
                  child: CustomElevatedButton(
                    title: 'Post your service', borderRadius: 50, height: 48,
                    onPress: () => Get.to(() => GalleryPostScreen(groupId: widget.groupId)),
                  ),
                ),
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
                    child: CustomElevatedButton(
                      title: 'Post a job', borderRadius: 50, height: 48,
                      onPress: () => Get.to(() => JobPostScreen(groupId: widget.groupId)),
                    ),
                  ),
                ])),
              ]),
            ),
            if (_tabIndex == 3) _buildMembers(),
          ],
        ],
      ),
    );
  }
}
