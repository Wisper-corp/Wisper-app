import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/utils/community_tags.dart';
import 'package:wisper/app/core/utils/initials.dart';
import 'package:wisper/app/modules/chat/model/communities_model.dart';

/// A single community row: rounded-square cover, name, tag pills, and the
/// subscriber avatar stack with a compact count.
class CommunityCard extends StatelessWidget {
  final CommunitiesItemModel item;
  final VoidCallback onTap;

  const CommunityCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rawName = (item.name ?? '').trim();
    final name = rawName.isEmpty ? 'Untitled community' : rawName;
    // Only ever three tags exist (Trade / Market / Category); cap defensively
    // so a malformed description cannot grow the row without bound.
    final tags = parseCommunityTags(item.description).take(3).toList();
    final subscriberCount = (item.memberCount ?? 0) < 0 ? 0 : (item.memberCount ?? 0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommunityCover(name: name, imageUrl: item.image),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    LayoutBuilder(
                      builder: (context, constraints) =>
                          _TagRow(tags: tags, maxWidth: constraints.maxWidth),
                    ),
                  ],
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      if (item.members.isNotEmpty) ...[
                        _SubscriberAvatars(members: item.members),
                        SizedBox(width: 8.w),
                      ],
                      Flexible(
                        child: Text(
                          '${formatSubscriberCount(subscriberCount)} '
                          '${subscriberCount == 1 ? 'member' : 'members'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xff98A2B3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded-square community cover. Falls back to initials on a colour derived
/// from the name so a community without an image still reads as itself.
class _CommunityCover extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _CommunityCover({required this.name, this.imageUrl});

  static const _palette = [
    Color(0xff9E4A4A),
    Color(0xff41597F),
    Color(0xff4A7C59),
    Color(0xff7A5A9E),
    Color(0xffB07A3C),
    Color(0xff3C7F86),
  ];

  Color get _fallbackColor {
    if (name.isEmpty) return _palette.first;
    var hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return _palette[hash.abs() % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final size = 76.w;
    final radius = BorderRadius.circular(16.r);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    // Matches the client mockup: a quiet solid block. The initials are kept
    // small and low-contrast so the tile still identifies its community
    // without competing with the name beside it.
    Widget placeholder() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: _fallbackColor, borderRadius: radius),
          alignment: Alignment.center,
          child: Text(
            initialsFromName(name),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        );

    if (!hasImage) return placeholder();

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder(),
        errorWidget: (_, __, ___) => placeholder(),
      ),
    );
  }
}


/// Keeps the tags on a single line. Whatever does not fit collapses behind a
/// "+N" chip that reveals the rest on tap.
///
/// [parseCommunityTags] returns Category first, so the industry tag is always
/// among the visible ones and never hides behind the chip.
class _TagRow extends StatefulWidget {
  final List<String> tags;
  final double maxWidth;

  const _TagRow({required this.tags, required this.maxWidth});

  @override
  State<_TagRow> createState() => _TagRowState();
}

