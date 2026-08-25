import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The forum composer. Visually the chat input bar, but it posts to the forum
/// rather than a chat, so it carries none of the chat's socket wiring.
class ForumComposer extends StatefulWidget {
  final String hintText;
  final Future<bool> Function(String text) onSend;

  const ForumComposer({
    super.key,
    required this.onSend,
    this.hintText = 'Type here...',
  });

  @override
  State<ForumComposer> createState() => _ForumComposerState();
}

class _ForumComposerState extends State<ForumComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final can = _controller.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Lets the parent put the caret here when someone taps Reply.
  void focus() => _focusNode.requestFocus();

  Future<void> _send() async {
    if (!_canSend || _sending) return;
    final text = _controller.text;
    setState(() => _sending = true);
    final ok = await widget.onSend(text);
    if (!mounted) return;
    if (ok) _controller.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: const BoxDecoration(
                color: Color(0xff2A2A2A),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: Colors.grey[400], size: 22.sp),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: 44.h, maxHeight: 120.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: const Color(0xff2A2A2A),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Center(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(color: Colors.white, fontSize: 15.sp),
                    cursorColor: const Color(0xFF168DE1),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: _canSend
                      ? const Color(0xFF168DE1)
                      : const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? Padding(
                        padding: EdgeInsets.all(12.r),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: _canSend ? Colors.white : Colors.grey[600],
                        size: 22.sp,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
