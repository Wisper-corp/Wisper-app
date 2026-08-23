import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A bare chat-header icon with a 36px tap target.
///
/// Shared by the person, group and class chat headers so the three bars stay
/// identical. Icons are deliberately unchipped — the avatar carries the visual
/// weight and the chrome stays out of the way of the conversation.
class HeaderIcon extends StatelessWidget {
  final String asset;
  final double size;
  final VoidCallback onTap;
  final String tooltip;

  const HeaderIcon({
    super.key,
    required this.asset,
    required this.size,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 36.w,
          height: 36.w,
          child: Center(
            child: Image.asset(
              asset,
              height: size.w,
              width: size.w,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Groups the call actions into one bordered pill, the way WhatsApp does —
/// it reads as a single "call" control rather than loose icons, and separates
/// them from the overflow menu.
class HeaderActionGroup extends StatelessWidget {
  final List<Widget> children;

  const HeaderActionGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: const Color(0xff17191C),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xff2E343B)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
