import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/widgets/shimmer/gallery_post_shimmer.dart';
import 'package:wisper/app/modules/job/controller/favorite_job_controller.dart';
import 'package:wisper/app/modules/job/widgets/job_card.dart';

class FavoriteJobScreen extends StatefulWidget {
  const FavoriteJobScreen({super.key});

  @override
  State<FavoriteJobScreen> createState() => _FavoriteJobScreenState();
}

class _FavoriteJobScreenState extends State<FavoriteJobScreen> {
  final FavoriteController favoriteController = Get.put(FavoriteController());
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();
    favoriteController.getAllFavorite();
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Jobs'),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
        child: Obx(() {
          if (favoriteController.inProgress) {
            return PostShimmerEffectWidget();
          } else if (favoriteController.favoriteJobData == null ||
              favoriteController.favoriteJobData!.isEmpty) {
            if (!connectivityService.isOnline.value) {
              return const Center(child: PostShimmerEffectWidget());
            }
            return SizedBox(
              height: 500,
              child: const Center(
                child: Text('No job found', style: TextStyle(fontSize: 12)),
              ),
            );
          } else {
            print('Length: ${favoriteController.favoriteJobData?.length}');

            return Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(0),
                itemCount: favoriteController.favoriteJobData?.length,

                itemBuilder: (context, index) {
                  var date =
                      favoriteController.favoriteJobData?[index].job?.createdAt;
                  final DateFormatter formattedTime = DateFormatter(date!);
                  var job = favoriteController.favoriteJobData?[index].job;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: JobCard(
                      postId: job?.id ?? '',
                      ownerImage: job?.author?.business?.image ?? '',
                      ownerName: job?.author?.business?.name ?? '',
                      ownerDesignation: job?.author?.business?.name ?? '',
                      jobTitle: job?.title ?? '',
                      salary: job?.salary.toString() ?? '',
                      location: job?.location ?? '',
                      jobType: job?.type ?? '',
                      jobDescription: job?.description ?? '',
                      shiftType: job?.compensationType ?? '',
                      date: formattedTime.getRelativeTimeFormat(),
                    ),
                  );
                },
              ),
            );
          }
        }),
      ),
    );
  }
}
