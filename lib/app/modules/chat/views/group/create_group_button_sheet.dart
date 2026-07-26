// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/label.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/chat/controller/all_chats_controller.dart';
import 'package:wisper/app/modules/chat/controller/group/create_group_controller.dart';
import 'package:wisper/app/modules/chat/widgets/create_header.dart';
import 'package:wisper/app/modules/chat/widgets/toggle_option.dart';
import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/widgets/common/searchable_tag_field.dart';
import 'package:wisper/app/urls.dart';

// ── Community Tag Options ─────────────────────────────────────────────────────

const _tradeTypes = [
  'Local B2B',
  'Local B2C',
  'B2B Export',
  'B2C Export',
  'B2B Import',
  'B2C Import',
];

const _marketTypes = ['Wholesale', 'Retail'];

const _businessCategories = [
  'Agriculture & Farming',
  'Livestock & Poultry',
  'Furniture & Home Décor',
  'Solar Panels & Energy',
  'Electronics & Tech',
  'Fashion & Clothing',
  'Food & Beverages',
  'Health & Pharmaceuticals',
  'Building & Construction',
  'Automotive & Spare Parts',
  'Beauty & Personal Care',
  'Stationery & Office Supplies',
  'Toys & Baby Products',
  'Sports & Fitness',
  'Industrial Equipment',
  'Other',
];

class CreateGroupButtomSheet extends StatefulWidget {
  final List<String> selectedMemberIds;

  const CreateGroupButtomSheet({super.key, required this.selectedMemberIds});

  @override
  State<CreateGroupButtomSheet> createState() => _CreateGroupButtomSheetState();
}

class _CreateGroupButtomSheetState extends State<CreateGroupButtomSheet> {
  final CreateGroupController createGroupController = Get.put(
    CreateGroupController(),
  );

  final TextEditingController _groupNameC = TextEditingController();
  final TextEditingController _groupDescriptionC = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool _isPrivate = false.obs;
  final RxBool _allowInvitation = true.obs;

  // Community tags
  String? _selectedTradeType;
  String? _selectedMarketType;
  String? _selectedCategory;

  // Name suffix
  String? _selectedSuffix; // 'MKT' or 'STY'
  static const _suffixOptions = ['MKT', 'STY'];

  // Business category search
  final TextEditingController _categorySearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _categorySuggestions = [];
  bool _showCategorySuggestions = false;
  bool _loadingCategories = false;

  Future<void> _searchCategories(String query) async {
    if (query.length < 2) {
      setState(() { _showCategorySuggestions = false; _categorySuggestions = []; });
      return;
    }
    setState(() => _loadingCategories = true);
    try {
      final response = await Get.find<NetworkCaller>().getRequest(
        '${Urls.baseUrl}/industries/search?q=${Uri.encodeComponent(query)}&limit=10',
      );
      if (response.isSuccess && response.responseData != null) {
        final data = response.responseData['data'] as List? ?? [];
        setState(() {
          _categorySuggestions = data.cast<Map<String, dynamic>>();
          _showCategorySuggestions = _categorySuggestions.isNotEmpty;
        });
      }
    } catch (_) {
      // Fallback to local list
      final filtered = _businessCategories
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .map((c) => {'name': c, 'sector': ''})
          .toList();
      setState(() {
        _categorySuggestions = filtered.cast<Map<String, dynamic>>();
        _showCategorySuggestions = filtered.isNotEmpty;
      });
    }
    setState(() => _loadingCategories = false);
  }

  @override
  void dispose() {
    _groupNameC.dispose();
    _groupDescriptionC.dispose();
    _categorySearchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Rebuild preview when name changes
    _groupNameC.addListener(() => setState(() {}));
  }

  void createGroup() {
    if (_groupNameC.text.trim().isEmpty) {
      showSnackBarMessage(context, 'Please enter community name', true);
      return;
    }
    if (_selectedSuffix == null) {
      showSnackBarMessage(context, 'Please select a suffix (MKT or STY)', true);
      return;
    }
    showLoadingOverLay(
      asyncFunction: () async => await performCreateGroup(),
      msg: 'Please wait...',
    );
  }

