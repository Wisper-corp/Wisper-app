import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/chat/model/communities_model.dart';
import 'package:wisper/app/modules/chat/views/group/group_message_screen.dart';
import 'package:wisper/app/modules/homepage/widget/community_card.dart';

/// Shared list body for the community lists (Home, Explore and search
/// results). Handles the loading, empty and populated states.
class CommunityListView extends StatelessWidget {
  final bool isLoading;
  final List<CommunitiesItemModel> items;

  /// Shown when [items] is empty — an empty list is an invitation to act, so
  /// each caller passes copy that says what to do next.
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function()? onRefresh;

  const CommunityListView({
    super.key,
    required this.isLoading,
    required this.items,
    required this.emptyTitle,
    required this.emptyMessage,
    this.emptyIcon = Icons.groups_2_outlined,
    this.onRefresh,
  });

  Future<void> _openCommunity(CommunitiesItemModel item) async {
    await Get.to(
      () => GroupChatScreen(
        chatId: item.chatId ?? '',
        groupId: item.id,
        groupName: item.name,
        groupImage: item.image,
        hasJoined: item.isJoined ?? false,
      ),
    );

    // The user may have joined (or left) while inside the community, which
    // moves it between the Home and Explore lists — re-read on the way back.
    await onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      final empty = _EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
      // Keep pull-to-refresh reachable even with nothing in the list.
      if (onRefresh == null) return empty;
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: 120.h), empty],
        ),
      );
    }

    final list = ListView.separated(
      padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        color: const Color(0xff2A2A2A),
        height: 1,
        thickness: 0.5,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return CommunityCard(item: item, onTap: () => _openCommunity(item));
      },
    );

    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40.sp, color: const Color(0xff4D5860)),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.4,
                color: const Color(0xff98A2B3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
