import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The community screen's tab strip.
///
/// Two layouts, chosen by measuring rather than guessing:
///
/// * **Everything fits** — the tabs share the width equally, which is how this
///   bar has always looked and gives the generous gaps between labels.
/// * **It doesn't** — each label sizes to its own text and the row scrolls, so
///   nothing is truncated. Five tabs at 360dp clipped "Members" to "Mem"; that
///   is what this branch avoids.
///
/// One trap worth naming: inside a horizontally scrolling row the width
/// constraint is unbounded, so a `width: double.infinity` underline resolves to
/// infinity and the whole strip fails layout and renders blank. [IntrinsicWidth]
/// gives the column a real width — the label's — for the underline to stretch to.
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

  /// Breathing room either side of each label when the row has to scroll.
  static const double _scrollGap = 14;

  TextStyle _style(bool selected) => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : Colors.white38,
      );

  double _labelWidth(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _style(true)),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }

  Widget _tab(int i, {required bool expanded}) {
    final selected = selectedIndex == i;
    final label = Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        tabs[i],
        textAlign: TextAlign.center,
        maxLines: 1,
        style: _style(selected),
      ),
    );
    final underline = Container(
      height: 2,
      color: selected ? Colors.blue : Colors.transparent,
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [label, underline],
    );

    return GestureDetector(
      onTap: () => onSelected(i),
      behavior: HitTestBehavior.opaque,
      // Expanded already gives a bounded width; the scrolling branch does not,
      // so it needs IntrinsicWidth to keep the underline finite.
      child: expanded
          ? column
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: _scrollGap.w),
              child: IntrinsicWidth(child: column),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;

        // Would the scrolling layout overflow? If not, equal shares look better
        // and match how this bar read before the Forum tab was added.
        var natural = 0.0;
        for (final t in tabs) {
          natural += _labelWidth(context, t) + (_scrollGap.w * 2);
        }

        if (available.isFinite && natural <= available) {
          return Row(
            children: List.generate(
              tabs.length,
              (i) => Expanded(child: _tab(i, expanded: true)),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              tabs.length,
              (i) => _tab(i, expanded: false),
            ),
          ),
        );
      },
    );
  }
}
