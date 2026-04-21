import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/widgets/shimmer/gallery_post_shimmer.dart';
import 'package:wisper/app/modules/job/controller/feed_job_controller.dart';
import 'package:wisper/app/modules/job/widgets/job_card.dart';

class JobSection extends StatefulWidget {
  final String? searchQuery;
  final String? jobType;
  final String? groupId;
  const JobSection({super.key, this.searchQuery, this.jobType, this.groupId});

  @override
  State<JobSection> createState() => _JobSectionState();
}

class _JobSectionState extends State<JobSection> {
  final AllFeedJobController controller = Get.put(AllFeedJobController());
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.searchQuery != null || widget.searchQuery != '') {
        controller.resetPagination();
      }
      controller.getJobs(
        searchQuery: widget.searchQuery,
        groupId: widget.groupId,
      );
    });
  }

  @override
  void didUpdateWidget(covariant JobSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      controller.resetPagination();
      controller.getJobs(searchQuery: widget.searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.inProgress) {
        return const Center(child: PostShimmerEffectWidget());
      } else if (controller.allJobData.isEmpty) {
        if (!connectivityService.isOnline.value) {
          return const Center(child: PostShimmerEffectWidget());
        }
        return SizedBox(
          height: 500,
          child: const Center(
            child: Text('Not available', style: TextStyle(fontSize: 12)),
          ),
        );
      } else {
        print('Length: ${controller.allJobData.length}');

        return ListView.builder(
          padding: EdgeInsets.all(0),
          itemCount: controller.allJobData.length,

          itemBuilder: (context, index) {
            var date = controller.allJobData[index].createdAt;
            final DateFormatter formattedTime = DateFormatter(date!);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: JobCard(
                postId: controller.allJobData[index].id,
                ownerImage:
                    controller.allJobData[index].author!.business?.image ?? '',
                ownerName:
                    controller.allJobData[index].author!.business?.name ?? '',
                ownerDesignation:
                    controller.allJobData[index].author!.business?.industry ??
                    '',
                jobTitle: controller.allJobData[index].title ?? '',
                salary: controller.allJobData[index].salary.toString(),
                location:
                    controller.allJobData[index].location ?? 'Not Mentioned',
                jobType: controller.allJobData[index].type ?? '',
                jobDescription: controller.allJobData[index].description ?? '',
                shiftType: controller.allJobData[index].compensationType ?? '',
                date: formattedTime.getRelativeTimeFormat(),
              ),
            );
          },
        );
      }
    });
  }
}
