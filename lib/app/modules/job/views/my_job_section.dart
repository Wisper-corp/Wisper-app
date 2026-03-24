// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_popup.dart';
import 'package:wisper/app/core/widgets/shimmer/gallery_post_shimmer.dart';
import 'package:wisper/app/modules/job/controller/delete_job_controller.dart';
import 'package:wisper/app/modules/job/controller/feed_job_controller.dart';
import 'package:wisper/app/modules/job/controller/my_job_controller.dart';
import 'package:wisper/app/modules/job/views/edit_job_post_screen.dart';
import 'package:wisper/app/modules/job/widgets/job_card.dart';
import 'package:wisper/app/modules/post/views/my_post_section.dart';

class MyJobSection extends StatefulWidget {
  const MyJobSection({super.key});

  @override
  State<MyJobSection> createState() => _MyJobSectionState();
}

class _MyJobSectionState extends State<MyJobSection> {
  final MyFeedJobController controller = Get.find<MyFeedJobController>();
  final DeleteJobController deletePostController = DeleteJobController();
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();
    final userId = StorageUtil.getData(StorageUtil.userId);
    if (userId != null) {
      controller.getJobs(authorId: userId);
    }
  }

  void deleteJob(String jobId) {
    showLoadingOverLay(
      asyncFunction: () async => await performDeleteJob(context, jobId), 
      msg: 'Please wait...',
    );
  }

  Future<void> performDeleteJob(BuildContext context, String jobId) async {
    final bool isSuccess = await deletePostController.deletePost(jobId: jobId);

    if (isSuccess) {
      final MyFeedJobController myFeedJobController =
          Get.find<MyFeedJobController>();
      final AllFeedJobController allFeedJobController = 
          Get.find<AllFeedJobController>();

      allFeedJobController.resetPagination();
      myFeedJobController.resetPagination();
      await myFeedJobController.getJobs();
      await allFeedJobController.getJobs();

      Get.back();
      showSnackBarMessage(context, "Job deleted successfully!", false);
    } else {
      showSnackBarMessage(context, deletePostController.errorMessage, true);
    }
  }

  void _showDeleteJob(String jobId) {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Delete Job?",
      message:
          "This job will be permanently removed.\nThis action cannot be undone.",
      onDelete: () => deleteJob(jobId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.inProgress) {
              return PostShimmerEffectWidget();
            }

            if (controller.allJobData.isEmpty) {
              if (!connectivityService.isOnline.value) {
                return PostShimmerEffectWidget();
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_off, size: 64.sp, color: Colors.grey),
                    SizedBox(height: 16.h),
                    Text(
                      'No jobs posted yet',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your posted jobs will appear here',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: controller.allJobData.length,
              itemBuilder: (context, index) {
                final job = controller.allJobData[index];
                final date = job.createdAt;
                final formattedTime = date != null
                    ? DateFormatter(date).getRelativeTimeFormat()
                    : 'Just now';

                final GlobalKey suffixButtonKey = GlobalKey();

                final customPopupMenu = CustomPopupMenu(
                  targetKey: suffixButtonKey,
                  options: [
                    Text(
                      'Edit Job',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Delete Job',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                  optionActions: {
                    '0': () => Get.to(() => EditJobPostScreen(job: job)),
                    '1': () => _showDeleteJob(job.id ?? ''),
                  },
                  menuWidth: 180.w,
                  menuHeight: 48.h,
                );

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: JobCard(
                    showAction: true,
                    suffixIconKey: suffixButtonKey,
                    ontap: () => customPopupMenu.showMenuAtPosition(context),
                    postId: job.id ?? '',
                    ownerImage: job.author?.business?.image ?? '',
                    ownerName: job.author?.business?.name ?? 'Unknown Company',
                    ownerDesignation: job.author?.business?.industry ?? '',
                    jobTitle: job.title ?? 'No Title',
                    salary: job.salary?.toString() ?? 'Negotiable',
                    location: job.location ?? 'Remote',
                    jobType: job.type ?? 'Full Time',
                    jobDescription: job.description ?? '',
                    shiftType: job.compensationType ?? 'Hourly',
                    date: formattedTime,
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
