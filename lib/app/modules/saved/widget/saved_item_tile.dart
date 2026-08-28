import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/modules/saved/model/saved_item_model.dart';
import 'package:wisper/app/modules/saved/widget/save_button.dart';

/// One saved post in the list.
///
/// A service and a forum post are shown with the same frame but different
/// detail: a service leads with its price, a forum post with the community it
/// came from, because that is what tells them apart at a glance.
class SavedItemTile extends StatelessWidget {
  const SavedItemTile({super.key, required this.item});

  final SavedItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xff121417),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xff23262B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: const Color(0xff23262B),
                backgroundImage:
                    (item.authorImage != null && item.authorImage!.isNotEmpty)
                        ? NetworkImage(item.authorImage!)
                        : null,
                child: (item.authorImage == null || item.authorImage!.isEmpty)
                    ? Icon(Icons.person, size: 18.r, color: Colors.white38)
                    : null,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_subtitle != null)
                      Text(
                        _subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.sp, color: Colors.white38),
                      ),
                  ],
                ),
              ),
              SaveButton(kind: item.kind, itemId: item.id, size: 18.sp),
            ],
          ),
          if (item.text.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              item.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
          ],
          if (item.isService && item.price != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                _chip(_priceLabel),
                if (item.deliveryTime != null &&
                    item.deliveryTime!.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  _chip(item.deliveryTime!),
                ],
              ],
            ),
          ],
          if (item.images.isNotEmpty) ...[
            SizedBox(height: 10.h),
            SizedBox(
              height: 84.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.images.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Image.network(
                    item.images[index],
                    width: 84.w,
                    height: 84.h,
                    fit: BoxFit.cover,
                    // A picture that will not load must not blank the tile.
                    errorBuilder: (_, __, ___) => Container(
                      width: 84.w,
                      height: 84.h,
                      color: const Color(0xff23262B),
                      child: Icon(Icons.image_not_supported_outlined,
                          size: 20.r, color: Colors.white24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// A forum post is best identified by where it was said; a service by what
  /// the person does.
  String? get _subtitle {
    if (!item.isService && (item.groupName ?? '').isNotEmpty) {
      return item.groupName;
    }
    return item.authorTitle;
  }

  String get _priceLabel {
    final amount = item.price!;
    final whole = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    // The server stores the currency the post was priced in; scraped jobs
    // taught us not to assume one.
    switch (item.currency) {
      case 'USD':
        return '\$$whole';
      case 'NGN':
      case null:
        return '₦$whole';
      default:
        return '${item.currency} $whole';
    }
  }

  Widget _chip(String label) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: const Color(0xff17191C),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xffC9D1D9),
          ),
        ),
      );
}
