import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/widgets/shimmer/gallery_post_shimmer.dart';
import 'package:wisper/app/modules/post/controller/others_job_post_controller.dart';
import 'package:wisper/app/modules/job/widgets/job_card.dart';

class OthersJobSection extends StatefulWidget {
  final String? userId;
  const OthersJobSection({super.key, this.userId});

  @override
  State<OthersJobSection> createState() => _OthersJobSectionState();
}

class _OthersJobSectionState extends State<OthersJobSection> {
  final OthersJobController controller = Get.put(OthersJobController());
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();
    print('User ID: ${widget.userId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetPagination();
      print('User ID avobe callback: ${widget.userId}');
      controller.getAllJob(userId: widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // Expanded Obx এর বাইরে → সমস্যা সমাধান!
      child: Obx(() {
        if (controller.inProgress) {
          return PostShimmerEffectWidget();
        }

        if (controller.allJobData.isEmpty) {
          if (!connectivityService.isOnline.value) {
            return const Center(child: PostShimmerEffectWidget());
          }
          return const Center(
            child: Text(
              'No posts yet',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: controller.allJobData.length,
          itemBuilder: (context, index) {
            final job = controller.allJobData[index];
            final formattedTime = DateFormatter(
              job.createdAt!,
            ).getRelativeTimeFormat();

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: JobCard(
                showAction: false,
                ontap: null,
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
    );
  }
}
