import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/initials.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class RoleCard extends StatelessWidget {
  final String? title;
  final String? imagePath;
  final String? role;
  final int? post;
  final int? recommendations;
  final VoidCallback? addOnTap;
  final VoidCallback? messagesOnTap;
  final String? status;
  final bool? isEnable;

  final String? id;
  const RoleCard({
    super.key,
    this.id,
    this.title,
    this.imagePath,
    this.role,
    this.post,
    this.recommendations,
    this.addOnTap,
    this.messagesOnTap,
    this.status,
    this.isEnable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Get.to(() => OthersPersonScreen(userId: id ?? ''));
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: (imagePath ?? '').isNotEmpty
                        ? NetworkImage(imagePath!)
                        : null,
                    child: imagePath == null || imagePath == ''
                        ? Text(
                            initialsFromName(title),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  widthBox8,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        role ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: LightThemeColors.themeGreyColor,
                        ),
                      ),
                      heightBox4,
                      Row(
                        children: [
                          Row(
                            children: [
                              Text(
                                '$post',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 8,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),

                              Text(
                                ' Post',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 8,
                                  color: LightThemeColors.themeGreyColor,
                                ),
                              ),
                            ],
                          ),
                          widthBox14,
                          Row(
                            children: [
                              Text(
                                '$recommendations',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 8,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),

                              Text(
                                ' Recommendation',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 8,
                                  color: LightThemeColors.themeGreyColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                CircleIconWidget(
                  imagePath: Assets.images.unselectedChat.keyName,
                  onTap: () {
                    messagesOnTap!();
                  },
                  iconRadius: 18.r,
                ),
                widthBox8,
                SizedBox(
                  height: 30.h,
                  width: 70.w,
                  child: CustomElevatedButton(
                    color: isEnable! ? LightThemeColors.blueColor : Colors.grey,
                    borderRadius: 50,
                    textSize: 12.sp,
                    title: status ?? '',
                    onPress: addOnTap,
                  ),
                ),
              ],
            ),
          ],
        ),
        heightBox20,
        StraightLiner(height: 0.4, color: Color(0xff454545)),
      ],
    );
  }
}
