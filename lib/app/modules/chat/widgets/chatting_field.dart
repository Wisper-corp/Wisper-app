import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/file_picker.dart';
import 'package:wisper/app/core/utils/image_picker.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/modules/chat/controller/image_decode_controller.dart';
import 'package:wisper/app/modules/chat/controller/message_controller.dart';
import 'package:wisper/app/modules/chat/views/person/attach_buttom.dart';
import 'package:wisper/app/modules/chat/widgets/create_offer_dialog.dart';
import 'package:wisper/gen/assets.gen.dart';

class ChattingFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final RxBool isSendEnabled;
  final String chatId;
  final String receiverId;

  const ChattingFieldWidget({
    super.key,
    required this.controller,
    required this.isSendEnabled,
    required this.chatId,
    required this.receiverId,
  });

  @override
  State<ChattingFieldWidget> createState() => _ChattingFieldWidgetState();
}

class _ChattingFieldWidgetState extends State<ChattingFieldWidget> {
  final FileDecodeController fileDecodeController = Get.find<FileDecodeController>();

  final ImagePickerHelper _imagePickerHelper = ImagePickerHelper();
  final AttachmentPickerHelper _attachmentPickerHelper = AttachmentPickerHelper();

  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_updateSendButton);
    ever(fileDecodeController.imageUrlRx, (_) => _updateSendButton());
  }

  void _updateSendButton() {
    widget.isSendEnabled.value = widget.controller.text.trim().isNotEmpty ||
        fileDecodeController.imageUrl.isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSendButton);
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
        onOfferSelected: () {
          Navigator.pop(context); // close attachment sheet
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => CreateOfferDialog(
                chatId: widget.chatId,
                receiverId: widget.receiverId,
                onOfferCreated: (offer) {
                  // Inject offer as a chat message immediately
                  try {
                    final msgController = Get.find<MessageController>();
                    msgController.injectOfferMessage(offer);
                    msgController.scrollToBottom();
                  } catch (_) {}
                  Get.snackbar(
                    'Offer Sent',
                    'Your offer has been sent successfully!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
              ),
            ),
          );
        },
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
          child: Obx(() {
            final hasAttachment = fileDecodeController.imageUrl.isNotEmpty || fileDecodeController.inProgress;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attachment preview — only shown when there's something
                if (hasAttachment)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildAttachmentPreview(),
                  ),

                // Text field
                TextFormField(
                  controller: widget.controller,
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
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAttachmentPreview() {
    if (fileDecodeController.inProgress) {
      return _buildPreviewContainer(
        child: const SizedBox(
          width: 80,
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
      );
    }

    final url = fileDecodeController.imageUrl;
    if (url.isEmpty) return const SizedBox.shrink();

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