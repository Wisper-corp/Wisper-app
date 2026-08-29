import 'dart:async';

import 'package:flutter/material.dart';

/// How long a custom entry may be.
///
/// These are shown inline beside a name, on cards and in lists, so a long one
/// pushes everything else off the row. Thirty-two characters fits every real
/// title in the shipped list with room to spare.
const int kMaxCustomChoiceLength = 32;

/// A search field for a curated list — job titles, industries, community
/// categories — that lets someone enter their own when the list has nothing
/// for them.
///
/// The list can never be complete, and the alternative to typing your own is
/// picking something that is not true, so the custom row appears as soon as
/// the search finds no exact match.
class SearchableChoiceField extends StatefulWidget {
  const SearchableChoiceField({
    super.key,
    required this.onSelected,
    required this.search,
    this.initialValue,
    this.hintText = 'Search...',
    this.icon = Icons.work_outline,
    this.allowCustom = true,
  });

  /// Called with the chosen value — from the list or typed. Called with an
  /// empty string when cleared.
  final ValueChanged<String> onSelected;

  /// Looks up matches. Errors are the caller's to swallow: a failed lookup
  /// leaves the custom row, which is better than a dead field.
  final Future<List<String>> Function(String query) search;

  final String? initialValue;
  final String hintText;
  final IconData icon;
  final bool allowCustom;

  @override
  State<SearchableChoiceField> createState() => _SearchableChoiceFieldState();
}

class _SearchableChoiceFieldState extends State<SearchableChoiceField> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _open = false;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) _ctrl.text = widget.initialValue!;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // A tap on a suggestion takes the focus first; closing immediately
        // would swallow it.
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _open = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _trimmed => _query.trim();

  /// Whether what was typed is already in the list, ignoring case — offering
  /// to "add" something that exists would create a near-duplicate.
  bool get _matchesExisting => _suggestions
      .any((s) => s.toLowerCase() == _trimmed.toLowerCase());

  bool get _customFits => _trimmed.length <= kMaxCustomChoiceLength;

  bool get _showCustomRow =>
      widget.allowCustom && _trimmed.isNotEmpty && !_matchesExisting;

  Future<void> _run(String query) async {
    if (query.trim().length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          // The custom row still needs somewhere to live.
          _open = _showCustomRow;
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await widget.search(query);
      if (!mounted) return;
      setState(() => _suggestions = results);
    } catch (_) {
      // A lookup that fails must not take the custom row down with it.
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _open = _suggestions.isNotEmpty || _showCustomRow;
        });
      }
    }
  }

  void _onChanged(String value) {
    setState(() {
      _query = value;
      _open = true;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(value));
  }

  void _select(String value) {
    _ctrl.text = value;
    setState(() {
      _query = value;
      _open = false;
    });
    _focusNode.unfocus();
    widget.onSelected(value);
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _query = '';
      _suggestions = [];
      _open = false;
    });
    widget.onSelected('');
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
            textInputAction: TextInputAction.done,
            // Enter is the obvious way to accept what you typed.
            onSubmitted: (_) {
              if (_showCustomRow && _customFits) _select(_trimmed);
            },
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Color(0xff8E8E93)),
              prefixIcon:
                  Icon(widget.icon, color: const Color(0xff8E8E93), size: 20),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.blue),
                      ),
                    )
                  : _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Color(0xff8E8E93), size: 18),
                          onPressed: _clear,
                        )
                      : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_open && (_suggestions.isNotEmpty || _showCustomRow))
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: const Color(0xff2C2C2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xff3A3A3A)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final s in _suggestions) ...[
                  _Row(
                    icon: widget.icon,
                    label: s,
                    onTap: () => _select(s),
                  ),
                  const Divider(height: 1, color: Color(0xff3A3A3A)),
                ],
                if (_showCustomRow) _buildCustomRow(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCustomRow() {
    if (!_customFits) {
      // Say what the limit is rather than silently refusing the tap.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xffE5A34D), size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Keep it to $kMaxCustomChoiceLength characters '
                '(${_trimmed.length} now)',
                style: const TextStyle(color: Color(0xffE5A34D), fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return _Row(
      icon: Icons.add_circle_outline,
      label: 'Use "$_trimmed"',
      highlight: true,
      onTap: () => _select(_trimmed),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colour = highlight ? const Color(0xff4DA3F5) : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                color: highlight
                    ? const Color(0xff4DA3F5)
                    : const Color(0xff8E8E93),
                size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colour,
                  fontSize: 14,
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
