import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/label_data.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/job/views/job_details_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class JobCard extends StatelessWidget {
  final bool? showAction;
  final VoidCallback? ontap;
  final GlobalKey? suffixIconKey; // This is the key for CustomPopupMenu

  final String? postId;
  final String? ownerName;
  final String? ownerImage;
  final String? ownerDesignation;
  final String? jobTitle;
  final String? salary;
  final String? location;
  final String? jobType;
  final String? shiftType;
  final String? jobDescription;
  final String? date;

  const JobCard({
    super.key,
    this.postId,
    this.ownerName,
    this.ownerImage,
    this.ownerDesignation,
    this.jobTitle,
    this.salary,
    this.location,
    this.jobType,
    this.shiftType,
    this.jobDescription,
    this.date,
    this.showAction = false,
    this.ontap,
    this.suffixIconKey, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    final String shift = shiftType == 'MONTHLY' ? 'mo' : 'hr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Get.to(
            () => JobDetailsScreen(jobId: postId!),
            transition: Transition.rightToLeft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade800,
                radius: 21.r,
                backgroundImage: ownerImage != null && ownerImage!.isNotEmpty
                    ? NetworkImage(ownerImage!)
                    : null,
                child: ownerImage == null || ownerImage!.isEmpty
                    ? Icon(Icons.business, color: Colors.white, size: 24.r)
                    : null,
              ),
              widthBox8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ownerName ?? 'Unknown Company',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showAction == true)
                          GestureDetector(
                            onTap: ontap,
                            child: Icon(
                              Icons.more_vert,
                              key: suffixIconKey, // Critical: attach the key here!
                              color: LightThemeColors.themeGreyColor,
                              size: 24.r,
                            ),
                          ),
                      ],
                    ),
                    heightBox4,
                    Text(
                      ownerDesignation ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 10.sp,
                        color: LightThemeColors.themeGreyColor,
                      ),
                    ),
                    heightBox4,
                    Text(
                      jobTitle ?? 'No Title',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: LightThemeColors.blueColor,
                      ),
                    ),
                    heightBox4,
                    Text(
                      '\$${salary ?? 'Negotiable'}/$shift',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                    heightBox8,
                    Row(
                      children: [
                        Image.asset(
                          Assets.images.location.keyName,
                          height: 12.h,
                        ),
                        widthBox10,
                        Text(
                          location ?? 'Remote',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 10.sp,
                            color: LightThemeColors.themeGreyColor,
                          ),
                        ),
                      ],
                    ),
                    heightBox12,
                    Row(
                      children: [
                        LabelData(
                          title: 'Part-time',
                          bgColor: jobType == 'PART_TIME'
                              ? LightThemeColors.blueColor
                              : null,
                        ),
                        widthBox10,
                        LabelData(
                          title: 'Full-time',
                          bgColor: jobType == 'FULL_TIME'
                              ? LightThemeColors.blueColor
                              : null,
                        ),
                        widthBox10,
                        LabelData(
                          title: 'Contract',
                          bgColor: jobType == 'CONTRACT'
                              ? LightThemeColors.blueColor
                              : null,
                        ),
                      ],
                    ),
                    heightBox12,
                    SizedBox(
                      width: 250.w,
                      child: Text(
                        jobDescription ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12.sp,
                          color: const Color(0xffD0D5DD),
                        ),
                      ),
                    ),
                    heightBox16,
                    Text(
                      date ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                        color: LightThemeColors.themeGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        heightBox24,
        StraightLiner(height: 0.4, color: const Color(0xff454545)),
      ],
    );
  }
}