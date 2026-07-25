import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A searchable dropdown field for selecting from a list of tag options.
/// Shows a text field with search, and a dropdown list below filtered by the query.
class SearchableTagField extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> options;
  final String? selected;
  final bool enabled;
  final void Function(String) onSelect;

  const SearchableTagField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.enabled = true,
  });

  @override
  State<SearchableTagField> createState() => _SearchableTagFieldState();
}

class _SearchableTagFieldState extends State<SearchableTagField> {
  final TextEditingController _ctrl = TextEditingController();
  List<String> _suggestions = [];
  bool _showDropdown = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) {
      _ctrl.text = widget.selected!;
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showDropdown = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SearchableTagField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && widget.selected != null) {
      _ctrl.text = widget.selected!;
    }
  }

  void _onChanged(String query) {
    final filtered = query.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.toLowerCase().contains(query.toLowerCase()))
            .toList();
    setState(() {
      _suggestions = filtered;
      _showDropdown = filtered.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: widget.enabled ? Colors.white70 : Colors.white30,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _ctrl,
          focusNode: _focusNode,
          enabled: widget.enabled,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xff2A2A2A)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: widget.selected != null
                ? const Icon(Icons.check_circle, color: Color(0xff2799EA), size: 20)
                : const Icon(Icons.search, color: Colors.grey, size: 20),
          ),
          onChanged: _onChanged,
          onTap: () {
            _onChanged(_ctrl.text);
          },
        ),
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: const Color(0xff1E1E1E),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xff2C2C2E)),
            ),
            constraints: BoxConstraints(maxHeight: 200.h),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xff2C2C2E)),
              itemBuilder: (context, i) {
                final opt = _suggestions[i];
                final isSelected = widget.selected == opt;
                return ListTile(
                  dense: true,
                  title: Text(
                    opt,
                    style: TextStyle(
                      color: isSelected ? const Color(0xff2799EA) : Colors.white,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xff2799EA), size: 16)
                      : null,
                  onTap: () {
                    _ctrl.text = opt;
                    widget.onSelect(opt);
                    setState(() => _showDropdown = false);
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
        SizedBox(height: 16.h),
      ],
    );
  }
}
