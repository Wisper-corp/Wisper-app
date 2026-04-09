// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/initials.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';
import 'package:wisper/app/modules/homepage/controller/create_resume_controller.dart';
import 'package:wisper/app/modules/homepage/controller/my_resume_controller.dart';
import 'package:wisper/app/modules/profile/controller/buisness/buisness_controller.dart';
import 'package:wisper/app/modules/profile/controller/person/profile_controller.dart';
import 'package:wisper/gen/assets.gen.dart';
import 'package:file_picker/file_picker.dart';

 class ResumePostScreen extends StatefulWidget {
  const ResumePostScreen({super.key});

  @override
  State<ResumePostScreen> createState() => _ResumePostScreenState();
}

class _ResumePostScreenState extends State<ResumePostScreen> {
  final List<File> _selectedFiles = [];
  final FilePickerHelper _filePickerHelper = FilePickerHelper();
  final CreateResumeController createPostController = CreateResumeController();

  final ProfileController profileController = Get.put(ProfileController());
  final BusinessController businessController = Get.put(BusinessController());

  // Role-based user info observables
  final RxBool isLoading = true.obs;
  final RxString userName = ''.obs;
  final RxString userSubtitle = ''.obs;
  final RxString userImageUrl = ''.obs;

  late final bool isPerson;

  void _addFile(File file) {
    setState(() {
      _selectedFiles.add(file);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void createPost() {
    if (_selectedFiles.isEmpty) {
      showSnackBarMessage(
        context,
        "Please select at least one resume file",
        true,
      );
      return;
    }

    showLoadingOverLay(
      asyncFunction: () async => await performCreatePost(),
      msg: 'Please wait...',
    );
  }

  Future<void> performCreatePost() async {
    final bool isSuccess = await createPostController.createResume(
      file: _selectedFiles,
    );

    if (isSuccess) {
      final MyResumeController myResumeController =
          Get.find<MyResumeController>();
      await myResumeController.getAllResume(
        StorageUtil.getData(StorageUtil.userId),
      );
      if (mounted) Navigator.pop(context);
      showSnackBarMessage(context, "Resume posted successfully!", false);
    } else {
      showSnackBarMessage(context, createPostController.errorMessage, true);
    }
  }

  void _updateUserInfo() {
    if (isPerson) {
      final person = profileController.profileData?.auth?.person;
      userName.value = person?.name ?? '';
      userSubtitle.value = person?.title ?? '';
      userImageUrl.value = person?.image ?? '';
      isLoading.value = profileController.inProgress;
    } else {
      final business = businessController.buisnessData?.auth?.business;
      userName.value = business?.name ?? '';
      userSubtitle.value = business?.industry ?? '';
      userImageUrl.value = business?.image ?? '';
      isLoading.value = businessController.inProgress;
    }
  }

  @override
  void initState() {
    super.initState();
    isPerson = StorageUtil.getData(StorageUtil.userRole) == 'PERSON';

    // Fetch profile based on role
    if (isPerson) {
      profileController.getMyProfile().then((_) {
        if (mounted) _updateUserInfo();
      });
    } else {
      businessController.getMyProfile().then((_) {
        if (mounted) _updateUserInfo();
      }); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme consistent
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heightBox40,

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'Resume',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    _selectedFiles.isEmpty
                        ? SizedBox(
                            height: 32.h,
                            width: 66.w,
                            child: CustomElevatedButton(
                              title: 'Post',
                              textSize: 12,
                              borderRadius: 50,
                              color: LightThemeColors.themeGreyColor,
                            ),
                          )
                        : SizedBox(
                            height: 32.h,
                            width: 66.w,
                            child: CustomElevatedButton(
                              title: 'Post',
                              textSize: 12,
                              borderRadius: 50,
                              onPress: createPost,
                            ),
                          ),
                  ],
                ),

                heightBox16,

                // User Info
                Obx(() {
                  if (isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 18.r,
                        backgroundImage: userImageUrl.value.isNotEmpty
                            ? NetworkImage(userImageUrl.value)
                            : null,
                        child: userImageUrl.value.isEmpty
                            ? Text(
                                initialsFromName(userName.value),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      widthBox8,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.value.isEmpty
                                ? 'User Name'
                                : userName.value,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                          if (userSubtitle.value.isNotEmpty)
                            Text(
                              userSubtitle.value,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: LightThemeColors.themeGreyColor,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                }),

                heightBox20,

                // Add Resume Button
                _selectedFiles.isNotEmpty
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        onTap: () {
                          _filePickerHelper.showAlertDialog(context, _addFile);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF60606B)),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          height: 80.h,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CrashSafeImage(
                                Assets.images.gallery02.keyName,
                                height: 24.h,
                              ),
                              widthBox10,
                              Text(
                                'Add Resume',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                  color: LightThemeColors.blueColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                heightBox20,

                // Selected Files List
                if (_selectedFiles.isNotEmpty)
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedFiles.length,
                    separatorBuilder: (_, __) => heightBox10,
                    itemBuilder: (context, index) {
                      final fileName = _selectedFiles[index].path
                          .split('/')
                          .last;
                      return DetailsCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    CrashSafeImage(
                                      Assets.images.pdf.keyName,
                                      height: 20.h,
                                    ),
                                    widthBox10,
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: TextStyle( 
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _removeFile(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                heightBox100, // Keyboard safety
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// FilePickerHelper unchanged
class FilePickerHelper {
  Future<void> pickFiles(
    BuildContext context,
    Function(File) onFilePicked,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom, 
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.path != null) {
            onFilePicked(File(file.path!));
          }
        }
      }
      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error picking files: $e");
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  Future<void> showAlertDialog(
    BuildContext context,
    Function(File) onFilePicked,
  ) {
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          content: SizedBox(
            height: 100.h,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => pickFiles(context, onFilePicked),
                    child: Row(
                      children: [
                        Icon(Icons.description, size: 30.sp),
                        const SizedBox(width: 10),
                        Text(
                          'Choose Resume',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  heightBox12,
                  Container(height: 1, color: Colors.grey[400]),
                  heightBox12,
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
