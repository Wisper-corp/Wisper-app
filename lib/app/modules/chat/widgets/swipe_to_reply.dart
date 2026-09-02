import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Drag a message sideways to reply to it.
///
/// Written here rather than pulled from a package: adding a dependency means
/// touching pubspec, and a stale constraint in this project has broken every
/// build before now. What is needed is small — follow the finger a little way,
/// show an arrow appearing as it goes, fire once past a threshold, spring back
/// either way.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onReply;

  /// A message still being sent has no id to reply to yet.
  final bool enabled;

  /// How far the message follows the finger.
  static const double maxDrag = 64;

  /// How far it has to go before letting go counts as a reply.
  static const double threshold = 44;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  // Created in initState rather than as a field initializer: a lazily-created
  // ticker reaches for its TickerMode ancestor whenever it is first touched,
  // which may be while the tree is being torn down.
  late final AnimationController _controller;
  double _offset = 0;
  bool _buzzed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _springBack() {
    final from = _offset;
    final animation = Tween<double>(begin: from, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    void listener() => setState(() => _offset = animation.value);
    animation.addListener(listener);
    _controller
      ..reset()
      ..forward().whenComplete(() => animation.removeListener(listener));
  }

  void _onUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() {
      // Rightwards only, and never further than the arrow needs.
      _offset = (_offset + details.delta.dx).clamp(0.0, SwipeToReply.maxDrag);
    });
    // A nudge at the point it would fire, so you can feel it without looking.
    if (!_buzzed && _offset >= SwipeToReply.threshold) {
      _buzzed = true;
      HapticFeedback.lightImpact();
    }
  }

  void _onEnd(DragEndDetails details) {
    final fired = _offset >= SwipeToReply.threshold;
    _buzzed = false;
    _springBack();
    if (fired) widget.onReply();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final progress = (_offset / SwipeToReply.threshold).clamp(0.0, 1.0);

    return GestureDetector(
      // Vertical drags still reach the list, so the conversation scrolls.
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      behavior: HitTestBehavior.deferToChild,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // The arrow is revealed by the message moving off it, and fades in
          // as the swipe gets closer to counting.
          Positioned(
            left: 8.w,
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: 0.6 + 0.4 * progress,
                child: Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: const BoxDecoration(
                    color: Color(0xff2A2C31),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.reply,
                    size: 15.sp,
                    color: Colors.white,
                    semanticLabel: 'Reply',
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_offset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
