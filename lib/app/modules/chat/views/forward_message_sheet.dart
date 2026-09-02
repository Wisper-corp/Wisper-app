import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';

/// One conversation a message can be forwarded to.
class ForwardTarget {
  const ForwardTarget({
    required this.chatId,
    required this.name,
    required this.image,
    required this.isGroup,
  });

  final String chatId;
  final String name;
  final String image;
  final bool isGroup;
}

/// The conversations to offer, read from the chat list the socket already
/// keeps — no extra request, and the ordering people already recognise.
List<ForwardTarget> forwardTargets(
  List<Map<String, dynamic>> chats, {
  required String myAuthId,
  String? excludeChatId,
  String query = '',
}) {
  final needle = query.trim().toLowerCase();
  final out = <ForwardTarget>[];

  for (final chat in chats) {
    final chatId = chat['id']?.toString() ?? '';
    if (chatId.isEmpty || chatId == excludeChatId) continue;

    final type = (chat['type']?.toString() ?? 'INDIVIDUAL').toUpperCase();
    String name = '';
    String image = '';

    if (type == 'GROUP') {
      name = chat['group']?['name']?.toString() ?? 'Community';
      image = chat['group']?['image']?.toString() ?? '';
    } else if (type == 'CLASS') {
      name = chat['chatClass']?['name']?.toString() ?? 'Class';
      image = chat['chatClass']?['image']?.toString() ?? '';
    } else {
      // The other person in a one-to-one, whichever side of it we are on.
      final participants = chat['participants'];
      if (participants is List) {
        for (final p in participants) {
          if (p is! Map) continue;
          final auth = p['auth'];
          if (auth is! Map || auth['id']?.toString() == myAuthId) continue;
          final profile = auth['person'] ?? auth['business'];
          if (profile is Map) {
            name = profile['name']?.toString() ?? '';
            image = profile['image']?.toString() ?? '';
          }
        }
      }
      if (name.isEmpty) name = chat['receiverName']?.toString() ?? 'Chat';
      if (image.isEmpty) image = chat['receiverImage']?.toString() ?? '';
    }

    if (needle.isNotEmpty && !name.toLowerCase().contains(needle)) continue;

    out.add(ForwardTarget(
      chatId: chatId,
      name: name,
      image: image,
      isGroup: type != 'INDIVIDUAL',
    ));
  }
  return out;
}

/// Picks a conversation to forward a message into.
///
/// Returns the chat id chosen, or null if the sheet was dismissed.
Future<String?> showForwardSheet(
  BuildContext context, {
  required String fromChatId,
}) {
  final socket = Get.find<SocketService>();
  final myAuthId = StorageUtil.getData(StorageUtil.userId) ?? '';
  final query = ''.obs;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: const Color(0xff121417),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 38.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xff3A4048),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 14.h),
            Text('Forward to',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                onChanged: (v) => query.value = v,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle:
                      TextStyle(color: Colors.grey[500], fontSize: 14.sp),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey[500], size: 20.sp),
                  filled: true,
                  fillColor: const Color(0xff1B1E22),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: Obx(() {
                final targets = forwardTargets(
                  socket.socketFriendList.toList(),
                  myAuthId: myAuthId,
                  excludeChatId: fromChatId,
                  query: query.value,
                );
                if (targets.isEmpty) {
                  return Center(
                    child: Text(
                      'No other conversations',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 14.sp),
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: targets.length,
                  itemBuilder: (_, i) {
                    final t = targets[i];
                    return ListTile(
                      onTap: () => Navigator.of(sheetContext).pop(t.chatId),
                      leading: InitialsAvatar(
                        name: t.name,
                        imageUrl:
                            t.image.startsWith('http') ? t.image : null,
                        radius: 20.r,
                        fontSize: 14,
                      ),
                      title: Text(
                        t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white, fontSize: 14.sp),
                      ),
                      subtitle: t.isGroup
                          ? Text('Community',
                              style: TextStyle(
                                  color: const Color(0xff8B949E),
                                  fontSize: 11.sp))
                          : null,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    ),
  );
}
