import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/chat/controller/all_community_controller.dart';
import 'package:wisper/app/modules/chat/model/communities_model.dart';
import 'package:wisper/app/modules/homepage/widget/community_list_view.dart';

/// Search for communities to join. Runs against `/groups/public?searchTerm=`,
/// listing communities you have not joined first.
class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  static const String _controllerTag = 'community_search';

  final TextEditingController _searchController = TextEditingController();

  /// Tagged so searching never overwrites the Home/Explore lists.
  final CommunityController _controller =
      Get.isRegistered<CommunityController>(tag: _controllerTag)
          ? Get.find<CommunityController>(tag: _controllerTag)
          : Get.put(CommunityController(), tag: _controllerTag);

  Timer? _debounce;
  String _query = '';

  /// Re-runs the *current* query, so refreshing after joining from a search
  /// result does not silently drop the search term.
  Future<void> _refresh() =>
      _controller.getCommunities(searchTerm: _query.isEmpty ? null : _query);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getCommunities();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String? value) {
    final query = (value ?? '').trim();
    setState(() => _query = query);

    // Debounce so a fast typist does not fire a request per keystroke.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _controller.getCommunities(searchTerm: query.isEmpty ? null : query);
    });
  }

  /// Communities you can still join come first — that is what this screen is for.
  List<CommunitiesItemModel> get _results {
    final items = List<CommunitiesItemModel>.from(_controller.communitiesData);
    items.sort((a, b) {
      final aJoined = (a.isJoined ?? false) ? 1 : 0;
      final bJoined = (b.isJoined ?? false) ? 1 : 0;
      return aJoined.compareTo(bJoined);
    });
    return items;
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
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xffB3B1B1),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomTextField(
                    controller: _searchController,
                    hintText: 'Search communities',
                    prefixIcon: Icons.search_rounded,
                    onChanged: _onQueryChanged,
                  ),
                ),
              ],
            ),
            heightBox16,
            Expanded(
              child: Obx(() {
                return CommunityListView(
                  isLoading: _controller.inProgress,
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
              }),
            ),
          ],
        ),
      ),
    );
  }
}
