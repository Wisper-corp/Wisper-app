import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/shimmer/gallery_post_shimmer.dart';
import 'package:wisper/app/modules/job/controller/feed_job_controller.dart';
import 'package:wisper/app/modules/job/views/job_post_screen.dart';
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
      controller.resetPagination();
      controller.getJobs(
        searchQuery: widget.searchQuery,
        groupId: widget.groupId,
      );
    });
  }

  Future<void> _refreshJobs() async {
    controller.resetPagination();
    controller.getJobs(searchQuery: widget.searchQuery, groupId: widget.groupId);
    while (controller.inProgress) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void didUpdateWidget(covariant JobSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.groupId != oldWidget.groupId) {
      controller.resetPagination();
      controller.getJobs(
        searchQuery: widget.searchQuery,
        groupId: widget.groupId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness = StorageUtil.getData(StorageUtil.userRole) != "PERSON";
    final showCreateButton = isBusiness && widget.groupId != null;

    return RefreshIndicator(
      onRefresh: _refreshJobs,
      child: Obx(() {
        Widget listBody;

        if (controller.inProgress) {
          listBody = ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              Center(child: PostShimmerEffectWidget()),
            ],
          );
        } else if (controller.allJobData.isEmpty) {
          if (!connectivityService.isOnline.value) {
            listBody = ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Center(child: PostShimmerEffectWidget()),
              ],
            );
          } else {
            listBody = ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 3.5),
                const Center(
                  child: Text('No Job Found', style: TextStyle(fontSize: 12)),
                ),
              ],
            );
          }
        } else {
          listBody = ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: controller.allJobData.length,
            itemBuilder: (context, index) {
              final job = controller.allJobData[index];
              final date = job.createdAt;
              final formattedTime = DateFormatter(date!).getRelativeTimeFormat();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: JobCard(
                  postId: job.id ?? '',
                  ownerImage: job.author!.business?.image ?? '',
                  ownerName: job.author!.business?.name ?? '',
                  ownerDesignation: job.author!.business?.industry ?? '',
                  jobTitle: job.title ?? '',
                  salary: job.salary.toString(),
                  location: job.location ?? 'Not Mentioned',
                  jobType: job.type ?? '',
                  jobDescription: job.description ?? '',
                  shiftType: job.compensationType ?? '',
                  date: formattedTime,
                ),
              );
            },
          );
        }

        return Column(
          children: [
            Expanded(child: listBody),
            if (showCreateButton)
              CustomElevatedButton(
                textSize: 12,
                borderRadius: 30,
                height: 40,
                title: 'Create Job',
                onPress: () {
                  Get.to(() => JobPostScreen(groupId: widget.groupId));
                },
              ),
            if (showCreateButton) heightBox10,
          ],
        );
      }),
    );
  }
}
