import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/modules/post/views/gallery_post_screen.dart';
import 'package:wisper/app/modules/job/views/job_post_screen.dart';
import 'package:wisper/app/modules/homepage/views/resume_post_screen.dart';
import 'package:wisper/app/modules/post/widgets/post_option_card.dart';
import 'package:wisper/gen/assets.gen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}
 
class _CreatePostScreenState extends State<CreatePostScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            heightBox70,
            Text(
              "Create Post",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              "What would you like to share today?",
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: Color(0xff98A2B3),
              ),
            ),

            heightBox30,
            PostOptionCard(
              onTap: () {
                Get.to(GalleryPostScreen());
              },
              imagePath: Assets.images.gallery02.keyName,
              color: Color(0xffD0DFFF),
              title: "Media",
              subtitle: "Share photos, videos, thoughts, or updates",
            ),
            StorageUtil.getData(StorageUtil.userRole) != "PERSON"
                ? heightBox12
                : const SizedBox(),
            StorageUtil.getData(StorageUtil.userRole) != "PERSON"
                ? PostOptionCard(
                    onTap: () {
                      Get.to(JobPostScreen());
                    },
                    imagePath: Assets.images.file.keyName,
                    color: Color(0xffDBFFE8),
                    title: "Job",
                    subtitle:
                        "Share your work experience, skills, or achievements",
                  )
                : const SizedBox(),
            heightBox12,
            StorageUtil.getData(StorageUtil.userRole) == "PERSON"
                ? PostOptionCard(
                    onTap: () {
                      Get.to(ResumePostScreen());
                    },
                    imagePath: Assets.images.file.keyName,
                    color: Color(0xffDBFFE8),
                    title: "Resume",
                    subtitle:
                        "Share your work experience, skills, or achievements",
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
