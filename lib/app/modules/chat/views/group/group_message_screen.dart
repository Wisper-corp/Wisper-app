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
import 'package:wisper/app/modules/chat/controller/group/all_group_member_controller.dart';
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

  static const _tabs = ['General Chat', 'Posts', 'Jobs', 'Members'];

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
    super.dispose();
  }

  Widget _buildHeader() {
    return Obx(() {
      final members = membersCtrl.groupMemnersData ?? [];
      final memberCount = members.length;
      final previewMembers = members.take(3).toList();

      return Container(
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
      );
    });
  }

  Widget _buildTabs() {
    return Column(
      children: [
        SizedBox(
          height: 36.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => SizedBox(width: 24.w),
            itemBuilder: (context, i) {
              final selected = _tabIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _tabIndex = i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _tabs[i],
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.white38,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      height: 2,
                      width: _tabs[i].length * 7.0,
                      color: selected ? Colors.blue : Colors.transparent,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        StraightLiner(height: 0.4, color: const Color(0xff454545)),
      ],
    );
  }

  Widget _buildGeneralChat() {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Expanded(child: Center(child: ChatShimmerEffectWidget()));
      }

      if (ctrl.messages.isEmpty) {
        return Expanded(
          child: Center(
            child: EmptyGroupInfoCard(
              isGroup: true,
              name: widget.groupName ?? '',
              member: '5',
            ),
          ),
        );
      }

      return Expanded(
        child: ListView.builder(
          reverse: true,
          controller: ctrl.scrollController,
          padding: EdgeInsets.all(10.r),
          itemCount: ctrl.messages.length,
          itemBuilder: (context, index) {
            final msg = ctrl.messages[index];
            final isMe = msg[SocketMessageKeys.senderId] == ctrl.userAuthId;
            final imageUrl = msg[SocketMessageKeys.imageUrl] ?? "";
            return MessageBubble(
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
                PostSection(groupId: widget.groupId),
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
          if (_tabIndex == 2) JobSection(groupId: widget.groupId),
          if (_tabIndex == 3) _buildMembers(),
        ],
      ],
    );

    if (!widget.showHeader) return content;
    return Scaffold(body: content);
  }
}
