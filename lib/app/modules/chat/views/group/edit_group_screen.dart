// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/label.dart';
import 'package:wisper/app/modules/authentication/widget/auth_header.dart';
import 'package:wisper/app/modules/chat/controller/group/edit_group_controller.dart';
import 'package:wisper/app/modules/chat/controller/group/group_info_controller.dart';
import 'package:wisper/app/modules/chat/widgets/toggle_option.dart';

// ── Community Tag Options ────────────────────────────────────────────────────
const _tradeTypes = [
  'Local B2B', 'Local B2C', 'B2B Export',
  'B2C Export', 'B2B Import', 'B2C Import',
];
const _marketTypes = ['Wholesale', 'Retail'];
const _businessCategories = [
  'Agriculture & Farming', 'Livestock & Poultry', 'Furniture & Home Décor',
  'Solar Panels & Energy', 'Electronics & Tech', 'Fashion & Clothing',
  'Food & Beverages', 'Health & Pharmaceuticals', 'Building & Construction',
  'Automotive & Spare Parts', 'Beauty & Personal Care',
  'Stationery & Office Supplies', 'Toys & Baby Products',
  'Sports & Fitness', 'Industrial Equipment', 'Other',
];

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupCaption;
  final bool isPublic;
  final bool isAllowInvitation;

  const EditGroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupCaption,
    required this.isPublic,
    required this.isAllowInvitation,
  });

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final EditGroupController editGroupController = EditGroupController();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();

  late bool _isPublic;
  late bool _isAllowInvitation;

  // Community tags
  String? _selectedTradeType;
  String? _selectedMarketType;
  String? _selectedCategory;

  // Tag edit restriction
  bool _canEditTags = true;
  DateTime? _lastTagEditDate;
  bool _tagsChanged = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.groupName;
    _captionCtrl.text = widget.groupCaption;
    _isPublic = widget.isPublic;
    _isAllowInvitation = widget.isAllowInvitation;
    _loadTagEditDate();
  }

  Future<void> _loadTagEditDate() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tag_edit_${widget.groupId}';
    final stored = prefs.getString(key);
    if (stored != null) {
      final lastEdit = DateTime.tryParse(stored);
      if (lastEdit != null) {
        final daysSince = DateTime.now().difference(lastEdit).inDays;
        setState(() {
          _lastTagEditDate = lastEdit;
          _canEditTags = daysSince >= 30;
        });
      }
    }
  }

  Future<void> _saveTagEditDate() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tag_edit_${widget.groupId}';
    await prefs.setString(key, DateTime.now().toIso8601String());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  void _updateGroup() {
    if (_formKey.currentState!.validate()) {
      showLoadingOverLay(
        asyncFunction: () async => await _performUpdateGroup(),
        msg: 'Updating group...',
      );
    }
  }

  Future<void> _performUpdateGroup() async {
    // Build description with community tags
    final tagSuffix = [
      if (_selectedTradeType != null) 'Trade: $_selectedTradeType',
      if (_selectedMarketType != null) 'Market: $_selectedMarketType',
      if (_selectedCategory != null) 'Category: $_selectedCategory',
    ].join(' | ');

    final description = [
      _captionCtrl.text.trim(),
      if (tagSuffix.isNotEmpty) tagSuffix,
    ].join('\n');

    final bool isSuccess = await editGroupController.editGroup(
      groupId: widget.groupId,
      name: _nameCtrl.text.trim(),
      caption: description,
      isPrivate: !_isPublic,
      allowInvitation: _isAllowInvitation,
    );

    if (isSuccess) {
      // Save tag edit date if tags were changed
      if (_tagsChanged) await _saveTagEditDate();

      final groupInfoController = Get.find<GroupInfoController>();
      await groupInfoController.getGroupInfo(widget.groupId);
      Navigator.pop(context);
      showSnackBarMessage(context, 'Community updated successfully', false);
    } else {
      showSnackBarMessage(context, editGroupController.errorMessage, true);
    }
  }

  Widget _buildChipSelector({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String) onSelect,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white70 : Colors.white30,
              ),
            ),
            if (!enabled) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Editable in ${30 - DateTime.now().difference(_lastTagEditDate!).inDays} days',
                  style: TextStyle(fontSize: 10.sp, color: Colors.orange),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: enabled
                  ? () {
                      onSelect(option);
                      _tagsChanged = true;
                    }
                  : null,
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
                        : enabled
                            ? const Color(0xff3A3A3A)
                            : const Color(0xff2A2A2A),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected
                        ? Colors.white
                        : enabled
                            ? Colors.white70
                            : Colors.white24,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBox60,
              AuthHeader(title: 'Edit Group Details'),
              heightBox30,

              const Label(label: 'Group Name'),
              heightBox10,
              CustomTextField(
                controller: _nameCtrl,
                hintText: 'Enter group name',
                keyboardType: TextInputType.text,
                validator: ValidatorService.validateSimpleField,
              ),

              heightBox20,
              const Label(label: 'Group Description'),
              heightBox10,
              CustomTextField(
                controller: _captionCtrl,
                hintText: 'Write something about the group',
                keyboardType: TextInputType.text,
              ),

              heightBox24,

              // ── Community Tags ──────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Community Tags',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: _canEditTags
                          ? const Color(0xff11AE46).withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _canEditTags ? 'Editable' : 'Locked (once/month)',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: _canEditTags
                            ? const Color(0xff11AE46)
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Tags can only be edited once per month.',
                style: TextStyle(fontSize: 11.sp, color: Colors.white38),
              ),
              heightBox16,

              _buildChipSelector(
                title: '1. Trade Type',
                options: _tradeTypes,
                selected: _selectedTradeType,
                onSelect: (v) => setState(() => _selectedTradeType = v),
                enabled: _canEditTags,
              ),

              _buildChipSelector(
                title: '2. Market Type',
                options: _marketTypes,
                selected: _selectedMarketType,
                onSelect: (v) => setState(() => _selectedMarketType = v),
                enabled: _canEditTags,
              ),

              _buildChipSelector(
                title: '3. Business Category',
                options: _businessCategories,
                selected: _selectedCategory,
                onSelect: (v) => setState(() => _selectedCategory = v),
                enabled: _canEditTags,
              ),

              heightBox20,

              ToggleOption(
                title: 'Private Group',
                subtitle: 'Only invited members can join',
                isToggled: !_isPublic,
                onToggle: (bool value) => setState(() => _isPublic = !value),
              ),
              heightBox20,
              ToggleOption(
                title: 'Allow Member Invites',
                subtitle: 'Let members invite others',
                isToggled: _isAllowInvitation,
                onToggle: (bool value) =>
                    setState(() => _isAllowInvitation = value),
              ),

              heightBox40,

              Center(
                child: CustomElevatedButton(
                  height: 56.h,
                  title: 'Update',
                  onPress: _updateGroup,
                  color: Colors.blue,
                ),
              ),
              heightBox50,
            ],
          ),
        ),
      ),
    );
  }
}
