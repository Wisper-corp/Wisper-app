import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What someone picked from the attachment sheet.
enum ForumAttachmentChoice { image, video, document }

/// The sheet behind the "+" in the forum composer.
///
/// It used to open the photo library directly, which was the only thing a
/// forum post could carry. With video and documents alongside it, the choice
/// has to be made before a picker opens.
Future<ForumAttachmentChoice?> showForumAttachmentSheet(BuildContext context) {
  return showModalBottomSheet<ForumAttachmentChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ForumAttachmentSheet(),
  );
}

class _ForumAttachmentSheet extends StatelessWidget {
  const _ForumAttachmentSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff121417),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(top: 12.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xff3A4048),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 18.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20.w, bottom: 6.h),
                child: Text(
                  'Attach',
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            _Option(
              icon: Icons.image_outlined,
              colour: const Color(0xff4DA3F5),
              label: 'Image',
              subtitle: 'Photos from your library',
              onTap: () =>
                  Navigator.of(context).pop(ForumAttachmentChoice.image),
            ),
            _Option(
              icon: Icons.videocam_outlined,
              colour: const Color(0xff5AC98B),
              label: 'Video',
              subtitle: 'A clip from your library',
              onTap: () =>
                  Navigator.of(context).pop(ForumAttachmentChoice.video),
            ),
            _Option(
              icon: Icons.insert_drive_file_outlined,
              colour: const Color(0xffE5A34D),
              label: 'Document',
              subtitle: 'PDF, Word, spreadsheets and more',
              onTap: () =>
                  Navigator.of(context).pop(ForumAttachmentChoice.document),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.colour,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color colour;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: colour.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colour, size: 21.sp),
            ),
            SizedBox(width: 14.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xff8B949E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
