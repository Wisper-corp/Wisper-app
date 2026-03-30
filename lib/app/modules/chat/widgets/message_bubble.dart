import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/video_player.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/modules/chat/model/message_keys.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final String fileUrl;
  final String fileType;
  final String senderName;
  final String? senderImage;
  final String time;
  final bool isGroupChat;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.fileUrl,
    required this.fileType,
    required this.senderName,
    this.senderImage,
    required this.time,
    this.isGroupChat = false,
  });

  // Helper: file name extract
  String _getFileName() {
    if (fileUrl.isEmpty) return '';
    return Uri.tryParse(fileUrl)?.pathSegments.last ?? 'file';
  }

  bool _isValidRemoteUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  // Helper: get file extension
  String _getFileExtension() {
    if (fileUrl.isEmpty) return '';
    final uri = Uri.tryParse(fileUrl);
    if (uri == null) return '';

    final path = uri.path;
    if (path.contains('.')) {
      return path.split('.').last.split('?').first.toLowerCase();
    }
    return '';
  }

  // Helper: get file icon
  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_fields;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _openFullScreenImage() {
    if (!_isValidRemoteUrl(fileUrl)) return;
    Get.to(
      () => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              fileUrl,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openSenderProfile() {
    if (isMe) return;
    final senderId = (message[SocketMessageKeys.senderId] ?? '')
        .toString()
        .trim();
    if (senderId.isEmpty) return;

    final senderType = (message[SocketMessageKeys.senderType] ?? 'PERSON')
        .toString()
        .toUpperCase();

    if (senderType == 'BUSINESS') {
      print('Sender type: $senderType');
      Get.to(() => OthersBusinessScreen(userId: senderId));
    } else {
      print('Sender type: $senderType');
      Get.to(() => OthersPersonScreen(userId: senderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String safeFileUrl = _isValidRemoteUrl(fileUrl) ? fileUrl : '';
    Future<void> _handleFileOpen() async {
      if (safeFileUrl.isEmpty) {
        showSnackBarMessage(context, "No file available", true);
        return;
      }

      final extension = _getFileExtension();
      final fileName = _getFileName();

      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        // For PDF - open in app
        if (extension == 'pdf') {
          Get.back(); // Remove loading dialog
          Get.to(
            () => Scaffold(
              appBar: AppBar(
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleIconWidget(
                    iconRadius: 18.r,
                    imagePath: Assets.images.cross.keyName,
                    onTap: () {
                      Get.back();
                    },
                  ),
                ),
                title: Text(fileName, style: const TextStyle(fontSize: 16)),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              backgroundColor: Colors.grey[900],
              body: SfPdfViewer.network(
                fileUrl,
                onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                  Get.back();
                  showSnackBarMessage(
                    Get.context!,
                    "Failed to load PDF: ${details.description}",
                    true,
                  );
                },
                onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                  // PDF loaded successfully
                },
              ),
            ),
          );
          return;
        }

        // For other files - download and open with external app
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';

        // Download the file
        await Dio().download(
          safeFileUrl,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              print(
                'Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
              );
            }
          },
        );

        Get.back(); // Remove loading dialog

        // Open with external app
        final OpenResult result = await OpenFilex.open(filePath);

        switch (result.type) {
          case ResultType.done:
            // Successfully opened
            break;
          case ResultType.fileNotFound:
            showSnackBarMessage(Get.context!, 'File not found', true);
            break;
          case ResultType.noAppToOpen:
            showSnackBarMessage(
              Get.context!,
              'No app found to open this file',
              true,
            );
            break;
          case ResultType.permissionDenied:
            showSnackBarMessage(Get.context!, 'Permission denied', true);
            break;
          case ResultType.error:
          default:
            showSnackBarMessage(Get.context!, 'Error: ${result.message}', true);
            break;
        }
      } catch (e) {
        Get.back(); // Remove loading dialog
        showSnackBarMessage(Get.context!, 'Error: ${e.toString()}', true);
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            GestureDetector(
              onTap: _openSenderProfile,
              child: CircleAvatar(
                radius: 16.r,
                backgroundImage: senderImage != null && senderImage!.isNotEmpty
                    ? NetworkImage(senderImage!)
                    : null,
                child: senderImage == null || senderImage!.isEmpty
                    ? Text(
                        senderName.isNotEmpty
                            ? senderName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          if (!isMe) widthBox8 else widthBox10,

          SizedBox(
            width: 270.w,
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),

                Container(
                  margin: EdgeInsets.symmetric(vertical: 5.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMe
                          ? [const Color(0xff2799EA), const Color(0xff2799EA)]
                          : [const Color(0xffF3F3F5), const Color(0xffF3F3F5)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                      bottomLeft: isMe
                          ? Radius.circular(16.r)
                          : Radius.circular(0),
                      bottomRight: isMe
                          ? Radius.circular(0)
                          : Radius.circular(16.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File Attachment Handling
                      if (safeFileUrl.isNotEmpty) ...[
                        if (fileType == 'IMAGE')
                          GestureDetector(
                            onTap: _openFullScreenImage,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.network(
                                safeFileUrl,
                                height: 200.h,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200.h,
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (_, __, ___) => Container(
                                  height: 20.h,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (fileType == 'VIDEO')
                          GestureDetector(
                            onTap: () {
                              Get.to(
                                () => VideoPlayerScreen(videoUrl: safeFileUrl),
                              );
                            },
                            child: Container(
                              height: 200.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Video thumbnail (if available)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: const Icon(
                                      Icons.play_circle_filled,
                                      size: 60,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                      child: Text(
                                        'Video',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else // Other files (pdf, doc, etc.)
                          GestureDetector(
                            onTap: _handleFileOpen,
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isMe
                                      ? Colors.white30
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getFileIcon(_getFileExtension()),
                                    size: 28.r,
                                    color: isMe
                                        ? Colors.white
                                        : Colors.blue[700],
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getFileName(),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          _getFileExtension().toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: isMe
                                                ? Colors.white70
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: 8.h),
                      ],

                      // Text Message
                      if (message['text'].toString().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: safeFileUrl.isNotEmpty ? 8.h : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['text'].toString(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                              // SizedBox(height: 4.h),
                              // Text(
                              //   time,
                              //   style: TextStyle(
                              //     fontSize: 8.sp,
                              //     color: isMe ? Colors.white : Colors.black,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Time + seen tick
                Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Row(
                    mainAxisAlignment: isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      // if (isMe) ...[
                      //   SizedBox(width: 6.w),
                      //   Icon(
                      //     message['seen'] == true
                      //         ? Icons.check_circle
                      //         : Icons.check,
                      //     size: 14.sp,
                      //     color: message['seen'] == true
                      //         ? Colors.cyan
                      //         : Colors.white70,
                      //   ),
                      // ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
