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
import 'package:wisper/app/core/widgets/common/searchable_tag_field.dart';
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

  // Suffix protection
  String _suffix = ''; // e.g. ' Mkt' or ' Sty'
  // All recognised suffix display forms
  static const _knownSuffixes = [' Mkt', ' Sty', ' MKT', ' STY', ' mkt', ' sty'];

  @override
  void initState() {
    super.initState();
    _isPublic = widget.isPublic;
    _isAllowInvitation = widget.isAllowInvitation;
    _loadTagEditDate();
    // Extract suffix first, THEN populate name field
    _extractSuffix(widget.groupName);
    _parseDescriptionAndPopulate(widget.groupCaption);
    // Add listener AFTER name is set so init doesn't trigger enforcement loop
    _nameCtrl.addListener(_enforceSuffix);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_enforceSuffix);
    _nameCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  /// Detect and store the suffix from the existing group name
  void _extractSuffix(String name) {
    for (final s in _knownSuffixes) {
      if (name.endsWith(s)) {
        // Normalise to canonical form
        _suffix = s.toLowerCase().contains('mkt') ? ' Mkt' : ' Sty';
        return;
      }
    }
    // No suffix found — no enforcement needed
    _suffix = '';
  }

  bool _enforcingNow = false;
  void _enforceSuffix() {
    if (_suffix.isEmpty || _enforcingNow) return;
    final text = _nameCtrl.text;
    if (text.endsWith(_suffix)) return; // already correct — do nothing

    _enforcingNow = true;

    // Strip any partial or full suffix variant the user may have typed
    String base = text;
    for (final s in _knownSuffixes) {
      if (base.endsWith(s)) {
        base = base.substring(0, base.length - s.length);
        break;
      }
    }
    // Also strip partial suffix characters at the end (e.g. user deleted 't' leaving ' Mk')
    final suffixTrimmed = _suffix.trim(); // 'Mkt' or 'Sty'
    for (int len = suffixTrimmed.length - 1; len >= 1; len--) {
      final partial = ' ${suffixTrimmed.substring(0, len)}';
      if (base.endsWith(partial)) {
        base = base.substring(0, base.length - partial.length);
        break;
      }
    }
    base = base.trimRight();

    // Re-append the correct suffix
    final newText = '$base$_suffix';

    // Place cursor just before the suffix
    final cursorPos = newText.length - _suffix.length;
    _nameCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPos.clamp(0, newText.length)),
    );

    _enforcingNow = false;
  }

  /// Parse "userDescription\nTrade: X | Market: Y | Category: Z | Suffix: S"
  /// Sets tag fields and strips tag line from description controller
  void _parseDescriptionAndPopulate(String raw) {
    if (raw.isEmpty) {
      _nameCtrl.text = widget.groupName;
      _captionCtrl.text = raw;
      return;
    }

    _nameCtrl.text = widget.groupName;

    final lines = raw.split('\n');
    String userDescription = raw;

    // Find the tag line — it contains "Trade:" or "Market:" or "Category:"
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('Trade:') || line.contains('Market:') || line.contains('Category:') || line.contains('Suffix:')) {
        // Parse each tag from this line
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
          // Suffix is metadata — don't need to display separately
        }
        // Strip the tag line so only user description shows in the text field
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

  void _showSelectionSheet({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          Container(width: 40.w, height: 4.h,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 16.h),
          Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
          SizedBox(height: 8.h),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xff2A2A2A), height: 1),
              itemBuilder: (ctx, i) {
                final opt = options[i];
                final isSelected = selected == opt;
                return ListTile(
                  title: Text(opt, style: TextStyle(
                    fontSize: 14.sp, color: isSelected ? const Color(0xff1877F2) : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
                  trailing: isSelected ? const Icon(Icons.check, color: Color(0xff1877F2)) : null,
                  onTap: () {
                    onSelect(opt);
                    _tagsChanged = true;
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildTagRow({
    required String label,
    required String? selected,
    required List<String> options,
    required void Function(String) onSelect,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () => _showSelectionSheet(title: label, options: options, selected: selected, onSelect: onSelect)
          : () => showSnackBarMessage(context,
              _lastTagEditDate != null
                  ? 'Tags locked. Editable in ${30 - DateTime.now().difference(_lastTagEditDate!).inDays} days'
                  : 'Tags locked (once per month)', true),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        margin: EdgeInsets.only(bottom: 1.h),
        decoration: BoxDecoration(
          color: const Color(0xff1E1E1E),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.white)),
            ),
            Text(
              selected ?? 'Select',
              style: TextStyle(
                fontSize: 13.sp,
                color: selected != null ? const Color(0xff1877F2) : Colors.white38,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              enabled ? Icons.chevron_right : Icons.lock_outline,
              color: enabled ? Colors.white38 : Colors.orange,
              size: 18.sp,
            ),
          ],
        ),
      ),
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
              if (_suffix.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    'Suffix "$_suffix" is locked and cannot be removed.',
                    style: TextStyle(fontSize: 11.sp, color: Colors.orange.withOpacity(0.8)),
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
