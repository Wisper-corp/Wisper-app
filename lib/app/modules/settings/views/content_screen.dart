import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/modules/profile/controller/content_controller.dart';

class ContentScreen extends StatefulWidget {
  final String title;
  const ContentScreen({super.key, required this.title});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final ContentController contentController = Get.put(ContentController());
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();
  @override
  void initState() {
    super.initState();
    contentController.getMyContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: Obx(() {
        if (contentController.inProgress) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (!connectivityService.isOnline.value &&
              contentController.contentData == null) {
            return const Center(child: CircularProgressIndicator());
          }
          var data = contentController.contentData;
          var updateData = widget.title == 'Privacy Policy'
              ? data?.privacyPolicy
              : data?.termsAndConditions;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Html(data: updateData),
                // Text(updateData ?? 'No Data found'),
              ],
            ),
          );
        }
      }),
    );
  }
}
