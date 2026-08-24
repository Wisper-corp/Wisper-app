import 'package:flutter/widgets.dart';

/// How far from the start of the content the header always stays expanded.
/// The brief says the full bar is visible "at the top of the page", and a
/// small band avoids the bar flickering shut on the first pixel of a drag.
const double kHeaderExpandZone = 24;

/// Ignore drags smaller than this so a resting finger cannot rattle the bar
/// open and shut.
const double kHeaderScrollThreshold = 6;

/// Decides what a scroll gesture should do to a collapsible header.
///
/// Returns `true` to collapse, `false` to expand, and `null` when the gesture
/// carries no opinion and the header should be left alone.
///
/// Written as a pure function so the awkward cases — a reversed viewport, a
/// list too short to scroll, an overscroll bounce — can be tested directly
/// rather than by driving the whole screen.
bool? headerCollapseIntent({
  required ScrollMetrics metrics,
  required double scrollDelta,
  double expandZone = kHeaderExpandZone,
  double threshold = kHeaderScrollThreshold,
}) {
  // A list that cannot scroll has nothing to make room for.
  if (metrics.maxScrollExtent <= 0) return false;

  // Near the start, always show the whole bar — including while overscrolling
  // past it, where pixels goes negative.
  if (metrics.pixels <= metrics.minScrollExtent + expandZone) return false;

  // In a reversed viewport a growing offset moves content the other way on
  // screen, so the sign has to be flipped to match what the finger did.
  final bool isReversed = metrics.axisDirection == AxisDirection.up ||
      metrics.axisDirection == AxisDirection.left;
  final double delta = isReversed ? -scrollDelta : scrollDelta;

  if (delta > threshold) return true; // scrolling down — give content room
  if (delta < -threshold) return false; // scrolling back up — bring it back
  return null; // too small to mean anything
}
