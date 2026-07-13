import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/chat/widgets/select_option_widget.dart';
import 'package:wisper/app/modules/job/controller/feed_job_controller.dart';
import 'package:wisper/app/modules/job/views/job_section.dart';
import 'package:wisper/app/modules/homepage/controller/all_role_controller.dart';
import 'package:wisper/app/modules/homepage/views/role_section.dart';
import 'package:wisper/app/modules/post/controller/gig_market_search_controller.dart';
import 'package:wisper/app/modules/post/widgets/post_card.dart';
import 'package:wisper/app/core/widgets/common/star_rating.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final AllFeedJobController jobController = Get.find<AllFeedJobController>();
  final GigMarketSearchController gigController =
      Get.put(GigMarketSearchController());

  // 0 = Jobs, 1 = Gig Market, 2 = Roles
  int selectedIndex = 0;

  String? selectedLocationType;
  String? selectedCountry;
  String _previousSearch = '';
  String? _previousLocation;

  // Countries list
  static const List<String> _countries = [
    'Nigeria', 'Pakistan', 'Bangladesh', 'India', 'Ghana',
    'Kenya', 'South Africa', 'United Kingdom', 'United States',
    'Canada', 'Australia', 'Germany', 'France', 'UAE',
  ];

  @override
  void initState() {
    super.initState();
    _fetchIfNeeded();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _fetchIfNeeded() {
    final q = searchController.text.trim();
    if (selectedIndex == 0) {
      if (q != _previousSearch || selectedLocationType != _previousLocation) {
        jobController.resetPagination();
        jobController.getJobs(
          searchQuery: q.isEmpty ? null : q,
          locationType: selectedLocationType,
        );
        _previousSearch = q;
        _previousLocation = selectedLocationType;
      }
    } else if (selectedIndex == 1) {
      gigController.search(q, country: selectedCountry);
    } else if (selectedIndex == 2) {
      Get.find<AllRoleController>().getAllRole(q.isEmpty ? null : q, country: selectedCountry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            heightBox30,
            // Search bar
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color.fromARGB(255, 179, 177, 177),
                  ),
                ),
                Expanded(
                  child: CustomTextField(
                    hintText: selectedIndex == 1
                        ? 'Search gig market...'
                        : selectedIndex == 2
                        ? 'Search members...'
                        : 'Search jobs...',
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {});
                      _fetchIfNeeded();
                    },
                  ),
                ),
              ],
            ),

            heightBox12,

            // Location filter — Jobs tab: locationType dropdown
            if (selectedIndex == 0)
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 44.h,
                  width: MediaQuery.of(context).size.width * 0.79,
                  child: CustomTextField(
                    hintText: 'Location type',
                    value: selectedLocationType,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any location')),
                      DropdownMenuItem(value: 'REMOTE', child: Text('Remote')),
                      DropdownMenuItem(value: 'ON_SITE', child: Text('On-site')),
                      DropdownMenuItem(value: 'HYBRID', child: Text('Hybrid')),
                    ],
                    onChanged: (String? newValue) {
                      setState(() => selectedLocationType = newValue);
                      _fetchIfNeeded();
                    },
                  ),
                ),
              ),

            // Country filter — Gig Market and Members tabs
            if (selectedIndex == 1 || selectedIndex == 2)
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 44.h,
                  width: MediaQuery.of(context).size.width * 0.79,
                  child: CustomTextField(
                    hintText: 'Filter by country',
                    value: selectedCountry,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All countries')),
                      ..._countries.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (String? newValue) {
                      setState(() => selectedCountry = newValue);
                      _fetchIfNeeded();
                    },
                  ),
                ),
              ),

            if (selectedIndex == 0 || selectedIndex == 1 || selectedIndex == 2) heightBox20,

            // Tabs: Jobs | Gig Market | Roles
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => selectedIndex = 0);
                    _fetchIfNeeded();
                  },
                  child: SelectOptionWidget(
                    currentIndex: 0,
                    selectedIndex: selectedIndex,
                    title: 'Jobs',
                    lineColor: LightThemeColors.blueColor,
                  ),
                ),
                SizedBox(width: 24.w),
                GestureDetector(
                  onTap: () {
                    setState(() => selectedIndex = 1);
                    _fetchIfNeeded();
                  },
                  child: SelectOptionWidget(
                    currentIndex: 1,
                    selectedIndex: selectedIndex,
                    title: 'Gig Market',
                    lineColor: LightThemeColors.blueColor,
                  ),
                ),
                SizedBox(width: 24.w),
                GestureDetector(
                  onTap: () => setState(() => selectedIndex = 2),
                  child: SelectOptionWidget(
                    currentIndex: 2,
                    selectedIndex: selectedIndex,
                    title: 'Members',
                    lineColor: LightThemeColors.blueColor,
                  ),
                ),
              ],
            ),

            const StraightLiner(height: 0.5, color: Color(0xff454545)),
            SizedBox(height: 12.h),

            // Content
            Expanded(
              child: selectedIndex == 0
                  ? JobSection(
                      searchQuery: searchController.text.trim(),
                      jobType: selectedLocationType,
                    )
                  : selectedIndex == 1
                      ? _GigMarketResults(controller: gigController)
                      : RoleSection(
                          searchQuery: searchController.text.trim(),
                          country: selectedCountry,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Gig Market search results widget
class _GigMarketResults extends StatelessWidget {
  final GigMarketSearchController controller;
  const _GigMarketResults({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.inProgress.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.results.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade600),
              const SizedBox(height: 12),
              Text(
                'Search gigs by job title e.g "Web Developer"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: controller.results.length,
        separatorBuilder: (_, __) => const StraightLiner(
          height: 0.5,
          color: Color(0xff2A2A2A),
        ),
        itemBuilder: (context, index) {
          final post = controller.results[index];
          final time = DateFormatter(post.createdAt).getRelativeTimeFormat();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: PostCard(
              isPerson: post.author?.person != null,
              onTapComment: () {},
              ownerId: post.author?.id ?? '',
              trailing: const SizedBox.shrink(),
              ownerName: post.author?.person != null
                  ? post.author?.person?.name ?? ''
                  : post.author?.business?.name ?? '',
              ownerImage: post.author?.person != null
                  ? post.author?.person?.image ?? ''
                  : post.author?.business?.image ?? '',
              ownerProfession: post.author?.person != null
                  ? post.author?.person?.title ?? ''
                  : post.author?.business?.industry ?? '',
              postImage: post.images.isNotEmpty ? post.images : [],
              postDescription: post.caption ?? '',
              postTime: time,
              views: post.views.toString(),
              price: post.price,
              currency: post.currency,
              deliveryTime: post.deliveryTime,
              ratingWidget: post.ratingCount > 0
                  ? StarRating(rating: post.avgRating, count: post.ratingCount)
                  : null,
            ),
          );
        },
      );
    });
  }
}
