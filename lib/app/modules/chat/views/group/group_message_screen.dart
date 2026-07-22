// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/core/widgets/shimmer/chat_shimmer.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/chat/controller/group/all_group_member_controller.dart';
import 'package:wisper/app/modules/job/views/job_post_screen.dart';
import 'package:wisper/app/modules/chat/views/group/group_info_screen.dart';
import 'package:wisper/app/modules/chat/controller/message_controller.dart';
import 'package:wisper/app/modules/chat/controller/seen_message_controller.dart';
import 'package:wisper/app/modules/chat/model/message_keys.dart';
import 'package:wisper/app/modules/chat/views/person/message_input_bar.dart';
import 'package:wisper/app/modules/chat/widgets/empty_group_card.dart';
import 'package:wisper/app/modules/chat/widgets/message_bubble.dart';
import 'package:wisper/app/modules/post/views/gallery_post_screen.dart';
import 'package:wisper/app/modules/job/views/job_section.dart';
import 'package:wisper/app/modules/post/views/post_section.dart';

class GroupChatScreen extends StatefulWidget {
  final String? groupName;
  final String? groupImage;
  final String? chatId;
  final String? groupId;
  final bool showHeader; // false when embedded in Announcement tab
  final bool showTabs;  // false when embedded in Announcement tab

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
  late final MessageController ctrl;
  final SeenMessageController seenMessageController = SeenMessageController();
  final GroupMembersController membersCtrl = Get.put(GroupMembersController());
  int _tabIndex = 0;

  // Search & filter state for Jobs tab
  final TextEditingController _jobSearchCtrl = TextEditingController();
  String? _jobLocationType;
  String _jobSearchQuery = '';

  static const _tabs = ['General Chat', 'Services', 'Jobs', 'Members'];

