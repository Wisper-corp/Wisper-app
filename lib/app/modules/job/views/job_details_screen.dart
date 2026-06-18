import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';
import 'package:wisper/app/core/widgets/common/label_data.dart';
import 'package:wisper/app/modules/chat/controller/create_chat_controller.dart';
import 'package:wisper/app/modules/chat/views/person/message_screen.dart';
import 'package:wisper/app/modules/job/controller/favorite_job_controller.dart';
import 'package:wisper/app/modules/job/controller/single_job_controller.dart';
import 'package:wisper/app/modules/homepage/widget/feature_list.dart';
import 'package:wisper/app/modules/payment/view/payment_webview_screen.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

import 'package:open_mail_launcher/open_mail_launcher.dart'; 
import 'package:url_launcher/url_launcher.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;
  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final SingleJobController singleJobController = Get.put(
    SingleJobController(),
  );
  final FavoriteController favoriteController = FavoriteController();
  final CreateChatController createChatController = Get.put(
    CreateChatController(),
  );

  @override
  void initState() {
    super.initState();
    singleJobController.getSingleJob(widget.jobId);
  }

  void favorite() {
    showLoadingOverLay(
      asyncFunction: () async => await perforfavorite(context),
      msg: 'Please wait...',
    );
  }

  Future<void> perforfavorite(BuildContext context) async {
    final bool isSuccess = await favoriteController.favorite(
      jobId: widget.jobId,
    );
    if (isSuccess) {
      final SingleJobController singleJobController =
          Get.find<SingleJobController>();
      final FavoriteController favoriteController =
          Get.put(FavoriteController());
      await favoriteController.getAllFavorite();
      await singleJobController.getSingleJob(widget.jobId);
    } else {
      showSnackBarMessage(context, favoriteController.errorMessage, true);
    }
  }

  void createChat(String? memberId, String? memberName, String? memberImage) {
    showLoadingOverLay(
      asyncFunction: () async =>
          await performCreateChat(context, memberId, memberName, memberImage),
      msg: 'Please wait...',
    );
  }

  Future<void> performCreateChat(
    BuildContext context,
    String? memberId,
    String? memberName,
    String? memberImage,
  ) async {
    final bool isSuccess = await createChatController.createChat(
      memberId: memberId,
    );
    if (isSuccess) {
      var chatId = createChatController.chatId;
      Get.to(
        ChatScreen(
          chatId: chatId,
          receiverId: memberId ?? '',
          receiverImage: memberImage ?? '',
          receiverName: memberName ?? '',
        ),
      );
    } else {
      showSnackBarMessage(context, createChatController.errorMessage, true);
    }
  }

  Future<void> routeToEmail(String emailAddress) async {
    if (emailAddress.isEmpty || !emailAddress.contains('@')) {
      showSnackBarMessage(context, 'Valid email address not available', true);
      return;
    }

    try {
      final List<MailApp> apps = await OpenMailLauncher.getMailApps();

      if (apps.isEmpty) {
        showSnackBarMessage(
          context,
          'No email apps installed on this device',
          true,
        );
        return;
      }

      final MailApp? gmailApp = apps.firstWhere(
        (app) => app.name.toLowerCase().contains('gmail'),
        orElse: () => apps.first,
      );

      final String jobTitle =
          singleJobController.singleJobData?.title ?? 'Job Position';

      final EmailContent emailContent = EmailContent(
        to: [emailAddress],
        subject: 'Application for $jobTitle',
        body:
            'Dear Hiring Manager,\n\nI am interested in applying for the $jobTitle position.\n\nBest regards,\n[Your Name]',
      );

      bool opened = false;

      if (gmailApp != null) {
        opened = await OpenMailLauncher.openSpecificMailApp(
          mailApp: gmailApp,
          emailContent: emailContent,
        );
      }

      if (!opened) {
        final Uri mailtoUri = Uri(
          scheme: 'mailto',
          path: emailAddress,
          query: encodeQueryParameters({
            'subject': emailContent.subject ?? '',
            'body': emailContent.body ?? '',
          }),
        );

        if (await canLaunchUrl(mailtoUri)) {
          await launchUrl(mailtoUri);
        } else {
          showSnackBarMessage(context, 'Could not open any email app', true);
        }
      }
    } catch (e) {
      showSnackBarMessage(context, 'Error opening email: $e', true);
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries 
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  bool isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
        child: Obx(() {
          if (singleJobController.inProgress) {
            return const Center(child: CircularProgressIndicator());
          } else {
            var job = singleJobController.singleJobData;
            bool isFavorite = job?.isFavorite ?? false;
            var shift = job?.compensationType == 'MONTHLY' ? 'mo' : 'onOff';
            var experience = (job?.experienceLevel == 'SENIOR'
                ? 'Senior'
                : job?.experienceLevel == 'MID_LEVEL'
                ? 'Mid Level'
                : job?.experienceLevel == 'JUNIOR'
                ? 'Junior'
                : 'Entry Level');

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heightBox40,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60.w,
                        child: CustomElevatedButton(
                          title: 'Cancel',
                          onPress: () => Navigator.pop(context),
                          height: 28,
                          textSize: 10,
                          color: Color(0xff323232),
                          borderRadius: 50,
                          textColor: Colors.white,
                        ),
                      ),
                      StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
                          ? CustomElevatedButton(
                              onPress: () {
                                var applicationType = singleJobController
                                    .singleJobData
                                    ?.applicationType;

                                if (applicationType == 'CHAT') {
                                  createChat(
                                    singleJobController
                                            .singleJobData
                                            ?.authorId ??
                                        '',
                                    singleJobController
                                            .singleJobData!
                                            .author!
                                            .business
                                            ?.name ??
                                        '',
                                    singleJobController
                                            .singleJobData
                                            ?.author
                                            ?.business
                                            ?.image ??
                                        '',
                                  );
                                } else if (applicationType == 'EXTERNAL') {
                                  Get.to(
                                    PaymentView(
                                      paymentData: {
                                        'title':
                                            'Apply for ${singleJobController.singleJobData?.title}',
                                        'link':
                                            singleJobController
                                                .singleJobData
                                                ?.applicationLink ??
                                            '',
                                        'reference': '',
                                      },
                                    ),
                                  );
                                } else {
                                  // EMAIL case – তোমার model-এ employer-এর email কোন field-এ আছে change করো
                                  String recipientEmail =
                                      'employer@example.com'; // fallback email
                                  routeToEmail(recipientEmail);
                                }
                              },
                              title: 'Apply for job',
                              width: 93,
                              height: 28,
                              textSize: 10,
                              color: LightThemeColors.blueColor,
                              borderRadius: 50,
                              textColor: Colors.white,
                            )
                          : Container(),
                    ],
                  ),
                  heightBox20,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        job?.title ?? 'Job Title',
                        style: TextStyle(
                          fontSize: 21.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
                          ? GestureDetector(
                              onTap: () {
                                favorite();
                              },
                              child: CircleAvatar(
                                backgroundColor:
                                    LightThemeColors.circleIconColor,
                                radius: 16.r,
                                child: isFavorite
                                    ? Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 20.r,
                                      )
                                    : Icon(
                                        Icons.favorite_border,
                                        color: Colors.white,
                                        size: 20.r,
                                      ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  heightBox10,
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        OthersBusinessScreen(userId: job?.author?.id ?? ''),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundImage: job?.author?.business?.image != null
                              ? NetworkImage(job!.author!.business!.image!)
                              : AssetImage(Assets.images.icon01.keyName)
                                    as ImageProvider,
                        ),
                        widthBox8,
                        Text(
                          job?.author?.business?.name ?? '',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xffD1D1D1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  heightBox20,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Type',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xffD1D1D1),
                            ),
                          ),
                          heightBox8,
                          LabelData(
                            horizontalPadding: 20,
                            verticalPadding: 8,
                            title: job?.type == 'FULL_TIME'
                                ? 'Full Time'
                                : 'Part Time',
                            bgColor: LightThemeColors.blueColor,
                          ),
                        ],
                      ),
                      widthBox40,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Experience Level',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xffD1D1D1),
                            ),
                          ),
                          heightBox8,
                          DetailsCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    Assets.images.adds.keyName,
                                    height: 16.h,
                                    width: 16,
                                    color: LightThemeColors.blueColor,
                                  ),
                                  widthBox4,
                                  Text(
                                    experience,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff8C8C8C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  heightBox10,
                  Text(
                    'Compensation',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xffD1D1D1),
                    ),
                  ),
                  heightBox10,
                  DetailsCard(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job?.compensationType == 'MONTHLY'
                                ? 'Monthly'
                                : 'One off',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff8C8C8C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  heightBox10,
                  Text(
                    'Salary',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xffD1D1D1),
                    ),
                  ),
                  heightBox10,
                  DetailsCard(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$ ${job?.salary.toString() ?? ''}/$shift',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  heightBox10,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Type',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xffD1D1D1),
                            ),
                          ),
                          heightBox8,
                          DetailsCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    Assets.images.location.keyName,
                                    height: 16.h,
                                    width: 16,
                                    color: LightThemeColors.blueColor,
                                  ),
                                  widthBox4,
                                  Text(
                                    job?.locationType ?? '',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff8C8C8C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Educational Qualifications',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xffD1D1D1),
                            ),
                          ),
                          heightBox8,
                          DetailsCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    Assets.images.education.keyName,
                                    height: 16.h,
                                    width: 16,
                                    color: LightThemeColors.blueColor,
                                  ),
                                  widthBox4,
                                  Text(
                                    job?.qualification ?? '',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff8C8C8C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  heightBox20,
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xffD1D1D1),
                    ),
                  ),
                  heightBox10,
                  DetailsCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job?.author!.business?.address ?? 'Not mentioned',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff8C8C8C),
                            ),
                            textAlign: TextAlign.justify,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  heightBox20,
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xffD1D1D1),
                    ),
                  ),
                  heightBox10,
                  DetailsCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job?.description ?? '',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff8C8C8C),
                            ),
                            textAlign: TextAlign.justify,
                            maxLines: isDescriptionExpanded ? null : 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                          heightBox10,
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isDescriptionExpanded = !isDescriptionExpanded;
                              });
                            },
                            child: Text(
                              isDescriptionExpanded ? 'Read Less' : 'Read More',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: LightThemeColors.blueColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  heightBox20,
                  Text(
                    'Application Type',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xffD1D1D1),
                    ),
                  ),
                  heightBox10,
                  DetailsCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job?.applicationType == 'CHAT'
                                ? 'Chat'
                                : job?.applicationType == 'EXTERNAL'
                                ? 'External'
                                : 'Email',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff8C8C8C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  heightBox20,
                  Text(
                    'Requirements',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xffD1D1D1),
                    ),
                  ),
                  heightBox10,
                  DetailsCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children:
                            job?.requirements
                                ?.map(
                                  (requirement) => FeatureList(
                                    iconPath: Assets.images.mark02.keyName,
                                    title: requirement,
                                  ),
                                )
                                .toList() ??
                            [],
                      ),
                    ),
                  ),
                  heightBox20,
                  Text(
                    'Key Responsibilities',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xffD1D1D1),
                    ),
                  ),
                  heightBox10,
                  DetailsCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children:
                            job?.responsibilities
                                ?.map(
                                  (re) => FeatureList(
                                    iconPath: Assets.images.mark02.keyName,
                                    title: re,
                                  ),
                                )
                                .toList() ??
                            [],
                      ),
                    ),
                  ),
                  heightBox20,
                ],
              ),
            );
          }
        }),
      ),
    );
  }
}
