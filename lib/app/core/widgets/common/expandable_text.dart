import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Text that collapses to [maxLines] with an inline "Show more" at the end of
/// the last visible line.
///
/// The link sits *in the flow of the text* rather than on a row beneath it, so
/// a long post costs the same vertical space whether or not it is truncated.
/// That means measuring: the body is trimmed until the body plus the link fits
/// inside [maxLines], found by binary search rather than by guessing a
/// character count, which would break the moment the font, width or text
/// scale changed.
///
/// Short text renders as a plain [Text] with no link and no measurement cost.
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;

  /// Lines shown while collapsed.
  final int maxLines;

  final String moreLabel;
  final String lessLabel;

  /// Colour of the inline link.
  final Color linkColor;

  const ExpandableText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 4,
    this.moreLabel = 'Show more',
    this.lessLabel = 'Show less',
    this.linkColor = const Color(0xff4DA3F5),
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final linkStyle = widget.style.copyWith(
      color: widget.linkColor,
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        TextPainter paint(InlineSpan span, {int? maxLines}) {
          final painter = TextPainter(
            text: span,
            maxLines: maxLines,
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout(maxWidth: maxWidth);
          return painter;
        }

        final fits = !paint(
          TextSpan(text: widget.text, style: widget.style),
          maxLines: widget.maxLines,
        ).didExceedMaxLines;

        // Nothing to collapse — render it plainly.
        if (fits) return Text(widget.text, style: widget.style);

        final recognizer = TapGestureRecognizer()
          ..onTap = () => setState(() => _expanded = !_expanded);

        if (_expanded) {
          return Text.rich(
            TextSpan(
              style: widget.style,
              children: [
                TextSpan(text: widget.text),
                const TextSpan(text: '  '),
                TextSpan(
                  text: widget.lessLabel,
                  style: linkStyle,
                  recognizer: recognizer,
                ),
              ],
            ),
          );
        }

        // Longest prefix of the body that still leaves room for the link on
        // the last line. Binary search over character positions.
        TextSpan collapsedSpan(int cut) => TextSpan(
              style: widget.style,
              children: [
                TextSpan(text: '${widget.text.substring(0, cut).trimRight()}… '),
                TextSpan(text: widget.moreLabel, style: linkStyle),
              ],
            );

        var low = 0;
        var high = widget.text.length;
        var best = 0;
        while (low <= high) {
          final mid = (low + high) ~/ 2;
          if (!paint(collapsedSpan(mid), maxLines: widget.maxLines)
              .didExceedMaxLines) {
            best = mid;
            low = mid + 1;
          } else {
            high = mid - 1;
          }
        }

        // Cut on a word boundary so the ellipsis never lands mid-word.
        final rough = widget.text.substring(0, best);
        final lastSpace = rough.lastIndexOf(' ');
        final cut = lastSpace > rough.length * 0.6 ? lastSpace : best;

        return Text.rich(
          TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: '${widget.text.substring(0, cut).trimRight()}… '),
              TextSpan(
                text: widget.moreLabel,
                style: linkStyle,
                recognizer: recognizer,
              ),
            ],
          ),
        );
      },
    );
  }
}
