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

  /// Tiles are separated rather than butted together: these are products and
  /// services in a trade catalogue, so each photo should read as its own item
  /// on a shelf, not as one mosaic. Nothing spans or dominates.
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final List<String> validImages =
        images?.where((url) => url.isNotEmpty).toList() ?? [];

    if (validImages.isEmpty) return const SizedBox.shrink();

    return _buildImageLayout(validImages);
  }

  Widget _buildImageLayout(List<String> images) {
    final int count = images.length;
    // Anything past the fourth still opens in the viewer; the fourth tile
    // carries the count so the post never silently hides photos.
    final int hidden = count > 4 ? count - 4 : 0;

    // The outer ratio is chosen so each tile lands portrait-ish, which suits
    // product photography better than the old landscape crops.
    if (count == 1) {
      return AspectRatio(aspectRatio: 16 / 9, child: _tile(images, 0));
    }

    if (count == 2) {
      return AspectRatio(
        aspectRatio: 8 / 5,
        child: Row(
          children: [
            Expanded(child: _tile(images, 0)),
            const SizedBox(width: _gap),
            Expanded(child: _tile(images, 1)),
          ],
        ),
      );
    }

    if (count == 3) {
      return AspectRatio(
        aspectRatio: 9 / 4,
        child: Row(
          children: [
            Expanded(child: _tile(images, 0)),
            const SizedBox(width: _gap),
            Expanded(child: _tile(images, 1)),
            const SizedBox(width: _gap),
            Expanded(child: _tile(images, 2)),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(images, 0)),
                const SizedBox(width: _gap),
                Expanded(child: _tile(images, 1)),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(images, 2)),
                const SizedBox(width: _gap),
                Expanded(child: _tile(images, 3, hidden: hidden)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(List<String> images, int index, {int hidden = 0}) {
    final radius = BorderRadius.circular(borderRadius.r);

    return GestureDetector(
      // Index by position: indexOf() opens the wrong photo when a post
      // repeats the same URL.
      onTap: () => Get.to(
        () => FullScreenImageViewer(imageUrls: images, initialIndex: index),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: Color(0xff1C1F23)),
              errorWidget: (_, __, ___) => ColoredBox(
                color: const Color(0xff1C1F23),
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 20.sp,
                  color: const Color(0xff5A6169),
                ),
              ),
            ),
            // A hairline keeps a dark photo from bleeding into the dark card
            // behind it, which is what makes the tiles read as separate.
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            if (hidden > 0)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: Text(
                    '+$hidden',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
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
        backgroundColor: Colors.black.withValues(alpha: 0.4),
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