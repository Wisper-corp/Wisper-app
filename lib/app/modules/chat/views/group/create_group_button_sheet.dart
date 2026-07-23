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

  @override
  void dispose() {
    _groupNameC.dispose();
    _groupDescriptionC.dispose();
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
                  imagePath: Assets.images.education.keyName,
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

                        // ── Tag 3: Business Category ─────────────────────────
                        _buildChipSelector(
                          title: '3. Business Category',
                          options: _businessCategories,
                          selected: _selectedCategory,
                          onSelect: (v) =>
                              setState(() => _selectedCategory = v),
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
