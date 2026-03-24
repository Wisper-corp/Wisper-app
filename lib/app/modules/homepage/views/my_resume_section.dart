// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/modules/chat/views/doc_info.dart';
import 'package:wisper/app/modules/homepage/controller/delete_reusme_controller.dart';
import 'package:wisper/app/modules/homepage/controller/my_resume_controller.dart';
import 'package:wisper/app/modules/post/views/my_post_section.dart';
import 'package:wisper/gen/assets.gen.dart';

class MyResumeSection extends StatefulWidget {
  final String userId;
  const MyResumeSection({super.key, required this.userId});

  @override
  State<MyResumeSection> createState() => _MyResumeSectionState();
}

class _MyResumeSectionState extends State<MyResumeSection> {
  late final MyResumeController controller;
  final DeleteResumeController deleteResumeController =
      DeleteResumeController();
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();
    controller = Get.find<MyResumeController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllResume(widget.userId);
    });
  }

  Future<void> _openResumeFile(dynamic resume) async {
    if (resume.file == null || resume.file!.isEmpty) {
      showSnackBarMessage(context, "No file attached", true);
      return;
    }

    String url = resume.file!;
    String fileName =
        resume.name ??
        'resume_${resume.id ?? DateTime.now().millisecondsSinceEpoch}';

    String extension = '';
    if (url.contains('.')) {
      extension = url.split('.').last.split('?').first.toLowerCase();
    }

    if (extension == 'pdf') {
      Get.to(
        () => Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleIconWidget(
                iconRadius: 18.r,
                imagePath: Assets.images.cross.keyName,
                onTap: () => Get.back(),
              ),
            ),
            title: Text(fileName),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          backgroundColor: Colors.black,
          body: SfPdfViewer.network(
            url,
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              Get.back();
              showSnackBarMessage(
                context,
                "Failed to load PDF: ${details.description}",
                true,
              );
            },
          ),
        ),
      );
      return;
    }

    try {
      if (extension.isNotEmpty && !fileName.endsWith('.$extension')) {
        fileName += '.$extension';
      }

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';

      await Dio().download(url, filePath);

      Get.back();

      final OpenResult result = await OpenFilex.open(filePath);

      switch (result.type) {
        case ResultType.done:
          break;
        case ResultType.fileNotFound:
          showSnackBarMessage(context, 'File not found', true);
          break;
        case ResultType.noAppToOpen:
          showSnackBarMessage(context, 'No app found to open this file', true);
          break;
        case ResultType.permissionDenied:
          showSnackBarMessage(context, 'Permission denied', true);
          break;
        case ResultType.error:
      }
    } catch (e) {
      Get.back();
      showSnackBarMessage(context, 'Error opening file: $e', true);
    }
  }

  void deleteResume(String resumeId) {
    showLoadingOverLay(
      asyncFunction: () async => await performDeleteResume(context, resumeId),
      msg: 'Please wait...',
    );
  }

  Future<void> performDeleteResume(
    BuildContext context,
    String resumeId,
  ) async {
    final bool isSuccess = await deleteResumeController.deleteResume(
      resumeId: resumeId,
    );

    if (isSuccess) {
      await controller.getAllResume(StorageUtil.getData(StorageUtil.userId));
      Get.back();
      showSnackBarMessage(context, "Resume deleted successfully!", false);
    } else {
      showSnackBarMessage(context, deleteResumeController.errorMessage, true);
    }
  }

  void _showDeleteResume(String resumeId) {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Delete Resume?",
      message:
          "This resume will be permanently removed.\nThis action cannot be undone.",
      onDelete: () => deleteResume(resumeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.inProgress) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      final resumes = controller.myResumeData;

      if (resumes == null || resumes.isEmpty) {
        if (!connectivityService.isOnline.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'No resumes yet',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ),
        );
      }

      return Expanded(
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: resumes.length,
          itemBuilder: (context, index) {
            final resume = resumes[index];
            final isMyResume =
                widget.userId == StorageUtil.getData(StorageUtil.userId);

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
              child: DocInfo(
                isMyResume: isMyResume,
                onDelete: () {
                  if (resume.id != null) {
                    _showDeleteResume(resume.id!);
                  }
                },
                title: resume.name ?? 'Untitled Resume',
                isDownloaded: true,
                onTap: () => _openResumeFile(resume),
              ),
            );
          },
        ),
      );
    });
  }
}