  Future<void> performCreateGroup() async {
    // Full name = base name + suffix
    final baseName = _groupNameC.text.trim();
    final fullName = _selectedSuffix != null ? '$baseName $_selectedSuffix' : baseName;

    // Build description with community tags appended
    final tagSuffix = [
      if (_selectedTradeType != null) 'Trade: $_selectedTradeType',
      if (_selectedMarketType != null) 'Market: $_selectedMarketType',
      if (_selectedCategory != null) 'Category: $_selectedCategory',
      if (_selectedSuffix != null) 'Suffix: $_selectedSuffix',
    ].join(' | ');

    final description = [
      _groupDescriptionC.text.trim(),
      if (tagSuffix.isNotEmpty) tagSuffix,
    ].join('\n');

    final bool isSuccess = await createGroupController.createGroup(
      name: fullName,
      description: description,
      members: widget.selectedMemberIds,
      isPrivate: _isPrivate.value,
      allowInvitation: _allowInvitation.value,
    );

    if (isSuccess && mounted) {
      final AllChatsController allChatsController =
          Get.find<AllChatsController>();
      await allChatsController.getAllChats();
      Get.offAll(() => const MainButtonNavbarScreen());
    } else if (mounted) {
      showSnackBarMessage(context, createGroupController.errorMessage, true);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildChipSelector({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () => onSelect(option),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xff1877F2)
                      : const Color(0xff1E1E1E),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xff1877F2)
                        : const Color(0xff3A3A3A),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Full screen — use Scaffold instead of bottom sheet constraints
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                heightBox16,
                CreateHeader(
                  bgColor: const Color(0xff051B33),
                  iconColor: const Color(0xff1F7DE9),
                  title: 'Create Community',
                  imagePath: Assets.images.userGroup.keyName,
                  onTap: () {
                    if (formKey.currentState!.validate()) {
                      createGroup();
                    }
                  },
                  trailinlgText: 'Create',
                ),
                heightBox10,
                const StraightLiner(height: 0.5),
                heightBox10,

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Group Name ───────────────────────────────────────
                        const Label(label: 'Community Name'),
                        heightBox8,
                        // Name field + suffix selector in one row
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xff1E1E1E),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: const Color(0xff2C2C2E)),
                          ),
                          child: Row(
                            children: [
                              // Name text field
                              Expanded(
                                child: TextFormField(
                                  controller: _groupNameC,
                                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                                  decoration: InputDecoration(
                                    hintText: 'Enter community name',
                                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              // Divider
                              Container(width: 1, height: 30.h, color: const Color(0xff3A3A3A)),
                              // Suffix selector
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: const Color(0xff1E1E1E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                                    ),
                                    builder: (_) => Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Select Suffix', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                                          SizedBox(height: 16.h),
                                          ..._suffixOptions.map((suffix) => GestureDetector(
                                            onTap: () {
                                              setState(() => _selectedSuffix = suffix);
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                                              margin: EdgeInsets.only(bottom: 8.h),
                                              decoration: BoxDecoration(
                                                color: _selectedSuffix == suffix
                                                    ? const Color(0xff1F3A5F)
                                                    : const Color(0xff2C2C2E),
                                                borderRadius: BorderRadius.circular(10.r),
                                                border: Border.all(
                                                  color: _selectedSuffix == suffix
                                                      ? const Color(0xff1F7DE9)
                                                      : Colors.transparent,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(suffix, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600)),
                                                  SizedBox(width: 10.w),
                                                  Text(
                                                    suffix == 'MKT' ? 'Market' : 'Society',
                                                    style: TextStyle(color: Colors.white54, fontSize: 13.sp),
                                                  ),
                                                  if (_selectedSuffix == suffix) ...[
                                                    const Spacer(),
                                                    Icon(Icons.check_circle, color: const Color(0xff1F7DE9), size: 18.sp),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          )).toList(),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedSuffix ?? 'MKT/STY',
                                        style: TextStyle(
                                          color: _selectedSuffix != null ? const Color(0xff1F7DE9) : Colors.white38,
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(Icons.arrow_drop_down, color: Colors.white38, size: 18.sp),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Preview of full name
                        if (_selectedSuffix != null && _groupNameC.text.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 6.h, left: 4.w),
                            child: Text(
                              'Preview: ${_groupNameC.text.trim()} $_selectedSuffix',
                              style: TextStyle(color: Colors.white54, fontSize: 11.sp),
                            ),
                          ),
                        heightBox12,

                        // ── Description ──────────────────────────────────────
                        const Label(label: 'Description'),
                        heightBox8,
                        CustomTextField(
                          controller: _groupDescriptionC,
                          hintText: 'Write description',
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                        ),
                        heightBox16,

                        // ── Tag 1: Trade Type ────────────────────────────────
                        SearchableTagField(
                          label: '1. Trade Type',
                          hint: 'Search trade type (e.g. Local B2B)',
                          options: _tradeTypes,
                          selected: _selectedTradeType,
                          onSelect: (v) => setState(() => _selectedTradeType = v),
                        ),

                        // ── Tag 2: Market Type ───────────────────────────────
                        SearchableTagField(
                          label: '2. Market Type',
                          hint: 'Search market type (e.g. Wholesale)',
                          options: _marketTypes,
                          selected: _selectedMarketType,
                          onSelect: (v) => setState(() => _selectedMarketType = v),
                        ),

                        // ── Tag 3: Business Category (searchable) ────────────
                        SearchableTagField(
                          label: '3. Business Category',
                          hint: 'Search category (e.g. Food & Beverages)',
                          options: _businessCategories,
                          selected: _selectedCategory,
                          onSelect: (v) => setState(() => _selectedCategory = v),
                        ),

                        // ── Toggles ──────────────────────────────────────────
                        Obx(() => ToggleOption(
                          title: 'Private Community',
                          subtitle: 'Only invited members can join',
                          onToggle: (v) => _isPrivate.value = v,
                          isToggled: _isPrivate.value,
                        )),
                        heightBox10,
                        Obx(() => ToggleOption(
                          isToggled: _allowInvitation.value,
                          title: 'Allow Member Invites',
                          subtitle: 'Let members invite others',
                          onToggle: (v) => _allowInvitation.value = v,
                        )),
                        heightBox12,

                        Text(
                          'Selected Members (${widget.selectedMemberIds.length})',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        heightBox24,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