class _TagRowState extends State<_TagRow> {
  TextStyle get _pillStyle => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );

  /// Rendered width of a pill: its text plus the 12.w padding on each side.
  ///
  /// Measured through the viewer's text scale — without it, a device with
  /// large-text accessibility enabled renders pills wider than measured, and
  /// the row silently squeezes them into ellipses instead of collapsing into
  /// the "+N" chip.
  double _pillWidth(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _pillStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width + 24.w + 1; // +1 guards against sub-pixel rounding
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.tags;
    final gap = 8.w;

    // Does everything fit on one line as-is?
    var total = 0.0;
    for (var i = 0; i < tags.length; i++) {
      total += _pillWidth(context, tags[i]) + (i == 0 ? 0 : gap);
    }
    if (total <= widget.maxWidth) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tags.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Flexible(child: _TagPill(label: tags[i], maxWidth: widget.maxWidth)),
          ],
        ],
      );
    }

    // Otherwise reserve room for the chip and fit what we can — always at
    // least the first tag (the industry category).
    final chipWidth = _pillWidth(context, '+${tags.length - 1}');
    var used = 0.0;
    var fit = 0;
    for (var i = 0; i < tags.length; i++) {
      final next = _pillWidth(context, tags[i]) + (i == 0 ? 0 : gap);
      if (used + next + gap + chipWidth <= widget.maxWidth) {
        used += next;
        fit++;
      } else {
        break;
      }
    }
    if (fit == 0) fit = 1;

    // Prefer showing a second tag when what is left is still readable, rather
    // than dropping straight to the chip. Mirrors the same rule in the preview.
    double? secondPillMax;
    if (fit == 1 && tags.length > 1) {
      final room =
          widget.maxWidth - _pillWidth(context, tags[0]) - gap - gap - chipWidth;
      if (room >= 64.w) {
        secondPillMax = room;
        fit = 2;
      }
    }

    final hidden = tags.length - fit;

    // A lone oversized tag is forced visible, leaving nothing hidden — the
    // chip would read "+0", so fall back to just showing it (truncated).
    if (hidden <= 0) {
      return _TagPill(label: tags.first, maxWidth: widget.maxWidth);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < fit; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Flexible(
            child: _TagPill(
              label: tags[i],
              maxWidth: (i == 1 && secondPillMax != null)
                  ? secondPillMax
                  : widget.maxWidth - chipWidth - gap,
            ),
          ),
        ],
        SizedBox(width: gap),
        _MoreChip(label: '+$hidden', hiddenTags: tags.sublist(fit)),
      ],
    );
  }
}

/// The "+N" affordance. Tapping it floats the remaining tags below the chip in
/// an overlay — the card never changes height, and the caret points at the chip.
class _MoreChip extends StatefulWidget {
  final String label;
  final List<String> hiddenTags;

  const _MoreChip({required this.label, required this.hiddenTags});

  @override
  State<_MoreChip> createState() => _MoreChipState();
}

class _MoreChipState extends State<_MoreChip> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  void _close() {
    if (_entry == null) return;
    _remove();
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (_entry != null) {
      _close();
      return;
    }
    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Tap anywhere else to dismiss.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: Offset(4.w, 8.h),
            child: _popover(),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  Widget _popover() {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 13.w),
            child: CustomPaint(
              size: Size(12.w, 6.h),
              painter: _CaretPainter(),
            ),
          ),
          Container(
            constraints: BoxConstraints(maxWidth: 210.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xff20262E),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xff39424D)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final t in widget.hiddenTags)
                  _TagPill(label: t, maxWidth: 190.w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          button: true,
          label: 'Show ${widget.label} more tags',
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xff1A2C3D),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xff2F4A66)),
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xff8FC2F5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Upward caret joining the popover to the chip, matching the popover's fill
/// and border.
class _CaretPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xff20262E));
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height),
      Paint()
        ..color = const Color(0xff39424D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TagPill extends StatelessWidget {
  final String label;

  /// Width of the text column. A pill never exceeds it; long values truncate.
  final double maxWidth;

  const _TagPill({required this.label, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: const Color(0xff2A2A2A),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Overlapping avatar stack for the first few subscribers.
///
/// The API returns only `id` and `image` per subscriber — there is no name to
/// derive initials from, so a subscriber without a photo gets a neutral chip
/// rather than a "?" placeholder.
class _SubscriberAvatars extends StatelessWidget {
  final List<Member> members;

  const _SubscriberAvatars({required this.members});

  static const double _size = 22;
  static const double _overlap = 8;

  Widget _fallback() => Container(
        width: _size,
        height: _size,
        decoration: const BoxDecoration(
          color: Color(0xff3A4550),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.person_rounded,
          size: 13,
          color: Color(0xffB9C4CE),
        ),
      );

  Widget _avatar(Member member) {
    final url = member.image?.trim() ?? '';
    if (url.isEmpty) return _fallback();

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = members.length.clamp(0, 3);
    if (count == 0) return const SizedBox.shrink();

    return SizedBox(
      height: _size,
      width: _size + (count - 1) * (_size - _overlap),
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * (_size - _overlap),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xff121212), width: 1.5),
              ),
              child: _avatar(members[i]),
            ),
          );
        }),
      ),
    );
  }
}
