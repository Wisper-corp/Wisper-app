import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/modules/forum/model/forum_post_model.dart';

/// A poll inside a forum post.
///
/// Before you vote the options read as plain, tappable rows — nothing competes
/// with the question above them. Once you vote each row fills proportionally
/// and gains a percentage, so the result is legible at a glance without a
/// separate results screen. Your own choice keeps a check so it stays findable
/// after the bars appear.
class ForumPollView extends StatelessWidget {
  final ForumPoll poll;

  /// Null while a vote is in flight, which also disables the rows.
  final void Function(ForumPollOption option)? onVote;

  const ForumPollView({super.key, required this.poll, this.onVote});

  static const _accent = Color(0xff168DE1);
  static const _rowIdle = Color(0xff17191C);
  static const _rowFill = Color(0xff1E3A57);
  static const _hairline = Color(0xff2A2F35);

  @override
  Widget build(BuildContext context) {
    final voted = poll.hasVoted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < poll.options.length; i++) ...[
          if (i > 0) SizedBox(height: 8.h),
          _Option(
            option: poll.options[i],
            voted: voted,
            isMine: poll.myOptionId == poll.options[i].id,
            onTap: onVote == null ? null : () => onVote!(poll.options[i]),
          ),
        ],
        SizedBox(height: 10.h),
        Text(
          _voteLabel(poll.totalVotes, voted),
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 12.sp,
            color: const Color(0xff8B949E),
          ),
        ),
      ],
    );
  }

  static String _voteLabel(int total, bool voted) {
    if (total == 0) return 'No votes yet — be the first.';
    final votes = total == 1 ? '1 vote' : '$total votes';
    return voted ? votes : '$votes · tap an option to vote';
  }
}

class _Option extends StatelessWidget {
  final ForumPollOption option;
  final bool voted;
  final bool isMine;
  final VoidCallback? onTap;

  const _Option({
    required this.option,
    required this.voted,
    required this.isMine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10.r);

    return Semantics(
      button: !voted,
      selected: isMine,
      label: voted
          ? '${option.text}, ${option.percent} percent'
          : 'Vote for ${option.text}',
      child: GestureDetector(
        onTap: voted ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // The fill is the bar: it sits behind the label rather than
              // beside it, so a long option never squeezes the bar away.
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    widthFactor: voted ? (option.percent / 100).clamp(0.0, 1.0) : 0,
                    child: const ColoredBox(color: ForumPollView._rowFill),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: voted ? Colors.transparent : ForumPollView._rowIdle,
                  borderRadius: radius,
                  border: Border.all(
                    color: isMine
                        ? ForumPollView._accent
                        : ForumPollView._hairline,
                    width: isMine ? 1.2 : 0.6,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  children: [
                    if (voted && isMine) ...[
                      Icon(Icons.check_circle,
                          size: 15.sp, color: ForumPollView._accent),
                      SizedBox(width: 8.w),
                    ],
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 14.sp,
                          height: 1.3,
                          fontWeight:
                              isMine ? FontWeight.w600 : FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (voted) ...[
                      SizedBox(width: 12.w),
                      Text(
                        '${option.percent}%',
                        style: TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isMine
                              ? Colors.white
                              : const Color(0xffC9D1D9),
                          // Percentages line up in a column, so they need
                          // tabular figures.
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
