import 'package:dio/dio.dart';
import 'package:wisper/app/core/widgets/common/video_poster.dart';
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
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

/// How tall a picture or clip may get inside a bubble.
///
/// Media keeps its own shape rather than being cropped to a fixed band, so
/// something needs to stop one very tall photo filling the screen.
final double kChatMediaMaxHeight = 320.h;

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final String fileUrl;
  final String fileType;
  final String senderName;
  final String? senderImage;
  final String time;
  final bool isGroupChat;
  final String? senderId;
  final String? senderType; // 'PERSON' | 'BUSINESS'

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
    this.senderId,
    this.senderType,
  });

  // Helper: file name extract
  String _getFileName() {
    if (fileUrl.isEmpty) return '';
    return Uri.tryParse(fileUrl)?.pathSegments.last ?? 'file';
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

  /// Whether this bubble is carrying a picture or a clip.
  ///
  /// A document is not media here: it is drawn as a bordered row that reads as
  /// part of the bubble, so it keeps the padding text has.
  bool get _isMedia =>
      fileUrl.isNotEmpty && (fileType == 'IMAGE' || fileType == 'VIDEO');

  void _openFullScreenImage() {
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

  @override
  Widget build(BuildContext context) {
    Future<void> _handleFileOpen() async {
      if (fileUrl.isEmpty) {
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
          fileUrl,
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
              onTap: (senderId != null && senderId!.isNotEmpty)
                  ? () => Get.to(() => senderType == 'BUSINESS'
                      ? OthersBusinessScreen(userId: senderId!)
                      : OthersPersonScreen(userId: senderId!))
                  : null,
              child: InitialsAvatar(
                name: senderName,
                imageUrl: senderImage,
                radius: 16.r,
                fontSize: 12,
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
                  // A picture or a clip nearly fills its bubble, the way every
                  // messaging app shows one: the wide padding meant for text
                  // left a thick band of bubble colour framing the media.
                  // A caption still gets room, added under the media itself.
                  padding: _isMedia
                      ? EdgeInsets.all(3.r)
                      : EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMe
                          ? [const Color(0xff2799EA), const Color(0xff2799EA)]
                          : [const Color(0xffF3F3F5), const Color(0xffF3F3F5)],
                    ),
                    borderRadius: BorderRadius.only(
                      // Sender (me): tail at bottom-right → top corners rounded, bottom-left rounded, bottom-right sharp
                      // Receiver: tail at top-left → bottom corners rounded, top-right rounded, top-left sharp
                      topLeft: isMe ? Radius.circular(16.r) : Radius.circular(0),
                      topRight: Radius.circular(16.r),
                      bottomLeft: Radius.circular(16.r),
                      bottomRight: isMe ? Radius.circular(0) : Radius.circular(16.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File Attachment Handling
                      if (fileUrl.isNotEmpty) ...[
                        if (fileType == 'IMAGE')
                          GestureDetector(
                            onTap: _openFullScreenImage,
                            child: ClipRRect(
                              // Concentric with the bubble: 16 outer, 3 of
                              // padding, so 13 inside.
                              borderRadius: BorderRadius.circular(13.r),
                              // No fixed height: the picture keeps its own
                              // shape, as it does in every messaging app. A
                              // 200-high letterbox cropped a tall photo to a
                              // band and left a wide one floating in filler.
                              // Capped so one very tall picture cannot take
                              // the whole screen.
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: kChatMediaMaxHeight),
                                child: Image.network(
                                fileUrl,
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
                                  height: 200.h,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              ),
                            ),
                          )
                        else if (fileType == 'VIDEO')
                          // Its own first frame with a play button, the way a
                          // feed shows a video, rather than a black box.
                          VideoPoster(
                            url: fileUrl,
                            borderRadius: 13,
                            // The same ceiling the picture has, so a portrait
                            // clip cannot tower over every other message.
                            maxHeight: kChatMediaMaxHeight,
                            onTap: () => Get.to(
                              () => VideoPlayerScreen(videoUrl: fileUrl),
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
                        if (!_isMedia) SizedBox(height: 8.h),
                      ],

                      // Text Message
                      if (message['text'].toString().isNotEmpty)
                        Padding(
                          // The bubble no longer pads a media message, so a
                          // caption brings its own margins rather than sitting
                          // flush against the edge.
                          padding: _isMedia
                              ? EdgeInsets.fromLTRB(11.w, 8.h, 11.w, 7.h)
                              : EdgeInsets.only(
                                  top: fileUrl.isNotEmpty ? 8.h : 0,
                                ),
                          child: Text(
                            message['text'].toString(),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Time + seen tick
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
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
                      if (isMe) ...[
                        SizedBox(width: 6.w),
                        Icon(
                          message['seen'] == true
                              ? Icons.check_circle
                              : Icons.check,
                          size: 14.sp,
                          color: message['seen'] == true
                              ? Colors.cyan
                              : Colors.white70,
                        ),
                      ],
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
