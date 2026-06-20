import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/chat/widgets/option.dart';
import 'package:wisper/gen/assets.gen.dart';

class AttachmentBottomSheet extends StatelessWidget {
  final VoidCallback onImageSelected;
  final VoidCallback onVideoSelected;
  final VoidCallback onFileSelected;
  final VoidCallback onOfferSelected;

  const AttachmentBottomSheet({
    super.key,
    required this.onImageSelected,
    required this.onVideoSelected,
    required this.onFileSelected,
    required this.onOfferSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: Get.height * 0.22,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Option(
                onTap: () {
                  Get.back(); // Close bottom sheet
                  onImageSelected(); // Trigger image picker
                },
                imagePath: Assets.images.gallery.keyName,
                iconColor: const Color(0xff6192FD),
                title: 'Image',
              ),
              Option(
                onTap: () {
                  Get.back();
                  onVideoSelected();
                },
                imagePath: Assets.images.video.keyName,
                iconColor: const Color(0xffB95BFC),
                title: 'Video',
              ),
              Option(
                onTap: () {
                  Get.back();
                  onFileSelected();
                },
                imagePath: Assets.images.file.keyName,
                iconColor: const Color(0xff00F359),
                title: 'Document',
              ),
              Option(
                onTap: () {
                  Get.back();
                  onOfferSelected();
                },
                imagePath: Assets.images.file.keyName, // Will use a money/offer icon
                iconColor: const Color(0xffFFD700),
                title: 'Offer',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
