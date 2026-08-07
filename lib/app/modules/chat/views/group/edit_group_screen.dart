// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/label.dart';
import 'package:wisper/app/modules/authentication/widget/auth_header.dart';
import 'package:wisper/app/modules/chat/controller/group/edit_group_controller.dart';
import 'package:wisper/app/modules/chat/controller/group/group_info_controller.dart';
import 'package:wisper/app/modules/chat/controller/all_chats_controller.dart';
import 'package:wisper/app/core/widgets/common/searchable_tag_field.dart';

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

  // Suffix dropdown — same options as create screen
  String? _selectedSuffix; // 'MKT' or 'STY'
  static const _suffixOptions = ['MKT', 'STY'];
  static const _knownSuffixVariants = ['MKT', 'STY', 'Mkt', 'Sty', 'mkt', 'sty'];

  @override
  void initState() {
    super.initState();
    _isPublic = widget.isPublic;
    _isAllowInvitation = widget.isAllowInvitation;
    _loadTagEditDate();
    _parseDescriptionAndPopulate(widget.groupCaption);
    // Strip suffix from name and set dropdown
    _extractAndSetSuffix(widget.groupName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  /// Strip suffix from the group name and store it in the dropdown variable.
  void _extractAndSetSuffix(String fullName) {
    for (final s in _knownSuffixVariants) {
      if (fullName.endsWith(' $s')) {
        _selectedSuffix = s.toUpperCase(); // normalise to 'MKT' or 'STY'
        _nameCtrl.text = fullName.substring(0, fullName.length - s.length - 1).trimRight();
        return;
      }
    }
    // No suffix found — just set the plain name
    _nameCtrl.text = fullName;
  }

  /// Parse "userDescription\nTrade: X | Market: Y | Category: Z"
  void _parseDescriptionAndPopulate(String raw) {
    if (raw.isEmpty) {
      _captionCtrl.text = '';
      return;
    }

    final lines = raw.split('\n');
    String userDescription = raw;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('Trade:') || line.contains('Market:') ||
          line.contains('Category:') || line.contains('Suffix:')) {
        final parts = line.split('|');
        for (final part in parts) {
          final trimmed = part.trim();
          if (trimmed.startsWith('Trade:')) {
            _selectedTradeType = trimmed.substring('Trade:'.length).trim();
          } else if (trimmed.startsWith('Market:')) {
            _selectedMarketType = trimmed.substring('Market:'.length).trim();
          } else if (trimmed.startsWith('Category:')) {
            _selectedCategory = trimmed.substring('Category:'.length).trim();
          }
        }
        userDescription = lines.sublist(0, i).join('\n').trim();
        break;
      }
    }

    _captionCtrl.text = userDescription;
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

  void _updateGroup() {
    if (_formKey.currentState!.validate()) {
      showLoadingOverLay(
        asyncFunction: () async => await _performUpdateGroup(),
        msg: 'Updating group...',
      );
    }
  }

  Future<void> _performUpdateGroup() async {
    // Build tag suffix — only include tags that are set
    final tagParts = <String>[
      if (_selectedTradeType != null && _selectedTradeType!.isNotEmpty)
        'Trade: $_selectedTradeType',
      if (_selectedMarketType != null && _selectedMarketType!.isNotEmpty)
        'Market: $_selectedMarketType',
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty)
        'Category: $_selectedCategory',
    ];

    // Clean user description — strip any existing tag lines first
    final cleanDesc = _captionCtrl.text.trim();

    final description = tagParts.isNotEmpty
        ? '$cleanDesc\n${tagParts.join(' | ')}'
        : cleanDesc;

    final String baseName = _nameCtrl.text.trim();
    final String fullName = _selectedSuffix != null && _selectedSuffix!.isNotEmpty
        ? '$baseName $_selectedSuffix'
        : baseName;

    final bool isSuccess = await editGroupController.editGroup(
      groupId: widget.groupId,
      name: fullName,
      caption: description,
      isPrivate: !_isPublic,
      allowInvitation: _isAllowInvitation,
    );

    if (isSuccess) {
      // Save tag edit date if tags were changed
      if (_tagsChanged) await _saveTagEditDate();

      final groupInfoController = Get.find<GroupInfoController>();
      await groupInfoController.getGroupInfo(widget.groupId);

      // Refresh chat inbox so name/image update shows immediately
      if (Get.isRegistered<AllChatsController>()) {
        Get.find<AllChatsController>().getAllChats();
      }

      Navigator.pop(context);
      showSnackBarMessage(context, 'Community updated successfully', false);
    } else {
      showSnackBarMessage(context, editGroupController.errorMessage, true);
    }
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
              // Name field + suffix dropdown in one row (same as create screen)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xff1E1E1E),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xff2C2C2E)),
                ),
                child: Row(
                  children: [
                    // Base name text field
                    Expanded(
                      child: TextFormField(
                        controller: _nameCtrl,
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
                    // Vertical divider
                    Container(width: 1, height: 30.h, color: const Color(0xff3A3A3A)),
                    // Suffix dropdown button
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: const Color(0xff1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                          ),
                          builder: (_) => StatefulBuilder(
                            builder: (ctx, setInner) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Select Suffix',
                                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                                  SizedBox(height: 16.h),
                                  ..._suffixOptions.map((suffix) => GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedSuffix = suffix);
                                      Navigator.pop(ctx);
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
                                          Text(suffix,
                                            style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600)),
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
                                color: _selectedSuffix != null
                                    ? const Color(0xff1F7DE9)
                                    : Colors.white38,
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
              if (_selectedSuffix != null && _nameCtrl.text.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 6.h, left: 4.w),
                  child: Text(
                    'Preview: ${_nameCtrl.text.trim()} $_selectedSuffix',
                    style: TextStyle(color: Colors.white54, fontSize: 11.sp),
                  ),
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

              // Tag rows — searchable dropdowns
              SearchableTagField(
                label: '1. Trade Type',
                hint: 'Search trade type (e.g. Local B2B)',
                options: _tradeTypes,
                selected: _selectedTradeType,
                enabled: _canEditTags,
                onSelect: (v) => setState(() {
                  _selectedTradeType = v;
                  _tagsChanged = true;
                }),
              ),
              SearchableTagField(
                label: '2. Market Type',
                hint: 'Search market type (e.g. Wholesale)',
                options: _marketTypes,
                selected: _selectedMarketType,
                enabled: _canEditTags,
                onSelect: (v) => setState(() {
                  _selectedMarketType = v;
                  _tagsChanged = true;
                }),
              ),
              SearchableTagField(
                label: '3. Business Category',
                hint: 'Search category (e.g. Food & Beverages)',
                options: _businessCategories,
                selected: _selectedCategory,
                enabled: _canEditTags,
                onSelect: (v) => setState(() {
                  _selectedCategory = v;
                  _tagsChanged = true;
                }),
              ),

              heightBox20,

              heightBox40,

              Center(
                child: CustomElevatedButton(
                  height: 46.h,
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
