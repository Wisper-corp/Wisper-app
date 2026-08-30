import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// How tall a pinned profile tab bar is: a divider, the tabs, a divider.
///
/// A pinned sliver must state its height up front, so this is fixed rather
/// than measured from the content — the tabs are a fixed-size row.
final double kProfileTabsHeight = 56.h;

/// Keeps a profile's tabs at the top once the card above them has scrolled
/// away, so switching tab never means scrolling back up first.
///
/// Shared by every profile screen — your own and other people's — so the three
/// cannot drift apart.
class PinnedTabsHeader extends SliverPersistentHeaderDelegate {
  const PinnedTabsHeader({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // The list scrolls underneath, so the bar has to be opaque or the posts
    // show through the tabs. The colour comes from the child it is given.
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(PinnedTabsHeader oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
