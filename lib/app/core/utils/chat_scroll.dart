import 'package:flutter/material.dart';

/// Scroll helpers for the chat message lists.
///
/// Extracted from MessageController so they can be tested directly — the
/// controller itself resolves SocketService in a field initializer and cannot
/// be constructed in a widget test.

/// Offset of the newest message for the attached viewport.
///
/// Offset 0 is the newest end only for a `reverse: true` list. The group chat
/// renders a normal list, where 0 is the OLDEST message.
double chatNewestOffset(ScrollPosition position) =>
    position.axisDirection == AxisDirection.up
        ? position.minScrollExtent
        : position.maxScrollExtent;

/// Jump/animate to the newest message.
void chatScrollToBottom(ScrollController controller, {bool animated = true}) {
  if (!controller.hasClients) return;
  final target = chatNewestOffset(controller.position);
  if (animated) {
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  } else {
    controller.jumpTo(target);
  }
}

/// True when the view is already showing the newest message.
bool chatIsAtNewest(ScrollController controller, {double tolerance = 8}) {
  if (!controller.hasClients) return false;
  return (controller.offset - chatNewestOffset(controller.position)).abs() <=
      tolerance;
}

/// Scroll once the newly-inserted message has actually been laid out.
///
/// A single post-frame callback is not enough: the first frame after
/// `messages.insert` can still report the OLD extent, leaving the view one
/// bubble short — the "does not scroll all the way down" report. Pin to the
/// newest end across two consecutive frames so late layout (wrapped text,
/// images, a taller bubble) is picked up. Deterministic, no timers.
void chatScrollToBottomAfterFrame(ScrollController controller, {int frames = 3}) {
  if (frames <= 0) return;
  // Best-effort immediate pin: on the initial load nothing may schedule another
  // frame, and a post-frame callback that never runs would leave the chat
  // parked at the oldest message.
  if (controller.hasClients) {
    controller.jumpTo(chatNewestOffset(controller.position));
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients) return;
    controller.jumpTo(chatNewestOffset(controller.position));
    chatScrollToBottomAfterFrame(controller, frames: frames - 1);
  });
  WidgetsBinding.instance.scheduleFrame();
}
