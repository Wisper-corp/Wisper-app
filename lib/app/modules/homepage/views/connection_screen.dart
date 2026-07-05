// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/core/widgets/shimmer/member_list_shimmer.dart';
import 'package:wisper/app/modules/chat/controller/all_connection_controller.dart';
import 'package:wisper/app/modules/chat/controller/update_connection_controller.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  AllConnectionController allConnectionController = Get.put(
    AllConnectionController(),
  );
  UpdateConnectionController updateConnectionController =
      UpdateConnectionController();

  // এডিট মোডে আছি কিনা এবং কোন কমেন্ট এডিট করছি
  String? currentEditingCommentId;

  @override
  void initState() {
    allConnectionController.getAllConnection(
      'PENDING',
      StorageUtil.getData(StorageUtil.userId),
    );
    super.initState();
  }

  // সেন্ড বাটনের কাজ (Add অথবা Edit)
  void changeStatus(String userId, String status) {
    showLoadingOverLay(
      asyncFunction: () async => await performSubmit(context, userId, status),
      msg: 'Please wait...',
    );
  }

  Future<void> performSubmit(
    BuildContext context,
    String userId,
    String status,
  ) async {
    bool isSuccess = false;

    // Edit mode
    isSuccess = await updateConnectionController.updateConnection(
      userId: userId,
      status: status,
    );

    if (isSuccess) {
      final AllConnectionController allConnectionController =
          Get.find<AllConnectionController>();

      await allConnectionController.getAllConnection(
        'PENDING',
        StorageUtil.getData(StorageUtil.userId),
      );
    } else {
      showSnackBarMessage(
        context,
        updateConnectionController.errorMessage,
        true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Connections',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            /// COMMENT LIST
            Expanded(
              child: Obx(() {
                if (allConnectionController.inProgress) {
                  return MemberShimmerEffectWidget();
                }

                if (allConnectionController.allConnectionData == null ||
                    allConnectionController.allConnectionData!.isEmpty) {
                  return const Center(child: Text('No Connection found'));
                }

                return ListView.builder(
                  itemCount: allConnectionController.allConnectionData!.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final data =
                        allConnectionController.allConnectionData![index];
                    var status = data.status;
                    var name = data.partner?.person != null
                        ? data.partner!.person!.name
                        : data.partner!.business!.name;
                    var avatar = data.partner?.person != null
                        ? data.partner!.person!.image
                        : data.partner!.business!.image;

                    var title = data.partner?.person != null
                        ? data.partner!.person!.title
                        : data.partner!.business!.industry;
                    return status != 'PENDING'
                        ? Container()
                        : SizedBox(
                            height: 70.h,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              trailing: SizedBox(
                                width: 140.w,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 30.h,
                                        child: CustomElevatedButton(
                                          title: 'Accept',
                                          textSize: 10.sp,
                                          onPress: () {
                                            changeStatus(
                                              data.id ?? '',
                                              'ACCEPTED',
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: SizedBox(
                                        height: 30.h,
                                        child: CustomElevatedButton(
                                          title: 'Reject',
                                          textSize: 10.sp,
                                          color: Colors.red,
                                          onPress: () {
                                            changeStatus(
                                              data.id ?? '',
                                              'REJECTED',
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              leading: GestureDetector(
                                onTap: () {
                                  Get.to(
                                    () => data.partner?.person != null
                                        ? OthersPersonScreen(
                                            userId: data.partner?.id ?? '',
                                          ) 
                                        : OthersBusinessScreen(
                                            userId: data.partner?.id ?? '',
                                          ),
                                  );
                                },
                                child: InitialsAvatar(
                                  name: name ?? '',
                                  imageUrl: avatar,
                                  radius: 20.r,
                                  fontSize: 14,
                                ),
                              ),
                              title: Text(
                                name ?? '',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                title ?? '',

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
