import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/chat/controller/all_community_controller.dart';
import 'package:wisper/app/modules/chat/model/communities_model.dart';
import 'package:wisper/app/modules/homepage/widget/community_list_view.dart';
import 'package:wisper/gen/assets.gen.dart';

/// Home is community navigation: the communities you have joined ("Home") and
/// the ones you could join ("Explore"), plus an inline search over both.
///
/// All three are driven by a single `/groups/public` call split on `isJoined`.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CommunityController _communityController =
      Get.isRegistered<CommunityController>()
          ? Get.find<CommunityController>()
          : Get.put(CommunityController());

  static const List<String> _tabs = ['Home', 'Explore'];

  /// Explore only suggests communities with real activity behind them, so the
  /// list is not flooded with empty or abandoned ones. Joined communities and
  /// search results are never filtered by size — you already chose those, or
  /// you are looking for one by name.
  static const int _minExploreMembers = 30;
  int _selectedIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _communityController.getCommunities();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _communityController.getCommunities(
        searchTerm: _searching && _query.isNotEmpty ? _query : null,
      );

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      _query = '';
      _searchController.clear();
    });
    _communityController.getCommunities();
  }

  void _onQueryChanged(String? value) {
    final query = (value ?? '').trim();
    setState(() => _query = query);

    // Debounce so a fast typist does not fire a request per keystroke.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _communityController.getCommunities(
        searchTerm: query.isEmpty ? null : query,
      );
    });
  }

  /// Search lists communities you can still join first — that is its purpose.
  List<CommunitiesItemModel> get _results {
    final items =
        List<CommunitiesItemModel>.from(_communityController.communitiesData);
    items.sort((a, b) {
      final aJoined = (a.isJoined ?? false) ? 1 : 0;
      final bJoined = (b.isJoined ?? false) ? 1 : 0;
      return aJoined.compareTo(bJoined);
    });
    return items;
  }

  List<CommunitiesItemModel> _communities({required bool joined}) {
    final items = _communityController.communitiesData
        .where((c) => (c.isJoined ?? false) == joined);
    if (joined) return items.toList();
    return items
        .where((c) => (c.memberCount ?? 0) >= _minExploreMembers)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: Column(
          children: [
            heightBox40,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searching ? 'Search' : 'Home',
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                CircleIconWidget(
                  imagePath: Assets.images.search.keyName,
                  iconRadius: 18.r,
                  onTap: _toggleSearch,
                ),
              ],
            ),
            heightBox16,
            if (!_searching) _buildTabs(),
            if (_searching)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: CustomTextField(
                  controller: _searchController,
                  hintText: 'Search communities',
                  prefixIcon: Icons.search_rounded,
                  onChanged: _onQueryChanged,
                ),
              ),
            StraightLiner(height: 0.4, color: const Color(0xff454545)),
            Expanded(
              child: Obx(() {
                if (_searching) {
                  return CommunityListView(
                    isLoading: _communityController.inProgress,
                    items: _results,
                    onRefresh: _refresh,
                    emptyIcon: Icons.search_off_rounded,
                    emptyTitle: _query.isEmpty
                        ? 'Find a community'
                        : 'No matches for "$_query"',
                    emptyMessage: _query.isEmpty
                        ? 'Search by name to find a community to join.'
                        : 'Try a shorter or different name.',
                  );
                }

                final isJoinedTab = _selectedIndex == 0;
                return CommunityListView(
                  isLoading: _communityController.inProgress,
                  items: _communities(joined: isJoinedTab),
                  onRefresh: _refresh,
                  emptyTitle: isJoinedTab
                      ? 'No communities yet'
                      : 'Nothing to suggest right now',
                  emptyMessage: isJoinedTab
                      ? 'Communities you join will show up here. Open Explore to find your first one.'
                      : 'We only suggest communities with at least $_minExploreMembers members. '
                          'Use search to find a smaller one by name.',
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 34.h,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedIndex = index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _tabs[index],
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xff93A4B0),
                    ),
                  ),
                  heightBox6,
                  Container(
                    height: 2.h,
                    width: 72.w,
                    color: isSelected ? Colors.blue : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
