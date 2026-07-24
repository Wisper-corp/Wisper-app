import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
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
  late final AllFeedJobController controller;

  String get _tag => widget.groupId != null && widget.groupId!.isNotEmpty
      ? 'jobs_group_${widget.groupId}'
      : 'jobs_global';

  @override
  void initState() {
    super.initState();
    // Use tagged controller so group jobs don't overwrite global feed
    controller = Get.isRegistered<AllFeedJobController>(tag: _tag)
        ? Get.find<AllFeedJobController>(tag: _tag)
        : Get.put(AllFeedJobController(), tag: _tag);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetPagination();
      controller.getJobs(
        searchQuery: widget.searchQuery,
        groupId: widget.groupId,
      );
    });
  }

  @override
  void didUpdateWidget(covariant JobSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.jobType != oldWidget.jobType) {
      controller.resetPagination();
      controller.getJobs(
        searchQuery: widget.searchQuery,
        groupId: widget.groupId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.inProgress) {
        return const SizedBox.expand(
          child: Center(child: PostShimmerEffectWidget()),
        );
      } else if (controller.allJobData.isEmpty) {
        return const SizedBox.expand(
          child: Center(
            child: Text('No jobs available', style: TextStyle(fontSize: 12)),
          ),
        );
      } else {
        // Only show jobs that have a company logo
        final jobsWithLogo = controller.allJobData.where((job) {
          final logo = job.companyLogo?.trim() ?? '';
          final bizImage = job.author?.business?.image?.trim() ?? '';
          return logo.isNotEmpty || bizImage.isNotEmpty;
        }).toList();

        if (jobsWithLogo.isEmpty) {
          return const SizedBox.expand(
            child: Center(
              child: Text('No jobs available', style: TextStyle(fontSize: 12)),
            ),
          );
        }

        return ListView.builder(
            padding: EdgeInsets.all(0),
            itemCount: jobsWithLogo.length,
            itemBuilder: (context, index) {
              final job = jobsWithLogo[index];
              final logo = job.companyLogo?.trim() ?? '';
              final bizImage = job.author?.business?.image?.trim() ?? '';
              final resolvedLogo = logo.isNotEmpty ? logo : bizImage;

              var date = job.createdAt;
              final DateFormatter formattedTime = DateFormatter(date!);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: JobCard(
                  postId: job.id,
                  ownerImage: resolvedLogo,
                  ownerName: job.companyName?.isNotEmpty == true
                      ? job.companyName!
                      : job.author?.business?.name ?? '',
                  ownerDesignation: job.author?.business?.industry ?? '',
                  jobTitle: job.title ?? '',
                  salary: job.salary.toString(),
                  location: job.location ?? 'Not Mentioned',
                  jobType: job.type ?? '',
                  locationType: job.locationType ?? '',
                  jobDescription: job.description ?? '',
                  shiftType: job.compensationType ?? '',
                  date: formattedTime.getRelativeTimeFormat(),
                ),
              );
            },
          );
      }
    });
  }
}