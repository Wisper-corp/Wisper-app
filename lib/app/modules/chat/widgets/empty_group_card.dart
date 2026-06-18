import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';
import 'package:wisper/gen/assets.gen.dart';

class EmptyGroupInfoCard extends StatelessWidget {
  final bool? isGroup;
  final String? name;
  final String? member;
  const EmptyGroupInfoCard({super.key, this.isGroup, this.name, this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          isGroup!
              ? CircleIconWidget(
                  color: Color(0xff051B33),
                  iconColor: Color(0xff1F7DE9),
                  iconRadius: 35,
                  radius: 35,
                  imagePath: Assets.images.userGroup.keyName,
                  onTap: () {},
                )
              : CircleIconWidget(
                  color: Color(0xff102B19),
                  iconColor: Color(0xff11AE46),
                  iconRadius: 35,
                  radius: 35,
                  imagePath: Assets.images.education.keyName,
                  onTap: () {},
                ),
          heightBox20,
          isGroup!
              ? Text(
                  'You created this Group',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Text(
                  'You created this Class',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          heightBox8,
          Text(
            'Group • $member members',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,

              color: LightThemeColors.themeGreyColor,
            ),
          ),

          heightBox24,
          DetailsCard(
            borderColor: Colors.transparent,
            bgColor: Color(0xff1B1E25).withValues(alpha: 0.50),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    Assets.images.adds.keyName,
                    height: 20,
                    color: LightThemeColors.themeGreyColor,
                  ),
                  widthBox10,
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                'Messages and calls are end-to-end encrypted. Only people in this chat can read, listen to, or share them. ',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: LightThemeColors.themeGreyColor,
                            ),
                          ),
                          TextSpan(
                            text: 'Learn more',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff1F7DE9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
