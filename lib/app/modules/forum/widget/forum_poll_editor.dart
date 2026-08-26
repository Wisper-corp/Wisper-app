import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const int kPollMinOptions = 2;
const int kPollMaxOptions = 10;

/// Collects the options for a poll. The question is the post's own caption, so
/// this sheet only asks for the answers — which keeps it short and means a
/// poll post still reads like every other post in the feed.
///
/// Returns the trimmed options, or null if the person backs out.
Future<List<String>?> showForumPollEditor(
  BuildContext context, {
  List<String> initial = const [],
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _PollEditor(initial: initial),
  );
}

class _PollEditor extends StatefulWidget {
  final List<String> initial;
  const _PollEditor({required this.initial});

  @override
  State<_PollEditor> createState() => _PollEditorState();
}

class _PollEditorState extends State<_PollEditor> {
  late List<TextEditingController> _controllers;
  String? _error;

  @override
  void initState() {
    super.initState();
    final seed = widget.initial.isEmpty
        ? List.filled(kPollMinOptions, '')
        : widget.initial;
    _controllers = [
      for (final t in seed) TextEditingController(text: t),
    ];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _filled =>
      _controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  void _add() {
    if (_controllers.length >= kPollMaxOptions) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeAt(int i) {
    if (_controllers.length <= kPollMinOptions) return;
    setState(() => _controllers.removeAt(i).dispose());
  }

  void _done() {
    final options = _filled;
    if (options.length < kPollMinOptions) {
      setState(() => _error = 'A poll needs at least $kPollMinOptions options.');
      return;
    }
    final seen = <String>{};
    for (final o in options) {
      if (!seen.add(o.toLowerCase())) {
        setState(() => _error = 'Each option needs to be different.');
        return;
      }
    }
    Navigator.of(context).pop(options);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff121417),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xff3A4048),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Poll options',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Your post text is the question.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xff98A2B3),
                ),
              ),
              SizedBox(height: 18.h),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < _controllers.length; i++) ...[
                        if (i > 0) SizedBox(height: 10.h),
                        _OptionField(
                          controller: _controllers[i],
                          hint: 'Option ${i + 1}',
                          canRemove: _controllers.length > kPollMinOptions,
                          onRemove: () => _removeAt(i),
                          onChanged: () {
                            if (_error != null) setState(() => _error = null);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_controllers.length < kPollMaxOptions) ...[
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: _add,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18.sp, color: const Color(0xff168DE1)),
                      SizedBox(width: 8.w),
                      Text(
                        'Add option',
                        style: TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff168DE1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                SizedBox(height: 14.h),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xffE5484D),
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _done,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff168DE1),
                    disabledBackgroundColor: const Color(0xff2A2F35),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: Text(
                    'Attach poll',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _OptionField({
    required this.controller,
    required this.hint,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xff1B1E22),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xff2A2F35), width: 0.6),
            ),
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              maxLength: 120,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
              cursorColor: const Color(0xFF168DE1),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: const Color(0xff6B7280),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ),
        if (canRemove)
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(left: 10.w),
              child: Icon(Icons.close,
                  size: 18.sp, color: const Color(0xff8B949E)),
            ),
          ),
      ],
    );
  }
}
