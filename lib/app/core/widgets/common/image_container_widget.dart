import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ImageContainer extends StatelessWidget {
  final List<String>? images;
  final double height;
  final double width;
  final double borderRadius;

  const ImageContainer({
    super.key,
    this.images,
    required this.height,
    required this.width,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> validImages =
        images?.where((url) => url.isNotEmpty).toList() ?? [];

    if (validImages.isEmpty) return const SizedBox.shrink();

    final int displayCount = validImages.length.clamp(1, 4);

    return GestureDetector(
      onTap: () {
        Get.to(() => FullScreenImageViewer(
              imageUrls: validImages,
              initialIndex: 0,
            ));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: _buildImageLayout(displayCount, validImages),
      ),
    );
  }

  Widget _buildImageLayout(int count, List<String> images) {
    if (count == 1) {
      // Single image — full width, 16:9 landscape like Twitter/X
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _image(images[0]),
      );
    } else if (count == 2) {
      // Two images — side by side, equal width, taller (like Twitter/X)
      return AspectRatio(
        aspectRatio: 16 / 12,
        child: Row(
          children: [
            Expanded(child: _image(images[0])),
            const SizedBox(width: 3),
            Expanded(child: _image(images[1])),
          ],
        ),
      );
    } else if (count == 3) {
      // Twitter/X style: 1 large on left, 2 stacked on right
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: Row(
          children: [
            // Large left image
            Expanded(
              flex: 6,
              child: _image(images[0]),
            ),
            const SizedBox(width: 3),
            // Two stacked right
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Expanded(child: _image(images[1])),
                  const SizedBox(height: 3),
                  Expanded(child: _image(images[2])),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // 4 images — 1 large top + 3 in a row below (like Twitter/X)
      return AspectRatio(
        aspectRatio: 4 / 5,
        child: Column(
          children: [
            // Top large image
            Expanded(
              flex: 3,
              child: _image(images[0]),
            ),
            const SizedBox(height: 3),
            // Bottom 3 images in a row
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: _image(images[1])),
                  const SizedBox(width: 3),
                  Expanded(child: _image(images[2])),
                  const SizedBox(width: 3),
                  Expanded(child: _image(images[3])),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _image(String url) {
    return GestureDetector(
      onTap: () {
        final List<String> validImages =
            images?.where((u) => u.isNotEmpty).toList() ?? [];
        final int index = validImages.indexOf(url);
        Get.to(() => FullScreenImageViewer(
              imageUrls: validImages,
              initialIndex: index >= 0 ? index : 0,
            ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}


class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "${_currentIndex + 1} / ${widget.imageUrls.length}",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ),
              );
            },
          ),

          // Optional: left / right arrow (ছোট স্ক্রিনে সুবিধা হয়)
          if (widget.imageUrls.length > 1) ...[
            Positioned(
              left: 8.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                  onPressed: _currentIndex > 0
                      ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                ),
              ),
            ),
            Positioned(
              right: 8.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                  onPressed: _currentIndex < widget.imageUrls.length - 1
                      ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}