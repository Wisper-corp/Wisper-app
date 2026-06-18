import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';
import 'package:wisper/gen/assets.gen.dart';

class DocInfo extends StatelessWidget {
  final bool isMyResume;
  final VoidCallback onDelete;
  final String title;
  final bool isDownloaded;
  final VoidCallback onTap;
  const DocInfo({
    super.key, 
    required this.title,
    required this.isDownloaded,
    required this.onTap,
    required this.isMyResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DetailsCard(
      bgColor: Colors.transparent,
      borderWidth: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    Assets.images.pdf.keyName,
                    height: 24,
                    width: 24,
                  ),
                  widthBox10,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 200.w,
                        child: Text(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          title,
                          style: TextStyle(color: Colors.white, fontSize: 12.sp),
                        ),
                      ),
                      Text(
                        'PDF Document',
                        style: TextStyle(color: Colors.white, fontSize: 10.sp),
                      ),
                    ],
                  ),
                ],
              ),
          
              isMyResume == true
                  ? GestureDetector(
                      onTap: onDelete,
                      child: Image.asset(
                        Assets.images.delete.keyName,
                        height: 18,
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
