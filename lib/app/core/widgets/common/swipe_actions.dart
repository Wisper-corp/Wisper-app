import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One button revealed by swiping a row.
class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.colour,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final Color colour;
  final VoidCallback onTap;
  final String semanticLabel;
}

/// A row that slides left to reveal actions behind it.
///
/// Written here rather than pulled from a package: adding a dependency means
/// touching pubspec, and a stale constraint in this project has broken every
/// build before now. The behaviour needed is small — drag, snap open or shut,
/// close when another row opens or when the row is tapped.
class SwipeActions extends StatefulWidget {
  const SwipeActions({
    super.key,
    required this.child,
    required this.actions,
    this.actionWidth = 72,
  });

  final Widget child;
  final List<SwipeAction> actions;
  final double actionWidth;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions>
    with SingleTickerProviderStateMixin {
  // Created in initState, not as a field initializer: a lazily-created ticker
  // reaches for its TickerMode ancestor at whatever moment it is first
  // touched, which may be while the tree is being torn down.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  double get _maxOffset => widget.actionWidth * widget.actions.length;

  /// How far the row is currently pulled aside, in pixels.
  double _offset = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final start = _offset;
    final animation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    void listener() => setState(() => _offset = animation.value);
    animation.addListener(listener);
    _controller
      ..reset()
      ..forward().whenComplete(() => animation.removeListener(listener));
  }

  void close() => _animateTo(0);

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Only leftwards, and never past the actions themselves.
      _offset = (_offset - details.delta.dx).clamp(0.0, _maxOffset);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    // A decisive flick wins over where the finger happened to stop.
    if (velocity < -250) {
      _animateTo(_maxOffset);
    } else if (velocity > 250) {
      _animateTo(0);
    } else {
      _animateTo(_offset > _maxOffset / 2 ? _maxOffset : 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) return widget.child;

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // The buttons sit behind, revealed as the row moves off them.
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final action in widget.actions)
                  GestureDetector(
                    onTap: () {
                      close();
                      action.onTap();
                    },
                    child: Container(
                      width: widget.actionWidth,
                      color: action.colour,
                      alignment: Alignment.center,
                      child: Icon(
                        action.icon,
                        color: Colors.white,
                        size: 22.sp,
                        semanticLabel: action.semanticLabel,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(-_offset, 0),
            child: GestureDetector(
              // An open row swallows the tap to close, rather than opening the
              // chat the finger happens to be over.
              onTap: _offset > 0 ? close : null,
              child: AbsorbPointer(
                absorbing: _offset > 0,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
