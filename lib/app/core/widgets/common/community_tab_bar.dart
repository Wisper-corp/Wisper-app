import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The community screen's tab strip.
///
/// Two layouts, chosen by measuring the labels rather than guessing:
///
/// * **They fit** — the row spreads them across the full width, so the slack
///   becomes generous, even gaps. This is the roomy spacing the bar had before
///   the Forum tab was added.
/// * **They don't** — each label sizes to its text and the row scrolls, so
///   nothing is truncated. Five tabs at 360dp clipped "Members" to "Mem"; that
///   is what this branch avoids.
///
/// Equal `Expanded` shares are deliberately *not* used: at 390dp four tabs get
/// 97dp each, and "Services" alone measures 104dp, so it would be truncated.
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

  /// The least space a label needs either side before the row gives up on
  /// fitting them all and scrolls instead.
  static const double _minGap = 6;

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
          ? IntrinsicWidth(child: column)
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

        // Only the labels themselves have to fit; the leftover width becomes
        // the gaps between them.
        var labels = 0.0;
        for (final t in tabs) {
          labels += _labelWidth(context, t) + (_minGap.w * 2);
        }

        if (available.isFinite && labels <= available) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              tabs.length,
              (i) => _tab(i, expanded: true),
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