  @override
  void initState() {
    super.initState();
    final tag = widget.chatId ?? 'group';
    ctrl = Get.put(MessageController(), tag: tag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      seenMessageController.seenMessage(widget.chatId!);
      ctrl.setupChat(chatId: widget.chatId);
      membersCtrl.getGroupMembers(widget.groupId);
    });
  }

  @override
  void dispose() {
    final tag = widget.chatId ?? 'group';
    Get.delete<MessageController>(tag: tag);
    _jobSearchCtrl.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Obx(() {
      final members = membersCtrl.groupMemnersData ?? [];
      final memberCount = members.length;
      final previewMembers = members.take(3).toList();

      return GestureDetector(
        onTap: () => Get.to(() => GroupInfoScreen(
              groupId: widget.groupId ?? '',
              chatId: widget.chatId ?? '',
            )),
        child: Container(
          color: Colors.black,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8.h,
            left: 16.w,
            right: 16.w,
            bottom: 8.h,
          ),
          child: Row(
            children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
            SizedBox(width: 12.w),
            // Group avatar
            InitialsAvatar(
              name: widget.groupName ?? 'G',
              imageUrl: widget.groupImage?.isNotEmpty == true
                  ? widget.groupImage
                  : null,
              radius: 20.r,
              fontSize: 14,
            ),
            SizedBox(width: 10.w),
            // Name + members row
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName ?? '',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      // Member avatar previews
                      if (previewMembers.isNotEmpty)
                        SizedBox(
                          height: 18,
                          width: 18.0 + (previewMembers.length - 1) * 12.0,
                          child: Stack(
                            children: List.generate(previewMembers.length, (i) {
                              final m = previewMembers[i];
                              final img = m.auth?.person?.image ??
                                  m.auth?.business?.image;
                              final name = m.auth?.person?.name ??
                                  m.auth?.business?.name ??
                                  '?';
                              return Positioned(
                                left: i * 12.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.black, width: 1),
                                  ),
                                  child: InitialsAvatar(
                                    name: name,
                                    imageUrl: img,
                                    radius: 9,
                                    fontSize: 6,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      if (previewMembers.isNotEmpty) SizedBox(width: 6.w),
                      Text(
                        '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white54,
                        ),
                      ),
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

  Widget _buildTabs() {
    return Column(
      children: [
        Row(
          children: List.generate(_tabs.length, (i) {
            final selected = _tabIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = i),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _tabs[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.white38,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        height: 2,
                        width: double.infinity,
                        color: selected ? Colors.blue : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        StraightLiner(height: 0.4, color: const Color(0xff454545)),
      ],
    );
  }

  Widget _buildEncryptionNotice() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h, left: 8.w, right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 12.sp, color: Colors.grey[500]),
              SizedBox(width: 4.w),
              Text(
                'Messages and calls are end-to-end encrypted',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'No one outside of this chat can read or listen to them.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String text) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ),
    );
  }

  String _getDateLabel(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'Yesterday';
    }
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildGeneralChat() {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Expanded(child: Center(child: ChatShimmerEffectWidget()));
      }

      if (ctrl.messages.isEmpty) {
        return Expanded(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: _buildEncryptionNotice(),
              ),
              const Spacer(),
              Center(
                child: EmptyGroupInfoCard(
                  isGroup: true,
                  name: widget.groupName ?? '',
                  member: '5',
                ),
              ),
              const Spacer(),
            ],
          ),
        );
      }

      // Messages newest-first from controller — reverse to show oldest at top
      final displayMessages = ctrl.messages.reversed.toList();

      return Expanded(
        child: ListView.builder(
          controller: ctrl.scrollController,
          padding: EdgeInsets.all(10.r),
          itemCount: displayMessages.length + 2, // +2 for encryption notice + date separator
          itemBuilder: (context, index) {
            // First item: encryption notice
            if (index == 0) return _buildEncryptionNotice();

            // Second item: date separator for first message
            if (index == 1) {
              final firstDate = displayMessages.isNotEmpty
                  ? displayMessages[0][SocketMessageKeys.createdAt]
                  : null;
              return _buildDateSeparator(_getDateLabel(firstDate?.toString()));
            }

            final msgIndex = index - 2;
            if (msgIndex >= displayMessages.length) return const SizedBox.shrink();

            final msg = displayMessages[msgIndex];
            final isMe = msg[SocketMessageKeys.senderId] == ctrl.userAuthId;
            final imageUrl = msg[SocketMessageKeys.imageUrl] ?? "";

            // Show date separator when day changes
            String? separator;
            if (msgIndex > 0) {
              final prevLabel = _getDateLabel(
                  displayMessages[msgIndex - 1][SocketMessageKeys.createdAt]?.toString());
              final curLabel = _getDateLabel(msg[SocketMessageKeys.createdAt]?.toString());
              if (curLabel != prevLabel) separator = curLabel;
            }

            return Column(
              children: [
                if (separator != null) _buildDateSeparator(separator),
                MessageBubble(
                  message: msg,
                  isMe: isMe,
                  fileUrl: imageUrl,
                  fileType: msg[SocketMessageKeys.fileType] ?? '',
                  senderImage: msg[SocketMessageKeys.senderImage],
                  senderName: msg[SocketMessageKeys.senderName],
                  time: DateFormatter(
                    msg[SocketMessageKeys.createdAt],
                  ).getRelativeTimeFormat(),
                  isGroupChat: true,
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildMembers() {
    return Expanded(
      child: Obx(() {
        final members = membersCtrl.groupMemnersData ?? [];
        if (membersCtrl.inProgress) {
          return const Center(child: CircularProgressIndicator());
        }
        if (members.isEmpty) {
          return const Center(
            child: Text('No members yet', style: TextStyle(color: Colors.white54)),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: members.length,
          separatorBuilder: (_, __) => Divider(
            color: const Color(0xff2A2A2A),
            height: 1,
            thickness: 0.5,
          ),
          itemBuilder: (context, index) {
            final m = members[index];
            final name = m.auth?.person?.name ?? m.auth?.business?.name ?? 'Unknown';
            final image = m.auth?.person?.image ?? m.auth?.business?.image;
            final role = m.role ?? 'MEMBER';
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Row(
                children: [
                  InitialsAvatar(
                    name: name,
                    imageUrl: image,
                    radius: 22.r,
                    fontSize: 14,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (role == 'ADMIN')
                          Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        if (widget.showHeader) _buildHeader(),
        if (widget.showTabs) _buildTabs(),
        // When tabs hidden (Announcement embed), always show chat + input
        if (!widget.showTabs) ...[
          _buildGeneralChat(),
          MessageInputBar(
            controller: ctrl.textController,
            chatId: widget.chatId ?? '',
            receiverId: '',
            onSend: () => ctrl.sendMessage(widget.chatId ?? ''),
          ),
        ],
        // When tabs shown (Community group), switch between tabs
        if (widget.showTabs) ...[
          if (_tabIndex == 0) ...[
            _buildGeneralChat(),
            MessageInputBar(
              controller: ctrl.textController,
              chatId: widget.chatId ?? '',
              receiverId: '',
              onSend: () => ctrl.sendMessage(widget.chatId ?? ''),
            ),
          ],
          if (_tabIndex == 1) Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: PostSection(groupId: widget.groupId),
                ),
                Positioned(
                  bottom: 16.h,
                  left: 20.w,
                  right: 20.w,
                  child: CustomElevatedButton(
                    title: 'Post your service',
                    borderRadius: 50,
                    height: 48,
                    onPress: () => Get.to(() => GalleryPostScreen(groupId: widget.groupId)),
                  ),
                ),
              ],
            ),
          ),
          if (_tabIndex == 2) ...[
            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: CustomTextField(
                controller: _jobSearchCtrl,
                hintText: 'Search jobs...',
                onChanged: (val) {
                  setState(() => _jobSearchQuery = val ?? '');
                },
              ),
            ),
            // Location type filter dropdown
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
                onChanged: (String? val) {
                  setState(() => _jobLocationType = val);
                },
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: Stack(
                children: [
                  JobSection(
                    groupId: widget.groupId,
                    searchQuery: _jobSearchQuery.isEmpty ? null : _jobSearchQuery,
                    jobType: _jobLocationType,
                  ),
                  // Post a job button pinned at bottom
                  Positioned(
                    bottom: 16.h,
                    left: 20.w,
                    right: 20.w,
                    child: CustomElevatedButton(
                      title: 'Post a job',
                      borderRadius: 50,
                      height: 48,
                      onPress: () => Get.to(() => JobPostScreen(groupId: widget.groupId)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_tabIndex == 3) _buildMembers(),
        ],
      ],
    );

    if (!widget.showHeader) return content;
    return Scaffold(body: content);
  }
}
