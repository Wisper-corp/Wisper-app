import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/video_player.dart';
import 'package:wisper/app/core/widgets/common/video_poster.dart';
import 'package:wisper/app/core/utils/attachment_kind.dart';
import 'package:wisper/app/core/widgets/common/image_container_widget.dart';

/// What a post carries, once it can carry more than photos.
///
/// The server keeps every attachment in one list of URLs, so the kinds arrive
/// mixed together. Photos keep the grid the rest of the app uses; a video and
/// a document each need a row of their own, because neither can be shown as a
/// picture and a filename is the only thing that tells two PDFs apart.
class ForumAttachmentsView extends StatelessWidget {
  const ForumAttachmentsView({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final images = <String>[];
    final others = <String>[];
    for (final url in urls) {
      if (attachmentKindOf(url) == AttachmentKind.image) {
        images.add(url);
      } else {
        others.add(url);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          ImageContainer(
            images: images,
            height: 200,
            width: double.infinity,
            borderRadius: 12,
          ),
        for (final url in others) ...[
          SizedBox(height: 8.h),
          // A video is shown the way a feed shows one — its own frame with a
          // play button — rather than as a row saying "Video".
          if (attachmentKindOf(url) == AttachmentKind.video)
            // Capped at four-by-five, the tallest a feed lets a portrait clip
            // stand. Uncapped, a phone-shot video is taller than the screen
            // and one post is the whole feed. Landscape is unaffected: it is
            // already far wider than this.
            LayoutBuilder(
              builder: (context, constraints) => VideoPoster(
                url: url,
                maxHeight: constraints.maxWidth * 5 / 4,
                alignment: Alignment.center,
                onTap: () => Get.to(() => VideoPlayerScreen(videoUrl: url)),
              ),
            )
          else
            _FileRow(url: url),
        ],
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.url});

  final String url;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    // Handed to the system rather than played or rendered in-app: it already
    // knows how to open a PDF or a video, and every format it knows.
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not open that file.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = attachmentKindOf(url);
    final isVideo = kind == AttachmentKind.video;

    return GestureDetector(
      onTap: () => _open(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xff17191C),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xff23262B)),
        ),
        child: Row(
          children: [
            Icon(
              isVideo ? Icons.play_circle_fill : attachmentIcon(kind),
              size: 22.sp,
              color: isVideo ? const Color(0xff4DA3F5) : const Color(0xffC9D1D9),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                isVideo ? 'Video' : attachmentDisplayName(url),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 16.sp, color: const Color(0xff8B949E)),
          ],
        ),
      ),
    );
  }
}
