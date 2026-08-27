import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wisper/app/modules/forum/widget/forum_poll_editor.dart';

/// The forum composer. Visually the chat input bar, but it posts to the forum
/// rather than a chat, so it carries none of the chat's socket wiring.
/// A forum post carries at most this many images. The server enforces the same
/// cap, so this is a courtesy, not the guarantee.
const int kForumMaxImages = 4;

class ForumComposer extends StatefulWidget {
  final String hintText;
  final Future<bool> Function(
    String text,
    List<File> images,
    List<String>? pollOptions,
  ) onSend;

  /// Replies are text only; the post composer takes images.
  final bool allowImages;

  /// Lets the parent put the caret here — tapping Reply on a reply should
  /// open the keyboard, not make you tap the field as well.
  final FocusNode? focusNode;

  const ForumComposer({
    super.key,
    required this.onSend,
    this.hintText = 'Type here...',
    this.allowImages = true,
    this.focusNode,
  });

  @override
  State<ForumComposer> createState() => _ForumComposerState();
}

class _ForumComposerState extends State<ForumComposer> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  final List<File> _images = [];
  List<String> _pollOptions = [];
  bool _canSend = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // A caption is required even when images are attached, so send stays
    // disabled on images alone.
    _controller.addListener(() {
      final can = _controller.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Only dispose a node we created; the parent owns one it passed in.
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  /// Lets the parent put the caret here when someone taps Reply.
  void focus() => _focusNode.requestFocus();

  Future<void> _send() async {
    if (!_canSend || _sending) return;
    final text = _controller.text;
    setState(() => _sending = true);
    final ok = await widget.onSend(
      text,
      List<File>.from(_images),
      _pollOptions.isEmpty ? null : List<String>.from(_pollOptions),
    );
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      _images.clear();
      _pollOptions = [];
    }
    setState(() => _sending = false);
  }

  Future<void> _pickImages() async {
    final remaining = kForumMaxImages - _images.length;
    if (remaining <= 0) {
      _say('You can attach up to $kForumMaxImages images.');
      return;
    }

    // ImagePicker is used directly rather than through ImagePickerHelper:
    // that helper is written for use inside a dialog and calls
    // Navigator.pop() when it finishes, which from here closes the community
    // screen and throws the selection away.
    try {
      final picked = await ImagePicker().pickMultiImage();
      if (picked.isEmpty || !mounted) return;

      final taken = picked.take(remaining).map((x) => File(x.path)).toList();
      setState(() => _images.addAll(taken));

      if (picked.length > remaining) {
        _say('Only the first $remaining could be added — '
            '$kForumMaxImages images is the limit.');
      }
    } catch (e) {
      if (mounted) _say('Could not open your photos.');
    }
  }

  Future<void> _editPoll() async {
    final options = await showForumPollEditor(context, initial: _pollOptions);
    if (options == null || !mounted) return;
    setState(() => _pollOptions = options);
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pollOptions.isNotEmpty) _pollChip(),
            if (_images.isNotEmpty) _thumbnails(),
            Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.allowImages)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: const BoxDecoration(
                    color: Color(0xff2A2A2A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: Colors.grey[400], size: 22.sp),
                ),
              ),
            if (widget.allowImages) SizedBox(width: 8.w),
            if (widget.allowImages) ...[
              GestureDetector(
                onTap: _editPoll,
                child: Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: _pollOptions.isEmpty
                        ? const Color(0xff2A2A2A)
                        : const Color(0xff1E3A57),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: _pollOptions.isEmpty
                        ? Colors.grey[400]
                        : const Color(0xff168DE1),
                    size: 22.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
            Expanded(
              child: Container(
                // No Center here: Center fills whatever height it is offered,
                // so with a maxHeight it made the box permanently tall instead
                // of one line high. The padding does the centring, and the box
                // grows only as the text wraps.
                constraints: BoxConstraints(maxHeight: 120.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
                decoration: BoxDecoration(
                  color: const Color(0xff2A2A2A),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 4,
                  style: TextStyle(color: Colors.white, fontSize: 15.sp, height: 1.3),
                  cursorColor: const Color(0xFF168DE1),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15.sp,
                      height: 1.3,
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
          ],
        ),
      ),
    );
  }

  /// A poll in progress shows as a single line above the field, so the caption
  /// - which is the poll's question - stays in view while you write it.
  Widget _pollChip() {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 8.h),
      child: GestureDetector(
        onTap: _editPoll,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xff17191C),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xff2A2F35), width: 0.6),
          ),
          child: Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 16.sp, color: const Color(0xff168DE1)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Poll with ${_pollOptions.length} options',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _pollOptions = []),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(left: 10.w),
                  child: Icon(Icons.close,
                      size: 16.sp, color: const Color(0xff8B949E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Selected images sit above the field so the caption stays visible — the
  /// caption is required, so it must never be pushed out of sight.
  Widget _thumbnails() {
    return SizedBox(
      height: 72.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 8.h),
        itemCount: _images.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, i) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.file(
                _images[i],
                width: 60.r,
                height: 60.r,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => setState(() => _images.removeAt(i)),
                child: Container(
                  padding: EdgeInsets.all(2.r),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 14.sp, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
