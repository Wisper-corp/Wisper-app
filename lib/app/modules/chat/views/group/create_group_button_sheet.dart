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

  void createGroup() {
    if (_groupNameC.text.trim().isEmpty) {
      showSnackBarMessage(context, 'Please enter group name', true);
      return;
    }
    showLoadingOverLay(
      asyncFunction: () async => await performCreateGroup(),
      msg: 'Please wait...',
    );
  }

  Future<void> performCreateGroup() async {
    // Build description with community tags appended
    final tagSuffix = [
      if (_selectedTradeType != null) 'Trade: $_selectedTradeType',
      if (_selectedMarketType != null) 'Market: $_selectedMarketType',
      if (_selectedCategory != null) 'Category: $_selectedCategory',
    ].join(' | ');

    final description = [
      _groupDescriptionC.text.trim(),
      if (tagSuffix.isNotEmpty) tagSuffix,
    ].join('\n');

    final bool isSuccess = await createGroupController.createGroup(
      name: _groupNameC.text.trim(),
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
                        CustomTextField(
                          controller: _groupNameC,
                          hintText: 'Enter community name',
                          keyboardType: TextInputType.name,
                          validator: ValidatorService.validateSimpleField,
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
                        _buildChipSelector(
                          title: '1. Trade Type',
                          options: _tradeTypes,
                          selected: _selectedTradeType,
                          onSelect: (v) =>
                              setState(() => _selectedTradeType = v),
                        ),

                        // ── Tag 2: Market Type ───────────────────────────────
                        _buildChipSelector(
                          title: '2. Market Type',
                          options: _marketTypes,
                          selected: _selectedMarketType,
                          onSelect: (v) =>
                              setState(() => _selectedMarketType = v),
                        ),

                        // ── Tag 3: Business Category (searchable) ────────────
                        _buildSectionTitle('3. Business Category'),
                        // Search field
                        TextFormField(
                          controller: _categorySearchCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search category (e.g. Food & Beverages)',
                            hintStyle: const TextStyle(color: Color(0xff8C8C8C), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xff1E1E1E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(color: Color(0xff2C2C2E)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(color: Color(0xff2799EA)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: _loadingCategories
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff2799EA))))
                                : _selectedCategory != null
                                    ? Icon(Icons.check_circle, color: const Color(0xff2799EA), size: 20.sp)
                                    : Icon(Icons.search, color: Colors.grey, size: 20.sp),
                          ),
                          onChanged: (v) {
                            if (_selectedCategory != null) setState(() => _selectedCategory = null);
                            _searchCategories(v);
                          },
                        ),
                        // Show selected category chip
                        if (_selectedCategory != null) ...[
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xff1877F2),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_selectedCategory!, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                                SizedBox(width: 6.w),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedCategory = null;
                                    _categorySearchCtrl.clear();
                                  }),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Suggestions dropdown
                        if (_showCategorySuggestions)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xff1E1E1E),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: const Color(0xff2C2C2E)),
                            ),
                            constraints: BoxConstraints(maxHeight: 180.h),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _categorySuggestions.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xff2C2C2E)),
                              itemBuilder: (context, index) {
                                final item = _categorySuggestions[index];
                                final name = item['name'] as String? ?? '';
                                final sector = item['sector'] as String? ?? '';
                                return ListTile(
                                  dense: true,
                                  title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  subtitle: sector.isNotEmpty ? Text(sector, style: const TextStyle(color: Color(0xff8C8C8C), fontSize: 11)) : null,
                                  onTap: () => setState(() {
                                    _selectedCategory = name;
                                    _categorySearchCtrl.text = name;
                                    _showCategorySuggestions = false;
                                    _categorySuggestions = [];
                                  }),
                                );
                              },
                            ),
                          ),
                        SizedBox(height: 16.h),

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
