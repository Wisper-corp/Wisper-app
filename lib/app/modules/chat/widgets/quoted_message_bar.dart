import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/modules/chat/model/quoted_message.dart';

/// The message a reply quotes, as a bar.
///
/// The same bar appears above the composer while the reply is being written
/// and on the reply once it is sent, so what you set up is what the other
/// person sees.
class QuotedMessageBar extends StatelessWidget {
  const QuotedMessageBar({
    super.key,
    required this.quoted,
    this.onDismiss,
    this.onLight = false,
  });

  final QuotedMessage quoted;

  /// Only the composer offers a way to drop the quote.
  final VoidCallback? onDismiss;

  /// A sent message sits on a coloured bubble, so the bar lightens rather
  /// than darkening to stay legible on it.
  final bool onLight;

  static const _accent = Color(0xff1F7DE9);

  @override
  Widget build(BuildContext context) {
    final background =
        onLight ? Colors.white.withValues(alpha: 0.18) : const Color(0xff1B1E22);
    final nameColour = onLight ? Colors.white : _accent;
    final bodyColour = onLight ? Colors.white : const Color(0xffC9D1D9);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          left: BorderSide(color: onLight ? Colors.white : _accent, width: 3),
        ),
      ),
      padding: EdgeInsets.fromLTRB(9.w, 6.h, 6.w, 6.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quoted.senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: nameColour,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  quoted.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, color: bodyColour),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(2.r),
                child: Icon(
                  Icons.close_rounded,
                  size: 16.sp,
                  color: const Color(0xff8B949E),
                  semanticLabel: 'Cancel reply',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
