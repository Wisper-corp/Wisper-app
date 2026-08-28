import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/saved/controller/saved_controller.dart';
import 'package:wisper/app/modules/saved/widget/saved_item_tile.dart';

/// Everything the person kept, newest first.
///
/// Service posts and forum posts sit in one list because that is how they were
/// saved — a filter narrows it when the list gets long, and search matches the
/// text, the author and the community it came from.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final SavedController _controller = Get.isRegistered<SavedController>()
      ? Get.find<SavedController>()
      : Get.put(SavedController(), permanent: true);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  /// null means everything.
  String? _type;

  static const List<({String? value, String label})> _filters = [
    (value: null, label: 'All'),
    (value: 'service', label: 'Services'),
    (value: 'forum', label: 'Forum'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() =>
      _controller.getSavedItems(type: _type, searchTerm: _query);

  void _onQueryChanged(String? value) {
    final query = (value ?? '').trim();
    setState(() => _query = query);
    // Debounce so a fast typist does not fire a request per keystroke.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.only(right: 12.w, top: 4.h, bottom: 4.h),
                      child: Icon(Icons.arrow_back_rounded, size: 22.r),
                    ),
                  ),
                  Text(
                    'Saved',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              CustomTextField(
                controller: _searchController,
                hintText: 'Search saved posts',
                prefixIcon: Icons.search_rounded,
                onChanged: _onQueryChanged,
              ),
              SizedBox(height: 12.h),
              _buildFilters(),
              SizedBox(height: 4.h),
              Expanded(
                child: Obx(() {
                  if (_controller.inProgress && _controller.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_controller.items.isEmpty) return _buildEmpty();

                  return RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: EdgeInsets.only(top: 8.h, bottom: 24.h),
                      itemCount: _controller.items.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) =>
                          SavedItemTile(item: _controller.items[index]),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 34.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = _type == filter.value;
          return GestureDetector(
            onTap: () {
              setState(() => _type = filter.value);
              _load();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xff1F7DE9)
                    : const Color(0xff17191C),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xffC9D1D9),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    // Searching for something that is not there is a different message from
    // having saved nothing at all.
    final searching = _query.isNotEmpty;
    return ListView(
      children: [
        SizedBox(height: 80.h),
        Icon(
          searching ? Icons.search_off_rounded : Icons.bookmark_border_rounded,
          size: 48.r,
          color: Colors.white24,
        ),
        SizedBox(height: 12.h),
        Center(
          child: Text(
            searching ? 'No matches for "$_query"' : 'Nothing saved yet',
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              searching
                  ? 'Try a shorter or different word.'
                  : 'Tap the bookmark on a service or forum post to keep it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: Colors.white38),
            ),
          ),
        ),
      ],
    );
  }
}
