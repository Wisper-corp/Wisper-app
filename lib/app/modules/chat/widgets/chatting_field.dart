import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/file_picker.dart';
import 'package:wisper/app/core/utils/image_picker.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/modules/chat/controller/image_decode_controller.dart';
import 'package:wisper/app/modules/chat/views/person/attach_buttom.dart';
import 'package:wisper/gen/assets.gen.dart';

class ChattingFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final RxBool isSendEnabled;

  const ChattingFieldWidget({
    super.key,
    required this.controller,
    required this.isSendEnabled,
  });

  @override
  State<ChattingFieldWidget> createState() => _ChattingFieldWidgetState();
}

class _ChattingFieldWidgetState extends State<ChattingFieldWidget> {
  final FileDecodeController fileDecodeController = Get.find<FileDecodeController>();

  final ImagePickerHelper _imagePickerHelper = ImagePickerHelper();
  final AttachmentPickerHelper _attachmentPickerHelper = AttachmentPickerHelper();

  late FocusNode _focusNode;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = widget.controller;
    _controller.addListener(_updateSendButton);
    ever(fileDecodeController.imageUrlRx, (_) => _updateSendButton());
  }

  void _updateSendButton() {
    if (!mounted) return;
    try {
      widget.isSendEnabled.value =
          _controller.text.trim().isNotEmpty || fileDecodeController.imageUrl.isNotEmpty;
    } catch (_) {
      // Controller might be disposed by parent during a rebuild; ignore.
    }
  }

  @override
  void didUpdateWidget(covariant ChattingFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateSendButton);
      _controller = widget.controller;
      _controller.addListener(_updateSendButton);
      _updateSendButton();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSendButton);
    _focusNode.dispose();
    super.dispose();
  }

  void _onImagePicked(File image) async => await fileDecodeController.imageDecode(image: image);
  void _onVideoPicked(File video) async => await fileDecodeController.videoDecode(image: video);
  void _onDocumentsPicked(List<File> docs) async {
    if (docs.isNotEmpty) await fileDecodeController.fileDecode(image: docs.first);
  }

  void _clearAllAttachments() {
    fileDecodeController.clearAll();
    _updateSendButton();
  }

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentBottomSheet(
        onImageSelected: () => _imagePickerHelper.showAlertDialog(context, _onImagePicked),
        onVideoSelected: () => _attachmentPickerHelper.pickVideo(context, _onVideoPicked),
        onFileSelected: () => _attachmentPickerHelper.pickDocument(context, _onDocumentsPicked),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Plus button – centered vertically
        CircleIconWidget(
          imagePath: Assets.images.plus.keyName,
          radius: 20,
          iconRadius: 18,
          onTap: _showAttachmentBottomSheet,
        ),
        const SizedBox(width: 8),

        // Main input area with preview
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomLeft,
            children: [
              // Text field – always visible at bottom
              TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'Type here...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),

              // Attachment preview – floating above the text field
              Positioned(
                left: 0,
                bottom: 56, // ≈ text field height + small overlap
                child: Obx(() {
                  if (fileDecodeController.inProgress) {
                    final localPath = fileDecodeController.localPath;
                    final isImage = fileDecodeController.currentFileType == 'IMAGE';
                    if (isImage && localPath.isNotEmpty) {
                      return _buildPreviewContainer(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(localPath),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                            const SizedBox(
                              width: 80,
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 3),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return _buildPreviewContainer(
                      child: const SizedBox(
                        width: 80,
                        height: 80,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ),
                    );
                  }

                  if (fileDecodeController.imageUrl.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final url = fileDecodeController.imageUrl;
                  String type = 'image';
                  if (url.contains('.mp4')) type = 'video';
                  if (url.contains('.pdf')) type = 'pdf';

                  return _buildPreviewContainer(
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade700,
                          ),
                          child: type == 'image'
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    type == 'video' ? Icons.play_circle_fill : Icons.picture_as_pdf,
                                    size: 40,
                                    color: Colors.white70,
                                  ),
                                ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: CircleIconWidget(
                            imagePath: Assets.images.cross.keyName,
                            radius: 14,
                            iconRadius: 12,
                            onTap: _clearAllAttachments,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(6),
      child: child,
    );
  }
}
