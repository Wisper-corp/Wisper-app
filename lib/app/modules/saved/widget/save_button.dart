import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/saved/controller/saved_controller.dart';

/// The bookmark on a post.
///
/// Reads its filled/hollow state from [SavedController] rather than from the
/// card, so every card showing the same post agrees — saving from a feed and
/// then opening the saved list does not show two different answers.
class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.kind,
    required this.itemId,
    this.size,
    this.color,
  });

  /// 'service' or 'forum'.
  final String kind;
  final String itemId;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SavedController>()
        ? Get.find<SavedController>()
        : Get.put(SavedController(), permanent: true);

    return Obx(() {
      final saved = controller.isSaved(kind, itemId);
      return GestureDetector(
        onTap: () => controller.toggle(kind, itemId),
        // A bookmark is a small target; give the finger some room around it.
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          child: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: size ?? 16.sp,
            color: saved ? const Color(0xff1F7DE9) : (color ?? Colors.grey),
            semanticLabel: saved ? 'Saved' : 'Save',
          ),
        ),
      );
    });
  }
}
