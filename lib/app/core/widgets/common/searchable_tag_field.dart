import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/utils/community_tags.dart';

/// A dropdown button field for selecting from a list of tag options.
/// Shows selected value with a dropdown arrow. Tapping opens a searchable bottom sheet.
class SearchableTagField extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> options;
  final String? selected;
  final bool enabled;
  final void Function(String) onSelect;

  /// Whether someone may enter a value the list does not have.
  ///
  /// Off by default: Trade and Market are fixed taxonomies, and a stray value
  /// there means nothing to anyone reading it. Category is the one people
  /// genuinely outgrow.
  final bool allowCustom;

  /// Says so beside the label. Every tag has always been optional in the code,
  /// but a numbered list of fields reads as a form you must fill in.
  final bool optional;

  const SearchableTagField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.enabled = true,
    this.allowCustom = false,
    this.optional = false,
  });

  @override
  State<SearchableTagField> createState() => _SearchableTagFieldState();
}

class _SearchableTagFieldState extends State<SearchableTagField> {

  void _openSheet() {
    if (!widget.enabled) return;

    final searchCtrl = TextEditingController();
    List<String> filtered = List.from(widget.options);
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.65,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 12.h),
                    // Handle bar
                    Container(
                      width: 40.w, height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Search field
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: const TextStyle(color: Color(0xff8C8C8C)),
                          filled: true,
                          fillColor: const Color(0xff2C2C2E),
                          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (q) {
                          setSheetState(() {
                            query = q;
                            filtered = q.isEmpty
                                ? List.from(widget.options)
                                : widget.options
                                    .where((o) => o.toLowerCase().contains(q.toLowerCase()))
                                    .toList();
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Nothing in the list fits — offer what was typed.
                    if (widget.allowCustom)
                      _CustomTagRow(
                        query: query,
                        options: widget.options,
                        onUse: (value) {
                          widget.onSelect(value);
                          Navigator.pop(ctx);
                        },
                      ),
                    // Options list
                    Flexible(
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1, color: Color(0xff2A2A2A)),
                        itemBuilder: (ctx, i) {
                          final opt = filtered[i];
                          final isSelected = widget.selected == opt;
                          return ListTile(
                            dense: true,
                            title: Text(
                              opt,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xff2799EA)
                                    : Colors.white,
                                fontSize: 14.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xff2799EA), size: 18)
                                : null,
                            onTap: () {
                              widget.onSelect(opt);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.selected != null && widget.selected!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: widget.enabled ? Colors.white70 : Colors.white30,
              ),
            ),
            if (widget.optional) ...[
              SizedBox(width: 6.w),
              Text(
                'Optional',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff8C8C8C),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _openSheet,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xff1E1E1E),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: hasValue
                    ? const Color(0xff2799EA)
                    : const Color(0xff2C2C2E),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? widget.selected! : widget.hint,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: hasValue ? Colors.white : const Color(0xff8C8C8C),
                    ),
                  ),
                ),
                Icon(
                  widget.enabled
                      ? Icons.arrow_drop_down_rounded
                      : Icons.lock_outline,
                  color: widget.enabled
                      ? (hasValue
                          ? const Color(0xff2799EA)
                          : Colors.white38)
                      : Colors.orange,
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

/// The "use what I typed" row inside the picker sheet.
///
/// Hidden until there is something to add that the list does not already
/// have — offering to add an option that exists would create a near-duplicate.
class _CustomTagRow extends StatelessWidget {
  const _CustomTagRow({
    required this.query,
    required this.options,
    required this.onUse,
  });

  final String query;
  final List<String> options;
  final ValueChanged<String> onUse;

  @override
  Widget build(BuildContext context) {
    final cleaned = sanitizeTagValue(query);
    if (cleaned.isEmpty) return const SizedBox.shrink();

    final exists =
        options.any((o) => o.toLowerCase() == cleaned.toLowerCase());
    if (exists) return const SizedBox.shrink();

    // Sanitising strips the characters that would break the tag line and caps
    // the length, so say so when what is offered is not what was typed.
    final trimmed = cleaned != query.trim();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: InkWell(
        onTap: () => onUse(cleaned),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline,
                  color: Color(0xff2799EA), size: 18),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use "$cleaned"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xff2799EA),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trimmed)
                      Text(
                        'Shortened to fit',
                        style: TextStyle(
                          color: const Color(0xff8C8C8C),
                          fontSize: 11.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
