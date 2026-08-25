import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The community screen's tab strip.
///
/// Five tabs no longer fit in equal shares — that clipped "Members" to "Mem" —
/// so each label sizes to its own text and the row scrolls instead.
///
/// The catch: inside a horizontally scrolling row the width constraint is
/// unbounded, so a `width: double.infinity` underline resolves to infinity and
/// the whole strip fails to lay out and renders blank. [IntrinsicWidth] gives
/// the column a real width — the label's — which the underline can then stretch
/// to.
class CommunityTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CommunityTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (i) {
          final selected = selectedIndex == i;
          return GestureDetector(
            onTap: () => onSelected(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        tabs[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.white38,
                        ),
                      ),
                    ),
                    Container(
                      height: 2,
                      color: selected ? Colors.blue : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
