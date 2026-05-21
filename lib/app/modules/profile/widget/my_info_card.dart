import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';

class MyInfoCard extends StatelessWidget {
  final VoidCallback ontap;
  final String imagePath;
  final String name;
  final String job;
  const MyInfoCard({
    super.key,
    required this.imagePath,
    required this.name,
    required this.job,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imagePath.trim().isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: ontap,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: hasImage ? NetworkImage(imagePath) : null,
                child: hasImage
                    ? null
                    : Text(
                        name.isNotEmpty
                            ? '${name[0].toUpperCase()}${name.length > 1 ? name[1].toUpperCase() : ''}'
                            : '',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
              ),
              widthBox8,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),

                  Text(
                    job,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: LightThemeColors.themeGreyColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 20.h,
          width: 60,

          child: CustomElevatedButton(
            textSize: 10,
            borderRadius: 50,
            title: StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
                ? 'Personal'
                : 'Business',
            onPress: () {},
          ),
        ),
      ],
    );
  }
}
