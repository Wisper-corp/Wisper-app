import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/urls.dart';

class IndustrySearchField extends StatefulWidget {
  final String? initialValue;
  final Function(String) onSelected;
  final String hintText;

  const IndustrySearchField({
    super.key,
    this.initialValue,
    required this.onSelected,
    this.hintText = 'Search industry (e.g. Software Devel...)',
  });

  @override
  State<IndustrySearchField> createState() => _IndustrySearchFieldState();
}

class _IndustrySearchFieldState extends State<IndustrySearchField> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _showDropdown = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _ctrl.text = widget.initialValue!;
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showDropdown = false);
        });
      } else {
        // Show top results when focused even without typing
        if (_suggestions.isEmpty && _ctrl.text.isEmpty) {
          _search('');
        }
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      final response = await Get.find<NetworkCaller>().getRequest(
        Urls.industrySearchUrl(query),
      );
      if (response.isSuccess && response.responseData != null) {
        final data = response.responseData['data'];
        if (data is List) {
          setState(() {
            _suggestions = data
                .map((e) => {'name': e['name'] as String, 'sector': e['sector'] as String})
                .toList();
            _showDropdown = _suggestions.isNotEmpty;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  void _select(String name) {
    _ctrl.text = name;
    setState(() => _showDropdown = false);
    _focusNode.unfocus();
    widget.onSelected(name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xff1C1C1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xff3A3A3A)),
          ),
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            onChanged: _onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Color(0xff8E8E93)),
              prefixIcon: const Icon(Icons.business_outlined, color: Color(0xff8E8E93), size: 20),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                      ),
                    )
                  : _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xff8E8E93), size: 18),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() { _suggestions = []; _showDropdown = false; });
                            widget.onSelected('');
                          },
                        )
                      : const Icon(Icons.arrow_drop_down, color: Color(0xff8E8E93)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        if (_showDropdown && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: const Color(0xff2C2C2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xff3A3A3A)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xff3A3A3A)),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return InkWell(
                  onTap: () => _select(item['name']),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.business_outlined, color: Color(0xff8E8E93), size: 16),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              Text(
                                item['sector'],
                                style: const TextStyle(color: Color(0xff8E8E93), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
