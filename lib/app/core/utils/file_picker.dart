import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AttachmentPickerHelper {
  final ImagePicker _imagePicker = ImagePicker();
   
  // ───────────────────────────────────────────────────────────
  // ১. Video পিক করা (শুধু গ্যালারি থেকে, single)
  // ───────────────────────────────────────────────────────────
  Future<void> pickVideo(
    BuildContext context,
    Function(File) onVideoPicked,
  ) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        onVideoPicked(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    }
  }

  // ───────────────────────────────────────────────────────────
  // ২. Document পিক করা (PDF, multiple allowed)
  // ───────────────────────────────────────────────────────────
  Future<void> pickDocument(
    BuildContext context, 
    Function(List<File>) onDocumentsPicked,
  ) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'], 
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.paths
            .whereType<String>()
            .map((path) => File(path))
            .toList();
        onDocumentsPicked(files);
      }
    } catch (e) {
      debugPrint("Error picking document: $e");
    } finally {
      // if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  // ───────────────────────────────────────────────────────────
  // ৩. Main Attachment Dialog (শুধু Video + Document)
  //    Image এখানে থাকবে না
  // ───────────────────────────────────────────────────────────
  Future<void> showAttachmentDialog(
    BuildContext context, {
    required Function(File) onVideoSelected,
    required Function(List<File>) onDocumentSelected,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Choose Video
                ListTile(
                  leading: Icon(
                    Icons.videocam,
                    size: 30.sp,
                    color: const Color(0xffB95BFC),
                  ),
                  title: Text(
                    'Choose Video',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await pickVideo(context, onVideoSelected);
                  },
                ),

                const Divider(height: 1),

                // Choose Document
                ListTile(
                  leading: Icon(
                    Icons.description,
                    size: 30.sp,
                    color: const Color(0xff00F359),
                  ),
                  title: Text(
                    'Choose Document',
                    style: TextStyle( 
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    // Navigator.pop(dialogContext);
                    await pickDocument(context, onDocumentSelected);
                  },
                ),

                const Divider(height: 1),
 
                // Cancel
                ListTile(
                  title: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  onTap: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
